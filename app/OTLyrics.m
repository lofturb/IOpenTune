//
//  OTLyrics.m
//  OpenTune 9
//

#import "OTLyrics.h"
#import "OTInnertube.h"

@implementation OTLyricLine
@end


@interface OTLyrics ()
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSArray<OTLyricLine *> *> *memory;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *syncedFlags;
@property (nonatomic, strong) NSURLSession *session;
@end

@implementation OTLyrics

+ (instancetype)sharedLyrics
{
    static OTLyrics *lyrics = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        lyrics = [[OTLyrics alloc] init];
    });
    return lyrics;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _memory = [NSMutableDictionary dictionary];
        _syncedFlags = [NSMutableDictionary dictionary];
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        config.timeoutIntervalForRequest = 12.0;
        _session = [NSURLSession sessionWithConfiguration:config];
    }
    return self;
}

- (NSArray<OTLyricLine *> *)cachedLyricsForItemId:(NSString *)itemId
{
    if (itemId.length == 0) {
        return nil;
    }
    return self.memory[itemId];
}

- (BOOL)cachedLyricsAreSyncedForItemId:(NSString *)itemId
{
    if (itemId.length == 0) {
        return NO;
    }
    return [self.syncedFlags[itemId] boolValue];
}

- (void)lyricsForItem:(OTItem *)item
           completion:(void (^)(NSArray<OTLyricLine *> *, BOOL, NSString *, NSError *))completion
{
    if (completion == nil || item == nil) {
        return;
    }
    NSArray<OTLyricLine *> *cached = [self cachedLyricsForItemId:item.itemId];
    if (cached.count > 0) {
        completion(cached, [self cachedLyricsAreSyncedForItemId:item.itemId], nil, nil);
        return;
    }

    NSString *track = item.title ?: @"";
    NSString *artist = item.artistsText ?: @"";
    if (artist.length == 0 && item.subtitle.length > 0) {
        NSArray *parts = [item.subtitle componentsSeparatedByString:@" • "];
        artist = parts.count > 0 ? parts[0] : @"";
    }

    [self fetchLRCLIBTrack:track artist:artist duration:item.duration completion:^(NSString *synced, NSString *plain, NSError *error) {
        if (synced.length > 0 || plain.length > 0) {
            BOOL isSynced = synced.length > 0;
            NSString *text = isSynced ? synced : plain;
            NSArray *lines = [OTLyrics parseLyrics:text];
            if (lines.count > 0) {
                [self cacheLines:lines synced:isSynced forItemId:item.itemId];
                completion(lines, isSynced, text, nil);
                return;
            }
        }
        [self fetchYouTubeLyricsForItem:item completion:completion];
    }];
}

- (void)cacheLines:(NSArray<OTLyricLine *> *)lines synced:(BOOL)synced forItemId:(NSString *)itemId
{
    if (itemId.length == 0) {
        return;
    }
    self.memory[itemId] = lines;
    self.syncedFlags[itemId] = @(synced);
}

#pragma mark - LRCLIB

- (NSString *)escaped:(NSString *)value
{
    NSCharacterSet *allowed = [NSCharacterSet characterSetWithCharactersInString:
                               @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~"];
    return [value stringByAddingPercentEncodingWithAllowedCharacters:allowed] ?: @"";
}

- (void)fetchLRCLIBTrack:(NSString *)track
                  artist:(NSString *)artist
                duration:(NSInteger)duration
              completion:(void (^)(NSString *synced, NSString *plain, NSError *error))completion
{
    if (track.length == 0) {
        completion(nil, nil, nil);
        return;
    }
    NSString *urlString = [NSString stringWithFormat:
        @"https://lrclib.net/api/get?track_name=%@&artist_name=%@&duration=%ld",
        [self escaped:track], [self escaped:artist], (long)MAX(0, duration)];
    [self requestJSON:urlString completion:^(id json, NSError *error) {
        NSDictionary *dictionary = [json isKindOfClass:[NSDictionary class]] ? (NSDictionary *)json : nil;
        if (dictionary) {
            NSString *synced = OTSafeString(dictionary[@"syncedLyrics"]);
            NSString *plain = OTSafeString(dictionary[@"plainLyrics"]);
            if (synced.length > 0 || plain.length > 0) {
                completion(synced, plain, nil);
                return;
            }
        }
        [self searchLRCLIB:track artist:artist completion:completion];
    }];
}

- (void)searchLRCLIB:(NSString *)track
              artist:(NSString *)artist
          completion:(void (^)(NSString *, NSString *, NSError *))completion
{
    NSString *urlString = [NSString stringWithFormat:
        @"https://lrclib.net/api/search?track_name=%@&artist_name=%@",
        [self escaped:track], [self escaped:artist]];
    [self requestJSON:urlString completion:^(NSDictionary *json, NSError *error) {
        NSArray *results = nil;
        if ([json isKindOfClass:[NSDictionary class]]) {
            results = OTSafeArray(json[@"data"]);
        } else if ([json isKindOfClass:[NSArray class]]) {
            results = (NSArray *)json;
        }
        for (NSDictionary *entry in results ?: @[]) {
            NSString *synced = OTSafeString(entry[@"syncedLyrics"]);
            NSString *plain = OTSafeString(entry[@"plainLyrics"]);
            if (synced.length > 0 || plain.length > 0) {
                completion(synced, plain, nil);
                return;
            }
        }
        completion(nil, nil, error);
    }];
}

- (void)requestJSON:(NSString *)urlString completion:(void (^)(id json, NSError *error))completion
{
    NSURL *url = [NSURL URLWithString:urlString];
    if (!url) {
        completion(nil, nil);
        return;
    }
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setValue:@"OpenTune9/1.0 (iPad; iOS 9)" forHTTPHeaderField:@"User-Agent"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request
                                                completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (!data || error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(nil, error);
            });
            return;
        }
        NSError *jsonError = nil;
        id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(json, jsonError);
        });
    }];
    [task resume];
}

#pragma mark - YouTube

- (void)fetchYouTubeLyricsForItem:(OTItem *)item
                       completion:(void (^)(NSArray<OTLyricLine *> *, BOOL, NSString *, NSError *))completion
{
    [[OTInnertube shared] nextForVideo:item.itemId
                            playlistId:item.playlistId
                                 index:0
                            completion:^(NSArray<OTItem *> *items,
                                         NSInteger currentIndex,
                                         NSString *lyricsBrowseId,
                                         NSString *lyricsParams,
                                         NSError *error) {
        if (lyricsBrowseId.length == 0) {
            completion(nil, NO, nil, error ?: [NSError errorWithDomain:@"OTLyrics"
                                                                  code:-1
                                                              userInfo:@{NSLocalizedDescriptionKey:
                                                                             @"Esta canción no tiene letras"}]);
            return;
        }
        [[OTInnertube shared] lyricsWithBrowseId:lyricsBrowseId params:lyricsParams completion:^(NSString *lyrics, NSError *lyricsError) {
            if (lyrics.length == 0) {
                completion(nil, NO, nil, lyricsError);
                return;
            }
            NSArray *lines = [OTLyrics parseLyrics:lyrics];
            [self cacheLines:lines synced:NO forItemId:item.itemId];
            completion(lines, NO, lyrics, nil);
        }];
    }];
}

#pragma mark - Parseo LRC

+ (NSArray<OTLyricLine *> *)parseLyrics:(NSString *)text
{
    if (text.length == 0) {
        return @[];
    }
    NSString *normalized = [text stringByReplacingOccurrencesOfString:@"\r\n" withString:@"\n"];
    normalized = [normalized stringByReplacingOccurrencesOfString:@"\r" withString:@"\n"];
    NSArray *rawLines = [normalized componentsSeparatedByString:@"\n"];

    NSMutableArray *timed = [NSMutableArray array];
    NSMutableArray *plain = [NSMutableArray array];
    NSTimeInterval offset = 0;

    for (NSString *raw in rawLines) {
        NSString *line = [raw stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if (line.length == 0) {
            continue;
        }
        if ([line hasPrefix:@"[offset:"]) {
            NSString *value = [line stringByReplacingOccurrencesOfString:@"[offset:" withString:@""];
            value = [value stringByReplacingOccurrencesOfString:@"]" withString:@""];
            offset = [value doubleValue] / 1000.0;
            continue;
        }
        if ([line hasPrefix:@"[ar:"] || [line hasPrefix:@"[ti:"] || [line hasPrefix:@"[al:"] ||
            [line hasPrefix:@"[by:"] || [line hasPrefix:@"[re:"] || [line hasPrefix:@"[ve:"]) {
            continue;
        }

        NSMutableArray *times = [NSMutableArray array];
        NSString *remaining = line;
        while ([remaining hasPrefix:@"["]) {
            NSRange close = [remaining rangeOfString:@"]"];
            if (close.location == NSNotFound) {
                break;
            }
            NSString *stamp = [remaining substringWithRange:NSMakeRange(1, close.location - 1)];
            NSTimeInterval stampTime = [OTLyrics secondsFromStamp:stamp];
            if (stampTime < 0) {
                break;
            }
            [times addObject:@(stampTime)];
            remaining = [[remaining substringFromIndex:close.location + 1]
                         stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        }

        if (times.count > 0) {
            for (NSNumber *number in times) {
                OTLyricLine *lyric = [[OTLyricLine alloc] init];
                lyric.time = [number doubleValue] + offset;
                lyric.text = remaining;
                [timed addObject:lyric];
            }
        } else {
            [plain addObject:line];
        }
    }

    if (timed.count > 0) {
        [timed sortUsingComparator:^NSComparisonResult(OTLyricLine *a, OTLyricLine *b) {
            if (a.time < b.time) return NSOrderedAscending;
            if (a.time > b.time) return NSOrderedDescending;
            return NSOrderedSame;
        }];
        return timed;
    }

    NSMutableArray *lines = [NSMutableArray array];
    for (NSString *line in plain) {
        OTLyricLine *lyric = [[OTLyricLine alloc] init];
        lyric.time = 0;
        lyric.text = line;
        [lines addObject:lyric];
    }
    return lines;
}

+ (NSTimeInterval)secondsFromStamp:(NSString *)stamp
{
    NSArray *parts = [stamp componentsSeparatedByString:@":"];
    if (parts.count < 2) {
        return -1;
    }
    double minutes = [parts[0] doubleValue];
    double seconds = [parts[1] doubleValue];
    return minutes * 60.0 + seconds;
}

@end

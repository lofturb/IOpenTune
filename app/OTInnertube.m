//
//  OTInnertube.m
//  OpenTune 9
//
//  Cliente de la API interna de YouTube Music (Innertube), equivalente al
//  modulo innertube del OpenTune original.
//

#import "OTInnertube.h"
#import "OTStore.h"
#import <CommonCrypto/CommonDigest.h>

static NSString *const OTUserAgentWeb =
    @"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36";
static NSString *const OTUserAgentAndroidMusic =
    @"com.google.android.apps.youtube.music/7.27.52 (Linux; U; Android 15; en_US; Pixel 9 Pro; Build/AP4A.250205.002; Cronet/132.0.6834.79) gzip";
static NSString *const OTUserAgentVR =
    @"com.google.android.apps.youtube.vr.oculus/1.37 (Linux; U; Android 12; en_US; Quest 3; Build/SQ3A.220605.009.A1; Cronet/107.0.5284.2)";
static NSString *const OTUserAgentIOS =
    @"com.google.ios.youtube/19.29.1 (iPhone16,2; U; CPU iOS 17_5_1 like Mac OS X;)";
static NSString *const OTUserAgentIPad =
    @"com.google.ios.youtube/19.22.3 (iPad7,6; U; CPU iPadOS 17_7_10 like Mac OS X; en-US)";

static NSString *OTSHA1String(NSString *string)
{
    const char *cstr = [string UTF8String];
    unsigned char digest[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(cstr, (CC_LONG)strlen(cstr), digest);
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++) {
        [output appendFormat:@"%02x", digest[i]];
    }
    return output;
}

static NSDictionary *OTWebRemixClient(void)
{
    return @{
        @"clientName": @"WEB_REMIX",
        @"clientVersion": @"1.20260114.01.00",
        @"clientId": @"67",
        @"userAgent": OTUserAgentWeb,
        @"loginSupported": @YES,
        @"useSignatureTimestamp": @YES
    };
}

static NSDictionary *OTVrClient(void)
{
    return @{
        @"clientName": @"ANDROID_VR",
        @"clientVersion": @"1.37",
        @"clientId": @"28",
        @"userAgent": OTUserAgentVR,
        @"osName": @"Android",
        @"osVersion": @"12",
        @"deviceMake": @"Oculus",
        @"deviceModel": @"Quest 3",
        @"androidSdkVersion": @"32",
        @"loginSupported": @NO,
        @"useSignatureTimestamp": @NO
    };
}

static NSDictionary *OTIOSClient(void)
{
    return @{
        @"clientName": @"IOS",
        @"clientVersion": @"19.29.1",
        @"clientId": @"5",
        @"userAgent": OTUserAgentIOS,
        @"osVersion": @"17.5.1.21F90",
        @"loginSupported": @NO,
        @"useSignatureTimestamp": @NO
    };
}

static NSDictionary *OTIPadClient(void)
{
    return @{
        @"clientName": @"IOS",
        @"clientVersion": @"19.22.3",
        @"clientId": @"5",
        @"userAgent": OTUserAgentIPad,
        @"osName": @"iPadOS",
        @"osVersion": @"17.7.10.21H450",
        @"deviceMake": @"Apple",
        @"deviceModel": @"iPad7,6",
        @"loginSupported": @NO,
        @"useSignatureTimestamp": @NO
    };
}

static NSDictionary *OTAndroidMusicClient(void)
{
    return @{
        @"clientName": @"ANDROID_MUSIC",
        @"clientVersion": @"7.27.52",
        @"clientId": @"21",
        @"userAgent": OTUserAgentAndroidMusic,
        @"osName": @"Android",
        @"osVersion": @"15",
        @"deviceMake": @"Google",
        @"deviceModel": @"Pixel 9 Pro",
        @"androidSdkVersion": @"35",
        @"loginSupported": @YES,
        @"useSignatureTimestamp": @YES
    };
}

@interface OTInnertube ()
@property (nonatomic, strong) NSURLSession *session;
@end

@implementation OTInnertube

+ (instancetype)shared
{
    static OTInnertube *client = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        client = [[OTInnertube alloc] init];
    });
    return client;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        config.timeoutIntervalForRequest = 20.0;
        config.timeoutIntervalForResource = 45.0;
        config.HTTPMaximumConnectionsPerHost = 5;
        config.HTTPAdditionalHeaders = @{@"Accept-Language": @"es-ES,es;q=0.9,en;q=0.7"};
        _session = [NSURLSession sessionWithConfiguration:config];

        NSLocale *locale = [NSLocale currentLocale];
        NSString *language = [locale objectForKey:NSLocaleLanguageCode] ?: @"es";
        NSString *region = [locale objectForKey:NSLocaleCountryCode] ?: @"ES";
        _language = [NSString stringWithFormat:@"%@-%@", language, region];
        _region = region;

        OTStore *store = [OTStore sharedStore];
        _visitorData = [store settingForKey:@"ot.visitorData"];
        _cookie = [store settingForKey:@"ot.cookie"];
    }
    return self;
}

- (void)setVisitorData:(NSString *)visitorData
{
    _visitorData = [visitorData copy];
    [[OTStore sharedStore] setSetting:_visitorData forKey:@"ot.visitorData"];
}

- (void)setCookie:(NSString *)cookie
{
    _cookie = [cookie copy];
    [[OTStore sharedStore] setSetting:_cookie forKey:@"ot.cookie"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)isLoggedIn
{
    return [self cookieValueForName:@"SAPISID"].length > 0;
}

- (void)clearLogin
{
    self.cookie = nil;
    self.dataSyncId = nil;
}

#pragma mark - HTTP

- (NSString *)cookieValueForName:(NSString *)name
{
    NSString *cookie = self.cookie;
    if (cookie.length == 0) {
        return nil;
    }
    for (NSString *part in [cookie componentsSeparatedByString:@";"]) {
        NSString *trimmed = [part stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        NSRange equals = [trimmed rangeOfString:@"="];
        if (equals.location == NSNotFound) {
            continue;
        }
        NSString *key = [trimmed substringToIndex:equals.location];
        if ([key isEqualToString:name]) {
            return [trimmed substringFromIndex:equals.location + 1];
        }
    }
    return nil;
}

- (NSString *)authorizationHeader
{
    NSString *sapisid = [self cookieValueForName:@"SAPISID"];
    if (sapisid.length == 0) {
        return nil;
    }
    long long timestamp = (long long)[[NSDate date] timeIntervalSince1970];
    NSString *origin = @"https://music.youtube.com";
    NSString *payload = [NSString stringWithFormat:@"%lld %@ %@", timestamp, sapisid, origin];
    return [NSString stringWithFormat:@"SAPISIDHASH %lld_%@", timestamp, OTSHA1String(payload)];
}

- (NSDictionary *)contextForClient:(NSDictionary *)client
{
    NSMutableDictionary *clientContext = [NSMutableDictionary dictionary];
    clientContext[@"clientName"] = client[@"clientName"];
    clientContext[@"clientVersion"] = client[@"clientVersion"];
    clientContext[@"gl"] = self.region ?: @"ES";
    clientContext[@"hl"] = self.language ?: @"es-ES";
    if (self.visitorData.length > 0) {
        clientContext[@"visitorData"] = self.visitorData;
    }
    for (NSString *key in @[@"osName", @"osVersion", @"deviceMake", @"deviceModel", @"androidSdkVersion"]) {
        if (client[key]) {
            clientContext[key] = client[key];
        }
    }

    NSMutableDictionary *user = [NSMutableDictionary dictionary];
    user[@"lockedSafetyMode"] = @NO;
    if (self.dataSyncId.length > 0 && [client[@"loginSupported"] boolValue]) {
        user[@"onBehalfOfUser"] = self.dataSyncId;
    }

    return @{
        @"client": clientContext,
        @"user": user,
        @"request": @{@"useSsl": @YES, @"internalExperimentFlags": @[]}
    };
}

- (void)postEndpoint:(NSString *)endpoint
                body:(NSDictionary *)body
              client:(NSDictionary *)client
          completion:(OTJSONCompletion)completion
{
    [self postEndpoint:endpoint body:body client:client query:nil completion:completion];
}

- (void)postEndpoint:(NSString *)endpoint
                body:(NSDictionary *)body
              client:(NSDictionary *)client
               query:(NSDictionary *)query
          completion:(OTJSONCompletion)completion
{
    if (completion == nil) {
        return;
    }
    NSString *urlString = [@"https://music.youtube.com/youtubei/v1/" stringByAppendingString:endpoint];
    if (query.count > 0) {
        NSMutableArray *parts = [NSMutableArray array];
        for (NSString *key in query) {
            NSString *value = [query[key] description];
            NSString *escaped = [value stringByAddingPercentEncodingWithAllowedCharacters:
                                 [NSCharacterSet URLQueryAllowedCharacterSet]];
            [parts addObject:[NSString stringWithFormat:@"%@=%@", key, escaped]];
        }
        urlString = [urlString stringByAppendingFormat:@"?%@", [parts componentsJoinedByString:@"&"]];
    }

    NSURL *url = [NSURL URLWithString:urlString];
    if (!url) {
        completion(nil, [self errorWithMessage:@"Dirección no válida"]);
        return;
    }

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    request.timeoutInterval = 20.0;
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"1" forHTTPHeaderField:@"X-Goog-Api-Format-Version"];
    [request setValue:client[@"clientId"] forHTTPHeaderField:@"X-YouTube-Client-Name"];
    [request setValue:client[@"clientVersion"] forHTTPHeaderField:@"X-YouTube-Client-Version"];
    [request setValue:@"https://music.youtube.com" forHTTPHeaderField:@"X-Origin"];
    [request setValue:@"https://music.youtube.com/" forHTTPHeaderField:@"Referer"];
    [request setValue:client[@"userAgent"] forHTTPHeaderField:@"User-Agent"];
    if (self.visitorData.length > 0) {
        [request setValue:self.visitorData forHTTPHeaderField:@"X-Goog-Visitor-Id"];
    }
    if (self.cookie.length > 0) {
        [request setValue:self.cookie forHTTPHeaderField:@"cookie"];
        NSString *authorization = [self authorizationHeader];
        if (authorization) {
            [request setValue:authorization forHTTPHeaderField:@"Authorization"];
        }
        [request setValue:@"0" forHTTPHeaderField:@"X-Goog-AuthUser"];
    }

    NSError *serializationError = nil;
    request.HTTPBody = [NSJSONSerialization dataWithJSONObject:body
                                                      options:0
                                                        error:&serializationError];
    if (serializationError) {
        completion(nil, serializationError);
        return;
    }

    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request
                                                completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                completion(nil, error);
                return;
            }
            NSHTTPURLResponse *http = (NSHTTPURLResponse *)response;
            if ([http isKindOfClass:[NSHTTPURLResponse class]] && http.statusCode >= 400) {
                NSString *message = [NSString stringWithFormat:@"YouTube Music respondió %ld", (long)http.statusCode];
                completion(nil, [self errorWithMessage:message]);
                return;
            }
            NSError *jsonError = nil;
            id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
            if (![json isKindOfClass:[NSDictionary class]]) {
                completion(nil, jsonError ?: [self errorWithMessage:@"Respuesta no válida"]);
                return;
            }
            NSString *visitor = OTSafeString(json[@"responseContext"][@"visitorData"]);
            if (visitor.length > 0) {
                self.visitorData = visitor;
            }
            completion(json, nil);
        });
    }];
    [task resume];
}

- (NSError *)errorWithMessage:(NSString *)message
{
    return [NSError errorWithDomain:@"OTInnertube"
                               code:-1
                           userInfo:@{NSLocalizedDescriptionKey: message ?: @"Error de red"}];
}

- (NSDictionary *)browseBodyWithClient:(NSDictionary *)client
                              browseId:(NSString *)browseId
                                params:(NSString *)params
{
    NSMutableDictionary *body = [NSMutableDictionary dictionary];
    body[@"context"] = [self contextForClient:client];
    if (browseId.length > 0) body[@"browseId"] = browseId;
    if (params.length > 0) body[@"params"] = params;
    return body;
}

#pragma mark - Navegacion

- (void)homeWithCompletion:(OTFeedCompletion)completion
{
    [self browse:@"FEmusic_home" params:nil completion:^(NSDictionary *json, NSError *error) {
        if (error) {
            completion(nil, nil, error);
            return;
        }
        completion(OTParseSections(json), OTContinuationFromJSON(json), nil);
    }];
}

- (void)homeContinuation:(NSString *)continuation completion:(OTFeedCompletion)completion
{
    [self browseContinuation:continuation completion:^(NSDictionary *json, NSError *error) {
        if (error) {
            completion(nil, nil, error);
            return;
        }
        completion(OTParseSections(json), OTContinuationFromJSON(json), nil);
    }];
}

- (NSString *)searchParamsForFilter:(OTSearchFilter)filter
{
    switch (filter) {
        case OTSearchFilterSongs: return @"EgWKAQIIAWoKEAkQBRAKEAMQBA==";
        case OTSearchFilterVideos: return @"EgWKAQIQAWoKEAkQChAFEAMQBA==";
        case OTSearchFilterAlbums: return @"EgWKAQIYAWoKEAkQChAFEAMQBA==";
        case OTSearchFilterArtists: return @"EgWKAQIgAWoKEAkQChAFEAMQBA==";
        case OTSearchFilterPlaylists: return @"EgeKAQQoADgBagwQDhAKEAMQBRAJEAQ=";
        default: return nil;
    }
}

- (void)search:(NSString *)query filter:(OTSearchFilter)filter completion:(OTFeedCompletion)completion
{
    NSMutableDictionary *body = [NSMutableDictionary dictionary];
    body[@"context"] = [self contextForClient:OTWebRemixClient()];
    body[@"query"] = query ?: @"";
    NSString *params = [self searchParamsForFilter:filter];
    if (params.length > 0) {
        body[@"params"] = params;
    }
    [self postEndpoint:@"search" body:body client:OTWebRemixClient() completion:^(NSDictionary *json, NSError *error) {
        if (error) {
            completion(nil, nil, error);
            return;
        }
        NSMutableArray *sections = [OTParseSections(json) mutableCopy];
        completion(sections, OTContinuationFromJSON(json), nil);
    }];
}

- (void)searchContinuation:(NSString *)continuation completion:(OTFeedCompletion)completion
{
    NSMutableDictionary *body = [NSMutableDictionary dictionary];
    body[@"context"] = [self contextForClient:OTWebRemixClient()];
    body[@"continuation"] = continuation ?: @"";
    [self postEndpoint:@"search"
                  body:body
                client:OTWebRemixClient()
                 query:@{@"continuation": continuation ?: @""}
            completion:^(NSDictionary *json, NSError *error) {
        if (error) {
            completion(nil, nil, error);
            return;
        }
        completion(OTParseSections(json), OTContinuationFromJSON(json), nil);
    }];
}

- (void)searchSuggestions:(NSString *)input
               completion:(void (^)(NSArray<NSString *> *, NSError *))completion
{
    NSMutableDictionary *body = [NSMutableDictionary dictionary];
    body[@"context"] = [self contextForClient:OTWebRemixClient()];
    body[@"input"] = input ?: @"";
    [self postEndpoint:@"music/get_search_suggestions"
                  body:body
                client:OTWebRemixClient()
            completion:^(NSDictionary *json, NSError *error) {
        if (error) {
            completion(@[], error);
            return;
        }
        NSMutableArray *suggestions = [NSMutableArray array];
        for (NSDictionary *renderer in OTCollectObjects(json, @"searchSuggestionRenderer")) {
            NSString *text = OTTextFromRendererText(OTSafeDictionary(renderer[@"suggestion"]));
            if (text.length > 0 && ![suggestions containsObject:text]) {
                [suggestions addObject:text];
            }
        }
        for (NSDictionary *renderer in OTCollectObjects(json, @"musicResponsiveListItemRenderer")) {
            OTItem *item = [OTItem itemFromResponsiveRenderer:renderer];
            if (item.title.length > 0 && ![suggestions containsObject:item.title]) {
                [suggestions addObject:item.title];
            }
        }
        completion(suggestions, nil);
    }];
}

- (void)browse:(NSString *)browseId params:(NSString *)params completion:(OTJSONCompletion)completion
{
    NSDictionary *client = OTWebRemixClient();
    [self postEndpoint:@"browse"
                  body:[self browseBodyWithClient:client browseId:browseId params:params]
                client:client
            completion:completion];
}

- (void)browseContinuation:(NSString *)continuation completion:(OTJSONCompletion)completion
{
    NSDictionary *client = OTWebRemixClient();
    NSMutableDictionary *body = [NSMutableDictionary dictionary];
    body[@"context"] = [self contextForClient:client];
    body[@"continuation"] = continuation ?: @"";
    [self postEndpoint:@"browse" body:body client:client completion:completion];
}

- (void)exploreCompletion:(OTFeedCompletion)completion
{
    [self browse:@"FEmusic_explore" params:nil completion:^(NSDictionary *json, NSError *error) {
        completion(error ? nil : OTParseSections(json), OTContinuationFromJSON(json), error);
    }];
}

- (void)chartsCompletion:(OTFeedCompletion)completion
{
    [self browse:@"FEmusic_charts" params:nil completion:^(NSDictionary *json, NSError *error) {
        completion(error ? nil : OTParseSections(json), OTContinuationFromJSON(json), error);
    }];
}

- (void)newReleasesCompletion:(OTFeedCompletion)completion
{
    [self browse:@"FEmusic_new_releases_albums" params:nil completion:^(NSDictionary *json, NSError *error) {
        completion(error ? nil : OTParseSections(json), OTContinuationFromJSON(json), error);
    }];
}

- (void)moodAndGenresCompletion:(OTFeedCompletion)completion
{
    [self browse:@"FEmusic_moods_and_genres" params:nil completion:^(NSDictionary *json, NSError *error) {
        NSArray *moods = error ? @[] : OTParseMoodButtons(json);
        if (moods.count > 0) {
            OTSection *section = [OTSection sectionWithTitle:@"Estados de ánimo y géneros"
                                                       items:moods
                                                       style:OTSectionStyleList];
            completion(@[section], nil, nil);
            return;
        }
        completion(error ? nil : OTParseSections(json), OTContinuationFromJSON(json), error);
    }];
}

- (void)album:(NSString *)browseId completion:(OTFeedCompletion)completion
{
    [self browse:browseId params:nil completion:^(NSDictionary *json, NSError *error) {
        if (error) {
            completion(nil, nil, error);
            return;
        }
        completion(OTParseSections(json), OTContinuationFromJSON(json), nil);
    }];
}

- (void)playlist:(NSString *)playlistId completion:(OTFeedCompletion)completion
{
    if (playlistId.length == 0) {
        completion(@[], nil, [self errorWithMessage:@"Lista sin identificador"]);
        return;
    }
    NSString *browseId = [playlistId hasPrefix:@"VL"] ? playlistId : [@"VL" stringByAppendingString:playlistId];
    [self browse:browseId params:nil completion:^(NSDictionary *json, NSError *error) {
        if (error) {
            completion(nil, nil, error);
            return;
        }
        completion(OTParseSections(json), OTContinuationFromJSON(json), nil);
    }];
}

- (void)artist:(NSString *)browseId completion:(OTFeedCompletion)completion
{
    [self browse:browseId params:nil completion:^(NSDictionary *json, NSError *error) {
        completion(error ? nil : OTParseSections(json), OTContinuationFromJSON(json), error);
    }];
}

- (void)librarySongsCompletion:(OTFeedCompletion)completion
{
    [self browse:@"FEmusic_library_tracks" params:nil completion:^(NSDictionary *json, NSError *error) {
        completion(error ? nil : OTParseSections(json), OTContinuationFromJSON(json), error);
    }];
}

#pragma mark - Cola y letras

- (void)nextForVideo:(NSString *)videoId
           playlistId:(NSString *)playlistId
                index:(NSInteger)index
           completion:(OTNextCompletion)completion
{
    NSDictionary *client = OTWebRemixClient();
    NSMutableDictionary *body = [NSMutableDictionary dictionary];
    body[@"context"] = [self contextForClient:client];
    if (videoId.length > 0) body[@"videoId"] = videoId;
    if (playlistId.length > 0) body[@"playlistId"] = playlistId;
    if (index >= 0) body[@"index"] = @(index);
    body[@"isAudioOnly"] = @YES;
    body[@"enablePersistentPlaylistPanel"] = @YES;

    [self postEndpoint:@"next" body:body client:client completion:^(NSDictionary *json, NSError *error) {
        if (error) {
            completion(nil, 0, nil, nil, error);
            return;
        }
        NSMutableArray *items = [NSMutableArray array];
        NSMutableSet *seen = [NSMutableSet set];
        NSInteger currentIndex = 0;
        NSArray *panels = OTCollectObjects(json, @"playlistPanelVideoRenderer");
        for (NSDictionary *renderer in panels) {
            OTItem *item = [OTItem itemFromPlaylistPanelRenderer:renderer];
            if (!item || item.itemId.length == 0 || [seen containsObject:item.itemId]) {
                continue;
            }
            [seen addObject:item.itemId];
            if ([renderer[@"selected"] boolValue]) {
                currentIndex = items.count;
            }
            [items addObject:item];
        }
        completion(items,
                   currentIndex,
                   OTLyricsBrowseIdFromJSON(json),
                   OTLyricsParamsFromJSON(json),
                   nil);
    }];
}

- (void)lyricsWithBrowseId:(NSString *)browseId
                    params:(NSString *)params
                completion:(void (^)(NSString *, NSError *))completion
{
    if (browseId.length == 0) {
        completion(nil, [self errorWithMessage:@"Sin letras"]);
        return;
    }
    [self browse:browseId params:params completion:^(NSDictionary *json, NSError *error) {
        if (error) {
            completion(nil, error);
            return;
        }
        NSDictionary *shelf = OTFirstObject(json, @"musicDescriptionShelfRenderer");
        NSString *lyrics = nil;
        if (shelf) {
            lyrics = OTTextFromRendererText(OTSafeDictionary(shelf[@"description"]));
            if (lyrics.length == 0) {
                lyrics = OTTextFromRendererText(OTSafeDictionary(shelf[@"subtitle"]));
            }
        }
        if (lyrics.length == 0) {
            completion(nil, [self errorWithMessage:@"Esta canción no tiene letras"]);
        } else {
            completion(lyrics, nil);
        }
    }];
}

#pragma mark - Streaming

- (void)streamURLForVideo:(NSString *)videoId completion:(OTStreamCompletion)completion
{
    [self streamURLForVideo:videoId avoidMime:nil completion:completion];
}

- (void)streamURLForVideo:(NSString *)videoId
                avoidMime:(NSString *)avoidMime
               completion:(OTStreamCompletion)completion
{
    if (videoId.length == 0) {
        completion(nil, nil, nil, [self errorWithMessage:@"Canción sin identificador"]);
        return;
    }
    NSArray *clients = @[OTVrClient(), OTIOSClient(), OTIPadClient(), OTAndroidMusicClient(), OTWebRemixClient()];
    [self tryStreamClients:clients
                     index:0
                   videoId:videoId
                 avoidMime:avoidMime
                completion:completion];
}

- (void)tryStreamClients:(NSArray *)clients
                   index:(NSInteger)index
                 videoId:(NSString *)videoId
               avoidMime:(NSString *)avoidMime
              completion:(OTStreamCompletion)completion
{
    if (index >= (NSInteger)clients.count) {
        completion(nil, nil, nil, [self errorWithMessage:
            @"YouTube no devolvió un audio reproducible. Prueba otra canción o inicia sesión."]);
        return;
    }

    NSDictionary *client = clients[index];
    NSMutableDictionary *body = [NSMutableDictionary dictionary];
    body[@"context"] = [self contextForClient:client];
    body[@"videoId"] = videoId;
    body[@"contentCheckOk"] = @YES;
    body[@"racyCheckOk"] = @YES;

    [self postEndpoint:@"player" body:body client:client completion:^(NSDictionary *json, NSError *error) {
        if (error) {
            [self tryStreamClients:clients index:index + 1 videoId:videoId avoidMime:avoidMime completion:completion];
            return;
        }
        NSDictionary *status = OTSafeDictionary(json[@"playabilityStatus"]);
        NSString *state = OTSafeString(status[@"status"]);
        if (![state isEqualToString:@"OK"]) {
            [self tryStreamClients:clients index:index + 1 videoId:videoId avoidMime:avoidMime completion:completion];
            return;
        }

        NSDictionary *streamingData = OTSafeDictionary(json[@"streamingData"]);
        NSArray *adaptive = OTSafeArray(streamingData[@"adaptiveFormats"]) ?: @[];
        NSArray *muxed = OTSafeArray(streamingData[@"formats"]) ?: @[];
        NSMutableArray *candidates = [NSMutableArray array];

        for (NSDictionary *format in [adaptive arrayByAddingObjectsFromArray:muxed]) {
            NSString *mime = OTSafeString(format[@"mimeType"]);
            NSString *urlString = OTSafeString(format[@"url"]);
            if (urlString.length == 0 || ![mime containsString:@"audio/mp4"]) {
                continue;
            }
            if (avoidMime.length > 0 && [mime isEqualToString:avoidMime]) {
                continue;
            }
            NSInteger bitrate = [OTSafeString(format[@"bitrate"]) integerValue];
            if (bitrate <= 0) {
                bitrate = [format[@"averageBitrate"] integerValue];
            }
            [candidates addObject:@{
                @"url": urlString,
                @"mime": mime,
                @"bitrate": @(bitrate),
                @"client": client[@"clientName"] ?: @"",
                @"userAgent": client[@"userAgent"] ?: OTUserAgentVR
            }];
        }

        if (candidates.count == 0) {
            [self tryStreamClients:clients index:index + 1 videoId:videoId avoidMime:avoidMime completion:completion];
            return;
        }

        NSArray *ordered = [self orderCandidates:candidates quality:[[OTStore sharedStore] audioQuality]];
        [self tryCandidates:ordered
                        at:0
                      body:nil
                  videoId:videoId
                avoidMime:avoidMime
                   clients:clients
               clientIndex:index
                completion:completion];
    }];
}

- (NSArray *)orderCandidates:(NSArray *)candidates quality:(NSInteger)quality
{
    NSInteger target = 256000;
    if (quality == 0) target = 96000;
    if (quality == 1) target = 160000;

    return [candidates sortedArrayUsingComparator:^NSComparisonResult(NSDictionary *a, NSDictionary *b) {
        NSInteger ba = [a[@"bitrate"] integerValue];
        NSInteger bb = [b[@"bitrate"] integerValue];
        NSInteger da = ba > target ? ba - target : target - ba;
        NSInteger db = bb > target ? bb - target : target - bb;
        if (da == db) {
            return ba > bb ? NSOrderedAscending : NSOrderedDescending;
        }
        return da < db ? NSOrderedAscending : NSOrderedDescending;
    }];
}

- (void)tryCandidates:(NSArray *)candidates
                   at:(NSInteger)index
                 body:(NSDictionary *)unused
              videoId:(NSString *)videoId
            avoidMime:(NSString *)avoidMime
              clients:(NSArray *)clients
          clientIndex:(NSInteger)clientIndex
           completion:(OTStreamCompletion)completion
{
    if (index >= (NSInteger)candidates.count) {
        [self tryStreamClients:clients
                         index:clientIndex + 1
                       videoId:videoId
                     avoidMime:avoidMime
                    completion:completion];
        return;
    }
    NSDictionary *candidate = candidates[index];
    NSURL *url = [NSURL URLWithString:candidate[@"url"]];
    if (!url) {
        [self tryCandidates:candidates at:index + 1 body:nil videoId:videoId avoidMime:avoidMime
                    clients:clients clientIndex:clientIndex completion:completion];
        return;
    }

    __weak typeof(self) weakSelf = self;
    [self probeURL:url userAgent:candidate[@"userAgent"] completion:^(BOOL acceptable) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        if (acceptable) {
            completion(url, candidate[@"mime"], candidate[@"client"], nil);
        } else {
            [strongSelf tryCandidates:candidates
                                   at:index + 1
                                 body:nil
                              videoId:videoId
                            avoidMime:avoidMime
                              clients:clients
                          clientIndex:clientIndex
                           completion:completion];
        }
    }];
}

- (void)probeURL:(NSURL *)url userAgent:(NSString *)userAgent completion:(void (^)(BOOL))completion
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"HEAD";
    request.timeoutInterval = 8.0;
    if (userAgent.length > 0) {
        [request setValue:userAgent forHTTPHeaderField:@"User-Agent"];
    }
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request
                                                completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                // Si el CDN no admite HEAD o hay un fallo de red puntual,
                // dejamos que AVPlayer lo intente en vez de descartar el audio.
                completion(YES);
                return;
            }
            NSHTTPURLResponse *http = (NSHTTPURLResponse *)response;
            if ([http isKindOfClass:[NSHTTPURLResponse class]]) {
                NSInteger code = http.statusCode;
                completion(!(code == 403 || code == 404 || code == 410));
            } else {
                completion(YES);
            }
        });
    }];
    [task resume];
}

@end

#pragma mark - Parseo

static void OTAppendShelfContent(id content, NSMutableArray *out, NSInteger depth)
{
    if (![content isKindOfClass:[NSDictionary class]] || depth > 3) {
        return;
    }
    NSDictionary *dict = content;
    if (dict[@"musicCarouselShelfRenderer"] || dict[@"musicShelfRenderer"] ||
        dict[@"musicPlaylistShelfRenderer"] || dict[@"musicCardShelfRenderer"]) {
        [out addObject:dict];
        return;
    }
    NSDictionary *itemSection = OTSafeDictionary(dict[@"itemSectionRenderer"]);
    if (itemSection) {
        for (id inner in OTSafeArray(itemSection[@"contents"]) ?: @[]) {
            OTAppendShelfContent(inner, out, depth + 1);
        }
        return;
    }
    NSDictionary *grid = OTSafeDictionary(dict[@"gridRenderer"]);
    if (grid) {
        for (id inner in OTSafeArray(grid[@"items"]) ?: @[]) {
            OTAppendShelfContent(inner, out, depth + 1);
        }
    }
}

static NSArray *OTSectionContentsFromJSON(NSDictionary *json)
{
    NSMutableArray *contents = [NSMutableArray array];

    NSDictionary *sectionList = OTFirstObject(json, @"sectionListRenderer");
    for (id content in OTSafeArray(sectionList[@"contents"]) ?: @[]) {
        OTAppendShelfContent(content, contents, 0);
    }
    if (contents.count > 0) {
        return contents;
    }

    NSDictionary *continuation = OTFirstObject(json, @"sectionListContinuation");
    for (id content in OTSafeArray(continuation[@"contents"]) ?: @[]) {
        OTAppendShelfContent(content, contents, 0);
    }
    if (contents.count > 0) {
        return contents;
    }

    NSDictionary *playlistContinuation = OTFirstObject(json, @"musicPlaylistShelfContinuation");
    if (playlistContinuation) {
        NSDictionary *wrapper = @{@"musicPlaylistShelfRenderer": playlistContinuation};
        [contents addObject:wrapper];
    }

    for (NSDictionary *action in OTSafeArray(json[@"onResponseReceivedActions"]) ?: @[]) {
        NSArray *items = OTSafeArray(action[@"appendContinuationItemsAction"][@"continuationItems"]);
        for (id content in items ?: @[]) {
            OTAppendShelfContent(content, contents, 0);
        }
    }

    if (contents.count == 0) {
        // Ultimo recurso: cualquier estanteria suelta en la respuesta.
        for (NSDictionary *renderer in OTCollectObjects(json, @"musicCarouselShelfRenderer")) {
            [contents addObject:@{@"musicCarouselShelfRenderer": renderer}];
        }
        for (NSDictionary *renderer in OTCollectObjects(json, @"musicShelfRenderer")) {
            [contents addObject:@{@"musicShelfRenderer": renderer}];
        }
    }
    return contents;
}

NSArray<OTSection *> *OTParseSections(NSDictionary *json)
{
    NSMutableArray *sections = [NSMutableArray array];
    NSMutableSet *seen = [NSMutableSet set];

    for (NSDictionary *wrapper in OTSectionContentsFromJSON(json)) {
        if (wrapper[@"musicCarouselShelfRenderer"]) {
            NSDictionary *renderer = wrapper[@"musicCarouselShelfRenderer"];
            NSDictionary *header = OTSafeDictionary(renderer[@"header"]);
            NSDictionary *basic = OTSafeDictionary(header[@"musicCarouselShelfBasicHeaderRenderer"]);
            NSString *title = OTTextFromRendererText(OTSafeDictionary(basic[@"title"]));
            NSMutableArray *items = [NSMutableArray array];
            for (id content in OTSafeArray(renderer[@"contents"]) ?: @[]) {
                OTItem *item = [OTItem itemFromRenderer:content];
                if (item) [items addObject:item];
            }
            if (items.count == 0) continue;
            NSString *key = [NSString stringWithFormat:@"c|%@|%@", title ?: @"", items[0].itemId ?: @""];
            if ([seen containsObject:key]) continue;
            [seen addObject:key];
            OTSection *section = [OTSection sectionWithTitle:title items:items style:OTSectionStyleCarousel];
            NSDictionary *more = OTSafeDictionary(OTSafeDictionary(basic[@"moreContentButton"])[@"buttonRenderer"]);
            NSDictionary *endpoint = OTSafeDictionary(more[@"navigationEndpoint"]);
            NSDictionary *browse = OTSafeDictionary(endpoint[@"browseEndpoint"]);
            section.browseId = OTSafeString(browse[@"browseId"]);
            section.params = OTSafeString(browse[@"params"]);
            [sections addObject:section];
        } else if (wrapper[@"musicShelfRenderer"] || wrapper[@"musicPlaylistShelfRenderer"]) {
            NSDictionary *renderer = wrapper[@"musicShelfRenderer"] ?: wrapper[@"musicPlaylistShelfRenderer"];
            NSString *title = OTTextFromRendererText(OTSafeDictionary(renderer[@"title"]));
            NSMutableArray *items = [NSMutableArray array];
            NSMutableSet *ids = [NSMutableSet set];
            for (id content in OTSafeArray(renderer[@"contents"]) ?: @[]) {
                OTItem *item = [OTItem itemFromRenderer:content];
                if (!item) continue;
                if (item.itemId.length > 0 && [ids containsObject:item.itemId]) continue;
                if (item.itemId.length > 0) [ids addObject:item.itemId];
                [items addObject:item];
            }
            if (items.count == 0) continue;
            NSString *key = [NSString stringWithFormat:@"s|%@|%@", title ?: @"", items[0].itemId ?: @""];
            if ([seen containsObject:key]) continue;
            [seen addObject:key];

            BOOL allSongs = YES;
            for (OTItem *item in items) {
                if (item.type != OTItemTypeSong && item.type != OTItemTypeVideo) {
                    allSongs = NO;
                    break;
                }
            }
            OTSection *section = [OTSection sectionWithTitle:title
                                                       items:items
                                                       style:allSongs ? OTSectionStyleList : OTSectionStyleCarousel];
            NSDictionary *more = OTSafeDictionary(renderer[@"moreContentButton"]);
            NSDictionary *button = OTSafeDictionary(more[@"buttonRenderer"]);
            NSDictionary *endpoint = OTSafeDictionary(button[@"navigationEndpoint"]);
            NSDictionary *browse = OTSafeDictionary(endpoint[@"browseEndpoint"]);
            if (!browse) {
                NSDictionary *bottom = OTSafeDictionary(renderer[@"bottomEndpoint"]);
                browse = OTSafeDictionary(bottom[@"browseEndpoint"]);
            }
            section.browseId = OTSafeString(browse[@"browseId"]);
            section.params = OTSafeString(browse[@"params"]);
            [sections addObject:section];
        } else if (wrapper[@"musicCardShelfRenderer"]) {
            OTItem *item = OTParseCardShelf(@{@"musicCardShelfRenderer": wrapper[@"musicCardShelfRenderer"]});
            if (item) {
                [sections addObject:[OTSection sectionWithTitle:@"Mejor resultado"
                                                          items:@[item]
                                                          style:OTSectionStyleList]];
            }
        }
    }
    return sections;
}

NSArray<OTItem *> *OTParseSongItems(NSDictionary *json)
{
    NSMutableArray *items = [NSMutableArray array];
    NSMutableSet *seen = [NSMutableSet set];
    for (NSDictionary *renderer in OTCollectObjects(json, @"musicResponsiveListItemRenderer")) {
        OTItem *item = [OTItem itemFromResponsiveRenderer:renderer];
        if (!item || !item.isPlayable) {
            continue;
        }
        if ([seen containsObject:item.itemId]) {
            continue;
        }
        [seen addObject:item.itemId];
        [items addObject:item];
    }
    return items;
}

NSArray<OTItem *> *OTParseMoodButtons(NSDictionary *json)
{
    NSMutableArray *items = [NSMutableArray array];
    NSMutableSet *seen = [NSMutableSet set];
    for (NSDictionary *renderer in OTCollectObjects(json, @"musicNavigationButtonRenderer")) {
        NSString *title = OTTextFromRendererText(OTSafeDictionary(renderer[@"buttonText"]));
        NSDictionary *endpoint = OTSafeDictionary(renderer[@"clickCommand"]);
        NSDictionary *browse = OTSafeDictionary(endpoint[@"browseEndpoint"]);
        NSString *browseId = OTSafeString(browse[@"browseId"]);
        if (title.length == 0 || browseId.length == 0 || [seen containsObject:browseId]) {
            continue;
        }
        [seen addObject:browseId];
        OTItem *item = [[OTItem alloc] init];
        item.title = title;
        item.itemId = browseId;
        item.browseId = browseId;
        item.params = OTSafeString(browse[@"params"]);
        item.type = OTItemTypePlaylist;
        NSDictionary *solid = OTSafeDictionary(renderer[@"solid"]);
        NSString *stripe = OTSafeString(solid[@"leftStripeColor"]);
        if (stripe.length > 0) {
            item.colorValue = (NSUInteger)[stripe longLongValue];
        }
        [items addObject:item];
    }
    return items;
}

NSArray<NSDictionary *> *OTParseHomeChips(NSDictionary *json)
{
    NSMutableArray *chips = [NSMutableArray array];
    NSDictionary *sectionList = OTFirstObject(json, @"sectionListRenderer");
    NSDictionary *header = OTSafeDictionary(sectionList[@"header"]);
    NSDictionary *cloud = OTSafeDictionary(header[@"chipCloudRenderer"]);
    for (NSDictionary *wrapper in OTSafeArray(cloud[@"chips"]) ?: @[]) {
        NSDictionary *chip = OTSafeDictionary(wrapper[@"chipCloudChipRenderer"]);
        if (!chip) {
            continue;
        }
        NSString *title = OTTextFromRendererText(OTSafeDictionary(chip[@"text"]));
        NSDictionary *browse = OTSafeDictionary(OTSafeDictionary(chip[@"navigationEndpoint"])[@"browseEndpoint"]);
        NSString *params = OTSafeString(browse[@"params"]);
        if (title.length == 0) {
            continue;
        }
        [chips addObject:@{@"title": title, @"params": params ?: @""}];
    }
    if (chips.count == 0) {
        [chips addObject:@{@"title": @"Todo", @"params": @""}];
    }
    return chips;
}

OTItem *OTParseCollectionHeader(NSDictionary *json, OTItemType type)
{
    NSDictionary *header = OTFirstObject(json, @"musicResponsiveHeaderRenderer");
    if (!header) {
        header = OTFirstObject(json, @"musicDetailHeaderRenderer");
    }
    if (!header) {
        header = OTFirstObject(json, @"musicImmersiveHeaderRenderer");
    }
    if (!header) {
        header = OTFirstObject(json, @"musicVisualHeaderRenderer");
    }
    if (!header) {
        return nil;
    }

    OTItem *item = [[OTItem alloc] init];
    item.type = type;
    item.title = OTTextFromRendererText(OTSafeDictionary(header[@"title"]));
    NSString *subtitle = OTTextFromRendererText(OTSafeDictionary(header[@"subtitle"]));
    if (subtitle.length == 0) {
        subtitle = OTTextFromRendererText(OTSafeDictionary(header[@"straplineTextOne"]));
    }
    if (subtitle.length == 0) {
        NSDictionary *description = OTSafeDictionary(header[@"description"]);
        NSDictionary *shelf = OTSafeDictionary(description[@"musicDescriptionShelfRenderer"]);
        subtitle = OTTextFromRendererText(OTSafeDictionary(shelf[@"description"]));
    }
    item.subtitle = subtitle;
    item.artistsText = subtitle;
    item.thumbnailURL = OTThumbnailFromRenderer(OTSafeDictionary(header[@"thumbnail"]), 320.0);
    if (!item.thumbnailURL) {
        item.thumbnailURL = OTThumbnailFromRenderer(header, 320.0);
    }
    NSString *secondSubtitle = OTTextFromRendererText(OTSafeDictionary(header[@"secondSubtitle"]));
    item.playsText = secondSubtitle;
    if (secondSubtitle.length > 0) {
        NSArray *parts = [secondSubtitle componentsSeparatedByString:@" • "];
        if (parts.count > 0) {
            item.yearText = parts[0];
        }
    }

    for (NSDictionary *button in OTSafeArray(header[@"buttons"]) ?: @[]) {
        NSDictionary *play = OTSafeDictionary(button[@"musicPlayButtonRenderer"]);
        NSDictionary *endpoint = OTSafeDictionary(play[@"playNavigationEndpoint"]);
        NSDictionary *watch = OTSafeDictionary(endpoint[@"watchEndpoint"]);
        if (watch) {
            item.playlistId = OTSafeString(watch[@"playlistId"]);
            item.itemId = item.playlistId ?: OTSafeString(watch[@"videoId"]);
        }
    }
    return item.title.length > 0 ? item : nil;
}

OTItem *OTParseCardShelf(NSDictionary *json)
{
    NSDictionary *card = OTSafeDictionary(json[@"musicCardShelfRenderer"]);
    if (!card) {
        card = OTFirstObject(json, @"musicCardShelfRenderer");
    }
    if (!card) {
        return nil;
    }
    OTItem *item = [[OTItem alloc] init];
    item.title = OTTextFromRendererText(OTSafeDictionary(card[@"title"]));
    item.subtitle = OTTextFromRendererText(OTSafeDictionary(card[@"subtitle"]));
    item.thumbnailURL = OTThumbnailFromRenderer(card, 240.0);
    NSDictionary *endpoint = OTSafeDictionary(card[@"onTap"][@"navigationEndpoint"]);
    if (!endpoint) {
        endpoint = OTSafeDictionary(card[@"navigationEndpoint"]);
    }
    NSDictionary *watch = OTSafeDictionary(endpoint[@"watchEndpoint"]);
    NSDictionary *browse = OTSafeDictionary(endpoint[@"browseEndpoint"]);
    if (watch) {
        item.type = OTItemTypeSong;
        item.itemId = OTSafeString(watch[@"videoId"]);
        item.playlistId = OTSafeString(watch[@"playlistId"]);
    } else if (browse) {
        item.browseId = OTSafeString(browse[@"browseId"]);
        item.params = OTSafeString(browse[@"params"]);
        item.itemId = item.browseId;
        NSString *browseId = item.browseId ?: @"";
        if ([browseId hasPrefix:@"MPRE"]) item.type = OTItemTypeAlbum;
        else if ([browseId hasPrefix:@"UC"]) item.type = OTItemTypeArtist;
        else if ([browseId hasPrefix:@"VL"]) item.type = OTItemTypePlaylist;
        else item.type = OTItemTypeAlbum;
    }
    item.artistsText = item.subtitle;
    return item.title.length > 0 ? item : nil;
}

NSString *OTContinuationFromJSON(NSDictionary *json)
{
    NSDictionary *command = OTFirstObject(json, @"continuationCommand");
    NSString *token = OTSafeString(command[@"token"]);
    if (token.length > 0) {
        return token;
    }
    NSDictionary *next = OTFirstObject(json, @"nextContinuationData");
    token = OTSafeString(next[@"continuation"]);
    return token;
}

NSString *OTLyricsBrowseIdFromJSON(NSDictionary *json)
{
    NSArray *tabs = OTCollectObjects(json, @"tabRenderer");
    if (tabs.count > 1) {
        NSDictionary *endpoint = OTSafeDictionary(tabs[1][@"endpoint"]);
        NSDictionary *browse = OTSafeDictionary(endpoint[@"browseEndpoint"]);
        return OTSafeString(browse[@"browseId"]);
    }
    return nil;
}

NSString *OTLyricsParamsFromJSON(NSDictionary *json)
{
    NSArray *tabs = OTCollectObjects(json, @"tabRenderer");
    if (tabs.count > 1) {
        NSDictionary *endpoint = OTSafeDictionary(tabs[1][@"endpoint"]);
        NSDictionary *browse = OTSafeDictionary(endpoint[@"browseEndpoint"]);
        return OTSafeString(browse[@"params"]);
    }
    return nil;
}

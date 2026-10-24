//
//  OTItem.m
//  OpenTune 9
//

#import "OTItem.h"

#pragma mark - Helpers

NSString *OTSafeString(id value)
{
    if ([value isKindOfClass:[NSString class]]) {
        return value;
    }
    if ([value isKindOfClass:[NSNumber class]]) {
        return [value stringValue];
    }
    return nil;
}

NSArray *OTSafeArray(id value)
{
    return [value isKindOfClass:[NSArray class]] ? value : nil;
}

NSDictionary *OTSafeDictionary(id value)
{
    return [value isKindOfClass:[NSDictionary class]] ? value : nil;
}

NSString *OTTextFromRuns(NSArray *runs)
{
    if (![runs isKindOfClass:[NSArray class]]) {
        return nil;
    }
    NSMutableString *text = [NSMutableString string];
    for (id run in runs) {
        if (![run isKindOfClass:[NSDictionary class]]) {
            continue;
        }
        NSString *piece = OTSafeString(run[@"text"]);
        if (piece.length > 0) {
            [text appendString:piece];
        }
    }
    return text.length > 0 ? text : nil;
}

NSString *OTTextFromRendererText(NSDictionary *text)
{
    if (![text isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    NSString *simple = OTSafeString(text[@"simpleText"]);
    if (simple.length > 0) {
        return simple;
    }
    return OTTextFromRuns(OTSafeArray(text[@"runs"]));
}

static void OTCollectRecursive(id node, NSString *key, NSMutableArray *result)
{
    if ([node isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dict = (NSDictionary *)node;
        id value = dict[key];
        if ([value isKindOfClass:[NSDictionary class]]) {
            [result addObject:value];
        }
        for (id child in [dict allValues]) {
            OTCollectRecursive(child, key, result);
        }
    } else if ([node isKindOfClass:[NSArray class]]) {
        for (id child in (NSArray *)node) {
            OTCollectRecursive(child, key, result);
        }
    }
}

NSArray *OTCollectObjects(NSDictionary *json, NSString *rendererKey)
{
    NSMutableArray *result = [NSMutableArray array];
    if (!json || rendererKey.length == 0) {
        return result;
    }
    OTCollectRecursive(json, rendererKey, result);
    return result;
}

NSDictionary *OTFirstObject(NSDictionary *json, NSString *rendererKey)
{
    NSArray *all = OTCollectObjects(json, rendererKey);
    return all.count > 0 ? all[0] : nil;
}

NSString *OTResizeThumbnailURL(NSString *url, CGFloat size)
{
    if (url.length == 0) {
        return nil;
    }
    NSInteger px = (NSInteger)MAX(64.0, size * 2.0);
    NSRange range = [url rangeOfString:@"=w"];
    if (range.location == NSNotFound) {
        range = [url rangeOfString:@"=s"];
    }
    if (range.location != NSNotFound) {
        NSString *base = [url substringToIndex:range.location];
        return [base stringByAppendingFormat:@"=w%ld-h%ld-l90-rj", (long)px, (long)px];
    }
    if ([url containsString:@"/hqdefault."]) {
        return [url stringByReplacingOccurrencesOfString:@"/hqdefault." withString:@"/mqdefault."];
    }
    if ([url containsString:@"/default."]) {
        return [url stringByReplacingOccurrencesOfString:@"/default." withString:@"/mqdefault."];
    }
    return url;
}

NSString *OTThumbnailFromRenderer(NSDictionary *renderer, CGFloat size)
{
    if (![renderer isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    NSArray *thumbnails = nil;
    NSDictionary *musicThumb = OTSafeDictionary(renderer[@"musicThumbnailRenderer"]);
    if (musicThumb) {
        thumbnails = OTSafeArray(OTSafeDictionary(musicThumb[@"thumbnail"])[@"thumbnails"]);
    }
    if (!thumbnails) {
        NSDictionary *thumbRenderer = OTSafeDictionary(renderer[@"thumbnailRenderer"]);
        NSDictionary *music = OTSafeDictionary(thumbRenderer[@"musicThumbnailRenderer"]);
        if (music) {
            thumbnails = OTSafeArray(OTSafeDictionary(music[@"thumbnail"])[@"thumbnails"]);
        }
    }
    if (!thumbnails) {
        NSDictionary *wrapper = OTSafeDictionary(renderer[@"thumbnail"]);
        NSDictionary *music = OTSafeDictionary(wrapper[@"musicThumbnailRenderer"]);
        if (music) {
            thumbnails = OTSafeArray(OTSafeDictionary(music[@"thumbnail"])[@"thumbnails"]);
        }
    }
    if (!thumbnails) {
        thumbnails = OTSafeArray(OTSafeDictionary(renderer[@"thumbnail"])[@"thumbnails"]);
    }
    if (!thumbnails) {
        NSDictionary *crop = OTSafeDictionary(renderer[@"croppedSquareThumbnailRenderer"]);
        thumbnails = OTSafeArray(OTSafeDictionary(crop[@"thumbnail"])[@"thumbnails"]);
    }
    if (thumbnails.count == 0) {
        return nil;
    }
    NSString *best = nil;
    NSInteger bestWidth = 0;
    for (NSDictionary *thumb in thumbnails) {
        NSInteger width = [OTSafeString(thumb[@"width"]) integerValue];
        NSString *url = OTSafeString(thumb[@"url"]);
        if (url.length > 0 && width >= bestWidth) {
            bestWidth = width;
            best = url;
        }
    }
    if (!best) {
        best = OTSafeString([thumbnails lastObject][@"url"]);
    }
    return OTResizeThumbnailURL(best, size);
}

NSInteger OTDurationFromText(NSString *text)
{
    if (text.length == 0) {
        return 0;
    }
    NSArray *parts = [text componentsSeparatedByString:@":"];
    NSInteger total = 0;
    for (NSString *part in parts) {
        total = total * 60 + [part integerValue];
    }
    return total;
}

#pragma mark - OTItem

@implementation OTItem

+ (instancetype)itemWithJSON:(NSDictionary *)json
{
    if (![json isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    return [OTItem itemFromRenderer:json];
}

+ (instancetype)itemFromRenderer:(NSDictionary *)renderer
{
    if (![renderer isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    if (renderer[@"musicResponsiveListItemRenderer"]) {
        return [self itemFromResponsiveRenderer:renderer[@"musicResponsiveListItemRenderer"]];
    }
    if (renderer[@"musicTwoRowItemRenderer"]) {
        return [self itemFromTwoRowRenderer:renderer[@"musicTwoRowItemRenderer"]];
    }
    if (renderer[@"playlistPanelVideoRenderer"]) {
        return [self itemFromPlaylistPanelRenderer:renderer[@"playlistPanelVideoRenderer"]];
    }
    return nil;
}

+ (OTItemType)typeForNavigationEndpoint:(NSDictionary *)endpoint
{
    NSDictionary *browse = OTSafeDictionary(endpoint[@"browseEndpoint"]);
    if (browse) {
        NSString *browseId = OTSafeString(browse[@"browseId"]);
        NSString *pageType = OTSafeString(OTSafeDictionary(browse[@"browseEndpointContextSupportedConfigs"])[@"browseEndpointContextMusicConfig"][@"pageType"]);
        if ([pageType isEqualToString:@"MUSIC_PAGE_TYPE_ALBUM"]) {
            return OTItemTypeAlbum;
        }
        if ([pageType isEqualToString:@"MUSIC_PAGE_TYPE_ARTIST"]) {
            return OTItemTypeArtist;
        }
        if ([pageType isEqualToString:@"MUSIC_PAGE_TYPE_PLAYLIST"]) {
            return OTItemTypePlaylist;
        }
        if ([browseId hasPrefix:@"MPRE"]) {
            return OTItemTypeAlbum;
        }
        if ([browseId hasPrefix:@"UC"]) {
            return OTItemTypeArtist;
        }
        if ([browseId hasPrefix:@"VL"] || [browseId hasPrefix:@"FEmusic"] || [browseId hasPrefix:@"RD"]) {
            return OTItemTypePlaylist;
        }
    }
    NSDictionary *watch = OTSafeDictionary(endpoint[@"watchEndpoint"]);
    if (watch) {
        NSString *musicVideoType = OTSafeString(OTSafeDictionary(watch[@"watchEndpointMusicSupportedConfigs"])[@"watchEndpointMusicConfig"][@"musicVideoType"]);
        if ([musicVideoType isEqualToString:@"MUSIC_VIDEO_TYPE_OMV"] ||
            [musicVideoType isEqualToString:@"MUSIC_VIDEO_TYPE_UGC"]) {
            return OTItemTypeVideo;
        }
        return OTItemTypeSong;
    }
    NSDictionary *watchPlaylist = OTSafeDictionary(endpoint[@"watchPlaylistEndpoint"]);
    if (watchPlaylist) {
        return OTItemTypePlaylist;
    }
    return OTItemTypeSong;
}

+ (instancetype)itemFromResponsiveRenderer:(NSDictionary *)renderer
{
    if (![renderer isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    OTItem *item = [[OTItem alloc] init];
    item.type = OTItemTypeSong;

    NSArray *columns = OTSafeArray(renderer[@"flexColumns"]);
    if (columns.count > 0) {
        NSDictionary *column = OTSafeDictionary(columns[0]);
        NSDictionary *inner = OTSafeDictionary(column[@"musicResponsiveListItemFlexColumnRenderer"]);
        item.title = OTTextFromRendererText(OTSafeDictionary(inner[@"text"]));
    }
    if (columns.count > 1) {
        NSDictionary *column = OTSafeDictionary(columns[1]);
        NSDictionary *inner = OTSafeDictionary(column[@"musicResponsiveListItemFlexColumnRenderer"]);
        item.subtitle = OTTextFromRendererText(OTSafeDictionary(inner[@"text"]));
    }

    NSArray *fixed = OTSafeArray(renderer[@"fixedColumns"]);
    if (fixed.count > 0) {
        NSDictionary *column = OTSafeDictionary(fixed[0]);
        NSDictionary *inner = OTSafeDictionary(column[@"musicResponsiveListItemFixedColumnRenderer"]);
        item.durationText = OTTextFromRendererText(OTSafeDictionary(inner[@"text"]));
        item.duration = OTDurationFromText(item.durationText);
    }

    item.thumbnailURL = OTThumbnailFromRenderer(renderer, 120.0);

    NSDictionary *playlistItemData = OTSafeDictionary(renderer[@"playlistItemData"]);
    item.itemId = OTSafeString(playlistItemData[@"videoId"]);
    if (item.itemId.length == 0) {
        NSDictionary *endpoint = OTSafeDictionary(renderer[@"navigationEndpoint"]);
        item.itemId = OTSafeString(OTSafeDictionary(endpoint[@"watchEndpoint"])[@"videoId"]);
    }
    if (item.itemId.length == 0) {
        NSDictionary *overlay = OTSafeDictionary(renderer[@"overlay"]);
        NSDictionary *content = OTSafeDictionary(OTSafeDictionary(overlay[@"musicItemThumbnailOverlayRenderer"])[@"content"]);
        NSDictionary *play = OTSafeDictionary(content[@"musicPlayButtonRenderer"]);
        NSDictionary *endpoint = OTSafeDictionary(play[@"playNavigationEndpoint"]);
        item.itemId = OTSafeString(OTSafeDictionary(endpoint[@"watchEndpoint"])[@"videoId"]);
    }

    NSDictionary *endpoint = OTSafeDictionary(renderer[@"navigationEndpoint"]);
    if (endpoint) {
        OTItemType type = [self typeForNavigationEndpoint:endpoint];
        if (item.itemId.length == 0 || type != OTItemTypeSong) {
            item.type = type;
        }
        NSDictionary *watch = OTSafeDictionary(endpoint[@"watchEndpoint"]);
        if (watch) {
            item.playlistId = OTSafeString(watch[@"playlistId"]);
            if (item.itemId.length == 0) {
                item.itemId = OTSafeString(watch[@"videoId"]);
            }
        }
        NSDictionary *browse = OTSafeDictionary(endpoint[@"browseEndpoint"]);
        if (browse) {
            item.browseId = OTSafeString(browse[@"browseId"]);
            item.params = OTSafeString(browse[@"params"]);
            if (item.itemId.length == 0) {
                item.itemId = item.browseId;
            }
        }
    }

    // "Song • Artist • Album • 2024"
    if (item.subtitle.length > 0) {
        NSArray *parts = [item.subtitle componentsSeparatedByString:@" • "];
        if (parts.count >= 2) {
            item.artistsText = parts[1];
        }
        if (parts.count >= 3) {
            item.albumText = parts[2];
        }
        if (parts.count >= 4) {
            item.yearText = parts[3];
        }
        item.playsText = item.subtitle;
    }
    item.durationText = item.durationText.length > 0 ? item.durationText : nil;
    return item.title.length > 0 ? item : nil;
}

+ (instancetype)itemFromTwoRowRenderer:(NSDictionary *)renderer
{
    if (![renderer isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    OTItem *item = [[OTItem alloc] init];
    item.title = OTTextFromRendererText(OTSafeDictionary(renderer[@"title"]));
    item.subtitle = OTTextFromRendererText(OTSafeDictionary(renderer[@"subtitle"]));
    item.thumbnailURL = OTThumbnailFromRenderer(renderer, 200.0);

    NSDictionary *endpoint = OTSafeDictionary(renderer[@"navigationEndpoint"]);
    item.type = [self typeForNavigationEndpoint:endpoint];

    NSDictionary *browse = OTSafeDictionary(endpoint[@"browseEndpoint"]);
    if (browse) {
        item.browseId = OTSafeString(browse[@"browseId"]);
        item.params = OTSafeString(browse[@"params"]);
        item.itemId = item.browseId;
    }
    NSDictionary *watch = OTSafeDictionary(endpoint[@"watchEndpoint"]);
    if (watch) {
        item.playlistId = OTSafeString(watch[@"playlistId"]);
        if (item.itemId.length == 0) {
            item.itemId = OTSafeString(watch[@"videoId"]);
        }
    }
    NSDictionary *watchPlaylist = OTSafeDictionary(endpoint[@"watchPlaylistEndpoint"]);
    if (watchPlaylist) {
        item.playlistId = OTSafeString(watchPlaylist[@"playlistId"]);
        if (item.itemId.length == 0) {
            item.itemId = item.playlistId;
        }
    }

    if (item.subtitle.length > 0) {
        NSArray *parts = [item.subtitle componentsSeparatedByString:@" • "];
        if (item.type == OTItemTypeAlbum) {
            item.artistsText = parts.count > 0 ? parts[0] : nil;
            item.yearText = parts.count > 1 ? parts[1] : nil;
        } else if (item.type == OTItemTypePlaylist) {
            item.artistsText = item.subtitle;
        }
    }
    return item.title.length > 0 ? item : nil;
}

+ (instancetype)itemFromPlaylistPanelRenderer:(NSDictionary *)renderer
{
    if (![renderer isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    OTItem *item = [[OTItem alloc] init];
    item.type = OTItemTypeSong;
    item.itemId = OTSafeString(renderer[@"videoId"]);
    item.title = OTTextFromRendererText(OTSafeDictionary(renderer[@"title"]));
    NSString *byline = OTTextFromRendererText(OTSafeDictionary(renderer[@"longBylineText"]));
    if (byline.length == 0) {
        byline = OTTextFromRendererText(OTSafeDictionary(renderer[@"shortBylineText"]));
    }
    item.subtitle = byline;
    item.artistsText = byline;
    item.durationText = OTTextFromRendererText(OTSafeDictionary(renderer[@"lengthText"]));
    item.duration = OTDurationFromText(item.durationText);
    item.thumbnailURL = OTThumbnailFromRenderer(renderer, 120.0);

    NSDictionary *endpoint = OTSafeDictionary(renderer[@"navigationEndpoint"]);
    NSDictionary *watch = OTSafeDictionary(endpoint[@"watchEndpoint"]);
    if (watch) {
        item.playlistId = OTSafeString(watch[@"playlistId"]);
    }
    item.isDownloaded = NO;
    return item.title.length > 0 ? item : nil;
}

- (NSDictionary *)dictionaryRepresentation
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    if (self.itemId) dict[@"itemId"] = self.itemId;
    if (self.browseId) dict[@"browseId"] = self.browseId;
    if (self.playlistId) dict[@"playlistId"] = self.playlistId;
    if (self.title) dict[@"title"] = self.title;
    if (self.subtitle) dict[@"subtitle"] = self.subtitle;
    if (self.thumbnailURL) dict[@"thumbnailURL"] = self.thumbnailURL;
    if (self.artistsText) dict[@"artistsText"] = self.artistsText;
    if (self.albumText) dict[@"albumText"] = self.albumText;
    if (self.yearText) dict[@"yearText"] = self.yearText;
    if (self.durationText) dict[@"durationText"] = self.durationText;
    if (self.playsText) dict[@"playsText"] = self.playsText;
    if (self.params) dict[@"params"] = self.params;
    dict[@"duration"] = @(self.duration);
    dict[@"type"] = @(self.type);
    dict[@"explicitContent"] = @(self.explicitContent);
    dict[@"isDownloaded"] = @(self.isDownloaded);
    return dict;
}

+ (instancetype)itemFromDictionary:(NSDictionary *)dictionary
{
    if (![dictionary isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    OTItem *item = [[OTItem alloc] init];
    item.itemId = OTSafeString(dictionary[@"itemId"]);
    item.browseId = OTSafeString(dictionary[@"browseId"]);
    item.playlistId = OTSafeString(dictionary[@"playlistId"]);
    item.title = OTSafeString(dictionary[@"title"]);
    item.subtitle = OTSafeString(dictionary[@"subtitle"]);
    item.thumbnailURL = OTSafeString(dictionary[@"thumbnailURL"]);
    item.artistsText = OTSafeString(dictionary[@"artistsText"]);
    item.albumText = OTSafeString(dictionary[@"albumText"]);
    item.yearText = OTSafeString(dictionary[@"yearText"]);
    item.durationText = OTSafeString(dictionary[@"durationText"]);
    item.playsText = OTSafeString(dictionary[@"playsText"]);
    item.params = OTSafeString(dictionary[@"params"]);
    item.duration = [dictionary[@"duration"] integerValue];
    item.type = [dictionary[@"type"] integerValue];
    item.explicitContent = [dictionary[@"explicitContent"] boolValue];
    item.isDownloaded = [dictionary[@"isDownloaded"] boolValue];
    return item.itemId.length > 0 || item.browseId.length > 0 ? item : nil;
}

- (NSString *)displaySubtitle
{
    if (self.type == OTItemTypeSong || self.type == OTItemTypeVideo) {
        if (self.artistsText.length > 0 && self.albumText.length > 0) {
            return [NSString stringWithFormat:@"%@ • %@", self.artistsText, self.albumText];
        }
        return self.artistsText.length > 0 ? self.artistsText : self.subtitle;
    }
    return self.subtitle;
}

- (BOOL)isPlayable
{
    return (self.type == OTItemTypeSong || self.type == OTItemTypeVideo) && self.itemId.length > 0;
}

@end

#pragma mark - OTSection

@implementation OTSection

+ (instancetype)sectionWithTitle:(NSString *)title
                           items:(NSArray<OTItem *> *)items
                           style:(OTSectionStyle)style
{
    OTSection *section = [[OTSection alloc] init];
    section.title = title;
    section.items = items ?: @[];
    section.style = style;
    return section;
}

@end

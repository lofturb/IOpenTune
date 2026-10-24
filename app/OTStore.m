//
//  OTStore.m
//  OpenTune 9
//

#import "OTStore.h"
#import "OTImageCache.h"

static NSString *const OTKeyFavorites = @"ot.favorites";
static NSString *const OTKeyHistory = @"ot.history";
static NSString *const OTKeyPlaylists = @"ot.playlists";
static NSString *const OTKeyDownloads = @"ot.downloads";
static NSString *const OTKeyStats = @"ot.stats";
static NSString *const OTKeySearchHistory = @"ot.searchHistory";
static NSString *const OTKeyQuality = @"ot.audioQuality";

@implementation OTPlaylist

- (instancetype)init
{
    self = [super init];
    if (self) {
        _items = [NSMutableArray array];
    }
    return self;
}

- (NSDictionary *)dictionaryRepresentation
{
    NSMutableArray *items = [NSMutableArray array];
    for (OTItem *item in self.items) {
        [items addObject:[item dictionaryRepresentation]];
    }
    return @{
        @"playlistId": self.playlistId ?: @"",
        @"name": self.name ?: @"",
        @"createdAt": @(self.createdAt),
        @"items": items
    };
}

+ (instancetype)playlistFromDictionary:(NSDictionary *)dictionary
{
    if (![dictionary isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    OTPlaylist *playlist = [[OTPlaylist alloc] init];
    playlist.playlistId = OTSafeString(dictionary[@"playlistId"]);
    playlist.name = OTSafeString(dictionary[@"name"]);
    playlist.createdAt = [dictionary[@"createdAt"] doubleValue];
    for (NSDictionary *itemDict in OTSafeArray(dictionary[@"items"])) {
        OTItem *item = [OTItem itemFromDictionary:itemDict];
        if (item) {
            [playlist.items addObject:item];
        }
    }
    return playlist;
}

@end


@implementation OTStore

+ (instancetype)sharedStore
{
    static OTStore *store = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        store = [[OTStore alloc] init];
    });
    return store;
}

#pragma mark - Ajustes

- (id)settingForKey:(NSString *)key
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:key];
}

- (void)setSetting:(id)value forKey:(NSString *)key
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (value == nil) {
        [defaults removeObjectForKey:key];
    } else {
        [defaults setObject:value forKey:key];
    }
}

- (NSInteger)audioQuality
{
    id value = [[NSUserDefaults standardUserDefaults] objectForKey:OTKeyQuality];
    return value ? [value integerValue] : 2;
}

- (void)setAudioQuality:(NSInteger)quality
{
    [[NSUserDefaults standardUserDefaults] setInteger:quality forKey:OTKeyQuality];
}

#pragma mark - Favoritos

- (NSArray<OTItem *> *)itemsForKey:(NSString *)key
{
    NSArray *raw = [[NSUserDefaults standardUserDefaults] arrayForKey:key];
    NSMutableArray *items = [NSMutableArray array];
    for (NSDictionary *dict in raw) {
        OTItem *item = [OTItem itemFromDictionary:dict];
        if (item) {
            [items addObject:item];
        }
    }
    return items;
}

- (void)setItems:(NSArray<OTItem *> *)items forKey:(NSString *)key
{
    NSMutableArray *raw = [NSMutableArray array];
    for (OTItem *item in items) {
        [raw addObject:[item dictionaryRepresentation]];
    }
    [[NSUserDefaults standardUserDefaults] setObject:raw forKey:key];
}

- (BOOL)isFavorite:(OTItem *)item
{
    if (item.itemId.length == 0) {
        return NO;
    }
    for (OTItem *favorite in [self favoriteItems]) {
        if ([favorite.itemId isEqualToString:item.itemId]) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)toggleFavorite:(OTItem *)item
{
    if (item.itemId.length == 0) {
        return NO;
    }
    NSMutableArray *items = [[self favoriteItems] mutableCopy];
    NSInteger found = -1;
    for (NSInteger i = 0; i < items.count; i++) {
        if ([((OTItem *)items[i]).itemId isEqualToString:item.itemId]) {
            found = i;
            break;
        }
    }
    BOOL added = NO;
    if (found >= 0) {
        [items removeObjectAtIndex:found];
    } else {
        [items insertObject:item atIndex:0];
        added = YES;
    }
    [self setItems:items forKey:OTKeyFavorites];
    [[NSUserDefaults standardUserDefaults] synchronize];
    return added;
}

- (NSArray<OTItem *> *)favoriteItems
{
    return [self itemsForKey:OTKeyFavorites];
}

#pragma mark - Historial

- (void)recordPlay:(OTItem *)item
{
    if (item.itemId.length == 0) {
        return;
    }
    NSMutableArray *items = [[self itemsForKey:OTKeyHistory] mutableCopy];
    NSInteger found = -1;
    for (NSInteger i = 0; i < items.count; i++) {
        if ([((OTItem *)items[i]).itemId isEqualToString:item.itemId]) {
            found = i;
            break;
        }
    }
    if (found >= 0) {
        [items removeObjectAtIndex:found];
    }
    [items insertObject:item atIndex:0];
    while (items.count > 100) {
        [items removeLastObject];
    }
    [self setItems:items forKey:OTKeyHistory];
}

- (NSArray<OTItem *> *)historyItems
{
    return [self itemsForKey:OTKeyHistory];
}

- (void)clearHistory
{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:OTKeyHistory];
}

#pragma mark - Listas

- (NSArray<OTPlaylist *> *)playlists
{
    NSArray *raw = [[NSUserDefaults standardUserDefaults] arrayForKey:OTKeyPlaylists];
    NSMutableArray *playlists = [NSMutableArray array];
    for (NSDictionary *dict in raw) {
        OTPlaylist *playlist = [OTPlaylist playlistFromDictionary:dict];
        if (playlist) {
            [playlists addObject:playlist];
        }
    }
    return playlists;
}

- (void)savePlaylists:(NSArray<OTPlaylist *> *)playlists
{
    NSMutableArray *raw = [NSMutableArray array];
    for (OTPlaylist *playlist in playlists) {
        [raw addObject:[playlist dictionaryRepresentation]];
    }
    [[NSUserDefaults standardUserDefaults] setObject:raw forKey:OTKeyPlaylists];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (OTPlaylist *)createPlaylistNamed:(NSString *)name
{
    OTPlaylist *playlist = [[OTPlaylist alloc] init];
    playlist.playlistId = [NSString stringWithFormat:@"local-%lld", (long long)([[NSDate date] timeIntervalSince1970] * 1000.0)];
    playlist.name = name.length > 0 ? name : @"Nueva lista";
    playlist.createdAt = [[NSDate date] timeIntervalSince1970];
    NSMutableArray *all = [[self playlists] mutableCopy];
    [all insertObject:playlist atIndex:0];
    [self savePlaylists:all];
    return playlist;
}

- (void)deletePlaylistWithId:(NSString *)playlistId
{
    NSMutableArray *all = [[self playlists] mutableCopy];
    for (NSInteger i = 0; i < all.count; i++) {
        if ([((OTPlaylist *)all[i]).playlistId isEqualToString:playlistId]) {
            [all removeObjectAtIndex:i];
            break;
        }
    }
    [self savePlaylists:all];
}

- (OTPlaylist *)playlistWithId:(NSString *)playlistId
{
    for (OTPlaylist *playlist in [self playlists]) {
        if ([playlist.playlistId isEqualToString:playlistId]) {
            return playlist;
        }
    }
    return nil;
}

- (void)renamePlaylistWithId:(NSString *)playlistId name:(NSString *)name
{
    NSMutableArray *all = [[self playlists] mutableCopy];
    for (OTPlaylist *playlist in all) {
        if ([playlist.playlistId isEqualToString:playlistId]) {
            playlist.name = name;
            break;
        }
    }
    [self savePlaylists:all];
}

- (BOOL)containsItem:(OTItem *)item inPlaylistWithId:(NSString *)playlistId
{
    OTPlaylist *playlist = [self playlistWithId:playlistId];
    for (OTItem *entry in playlist.items) {
        if ([entry.itemId isEqualToString:item.itemId]) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)addItem:(OTItem *)item toPlaylistWithId:(NSString *)playlistId
{
    if (item == nil || playlistId.length == 0) {
        return NO;
    }
    if ([self containsItem:item inPlaylistWithId:playlistId]) {
        return NO;
    }
    NSMutableArray *all = [[self playlists] mutableCopy];
    for (OTPlaylist *playlist in all) {
        if ([playlist.playlistId isEqualToString:playlistId]) {
            [playlist.items addObject:item];
            [self savePlaylists:all];
            return YES;
        }
    }
    return NO;
}

- (void)removeItem:(OTItem *)item fromPlaylistWithId:(NSString *)playlistId
{
    NSMutableArray *all = [[self playlists] mutableCopy];
    for (OTPlaylist *playlist in all) {
        if (![playlist.playlistId isEqualToString:playlistId]) {
            continue;
        }
        for (NSInteger i = 0; i < playlist.items.count; i++) {
            if ([playlist.items[i].itemId isEqualToString:item.itemId]) {
                [playlist.items removeObjectAtIndex:i];
                break;
            }
        }
        break;
    }
    [self savePlaylists:all];
}

#pragma mark - Descargas

- (NSString *)downloadsDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documents = paths.count > 0 ? paths[0] : NSTemporaryDirectory();
    NSString *directory = [documents stringByAppendingPathComponent:@"Descargas"];
    [[NSFileManager defaultManager] createDirectoryAtPath:directory
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:NULL];
    return directory;
}

- (NSArray *)downloadEntries
{
    return [[NSUserDefaults standardUserDefaults] arrayForKey:OTKeyDownloads] ?: @[];
}

- (NSDictionary *)downloadEntryForItem:(OTItem *)item
{
    for (NSDictionary *entry in [self downloadEntries]) {
        NSString *itemId = OTSafeString(entry[@"itemId"]);
        if ([itemId isEqualToString:item.itemId]) {
            return entry;
        }
    }
    return nil;
}

- (NSString *)localPathForItem:(OTItem *)item
{
    NSDictionary *entry = [self downloadEntryForItem:item];
    NSString *file = OTSafeString(entry[@"file"]);
    if (file.length == 0) {
        return nil;
    }
    NSString *path = [[self downloadsDirectory] stringByAppendingPathComponent:file];
    return [[NSFileManager defaultManager] fileExistsAtPath:path] ? path : nil;
}

- (BOOL)isDownloaded:(OTItem *)item
{
    return [self localPathForItem:item] != nil;
}

- (void)registerDownload:(OTItem *)item path:(NSString *)path
{
    NSString *file = [path lastPathComponent];
    NSMutableArray *entries = [[self downloadEntries] mutableCopy];
    NSMutableArray *kept = [NSMutableArray array];
    for (NSDictionary *entry in entries) {
        if (![OTSafeString(entry[@"itemId"]) isEqualToString:item.itemId]) {
            [kept addObject:entry];
        }
    }
    [kept insertObject:@{
        @"itemId": item.itemId ?: @"",
        @"file": file ?: @"",
        @"item": [item dictionaryRepresentation]
    } atIndex:0];
    [[NSUserDefaults standardUserDefaults] setObject:kept forKey:OTKeyDownloads];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)removeDownloadForItem:(OTItem *)item
{
    NSDictionary *entry = [self downloadEntryForItem:item];
    NSString *file = OTSafeString(entry[@"file"]);
    if (file.length > 0) {
        NSString *path = [[self downloadsDirectory] stringByAppendingPathComponent:file];
        [[NSFileManager defaultManager] removeItemAtPath:path error:NULL];
    }
    NSMutableArray *kept = [NSMutableArray array];
    for (NSDictionary *other in [self downloadEntries]) {
        if (![OTSafeString(other[@"itemId"]) isEqualToString:item.itemId]) {
            [kept addObject:other];
        }
    }
    [[NSUserDefaults standardUserDefaults] setObject:kept forKey:OTKeyDownloads];
}

- (NSArray<OTItem *> *)downloadedItems
{
    NSMutableArray *items = [NSMutableArray array];
    for (NSDictionary *entry in [self downloadEntries]) {
        NSDictionary *dict = OTSafeDictionary(entry[@"item"]);
        OTItem *item = [OTItem itemFromDictionary:dict];
        if (item) {
            [items addObject:item];
        }
    }
    return items;
}

- (unsigned long long)downloadsSize
{
    unsigned long long total = 0;
    NSString *directory = [self downloadsDirectory];
    NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtPath:directory];
    for (NSString *file in enumerator) {
        NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:
                               [directory stringByAppendingPathComponent:file] error:NULL];
        total += attrs.fileSize;
    }
    return total;
}

#pragma mark - Estadisticas

- (void)recordListening:(OTItem *)item seconds:(double)seconds
{
    if (item.itemId.length == 0 || seconds < 1.0) {
        return;
    }
    NSMutableDictionary *stats = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:OTKeyStats] mutableCopy];
    if (!stats) {
        stats = [NSMutableDictionary dictionary];
    }
    NSMutableDictionary *entry = [stats[item.itemId] mutableCopy];
    if (!entry) {
        entry = [NSMutableDictionary dictionary];
    }
    entry[@"title"] = item.title ?: @"";
    entry[@"artist"] = item.artistsText ?: item.subtitle ?: @"";
    entry[@"thumbnail"] = item.thumbnailURL ?: @"";
    entry[@"count"] = @([entry[@"count"] integerValue] + 1);
    entry[@"seconds"] = @([entry[@"seconds"] doubleValue] + seconds);
    entry[@"lastPlayed"] = @([[NSDate date] timeIntervalSince1970]);
    stats[item.itemId] = entry;
    [[NSUserDefaults standardUserDefaults] setObject:stats forKey:OTKeyStats];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSArray<NSDictionary *> *)topItems:(NSInteger)limit
{
    NSDictionary *stats = [[NSUserDefaults standardUserDefaults] dictionaryForKey:OTKeyStats] ?: @{};
    NSMutableArray *entries = [NSMutableArray array];
    for (NSString *key in stats) {
        NSMutableDictionary *entry = [stats[key] mutableCopy];
        entry[@"itemId"] = key;
        [entries addObject:entry];
    }
    [entries sortUsingComparator:^NSComparisonResult(NSDictionary *a, NSDictionary *b) {
        return [b[@"count"] compare:a[@"count"]];
    }];
    if (limit > 0 && entries.count > (NSUInteger)limit) {
        return [entries subarrayWithRange:NSMakeRange(0, limit)];
    }
    return entries;
}

- (NSInteger)totalPlays
{
    NSInteger total = 0;
    for (NSDictionary *entry in [self topItems:0]) {
        total += [entry[@"count"] integerValue];
    }
    return total;
}

#pragma mark - Busquedas

- (NSArray<NSString *> *)searchHistory
{
    return [[NSUserDefaults standardUserDefaults] arrayForKey:OTKeySearchHistory] ?: @[];
}

- (void)addSearchTerm:(NSString *)term
{
    if (term.length == 0) {
        return;
    }
    NSMutableArray *terms = [[self searchHistory] mutableCopy];
    [terms removeObject:term];
    [terms insertObject:term atIndex:0];
    while (terms.count > 20) {
        [terms removeLastObject];
    }
    [[NSUserDefaults standardUserDefaults] setObject:terms forKey:OTKeySearchHistory];
}

- (void)clearSearchHistory
{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:OTKeySearchHistory];
}

#pragma mark - Mantenimiento

- (void)clearCaches
{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"ot.homeCache"];
    [[OTImageCache sharedCache] clearMemoryCache];
}

- (void)synchronize
{
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end

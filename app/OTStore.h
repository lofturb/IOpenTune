//
//  OTStore.h
//  OpenTune 9
//

#import <Foundation/Foundation.h>
#import "OTItem.h"

@interface OTPlaylist : NSObject

@property (nonatomic, copy) NSString *playlistId;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, strong) NSMutableArray<OTItem *> *items;
@property (nonatomic, assign) NSTimeInterval createdAt;

- (NSDictionary *)dictionaryRepresentation;
+ (instancetype)playlistFromDictionary:(NSDictionary *)dictionary;

@end


@interface OTStore : NSObject

+ (instancetype)sharedStore;

// Ajustes
- (id)settingForKey:(NSString *)key;
- (void)setSetting:(id)value forKey:(NSString *)key;
- (NSInteger)audioQuality;              // 0 baja, 1 alta, 2 maxima
- (void)setAudioQuality:(NSInteger)quality;

// Favoritos
- (BOOL)isFavorite:(OTItem *)item;
- (BOOL)toggleFavorite:(OTItem *)item;
- (NSArray<OTItem *> *)favoriteItems;

// Historial
- (void)recordPlay:(OTItem *)item;
- (NSArray<OTItem *> *)historyItems;
- (void)clearHistory;

// Listas locales
- (NSArray<OTPlaylist *> *)playlists;
- (OTPlaylist *)createPlaylistNamed:(NSString *)name;
- (void)deletePlaylistWithId:(NSString *)playlistId;
- (void)renamePlaylistWithId:(NSString *)playlistId name:(NSString *)name;
- (BOOL)addItem:(OTItem *)item toPlaylistWithId:(NSString *)playlistId;
- (void)removeItem:(OTItem *)item fromPlaylistWithId:(NSString *)playlistId;
- (OTPlaylist *)playlistWithId:(NSString *)playlistId;
- (BOOL)containsItem:(OTItem *)item inPlaylistWithId:(NSString *)playlistId;

// Descargas
- (NSString *)downloadsDirectory;
- (NSString *)localPathForItem:(OTItem *)item;
- (BOOL)isDownloaded:(OTItem *)item;
- (void)registerDownload:(OTItem *)item path:(NSString *)path;
- (void)removeDownloadForItem:(OTItem *)item;
- (NSArray<OTItem *> *)downloadedItems;
- (unsigned long long)downloadsSize;

// Estadisticas
- (void)recordListening:(OTItem *)item seconds:(double)seconds;
- (NSArray<NSDictionary *> *)topItems:(NSInteger)limit;
- (NSInteger)totalPlays;

// Busquedas
- (NSArray<NSString *> *)searchHistory;
- (void)addSearchTerm:(NSString *)term;
- (void)clearSearchHistory;

// Mantenimiento
- (void)clearCaches;
- (void)synchronize;

@end

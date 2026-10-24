//
//  OTItem.h
//  OpenTune 9
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, OTItemType) {
    OTItemTypeSong = 0,
    OTItemTypeVideo,
    OTItemTypeAlbum,
    OTItemTypeArtist,
    OTItemTypePlaylist
};

typedef NS_ENUM(NSInteger, OTSectionStyle) {
    OTSectionStyleCarousel = 0,
    OTSectionStyleList
};

@class OTItem;

@interface OTItem : NSObject

@property (nonatomic, copy) NSString *itemId;        // videoId o browseId
@property (nonatomic, copy) NSString *browseId;
@property (nonatomic, copy) NSString *playlistId;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subtitle;
@property (nonatomic, copy) NSString *thumbnailURL;
@property (nonatomic, copy) NSString *artistsText;
@property (nonatomic, copy) NSString *albumText;
@property (nonatomic, copy) NSString *yearText;
@property (nonatomic, copy) NSString *durationText;
@property (nonatomic, copy) NSString *playsText;
@property (nonatomic, copy) NSString *params;
@property (nonatomic, assign) NSInteger duration;
@property (nonatomic, assign) OTItemType type;
@property (nonatomic, assign) BOOL explicitContent;
@property (nonatomic, assign) BOOL isDownloaded;
@property (nonatomic, assign) NSUInteger colorValue;   // color de tarjeta (animos y generos)

+ (instancetype)itemWithJSON:(NSDictionary *)json;
+ (instancetype)itemFromRenderer:(NSDictionary *)renderer;
+ (instancetype)itemFromResponsiveRenderer:(NSDictionary *)renderer;
+ (instancetype)itemFromTwoRowRenderer:(NSDictionary *)renderer;
+ (instancetype)itemFromPlaylistPanelRenderer:(NSDictionary *)renderer;

- (NSDictionary *)dictionaryRepresentation;
+ (instancetype)itemFromDictionary:(NSDictionary *)dictionary;

- (NSString *)displaySubtitle;
- (BOOL)isPlayable;

@end


@interface OTSection : NSObject

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *browseId;
@property (nonatomic, copy) NSString *params;
@property (nonatomic, assign) OTSectionStyle style;
@property (nonatomic, strong) NSArray<OTItem *> *items;

+ (instancetype)sectionWithTitle:(NSString *)title
                           items:(NSArray<OTItem *> *)items
                           style:(OTSectionStyle)style;

@end


// Utilidades de parseo de la API interna de YouTube Music.
NSString *OTTextFromRuns(NSArray *runs);
NSString *OTTextFromRendererText(NSDictionary *text);
NSArray *OTCollectObjects(NSDictionary *json, NSString *rendererKey);
NSDictionary *OTFirstObject(NSDictionary *json, NSString *rendererKey);
NSString *OTThumbnailFromRenderer(NSDictionary *renderer, CGFloat size);
NSString *OTResizeThumbnailURL(NSString *url, CGFloat size);
NSString *OTSafeString(id value);
NSArray *OTSafeArray(id value);
NSDictionary *OTSafeDictionary(id value);
NSInteger OTDurationFromText(NSString *text);

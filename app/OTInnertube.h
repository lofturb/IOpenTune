//
//  OTInnertube.h
//  OpenTune 9
//

#import <Foundation/Foundation.h>
#import "OTItem.h"

typedef NS_ENUM(NSInteger, OTSearchFilter) {
    OTSearchFilterAll = 0,
    OTSearchFilterSongs,
    OTSearchFilterVideos,
    OTSearchFilterAlbums,
    OTSearchFilterArtists,
    OTSearchFilterPlaylists
};

typedef void (^OTJSONCompletion)(NSDictionary *json, NSError *error);
typedef void (^OTFeedCompletion)(NSArray<OTSection *> *sections, NSString *continuation, NSError *error);
typedef void (^OTNextCompletion)(NSArray<OTItem *> *items,
                                 NSInteger currentIndex,
                                 NSString *lyricsBrowseId,
                                 NSString *lyricsParams,
                                 NSError *error);
typedef void (^OTStreamCompletion)(NSURL *url, NSString *mimeType, NSString *clientName, NSError *error);

@interface OTInnertube : NSObject

+ (instancetype)shared;

@property (nonatomic, copy) NSString *visitorData;
@property (nonatomic, copy) NSString *cookie;       // SAPISID=...; __Secure-3PAPISID=...
@property (nonatomic, copy) NSString *dataSyncId;
@property (nonatomic, copy) NSString *language;     // es-ES
@property (nonatomic, copy) NSString *region;       // ES

- (BOOL)isLoggedIn;
- (void)clearLogin;

// Navegacion
- (void)homeWithCompletion:(OTFeedCompletion)completion;
- (void)homeContinuation:(NSString *)continuation completion:(OTFeedCompletion)completion;
- (void)search:(NSString *)query
        filter:(OTSearchFilter)filter
    completion:(OTFeedCompletion)completion;
- (void)searchContinuation:(NSString *)continuation completion:(OTFeedCompletion)completion;
- (void)searchSuggestions:(NSString *)input
               completion:(void (^)(NSArray<NSString *> *suggestions, NSError *error))completion;
- (void)browse:(NSString *)browseId params:(NSString *)params completion:(OTJSONCompletion)completion;
- (void)browseContinuation:(NSString *)continuation completion:(OTJSONCompletion)completion;

// Paginas especiales
- (void)exploreCompletion:(OTFeedCompletion)completion;
- (void)chartsCompletion:(OTFeedCompletion)completion;
- (void)newReleasesCompletion:(OTFeedCompletion)completion;
- (void)moodAndGenresCompletion:(OTFeedCompletion)completion;
- (void)album:(NSString *)browseId completion:(OTFeedCompletion)completion;
- (void)playlist:(NSString *)playlistId completion:(OTFeedCompletion)completion;
- (void)artist:(NSString *)browseId completion:(OTFeedCompletion)completion;
- (void)librarySongsCompletion:(OTFeedCompletion)completion;

// Cola / letras
- (void)nextForVideo:(NSString *)videoId
           playlistId:(NSString *)playlistId
                index:(NSInteger)index
           completion:(OTNextCompletion)completion;
- (void)lyricsWithBrowseId:(NSString *)browseId
                    params:(NSString *)params
                completion:(void (^)(NSString *lyrics, NSError *error))completion;

// Reproduccion
- (void)streamURLForVideo:(NSString *)videoId completion:(OTStreamCompletion)completion;
- (void)streamURLForVideo:(NSString *)videoId
                avoidMime:(NSString *)avoidMime
               completion:(OTStreamCompletion)completion;

@end


// Parseo compartido de respuestas.
NSArray<OTSection *> *OTParseSections(NSDictionary *json);
NSArray<OTItem *> *OTParseSongItems(NSDictionary *json);
NSArray<OTItem *> *OTParseMoodButtons(NSDictionary *json);
NSArray<NSDictionary *> *OTParseHomeChips(NSDictionary *json);
OTItem *OTParseCollectionHeader(NSDictionary *json, OTItemType type);
OTItem *OTParseCardShelf(NSDictionary *json);
NSString *OTContinuationFromJSON(NSDictionary *json);
NSString *OTLyricsBrowseIdFromJSON(NSDictionary *json);
NSString *OTLyricsParamsFromJSON(NSDictionary *json);

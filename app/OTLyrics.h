//
//  OTLyrics.h
//  OpenTune 9
//

#import <Foundation/Foundation.h>
#import "OTItem.h"

@interface OTLyricLine : NSObject

@property (nonatomic, assign) NSTimeInterval time;
@property (nonatomic, copy) NSString *text;

@end


@interface OTLyrics : NSObject

+ (instancetype)sharedLyrics;

- (void)lyricsForItem:(OTItem *)item
           completion:(void (^)(NSArray<OTLyricLine *> *lines,
                                BOOL synced,
                                NSString *plain,
                                NSError *error))completion;

- (NSArray<OTLyricLine *> *)cachedLyricsForItemId:(NSString *)itemId;
- (BOOL)cachedLyricsAreSyncedForItemId:(NSString *)itemId;

@end

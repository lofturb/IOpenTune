//
//  OTPlayer.h
//  OpenTune 9
//

#import <Foundation/Foundation.h>
#import "OTItem.h"

typedef NS_ENUM(NSInteger, OTRepeatMode) {
    OTRepeatOff = 0,
    OTRepeatAll,
    OTRepeatOne
};

extern NSString *const OTPlayerStateDidChangeNotification;
extern NSString *const OTPlayerTrackDidChangeNotification;
extern NSString *const OTPlayerTimeDidChangeNotification;
extern NSString *const OTPlayerErrorNotification;
extern NSString *const OTPlayerQueueDidChangeNotification;

@interface OTPlayer : NSObject

+ (instancetype)sharedPlayer;

@property (nonatomic, readonly) NSArray<OTItem *> *queue;
@property (nonatomic, readonly) NSInteger index;
@property (nonatomic, readonly) OTItem *currentItem;
@property (nonatomic, readonly) BOOL isPlaying;
@property (nonatomic, readonly) BOOL isLoading;
@property (nonatomic, readonly) double currentTime;
@property (nonatomic, readonly) double duration;
@property (nonatomic, assign) BOOL shuffle;
@property (nonatomic, assign) OTRepeatMode repeatMode;
@property (nonatomic, assign) float playbackRate;

- (void)setQueue:(NSArray<OTItem *> *)items startIndex:(NSInteger)startIndex;
- (void)playItem:(OTItem *)item inQueue:(NSArray<OTItem *> *)items;
- (void)togglePlayPause;
- (void)play;
- (void)pause;
- (void)next;
- (void)previous;
- (void)seekTo:(double)seconds;
- (void)addToQueue:(OTItem *)item;
- (void)removeFromQueueAtIndex:(NSInteger)index;
- (void)clearQueue;
- (void)cycleRepeatMode;
- (void)setSleepTimer:(NSTimeInterval)seconds;
- (void)cancelSleepTimer;
- (BOOL)sleepTimerActive;
- (NSInteger)sleepTimerRemaining;

@end

//
//  OTPlayer.m
//  OpenTune 9
//

#import "OTPlayer.h"
#import "OTInnertube.h"
#import "OTStore.h"
#import "OTTheme.h"
#import "OTImageCache.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>

NSString *const OTPlayerStateDidChangeNotification = @"OTPlayerStateDidChangeNotification";
NSString *const OTPlayerTrackDidChangeNotification = @"OTPlayerTrackDidChangeNotification";
NSString *const OTPlayerTimeDidChangeNotification = @"OTPlayerTimeDidChangeNotification";
NSString *const OTPlayerErrorNotification = @"OTPlayerErrorNotification";
NSString *const OTPlayerQueueDidChangeNotification = @"OTPlayerQueueDidChangeNotification";

static void *OTPlayerRateContext = &OTPlayerRateContext;
static void *OTPlayerItemStatusContext = &OTPlayerItemStatusContext;

@interface OTPlayer ()

@property (nonatomic, strong) NSMutableArray<OTItem *> *items;
@property (nonatomic, strong) NSMutableArray<NSNumber *> *order;
@property (nonatomic, assign) NSInteger currentIndex;
@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerItem *playerItem;
@property (nonatomic, strong) id timeObserver;
@property (nonatomic, assign) BOOL loading;
@property (nonatomic, assign) BOOL shouldResumeAfterInterruption;
@property (nonatomic, assign) double trackStartTime;
@property (nonatomic, strong) NSTimer *sleepTimer;
@property (nonatomic, assign) NSTimeInterval sleepDeadline;
@property (nonatomic, assign) BOOL observingPlayer;

@end

@implementation OTPlayer

+ (instancetype)sharedPlayer
{
    static OTPlayer *player = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        player = [[OTPlayer alloc] init];
    });
    return player;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _items = [NSMutableArray array];
        _order = [NSMutableArray array];
        _currentIndex = -1;
        _playbackRate = 1.0f;
        _repeatMode = OTRepeatOff;
        _shuffle = NO;

        [self configureAudioSession];
        [self configureRemoteCommands];

        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center addObserver:self
                   selector:@selector(handleInterruption:)
                       name:AVAudioSessionInterruptionNotification
                     object:nil];
        [center addObserver:self
                   selector:@selector(handleRouteChange:)
                       name:AVAudioSessionRouteChangeNotification
                     object:nil];
        [center addObserver:self
                   selector:@selector(handlePlaybackEnd:)
                       name:AVPlayerItemDidPlayToEndTimeNotification
                     object:nil];
        [center addObserver:self
                   selector:@selector(handleAudioSessionMediaReset:)
                       name:AVAudioSessionMediaServicesWereResetNotification
                     object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (self.timeObserver) {
        [self.player removeTimeObserver:self.timeObserver];
    }
    if (self.observingPlayer) {
        [self.player removeObserver:self forKeyPath:@"rate" context:OTPlayerRateContext];
    }
}

#pragma mark - Propiedades publicas

- (NSArray<OTItem *> *)queue
{
    return [self.items copy];
}

- (NSInteger)index
{
    return self.currentIndex;
}

- (OTItem *)currentItem
{
    if (self.currentIndex >= 0 && self.currentIndex < (NSInteger)self.items.count) {
        return self.items[self.currentIndex];
    }
    return nil;
}

- (BOOL)isPlaying
{
    return self.player.rate > 0.01;
}

- (BOOL)isLoading
{
    return self.loading;
}

- (double)currentTime
{
    CMTime time = self.player.currentTime;
    if (CMTIME_IS_VALID(time)) {
        return CMTimeGetSeconds(time);
    }
    return 0;
}

- (double)duration
{
    if (self.playerItem) {
        CMTime time = self.playerItem.duration;
        if (CMTIME_IS_VALID(time) && !CMTIME_IS_INDEFINITE(time)) {
            double seconds = CMTimeGetSeconds(time);
            if (seconds > 0 && isfinite(seconds)) {
                return seconds;
            }
        }
    }
    OTItem *item = self.currentItem;
    return item.duration > 0 ? (double)item.duration : 0;
}

- (BOOL)sleepTimerActive
{
    return self.sleepTimer != nil;
}

- (NSInteger)sleepTimerRemaining
{
    if (!self.sleepTimer || self.sleepDeadline <= 0) {
        return 0;
    }
    return (NSInteger)MAX(0.0, self.sleepDeadline - [[NSDate date] timeIntervalSince1970]);
}

#pragma mark - Configuracion

- (void)configureAudioSession
{
    NSError *error = nil;
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayback error:&error];
    [session setActive:YES error:&error];
}

- (void)configureRemoteCommands
{
    MPRemoteCommandCenter *center = [MPRemoteCommandCenter sharedCommandCenter];
    [center.playCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent *event) {
        [[OTPlayer sharedPlayer] play];
        return MPRemoteCommandHandlerStatusSuccess;
    }];
    [center.pauseCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent *event) {
        [[OTPlayer sharedPlayer] pause];
        return MPRemoteCommandHandlerStatusSuccess;
    }];
    [center.togglePlayPauseCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent *event) {
        [[OTPlayer sharedPlayer] togglePlayPause];
        return MPRemoteCommandHandlerStatusSuccess;
    }];
    [center.nextTrackCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent *event) {
        [[OTPlayer sharedPlayer] next];
        return MPRemoteCommandHandlerStatusSuccess;
    }];
    [center.previousTrackCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent *event) {
        [[OTPlayer sharedPlayer] previous];
        return MPRemoteCommandHandlerStatusSuccess;
    }];
    [center.changePlaybackPositionCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent *event) {
        MPChangePlaybackPositionCommandEvent *positionEvent = (MPChangePlaybackPositionCommandEvent *)event;
        [[OTPlayer sharedPlayer] seekTo:positionEvent.positionTime];
        return MPRemoteCommandHandlerStatusSuccess;
    }];
}

- (AVPlayer *)ensurePlayer
{
    if (!self.player) {
        self.player = [[AVPlayer alloc] init];
        self.player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
        self.player.allowsExternalPlayback = YES;
        [self.player addObserver:self
                      forKeyPath:@"rate"
                         options:NSKeyValueObservingOptionNew
                         context:OTPlayerRateContext];
        self.observingPlayer = YES;

        __weak typeof(self) weakSelf = self;
        self.timeObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(0.5, NSEC_PER_SEC)
                                                                      queue:dispatch_get_main_queue()
                                                                 usingBlock:^(CMTime time) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) {
                return;
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:OTPlayerTimeDidChangeNotification
                                                                object:strongSelf];
            [strongSelf updateNowPlayingElapsed];
        }];
    }
    return self.player;
}

#pragma mark - Cola

- (void)setQueue:(NSArray<OTItem *> *)items startIndex:(NSInteger)startIndex
{
    [self recordListeningTime];
    [self.items removeAllObjects];
    for (OTItem *item in items) {
        if (item.isPlayable) {
            [self.items addObject:item];
        }
    }
    if (self.items.count == 0) {
        [self stop];
        return;
    }
    NSInteger index = MAX(0, MIN(startIndex, (NSInteger)self.items.count - 1));
    self.currentIndex = index;
    [self rebuildOrder];
    [self loadCurrentTrack];
    [[NSNotificationCenter defaultCenter] postNotificationName:OTPlayerQueueDidChangeNotification object:self];
}

- (void)playItem:(OTItem *)item inQueue:(NSArray<OTItem *> *)items
{
    if (!item.isPlayable) {
        return;
    }
    NSInteger startIndex = 0;
    NSMutableArray *list = [NSMutableArray array];
    BOOL found = NO;
    for (NSInteger i = 0; i < (NSInteger)items.count; i++) {
        OTItem *entry = items[i];
        if (!entry.isPlayable) {
            continue;
        }
        if ([entry.itemId isEqualToString:item.itemId]) {
            startIndex = list.count;
            found = YES;
        }
        [list addObject:entry];
    }
    if (!found) {
        [list insertObject:item atIndex:0];
        startIndex = 0;
    }
    [self setQueue:list startIndex:startIndex];
}

- (void)addToQueue:(OTItem *)item
{
    if (!item.isPlayable) {
        return;
    }
    [self.items addObject:item];
    [self.order addObject:@(self.items.count - 1)];
    if (self.currentIndex < 0) {
        self.currentIndex = 0;
        [self loadCurrentTrack];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:OTPlayerQueueDidChangeNotification object:self];
}

- (void)removeFromQueueAtIndex:(NSInteger)index
{
    if (index < 0 || index >= (NSInteger)self.items.count) {
        return;
    }
    BOOL removingCurrent = (index == self.currentIndex);
    if (removingCurrent) {
        [self recordListeningTime];
    }
    [self.items removeObjectAtIndex:index];
    if (index < self.currentIndex) {
        self.currentIndex--;
    }
    [self rebuildOrder];
    if (self.items.count == 0) {
        [self stop];
    } else if (removingCurrent) {
        if (self.currentIndex >= (NSInteger)self.items.count) {
            self.currentIndex = (NSInteger)self.items.count - 1;
        }
        [self loadCurrentTrack];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:OTPlayerQueueDidChangeNotification object:self];
}

- (void)clearQueue
{
    [self stop];
    [self.items removeAllObjects];
    [self.order removeAllObjects];
    self.currentIndex = -1;
    [[NSNotificationCenter defaultCenter] postNotificationName:OTPlayerQueueDidChangeNotification object:self];
}

- (void)stop
{
    [self.player pause];
    [self removeItemObservers];
    [self.player replaceCurrentItemWithPlayerItem:nil];
    self.playerItem = nil;
}

- (void)rebuildOrder
{
    [self.order removeAllObjects];
    for (NSInteger i = 0; i < (NSInteger)self.items.count; i++) {
        [self.order addObject:@(i)];
    }
    if (self.shuffle && self.items.count > 0) {
        NSMutableArray *rest = [self.order mutableCopy];
        NSNumber *current = @(self.currentIndex);
        [rest removeObject:current];
        for (NSInteger i = (NSInteger)rest.count - 1; i > 0; i--) {
            NSInteger j = arc4random_uniform((uint32_t)(i + 1));
            [rest exchangeObjectAtIndex:i withObjectAtIndex:j];
        }
        [self.order removeAllObjects];
        if (self.currentIndex >= 0) {
            [self.order addObject:current];
        }
        [self.order addObjectsFromArray:rest];
    }
}

- (void)setShuffle:(BOOL)shuffle
{
    _shuffle = shuffle;
    [self rebuildOrder];
    [[NSNotificationCenter defaultCenter] postNotificationName:OTPlayerStateDidChangeNotification object:self];
}

- (void)cycleRepeatMode
{
    self.repeatMode = (self.repeatMode + 1) % 3;
    [[NSNotificationCenter defaultCenter] postNotificationName:OTPlayerStateDidChangeNotification object:self];
}

#pragma mark - Carga de audio

- (void)loadCurrentTrack
{
    OTItem *item = self.currentItem;
    if (!item) {
        return;
    }

    self.loading = YES;
    self.trackStartTime = 0;
    [self notifyState];

    [[NSNotificationCenter defaultCenter] postNotificationName:OTPlayerTrackDidChangeNotification object:self];
    [[OTStore sharedStore] recordPlay:item];
    [self updateNowPlayingMetadata];

    NSString *localPath = [[OTStore sharedStore] localPathForItem:item];
    if (localPath.length > 0) {
        NSURL *fileURL = [NSURL fileURLWithPath:localPath];
        [self startPlaybackWithURL:fileURL mimeType:nil];
        return;
    }

    __weak typeof(self) weakSelf = self;
    NSString *requestedId = [item.itemId copy];
    [[OTInnertube shared] streamURLForVideo:item.itemId completion:^(NSURL *url, NSString *mimeType, NSString *clientName, NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        if (![strongSelf.currentItem.itemId isEqualToString:requestedId]) {
            return;
        }
        if (!url) {
            strongSelf.loading = NO;
            [strongSelf notifyState];
            NSString *message = error.localizedDescription ?: @"No se pudo reproducir esta canción";
            [[NSNotificationCenter defaultCenter] postNotificationName:OTPlayerErrorNotification
                                                                object:strongSelf
                                                              userInfo:@{@"message": message}];
            return;
        }
        [strongSelf startPlaybackWithURL:url mimeType:mimeType];
    }];
}

- (void)startPlaybackWithURL:(NSURL *)url mimeType:(NSString *)mimeType
{
    [self removeItemObservers];

    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:url];
    playerItem.audioTimePitchAlgorithm = AVAudioTimePitchAlgorithmTimeDomain;
    self.playerItem = playerItem;
    [playerItem addObserver:self
                 forKeyPath:@"status"
                    options:NSKeyValueObservingOptionNew
                    context:OTPlayerItemStatusContext];

    AVPlayer *player = [self ensurePlayer];
    [player replaceCurrentItemWithPlayerItem:playerItem];
    [player play];
    player.rate = self.playbackRate;
    self.loading = YES;
    [self notifyState];
}

- (void)removeItemObservers
{
    if (self.playerItem) {
        @try {
            [self.playerItem removeObserver:self forKeyPath:@"status" context:OTPlayerItemStatusContext];
        } @catch (NSException *exception) {
            (void)exception;
        }
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if (context == OTPlayerRateContext) {
        [self notifyState];
        [self updateNowPlayingElapsed];
        return;
    }
    if (context == OTPlayerItemStatusContext) {
        AVPlayerItem *item = (AVPlayerItem *)object;
        if (item.status == AVPlayerItemStatusReadyToPlay) {
            self.loading = NO;
            if (self.player.rate < 0.01) {
                [self.player play];
                self.player.rate = self.playbackRate;
            }
            [self notifyState];
            [self updateNowPlayingMetadata];
        } else if (item.status == AVPlayerItemStatusFailed) {
            self.loading = NO;
            [self notifyState];
            NSString *message = item.error.localizedDescription ?: @"No se pudo reproducir esta canción";
            [[NSNotificationCenter defaultCenter] postNotificationName:OTPlayerErrorNotification
                                                                object:self
                                                              userInfo:@{@"message": message}];
        }
        return;
    }
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

#pragma mark - Control

- (void)play
{
    if (!self.player && self.currentItem) {
        [self loadCurrentTrack];
        return;
    }
    if (self.playerItem.status == AVPlayerItemStatusFailed) {
        [self loadCurrentTrack];
        return;
    }
    [self.player play];
    self.player.rate = self.playbackRate;
    [self notifyState];
}

- (void)pause
{
    [self.player pause];
    [self notifyState];
    [self recordListeningTime];
}

- (void)togglePlayPause
{
    if (self.isPlaying) {
        [self pause];
    } else {
        [self play];
    }
}

- (void)next
{
    NSInteger nextIndex = [self nextIndexUserInitiated:YES];
    if (nextIndex < 0) {
        if (self.repeatMode == OTRepeatAll && self.items.count > 0) {
            nextIndex = [self firstIndexInOrder];
        } else {
            [self pause];
            return;
        }
    }
    [self recordListeningTime];
    self.currentIndex = nextIndex;
    [self loadCurrentTrack];
}

- (void)previous
{
    if (self.currentTime > 3.0) {
        [self seekTo:0];
        return;
    }
    NSInteger previousIndex = [self nextIndexUserInitiated:NO];
    if (previousIndex < 0) {
        [self seekTo:0];
        return;
    }
    [self recordListeningTime];
    self.currentIndex = previousIndex;
    [self loadCurrentTrack];
}

- (NSInteger)firstIndexInOrder
{
    if (self.shuffle) {
        for (NSNumber *number in self.order) {
            if ([number integerValue] != self.currentIndex) {
                return [number integerValue];
            }
        }
        return self.currentIndex;
    }
    return 0;
}

- (NSInteger)nextIndexUserInitiated:(BOOL)forward
{
    if (self.items.count == 0) {
        return -1;
    }
    if (self.shuffle) {
        NSInteger position = -1;
        for (NSInteger i = 0; i < (NSInteger)self.order.count; i++) {
            if ([self.order[i] integerValue] == self.currentIndex) {
                position = i;
                break;
            }
        }
        if (position < 0) {
            return [self firstIndexInOrder];
        }
        NSInteger target = forward ? position + 1 : position - 1;
        if (target < 0) {
            target = self.repeatMode == OTRepeatAll ? (NSInteger)self.order.count - 1 : -1;
        }
        if (target >= (NSInteger)self.order.count) {
            target = self.repeatMode == OTRepeatAll ? 0 : -1;
        }
        return target >= 0 ? [self.order[target] integerValue] : -1;
    }

    NSInteger target = forward ? self.currentIndex + 1 : self.currentIndex - 1;
    if (target < 0) {
        target = self.repeatMode == OTRepeatAll ? (NSInteger)self.items.count - 1 : -1;
    }
    if (target >= (NSInteger)self.items.count) {
        target = self.repeatMode == OTRepeatAll ? 0 : -1;
    }
    return target;
}

- (void)seekTo:(double)seconds
{
    if (!self.playerItem) {
        return;
    }
    CMTime time = CMTimeMakeWithSeconds(MAX(0.0, seconds), NSEC_PER_SEC);
    [self.player seekToTime:time toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    [self notifyState];
}

- (void)setPlaybackRate:(float)playbackRate
{
    _playbackRate = MAX(0.5f, MIN(2.0f, playbackRate));
    if (self.player.rate > 0.01) {
        self.player.rate = _playbackRate;
    }
}

#pragma mark - Temporizador

- (void)setSleepTimer:(NSTimeInterval)seconds
{
    [self cancelSleepTimer];
    if (seconds <= 0) {
        return;
    }
    self.sleepDeadline = [[NSDate date] timeIntervalSince1970] + seconds;
    self.sleepTimer = [NSTimer scheduledTimerWithTimeInterval:seconds
                                                       target:self
                                                     selector:@selector(sleepTimerFired:)
                                                     userInfo:nil
                                                      repeats:NO];
    [[NSNotificationCenter defaultCenter] postNotificationName:OTPlayerStateDidChangeNotification object:self];
}

- (void)cancelSleepTimer
{
    [self.sleepTimer invalidate];
    self.sleepTimer = nil;
    self.sleepDeadline = 0;
    [[NSNotificationCenter defaultCenter] postNotificationName:OTPlayerStateDidChangeNotification object:self];
}

- (void)sleepTimerFired:(NSTimer *)timer
{
    self.sleepTimer = nil;
    self.sleepDeadline = 0;
    [self pause];
    [[NSNotificationCenter defaultCenter] postNotificationName:OTPlayerErrorNotification
                                                        object:self
                                                      userInfo:@{@"message": @"Temporizador: reproducción pausada"}];
}

#pragma mark - Eventos

- (void)handlePlaybackEnd:(NSNotification *)notification
{
    if (notification.object != self.playerItem) {
        return;
    }
    if (self.repeatMode == OTRepeatOne) {
        [self seekTo:0];
        [self play];
        return;
    }
    NSInteger nextIndex = [self nextIndexUserInitiated:YES];
    if (nextIndex < 0) {
        [self pause];
        return;
    }
    [self recordListeningTime];
    self.currentIndex = nextIndex;
    [self loadCurrentTrack];
}

- (void)handleInterruption:(NSNotification *)notification
{
    NSDictionary *info = notification.userInfo;
    NSInteger type = [info[AVAudioSessionInterruptionTypeKey] integerValue];
    if (type == AVAudioSessionInterruptionTypeBegan) {
        self.shouldResumeAfterInterruption = self.isPlaying;
        [self.player pause];
        [self notifyState];
    } else if (type == AVAudioSessionInterruptionTypeEnded) {
        NSInteger options = [info[AVAudioSessionInterruptionOptionKey] integerValue];
        if (options & AVAudioSessionInterruptionOptionShouldResume) {
            [self play];
        }
    }
}

- (void)handleRouteChange:(NSNotification *)notification
{
    NSInteger reason = [notification.userInfo[AVAudioSessionRouteChangeReasonKey] integerValue];
    if (reason == AVAudioSessionRouteChangeReasonOldDeviceUnavailable) {
        [self pause];
    }
}

- (void)handleAudioSessionMediaReset:(NSNotification *)notification
{
    [self configureAudioSession];
    if (self.isPlaying) {
        [self loadCurrentTrack];
    }
}

#pragma mark - Notificaciones y metadatos

- (void)notifyState
{
    [[NSNotificationCenter defaultCenter] postNotificationName:OTPlayerStateDidChangeNotification object:self];
}

- (void)updateNowPlayingMetadata
{
    OTItem *item = self.currentItem;
    if (!item) {
        [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = nil;
        return;
    }

    NSMutableDictionary *info = [NSMutableDictionary dictionary];
    info[MPMediaItemPropertyTitle] = item.title ?: @"";
    info[MPMediaItemPropertyArtist] = item.artistsText ?: item.subtitle ?: @"";
    info[MPMediaItemPropertyAlbumTitle] = item.albumText ?: @"";
    info[MPNowPlayingInfoPropertyPlaybackRate] = @(self.player.rate);
    if (item.duration > 0) {
        info[MPMediaItemPropertyPlaybackDuration] = @(item.duration);
    }

    __weak typeof(self) weakSelf = self;
    NSString *requestedId = item.itemId;
    [[OTImageCache sharedCache] imageForURLString:item.thumbnailURL size:320.0 completion:^(UIImage *image) {
        if (!image) {
            return;
        }
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf || ![strongSelf.currentItem.itemId isEqualToString:requestedId]) {
            return;
        }
        MPMediaItemArtwork *artwork = [[MPMediaItemArtwork alloc] initWithImage:image];
        NSMutableDictionary *updated = [[MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo mutableCopy];
        if (!updated) {
            updated = [NSMutableDictionary dictionary];
        }
        updated[MPMediaItemPropertyArtwork] = artwork;
        [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = updated;
    }];

    [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = info;
    [self updateNowPlayingElapsed];
}

- (void)updateNowPlayingElapsed
{
    NSMutableDictionary *info = [[MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo mutableCopy];
    if (!info) {
        return;
    }
    info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = @(self.currentTime);
    info[MPNowPlayingInfoPropertyPlaybackRate] = @(self.player.rate);
    if (self.duration > 0) {
        info[MPMediaItemPropertyPlaybackDuration] = @(self.duration);
    }
    [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = info;
}

- (void)recordListeningTime
{
    if (!self.currentItem || self.currentTime < 3.0) {
        return;
    }
    [[OTStore sharedStore] recordListening:self.currentItem seconds:self.currentTime];
}

@end

//
//  OTPlayerViewController.m
//  OpenTune 9
//

#import "OTPlayerViewController.h"
#import "OTTheme.h"
#import "OTPlayer.h"
#import "OTStore.h"
#import "OTDownloads.h"
#import "OTLyrics.h"
#import "OTImageCache.h"
#import "OTComponents.h"

#import <QuartzCore/QuartzCore.h>

@interface OTPlayerViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) OTImageView *backgroundView;
@property (nonatomic, strong) UIView *gradientView;

@property (nonatomic, strong) UIView *topBar;
@property (nonatomic, strong) UIButton *closeButton;
@property (nonatomic, strong) UIButton *moreButton;
@property (nonatomic, strong) UILabel *topLabel;

@property (nonatomic, strong) OTImageView *artworkView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *artistLabel;
@property (nonatomic, strong) UIButton *favoriteButton;
@property (nonatomic, strong) UIButton *downloadButton;

@property (nonatomic, strong) UISlider *slider;
@property (nonatomic, strong) UILabel *elapsedLabel;
@property (nonatomic, strong) UILabel *remainingLabel;

@property (nonatomic, strong) UIButton *shuffleButton;
@property (nonatomic, strong) UIButton *prevButton;
@property (nonatomic, strong) UIButton *playButton;
@property (nonatomic, strong) UIButton *nextButton;
@property (nonatomic, strong) UIButton *repeatButton;
@property (nonatomic, strong) UIActivityIndicatorView *playSpinner;

@property (nonatomic, strong) UIView *utilityRow;
@property (nonatomic, strong) NSArray<UIView *> *utilityContainers;
@property (nonatomic, strong) UILabel *sleepLabel;

@property (nonatomic, strong) UIView *lyricsPanel;
@property (nonatomic, strong) UITextView *lyricsTextView;
@property (nonatomic, strong) UILabel *lyricsStatusLabel;
@property (nonatomic, strong) UIActivityIndicatorView *lyricsSpinner;
@property (nonatomic, strong) NSArray<OTLyricLine *> *lyricsLines;
@property (nonatomic, strong) NSArray<NSValue *> *lyricsRanges;
@property (nonatomic, copy) NSString *lyricsPlain;
@property (nonatomic, assign) BOOL lyricsSynced;
@property (nonatomic, assign) NSInteger currentLyricIndex;
@property (nonatomic, copy) NSString *lyricsItemId;

@property (nonatomic, strong) UIView *queuePanel;
@property (nonatomic, strong) UITableView *queueTable;

@property (nonatomic, assign) BOOL draggingSlider;
@property (nonatomic, assign) BOOL queuePanelVisible;
@property (nonatomic, assign) BOOL lyricsPanelVisible;

@end

@implementation OTPlayerViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [OTTheme background];

    [self buildBackground];
    [self buildTopBar];
    [self buildContent];
    [self buildUtilities];
    [self buildLyricsPanel];
    [self buildQueuePanel];

    [self registerNotifications];
    [self refreshWithTrack];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)registerNotifications
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(trackChanged) name:OTPlayerTrackDidChangeNotification object:nil];
    [center addObserver:self selector:@selector(stateChanged) name:OTPlayerStateDidChangeNotification object:nil];
    [center addObserver:self selector:@selector(timeChanged) name:OTPlayerTimeDidChangeNotification object:nil];
    [center addObserver:self selector:@selector(queueChanged) name:OTPlayerQueueDidChangeNotification object:nil];
    [center addObserver:self selector:@selector(playerError:) name:OTPlayerErrorNotification object:nil];
}

#pragma mark - Construccion

- (void)buildBackground
{
    self.backgroundView = [[OTImageView alloc] initWithFrame:self.view.bounds];
    self.backgroundView.contentMode = UIViewContentModeScaleAspectFill;
    self.backgroundView.clipsToBounds = YES;
    self.backgroundView.alpha = 0.22;
    self.backgroundView.userInteractionEnabled = NO;
    [self.view addSubview:self.backgroundView];

    self.gradientView = [[UIView alloc] initWithFrame:self.view.bounds];
    self.gradientView.userInteractionEnabled = NO;
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.colors = @[(id)[[OTTheme background] colorWithAlphaComponent:0.15].CGColor,
                        (id)[[OTTheme background] colorWithAlphaComponent:0.85].CGColor,
                        (id)[[OTTheme background] CGColor]];
    gradient.locations = @[@0.0, @0.55, @1.0];
    [self.gradientView.layer addSublayer:gradient];
    [self.view addSubview:self.gradientView];
}

- (void)buildTopBar
{
    self.topBar = [[UIView alloc] initWithFrame:CGRectZero];
    self.topBar.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.topBar];

    self.closeButton = [OTTheme iconButton:OTIconChevronDown size:24 color:[OTTheme text] target:self action:@selector(closePlayer)];
    [self.topBar addSubview:self.closeButton];

    self.topLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.topLabel.font = [OTTheme labelLarge];
    self.topLabel.textColor = [OTTheme secondaryText];
    self.topLabel.textAlignment = NSTextAlignmentCenter;
    self.topLabel.text = @"Reproduciendo";
    [self.topBar addSubview:self.topLabel];

    self.moreButton = [OTTheme iconButton:OTIconMoreVert size:24 color:[OTTheme text] target:self action:@selector(showMore)];
    [self.topBar addSubview:self.moreButton];
}

- (void)buildContent
{
    self.artworkView = [[OTImageView alloc] initWithFrame:CGRectZero];
    self.artworkView.layer.cornerRadius = 16.0;
    self.artworkView.clipsToBounds = YES;
    self.artworkView.contentMode = UIViewContentModeScaleAspectFill;
    [self.view addSubview:self.artworkView];

    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.titleLabel.font = [OTTheme titleLarge];
    self.titleLabel.textColor = [OTTheme text];
    self.titleLabel.numberOfLines = 2;
    [self.view addSubview:self.titleLabel];

    self.artistLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.artistLabel.font = [OTTheme bodyLarge];
    self.artistLabel.textColor = [OTTheme secondaryText];
    self.artistLabel.numberOfLines = 1;
    [self.view addSubview:self.artistLabel];

    self.favoriteButton = [OTTheme iconButton:OTIconHeart size:24 color:[OTTheme text] target:self action:@selector(toggleFavorite)];
    [self.view addSubview:self.favoriteButton];

    self.downloadButton = [OTTheme iconButton:OTIconDownload size:24 color:[OTTheme text] target:self action:@selector(toggleDownload)];
    [self.view addSubview:self.downloadButton];

    self.slider = [[UISlider alloc] initWithFrame:CGRectZero];
    self.slider.minimumTrackTintColor = [OTTheme primary];
    self.slider.maximumTrackTintColor = [OTTheme colorWithHex:0x4A464F];
    [self.slider setThumbTintColor:[OTTheme primary]];
    [self.slider addTarget:self action:@selector(sliderTouchDown) forControlEvents:UIControlEventTouchDown];
    [self.slider addTarget:self action:@selector(sliderChanged) forControlEvents:UIControlEventValueChanged];
    [self.slider addTarget:self action:@selector(sliderTouchUp) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchCancel];
    [self.view addSubview:self.slider];

    self.elapsedLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.elapsedLabel.font = [OTTheme labelSmall];
    self.elapsedLabel.textColor = [OTTheme secondaryText];
    [self.view addSubview:self.elapsedLabel];

    self.remainingLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.remainingLabel.font = [OTTheme labelSmall];
    self.remainingLabel.textColor = [OTTheme secondaryText];
    self.remainingLabel.textAlignment = NSTextAlignmentRight;
    [self.view addSubview:self.remainingLabel];

    self.shuffleButton = [OTTheme iconButton:OTIconShuffle size:22 color:[OTTheme text] target:self action:@selector(toggleShuffle)];
    [self.view addSubview:self.shuffleButton];

    self.prevButton = [OTTheme iconButton:OTIconPrev size:30 color:[OTTheme text] target:self action:@selector(playPrevious)];
    [self.view addSubview:self.prevButton];

    self.playButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.playButton.backgroundColor = [OTTheme primary];
    self.playButton.layer.cornerRadius = 36.0;
    self.playButton.tintColor = [OTTheme onPrimary];
    [self.playButton setImage:[OTTheme icon:OTIconPlay size:32] forState:UIControlStateNormal];
    [self.playButton addTarget:self action:@selector(togglePlayPause) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.playButton];

    self.playSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    self.playSpinner.color = [OTTheme onPrimary];
    self.playSpinner.hidesWhenStopped = YES;
    [self.playButton addSubview:self.playSpinner];

    self.nextButton = [OTTheme iconButton:OTIconNext size:30 color:[OTTheme text] target:self action:@selector(playNext)];
    [self.view addSubview:self.nextButton];

    self.repeatButton = [OTTheme iconButton:OTIconRepeat size:22 color:[OTTheme text] target:self action:@selector(cycleRepeat)];
    [self.view addSubview:self.repeatButton];
}

- (void)buildUtilities
{
    self.utilityRow = [[UIView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:self.utilityRow];

    UIView *lyrics = [self utilityWithIcon:OTIconLyrics title:@"Letras" action:@selector(showLyrics)];
    UIView *queue = [self utilityWithIcon:OTIconQueue title:@"Cola" action:@selector(showQueue)];
    UIView *sleep = [self utilityWithIcon:OTIconSleep title:@"Temporizador" action:@selector(showSleepTimer)];
    UIView *speed = [self utilityWithIcon:OTIconSpeed title:@"Velocidad" action:@selector(showSpeed)];
    self.utilityContainers = @[lyrics, queue, sleep, speed];
    for (UIView *container in self.utilityContainers) {
        [self.utilityRow addSubview:container];
    }
    self.sleepLabel = [sleep viewWithTag:2];
}

- (UIView *)utilityWithIcon:(OTIcon)icon title:(NSString *)title action:(SEL)action
{
    UIView *container = [[UIView alloc] initWithFrame:CGRectZero];
    UIButton *button = [OTTheme iconButton:icon size:24 color:[OTTheme text] target:self action:action];
    button.tag = 1;
    [container addSubview:button];

    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.tag = 2;
    label.font = [OTTheme labelSmall];
    label.textColor = [OTTheme secondaryText];
    label.textAlignment = NSTextAlignmentCenter;
    label.text = title;
    [container addSubview:label];
    return container;
}

- (void)buildLyricsPanel
{
    self.lyricsPanel = [[UIView alloc] initWithFrame:CGRectZero];
    self.lyricsPanel.backgroundColor = [OTTheme background];
    self.lyricsPanel.hidden = YES;
    [self.view addSubview:self.lyricsPanel];

    UILabel *title = [[UILabel alloc] initWithFrame:CGRectZero];
    title.font = [OTTheme titleLarge];
    title.textColor = [OTTheme text];
    title.text = @"Letras";
    title.tag = 10;
    [self.lyricsPanel addSubview:title];

    UIButton *close = [OTTheme iconButton:OTIconClose size:22 color:[OTTheme text] target:self action:@selector(hideLyrics)];
    close.tag = 11;
    [self.lyricsPanel addSubview:close];

    self.lyricsStatusLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.lyricsStatusLabel.font = [OTTheme labelMedium];
    self.lyricsStatusLabel.textColor = [OTTheme outline];
    self.lyricsStatusLabel.textAlignment = NSTextAlignmentCenter;
    self.lyricsStatusLabel.numberOfLines = 2;
    self.lyricsStatusLabel.tag = 12;
    [self.lyricsPanel addSubview:self.lyricsStatusLabel];

    self.lyricsSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    self.lyricsSpinner.color = [OTTheme primary];
    self.lyricsSpinner.hidesWhenStopped = YES;
    self.lyricsSpinner.tag = 13;
    [self.lyricsPanel addSubview:self.lyricsSpinner];

    self.lyricsTextView = [[UITextView alloc] initWithFrame:CGRectZero];
    self.lyricsTextView.backgroundColor = [UIColor clearColor];
    self.lyricsTextView.editable = NO;
    self.lyricsTextView.selectable = NO;
    self.lyricsTextView.textContainerInset = UIEdgeInsetsMake(16, 20, 40, 20);
    self.lyricsTextView.tag = 14;
    [self.lyricsPanel addSubview:self.lyricsTextView];
}

- (void)buildQueuePanel
{
    self.queuePanel = [[UIView alloc] initWithFrame:CGRectZero];
    self.queuePanel.backgroundColor = [OTTheme background];
    self.queuePanel.hidden = YES;
    [self.view addSubview:self.queuePanel];

    UILabel *title = [[UILabel alloc] initWithFrame:CGRectZero];
    title.font = [OTTheme titleLarge];
    title.textColor = [OTTheme text];
    title.text = @"Cola de reproducción";
    title.tag = 10;
    [self.queuePanel addSubview:title];

    UIButton *close = [OTTheme iconButton:OTIconClose size:22 color:[OTTheme text] target:self action:@selector(hideQueue)];
    close.tag = 11;
    [self.queuePanel addSubview:close];

    UIButton *clear = [UIButton buttonWithType:UIButtonTypeCustom];
    clear.titleLabel.font = [OTTheme labelMedium];
    [clear setTitle:@"Vaciar" forState:UIControlStateNormal];
    [clear setTitleColor:[OTTheme primary] forState:UIControlStateNormal];
    [clear addTarget:self action:@selector(clearQueue) forControlEvents:UIControlEventTouchUpInside];
    clear.tag = 12;
    [self.queuePanel addSubview:clear];

    self.queueTable = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.queueTable.dataSource = self;
    self.queueTable.delegate = self;
    self.queueTable.backgroundColor = [OTTheme background];
    self.queueTable.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.queueTable.rowHeight = 64.0;
    self.queueTable.tag = 20;
    [self.queueTable registerClass:[OTItemCell class] forCellReuseIdentifier:@"OTQueueCell"];
    [self.queuePanel addSubview:self.queueTable];
}

#pragma mark - Layout

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];

    CGFloat width = self.view.bounds.size.width;
    CGFloat height = self.view.bounds.size.height;
    CGFloat top = self.topLayoutGuide.length;

    self.backgroundView.frame = self.view.bounds;
    self.gradientView.frame = self.view.bounds;
    CAGradientLayer *gradient = (CAGradientLayer *)self.gradientView.layer.sublayers.firstObject;
    gradient.frame = self.gradientView.bounds;

    self.topBar.frame = CGRectMake(0, top, width, 48.0);
    self.closeButton.frame = CGRectMake(8.0, 2.0, 44.0, 44.0);
    self.moreButton.frame = CGRectMake(width - 52.0, 2.0, 44.0, 44.0);
    self.topLabel.frame = CGRectMake(64.0, 2.0, width - 128.0, 44.0);

    CGFloat contentWidth = MIN(width - 48.0, 540.0);
    CGFloat contentX = (width - contentWidth) / 2.0;

    CGFloat artworkSize = MIN(contentWidth, height * 0.36);
    artworkSize = MIN(artworkSize, 380.0);
    CGFloat artworkY = top + 56.0 + 8.0;
    self.artworkView.frame = CGRectMake((width - artworkSize) / 2.0, artworkY, artworkSize, artworkSize);

    CGFloat y = CGRectGetMaxY(self.artworkView.frame) + 16.0;
    self.titleLabel.frame = CGRectMake(contentX, y, contentWidth - 96.0, 32.0);
    self.favoriteButton.frame = CGRectMake(contentX + contentWidth - 44.0, y - 4.0, 44.0, 44.0);
    self.downloadButton.frame = CGRectMake(contentX + contentWidth - 88.0, y - 4.0, 44.0, 44.0);

    y += 36.0;
    self.artistLabel.frame = CGRectMake(contentX, y, contentWidth, 24.0);

    y += 34.0;
    self.slider.frame = CGRectMake(contentX, y, contentWidth, 30.0);
    self.elapsedLabel.frame = CGRectMake(contentX, y + 28.0, 60.0, 16.0);
    self.remainingLabel.frame = CGRectMake(contentX + contentWidth - 60.0, y + 28.0, 60.0, 16.0);

    y += 58.0;
    self.shuffleButton.frame = CGRectMake(contentX + 6.0, y + 16.0, 44.0, 44.0);
    self.prevButton.frame = CGRectMake(contentX + contentWidth / 2.0 - 100.0, y + 6.0, 56.0, 64.0);
    self.playButton.frame = CGRectMake(contentX + contentWidth / 2.0 - 36.0, y, 72.0, 72.0);
    self.nextButton.frame = CGRectMake(contentX + contentWidth / 2.0 + 44.0, y + 6.0, 56.0, 64.0);
    self.repeatButton.frame = CGRectMake(contentX + contentWidth - 50.0, y + 16.0, 44.0, 44.0);
    self.playSpinner.center = CGPointMake(36.0, 36.0);

    y += 88.0;
    self.utilityRow.frame = CGRectMake(contentX, y, contentWidth, 64.0);
    CGFloat itemWidth = contentWidth / 4.0;
    for (NSInteger i = 0; i < (NSInteger)self.utilityContainers.count; i++) {
        UIView *container = self.utilityContainers[i];
        container.frame = CGRectMake(i * itemWidth, 0, itemWidth, 64.0);
        UIView *button = [container viewWithTag:1];
        UILabel *label = [container viewWithTag:2];
        button.frame = CGRectMake((itemWidth - 44.0) / 2.0, 0, 44.0, 44.0);
        label.frame = CGRectMake(0, 44.0, itemWidth, 16.0);
    }

    CGFloat panelTop = top + 56.0;
    self.lyricsPanel.frame = CGRectMake(0, panelTop, width, height - panelTop);
    self.queuePanel.frame = self.lyricsPanel.frame;

    UIView *lyricsTitle = [self.lyricsPanel viewWithTag:10];
    lyricsTitle.frame = CGRectMake(20.0, 0, width - 120.0, 52.0);
    UIView *lyricsClose = [self.lyricsPanel viewWithTag:11];
    lyricsClose.frame = CGRectMake(width - 52.0, 4.0, 44.0, 44.0);
    self.lyricsStatusLabel.frame = CGRectMake(24.0, 60.0, width - 48.0, 44.0);
    self.lyricsSpinner.center = CGPointMake(width / 2.0, 90.0);
    self.lyricsTextView.frame = CGRectMake(0, 56.0, width, height - panelTop - 56.0);

    UIView *queueTitle = [self.queuePanel viewWithTag:10];
    queueTitle.frame = CGRectMake(20.0, 0, width - 180.0, 52.0);
    UIView *queueClose = [self.queuePanel viewWithTag:11];
    queueClose.frame = CGRectMake(width - 52.0, 4.0, 44.0, 44.0);
    UIView *queueClear = [self.queuePanel viewWithTag:12];
    queueClear.frame = CGRectMake(width - 124.0, 4.0, 64.0, 44.0);
    self.queueTable.frame = CGRectMake(0, 56.0, width, height - panelTop - 56.0);
}

#pragma mark - Estado

- (void)refreshWithTrack
{
    OTPlayer *player = [OTPlayer sharedPlayer];
    OTItem *item = player.currentItem;
    if (!item) {
        return;
    }

    self.titleLabel.text = item.title;
    self.artistLabel.text = item.artistsText.length > 0 ? item.artistsText : [item displaySubtitle];
    [self.artworkView setImageURL:item.thumbnailURL
                             size:700.0
                      placeholder:[OTTheme musicPlaceholder:700]];
    [self.backgroundView setImageURL:item.thumbnailURL
                                size:400.0
                         placeholder:nil];

    BOOL favorite = [[OTStore sharedStore] isFavorite:item];
    [self.favoriteButton setImage:[OTTheme icon:(favorite ? OTIconHeartFill : OTIconHeart) size:24]
                         forState:UIControlStateNormal];
    self.favoriteButton.tintColor = favorite ? [OTTheme primary] : [OTTheme text];

    BOOL downloaded = [[OTStore sharedStore] isDownloaded:item];
    [self.downloadButton setImage:[OTTheme icon:(downloaded ? OTIconDone : OTIconDownload) size:24]
                         forState:UIControlStateNormal];
    self.downloadButton.tintColor = downloaded ? [OTTheme primary] : [OTTheme text];

    self.slider.maximumValue = MAX(1.0, player.duration > 0 ? player.duration : (double)item.duration);
    self.slider.value = 0;
    self.elapsedLabel.text = @"0:00";
    self.remainingLabel.text = [OTTheme formatTime:player.duration];
    [self updatePlayState];
    [self updateModes];
    [self updateSleepLabel];

    self.currentLyricIndex = -1;
    self.lyricsItemId = nil;
    if (self.lyricsPanelVisible) {
        [self loadLyrics];
    }
    if (self.queuePanelVisible) {
        [self.queueTable reloadData];
    }
}

- (void)updatePlayState
{
    OTPlayer *player = [OTPlayer sharedPlayer];
    [self.playButton setImage:[OTTheme icon:(player.isPlaying ? OTIconPause : OTIconPlay) size:32]
                     forState:UIControlStateNormal];
    if (player.isLoading) {
        [self.playSpinner startAnimating];
    } else {
        [self.playSpinner stopAnimating];
    }
}

- (void)updateModes
{
    OTPlayer *player = [OTPlayer sharedPlayer];
    self.shuffleButton.tintColor = player.shuffle ? [OTTheme primary] : [OTTheme text];
    self.shuffleButton.alpha = player.shuffle ? 1.0 : 0.65;

    OTIcon repeatIcon = player.repeatMode == OTRepeatOne ? OTIconRepeatOne : OTIconRepeat;
    [self.repeatButton setImage:[OTTheme icon:repeatIcon size:22] forState:UIControlStateNormal];
    self.repeatButton.tintColor = player.repeatMode == OTRepeatOff ? [OTTheme text] : [OTTheme primary];
    self.repeatButton.alpha = player.repeatMode == OTRepeatOff ? 0.65 : 1.0;
}

- (void)updateSleepLabel
{
    OTPlayer *player = [OTPlayer sharedPlayer];
    if ([player sleepTimerActive]) {
        NSInteger remaining = [player sleepTimerRemaining];
        self.sleepLabel.text = [OTTheme formatTime:remaining];
        self.sleepLabel.textColor = [OTTheme primary];
    } else {
        self.sleepLabel.text = @"Temporizador";
        self.sleepLabel.textColor = [OTTheme secondaryText];
    }
}

#pragma mark - Notificaciones

- (void)trackChanged
{
    [self refreshWithTrack];
}

- (void)stateChanged
{
    [self updatePlayState];
}

- (void)timeChanged
{
    OTPlayer *player = [OTPlayer sharedPlayer];
    double duration = player.duration;
    double current = player.currentTime;

    if (!self.draggingSlider) {
        self.slider.maximumValue = MAX(1.0, duration);
        self.slider.value = (float)MIN(current, MAX(1.0, duration));
    }
    self.elapsedLabel.text = [OTTheme formatTime:current];
    self.remainingLabel.text = [OTTheme formatTime:MAX(0.0, duration - current)];
    [self updateSleepLabel];

    if (self.lyricsPanelVisible && self.lyricsSynced) {
        [self highlightLyricsAtTime:current];
    }
}

- (void)queueChanged
{
    if (self.queuePanelVisible) {
        [self.queueTable reloadData];
    }
}

- (void)playerError:(NSNotification *)notification
{
    NSString *message = notification.userInfo[@"message"] ?: @"Error de reproducción";
    [OTTheme showToast:message inView:self.view];
}

#pragma mark - Acciones

- (void)closePlayer
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)togglePlayPause
{
    [[OTPlayer sharedPlayer] togglePlayPause];
}

- (void)playNext
{
    [[OTPlayer sharedPlayer] next];
}

- (void)playPrevious
{
    [[OTPlayer sharedPlayer] previous];
}

- (void)toggleShuffle
{
    OTPlayer *player = [OTPlayer sharedPlayer];
    player.shuffle = !player.shuffle;
    [self updateModes];
    [OTTheme showToast:(player.shuffle ? @"Aleatorio activado" : @"Aleatorio desactivado") inView:self.view];
}

- (void)cycleRepeat
{
    [[OTPlayer sharedPlayer] cycleRepeatMode];
    [self updateModes];
}

- (void)toggleFavorite
{
    OTItem *item = [OTPlayer sharedPlayer].currentItem;
    if (!item) {
        return;
    }
    BOOL added = [[OTStore sharedStore] toggleFavorite:item];
    [self.favoriteButton setImage:[OTTheme icon:(added ? OTIconHeartFill : OTIconHeart) size:24]
                         forState:UIControlStateNormal];
    self.favoriteButton.tintColor = added ? [OTTheme primary] : [OTTheme text];
    [OTTheme showToast:(added ? @"Añadido a favoritos" : @"Quitado de favoritos") inView:self.view];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"OTLibraryDidChangeNotification" object:nil];
}

- (void)toggleDownload
{
    OTItem *item = [OTPlayer sharedPlayer].currentItem;
    if (!item) {
        return;
    }
    OTStore *store = [OTStore sharedStore];
    if ([store isDownloaded:item]) {
        [store removeDownloadForItem:item];
        [self.downloadButton setImage:[OTTheme icon:OTIconDownload size:24] forState:UIControlStateNormal];
        self.downloadButton.tintColor = [OTTheme text];
        [OTTheme showToast:@"Descarga eliminada" inView:self.view];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"OTLibraryDidChangeNotification" object:nil];
        return;
    }
    [OTTheme showToast:@"Descargando…" inView:self.view];
    __weak typeof(self) weakSelf = self;
    [[OTDownloads sharedDownloads] downloadItem:item progress:nil completion:^(BOOL success, NSError *error, NSString *path) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        if (success) {
            [strongSelf.downloadButton setImage:[OTTheme icon:OTIconDone size:24] forState:UIControlStateNormal];
            strongSelf.downloadButton.tintColor = [OTTheme primary];
            [OTTheme showToast:@"Descarga completada" inView:strongSelf.view];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"OTLibraryDidChangeNotification" object:nil];
        } else {
            [OTTheme showToast:(error.localizedDescription ?: @"No se pudo descargar") inView:strongSelf.view];
        }
    }];
}

#pragma mark - Slider

- (void)sliderTouchDown
{
    self.draggingSlider = YES;
}

- (void)sliderChanged
{
    self.elapsedLabel.text = [OTTheme formatTime:self.slider.value];
}

- (void)sliderTouchUp
{
    self.draggingSlider = NO;
    [[OTPlayer sharedPlayer] seekTo:self.slider.value];
}

#pragma mark - Menus

- (void)showMore
{
    OTItem *item = [OTPlayer sharedPlayer].currentItem;
    if (!item) {
        return;
    }
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:item.title
                                                                  message:[item displaySubtitle]
                                                           preferredStyle:UIAlertControllerStyleActionSheet];
    __weak typeof(self) weakSelf = self;
    [sheet addAction:[UIAlertAction actionWithTitle:@"Añadir a la cola"
                                               style:UIAlertActionStyleDefault
                                             handler:^(UIAlertAction *action) {
        [[OTPlayer sharedPlayer] addToQueue:item];
        [OTTheme showToast:@"Añadido a la cola" inView:weakSelf.view];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:@"Ver letras"
                                               style:UIAlertActionStyleDefault
                                             handler:^(UIAlertAction *action) {
        [weakSelf showLyrics];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:@"Compartir"
                                               style:UIAlertActionStyleDefault
                                             handler:^(UIAlertAction *action) {
        [weakSelf shareCurrent];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:@"Temporizador"
                                               style:UIAlertActionStyleDefault
                                             handler:^(UIAlertAction *action) {
        [weakSelf showSleepTimer];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:@"Velocidad"
                                               style:UIAlertActionStyleDefault
                                             handler:^(UIAlertAction *action) {
        [weakSelf showSpeed];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:@"Cancelar" style:UIAlertActionStyleCancel handler:nil]];
    if (sheet.popoverPresentationController) {
        sheet.popoverPresentationController.sourceView = self.moreButton;
        sheet.popoverPresentationController.sourceRect = self.moreButton.bounds;
    }
    [self presentViewController:sheet animated:YES completion:nil];
}

- (void)shareCurrent
{
    OTItem *item = [OTPlayer sharedPlayer].currentItem;
    if (item.itemId.length == 0) {
        return;
    }
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://music.youtube.com/watch?v=%@", item.itemId]];
    if (!url) {
        return;
    }
    UIActivityViewController *activity = [[UIActivityViewController alloc] initWithActivityItems:@[url]
                                                                           applicationActivities:nil];
    if (activity.popoverPresentationController) {
        activity.popoverPresentationController.sourceView = self.moreButton;
        activity.popoverPresentationController.sourceRect = self.moreButton.bounds;
    }
    [self presentViewController:activity animated:YES completion:nil];
}

- (void)showSleepTimer
{
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:@"Temporizador"
                                                                  message:@"Detener la reproducción tras…"
                                                           preferredStyle:UIAlertControllerStyleActionSheet];
    NSArray *minutes = @[@5, @10, @15, @30, @60];
    __weak typeof(self) weakSelf = self;
    for (NSNumber *value in minutes) {
        NSString *title = [NSString stringWithFormat:@"%@ minutos", value];
        [sheet addAction:[UIAlertAction actionWithTitle:title
                                                   style:UIAlertActionStyleDefault
                                                 handler:^(UIAlertAction *action) {
            [[OTPlayer sharedPlayer] setSleepTimer:[value doubleValue] * 60.0];
            [weakSelf updateSleepLabel];
            [OTTheme showToast:[NSString stringWithFormat:@"Temporizador: %@ min", value] inView:weakSelf.view];
        }]];
    }
    if ([[OTPlayer sharedPlayer] sleepTimerActive]) {
        [sheet addAction:[UIAlertAction actionWithTitle:@"Desactivar"
                                                   style:UIAlertActionStyleDestructive
                                                 handler:^(UIAlertAction *action) {
            [[OTPlayer sharedPlayer] cancelSleepTimer];
            [weakSelf updateSleepLabel];
        }]];
    }
    [sheet addAction:[UIAlertAction actionWithTitle:@"Cancelar" style:UIAlertActionStyleCancel handler:nil]];
    if (sheet.popoverPresentationController) {
        sheet.popoverPresentationController.sourceView = self.view;
        sheet.popoverPresentationController.sourceRect = CGRectMake(self.view.bounds.size.width / 2.0,
                                                                    self.view.bounds.size.height / 2.0, 1, 1);
    }
    [self presentViewController:sheet animated:YES completion:nil];
}

- (void)showSpeed
{
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:@"Velocidad de reproducción"
                                                                  message:nil
                                                           preferredStyle:UIAlertControllerStyleActionSheet];
    NSArray *speeds = @[@0.5, @0.75, @1.0, @1.25, @1.5, @2.0];
    __weak typeof(self) weakSelf = self;
    for (NSNumber *value in speeds) {
        NSString *title = [NSString stringWithFormat:@"%.2gx", value.doubleValue];
        [sheet addAction:[UIAlertAction actionWithTitle:title
                                                   style:UIAlertActionStyleDefault
                                                 handler:^(UIAlertAction *action) {
            [OTPlayer sharedPlayer].playbackRate = value.floatValue;
            [OTTheme showToast:[NSString stringWithFormat:@"Velocidad %@", title] inView:weakSelf.view];
        }]];
    }
    [sheet addAction:[UIAlertAction actionWithTitle:@"Cancelar" style:UIAlertActionStyleCancel handler:nil]];
    if (sheet.popoverPresentationController) {
        sheet.popoverPresentationController.sourceView = self.view;
        sheet.popoverPresentationController.sourceRect = CGRectMake(self.view.bounds.size.width / 2.0,
                                                                    self.view.bounds.size.height / 2.0, 1, 1);
    }
    [self presentViewController:sheet animated:YES completion:nil];
}

#pragma mark - Letras

- (void)showLyrics
{
    self.lyricsPanelVisible = YES;
    self.queuePanelVisible = NO;
    self.queuePanel.hidden = YES;
    self.lyricsPanel.hidden = NO;
    [self.view bringSubviewToFront:self.lyricsPanel];
    [self loadLyrics];
}

- (void)hideLyrics
{
    self.lyricsPanelVisible = NO;
    self.lyricsPanel.hidden = YES;
}

- (void)loadLyrics
{
    OTItem *item = [OTPlayer sharedPlayer].currentItem;
    if (!item) {
        return;
    }
    self.lyricsItemId = item.itemId;
    self.lyricsLines = nil;
    self.lyricsPlain = nil;
    self.lyricsSynced = NO;
    self.currentLyricIndex = -1;
    self.lyricsTextView.text = @"";
    self.lyricsTextView.hidden = YES;
    self.lyricsStatusLabel.text = @"Buscando letras…";
    [self.lyricsSpinner startAnimating];

    __weak typeof(self) weakSelf = self;
    [[OTLyrics sharedLyrics] lyricsForItem:item completion:^(NSArray<OTLyricLine *> *lines, BOOL synced, NSString *plain, NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        if (![strongSelf.lyricsItemId isEqualToString:item.itemId]) {
            return;
        }
        [strongSelf.lyricsSpinner stopAnimating];
        if (lines.count == 0 && plain.length == 0) {
            strongSelf.lyricsStatusLabel.text = @"No hay letras disponibles para esta canción.";
            return;
        }
        strongSelf.lyricsStatusLabel.text = nil;
        strongSelf.lyricsTextView.hidden = NO;
        strongSelf.lyricsLines = lines;
        strongSelf.lyricsSynced = synced && lines.count > 0;
        strongSelf.lyricsPlain = plain;
        strongSelf.currentLyricIndex = -1;
        [strongSelf renderLyrics];
    }];
}

- (void)renderLyrics
{
    if (!self.lyricsSynced) {
        self.lyricsTextView.text = self.lyricsPlain ?: @"";
        self.lyricsTextView.font = [OTTheme bodyLarge];
        self.lyricsTextView.textColor = [OTTheme text];
        return;
    }

    NSMutableAttributedString *attributed = [[NSMutableAttributedString alloc] init];
    NSMutableArray *ranges = [NSMutableArray array];
    NSInteger index = 0;
    for (OTLyricLine *line in self.lyricsLines) {
        NSString *text = line.text.length > 0 ? line.text : @"♪";
        if (index > 0) {
            [attributed appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
        }
        NSRange range = NSMakeRange(attributed.length, text.length);
        [attributed appendAttributedString:[[NSAttributedString alloc] initWithString:text]];
        [ranges addObject:[NSValue valueWithRange:range]];
        index++;
    }

    NSMutableParagraphStyle *paragraph = [[NSMutableParagraphStyle alloc] init];
    paragraph.lineSpacing = 10.0;
    paragraph.alignment = NSTextAlignmentCenter;
    [attributed addAttributes:@{NSFontAttributeName: [OTTheme font:20.0 weight:UIFontWeightMedium],
                                NSForegroundColorAttributeName: [OTTheme secondaryText],
                                NSParagraphStyleAttributeName: paragraph}
                        range:NSMakeRange(0, attributed.length)];

    self.lyricsRanges = ranges;
    self.lyricsTextView.attributedText = attributed;
    [self highlightLyricsAtTime:[OTPlayer sharedPlayer].currentTime];
}

- (void)highlightLyricsAtTime:(double)time
{
    if (!self.lyricsSynced || self.lyricsLines.count == 0) {
        return;
    }
    NSInteger index = 0;
    for (NSInteger i = 0; i < (NSInteger)self.lyricsLines.count; i++) {
        if (self.lyricsLines[i].time <= time + 0.15) {
            index = i;
        } else {
            break;
        }
    }
    if (index == self.currentLyricIndex) {
        return;
    }
    self.currentLyricIndex = index;

    NSMutableAttributedString *attributed = [self.lyricsTextView.attributedText mutableCopy];
    if (!attributed) {
        return;
    }
    for (NSValue *value in self.lyricsRanges) {
        [attributed addAttribute:NSForegroundColorAttributeName value:[OTTheme secondaryText] range:value.rangeValue];
        [attributed addAttribute:NSFontAttributeName value:[OTTheme font:20.0 weight:UIFontWeightMedium] range:value.rangeValue];
    }
    if (index >= 0 && index < (NSInteger)self.lyricsRanges.count) {
        NSRange range = [self.lyricsRanges[index] rangeValue];
        [attributed addAttribute:NSForegroundColorAttributeName value:[OTTheme primary] range:range];
        [attributed addAttribute:NSFontAttributeName value:[OTTheme font:22.0 weight:UIFontWeightBold] range:range];
        self.lyricsTextView.attributedText = attributed;
        [self.lyricsTextView scrollRangeToVisible:range];
    }
}

#pragma mark - Cola

- (void)showQueue
{
    self.queuePanelVisible = YES;
    self.lyricsPanelVisible = NO;
    self.lyricsPanel.hidden = YES;
    self.queuePanel.hidden = NO;
    [self.view bringSubviewToFront:self.queuePanel];
    [self.queueTable reloadData];
}

- (void)hideQueue
{
    self.queuePanelVisible = NO;
    self.queuePanel.hidden = YES;
}

- (void)clearQueue
{
    [[OTPlayer sharedPlayer] clearQueue];
    [self.queueTable reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [OTPlayer sharedPlayer].queue.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 64.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OTItemCell *cell = [tableView dequeueReusableCellWithIdentifier:@"OTQueueCell" forIndexPath:indexPath];
    NSArray *queue = [OTPlayer sharedPlayer].queue;
    OTItem *item = queue[indexPath.row];
    [cell configureWithItem:item index:0 showsArtwork:YES];
    cell.moreButton.hidden = YES;
    [cell setCurrentTrack:(indexPath.row == [OTPlayer sharedPlayer].index)];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    OTPlayer *player = [OTPlayer sharedPlayer];
    NSArray *queue = player.queue;
    if (indexPath.row < (NSInteger)queue.count) {
        [player setQueue:queue startIndex:indexPath.row];
        [self hideQueue];
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [[OTPlayer sharedPlayer] removeFromQueueAtIndex:indexPath.row];
        [tableView reloadData];
    }
}

@end

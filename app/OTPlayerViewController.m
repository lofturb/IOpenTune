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
#import <AVFoundation/AVFoundation.h>

#pragma mark - Chip de salida de audio

@interface OTOutputChip : UIControl

@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, strong) UILabel *label;

- (void)setTitle:(NSString *)title icon:(OTIcon)icon;

@end

@implementation OTOutputChip

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [[OTTheme surfaceHigh] colorWithAlphaComponent:0.85];
        self.layer.cornerRadius = 22.0;
        self.clipsToBounds = YES;

        _iconView = [[UIImageView alloc] initWithFrame:CGRectZero];
        _iconView.contentMode = UIViewContentModeScaleAspectFit;
        _iconView.tintColor = [OTTheme text];
        _iconView.userInteractionEnabled = NO;
        [self addSubview:_iconView];

        _label = [[UILabel alloc] initWithFrame:CGRectZero];
        _label.font = [OTTheme font:15.0 weight:UIFontWeightSemibold];
        _label.textColor = [OTTheme text];
        _label.userInteractionEnabled = NO;
        [self addSubview:_label];
    }
    return self;
}

- (void)setTitle:(NSString *)title icon:(OTIcon)icon
{
    self.label.text = title;
    self.iconView.image = [OTTheme icon:icon size:18];
    [self setNeedsLayout];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    CGFloat height = self.bounds.size.height;
    CGSize textSize = [self.label sizeThatFits:CGSizeMake(220.0, height)];
    CGFloat iconWidth = 18.0;
    CGFloat spacing = 10.0;
    CGFloat total = iconWidth + spacing + textSize.width;
    CGFloat x = MAX(16.0, (self.bounds.size.width - total) / 2.0);
    self.iconView.frame = CGRectMake(x, (height - iconWidth) / 2.0, iconWidth, iconWidth);
    self.label.frame = CGRectMake(x + iconWidth + spacing,
                                  (height - textSize.height) / 2.0,
                                  textSize.width,
                                  textSize.height);
}

- (CGSize)sizeThatFits:(CGSize)size
{
    CGSize textSize = [self.label sizeThatFits:CGSizeMake(220.0, 44.0)];
    CGFloat width = textSize.width + 18.0 + 10.0 + 32.0;
    return CGSizeMake(MIN(width, size.width), 44.0);
}

@end


#pragma mark - Reproductor

@interface OTPlayerViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) OTImageView *backgroundView;
@property (nonatomic, strong) UIView *shadeView;
@property (nonatomic, strong) UIView *gradientView;

@property (nonatomic, strong) UIView *topBar;
@property (nonatomic, strong) UIButton *closeButton;
@property (nonatomic, strong) UILabel *topLabel;

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *artistLabel;
@property (nonatomic, strong) UIButton *favoriteButton;
@property (nonatomic, strong) UIButton *moreButton;

@property (nonatomic, strong) OTSlider *slider;
@property (nonatomic, strong) UILabel *elapsedLabel;
@property (nonatomic, strong) UILabel *remainingLabel;
@property (nonatomic, strong) UIView *formatChip;
@property (nonatomic, strong) UILabel *formatLabel;

@property (nonatomic, strong) UIButton *prevButton;
@property (nonatomic, strong) UIButton *playButton;
@property (nonatomic, strong) UIButton *nextButton;
@property (nonatomic, strong) UIActivityIndicatorView *playSpinner;

@property (nonatomic, strong) UILabel *metadataLabel;
@property (nonatomic, strong) UIButton *queueButton;
@property (nonatomic, strong) UIButton *lyricsButton;
@property (nonatomic, strong) OTOutputChip *outputChip;

@property (nonatomic, strong) UIView *panelDim;
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
@property (nonatomic, strong) UILabel *queueSubtitleLabel;

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
    [self buildTrackInfo];
    [self buildProgress];
    [self buildTransport];
    [self buildBottomRow];
    [self buildPanels];

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
    [center addObserver:self selector:@selector(routeChanged) name:AVAudioSessionRouteChangeNotification object:nil];
}

#pragma mark - Construccion

- (void)buildBackground
{
    self.backgroundView = [[OTImageView alloc] initWithFrame:self.view.bounds];
    self.backgroundView.contentMode = UIViewContentModeScaleAspectFill;
    self.backgroundView.clipsToBounds = YES;
    self.backgroundView.alpha = 0.62;
    self.backgroundView.userInteractionEnabled = NO;
    [self.view addSubview:self.backgroundView];

    self.shadeView = [[UIView alloc] initWithFrame:self.view.bounds];
    self.shadeView.backgroundColor = [[OTTheme background] colorWithAlphaComponent:0.28];
    self.shadeView.userInteractionEnabled = NO;
    [self.view addSubview:self.shadeView];

    self.gradientView = [[UIView alloc] initWithFrame:self.view.bounds];
    self.gradientView.userInteractionEnabled = NO;
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.colors = @[(id)[[OTTheme background] colorWithAlphaComponent:0.0].CGColor,
                        (id)[[OTTheme background] colorWithAlphaComponent:0.22].CGColor,
                        (id)[[OTTheme background] colorWithAlphaComponent:0.88].CGColor,
                        (id)[[OTTheme background] colorWithAlphaComponent:1.0].CGColor];
    gradient.locations = @[@0.0, @0.34, @0.72, @1.0];
    [self.gradientView.layer addSublayer:gradient];
    [self.view addSubview:self.gradientView];
}

- (void)buildTopBar
{
    self.topBar = [[UIView alloc] initWithFrame:CGRectZero];
    self.topBar.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.topBar];

    self.closeButton = [OTTheme iconButton:OTIconChevronDown size:26 color:[OTTheme text] target:self action:@selector(closePlayer)];
    [self.topBar addSubview:self.closeButton];

    self.topLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.topLabel.font = [OTTheme labelMedium];
    self.topLabel.textColor = [OTTheme secondaryText];
    self.topLabel.textAlignment = NSTextAlignmentCenter;
    self.topLabel.text = @"Reproduciendo ahora";
    [self.topBar addSubview:self.topLabel];
}

- (void)buildTrackInfo
{
    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.titleLabel.font = [OTTheme font:30.0 weight:UIFontWeightBold];
    self.titleLabel.textColor = [OTTheme text];
    self.titleLabel.numberOfLines = 2;
    [self.view addSubview:self.titleLabel];

    self.artistLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.artistLabel.font = [OTTheme font:17.0 weight:UIFontWeightMedium];
    self.artistLabel.textColor = [OTTheme secondaryText];
    self.artistLabel.numberOfLines = 1;
    [self.view addSubview:self.artistLabel];

    self.favoriteButton = [OTTheme iconButton:OTIconHeart size:26 color:[OTTheme text] target:self action:@selector(toggleFavorite)];
    [self.view addSubview:self.favoriteButton];

    self.moreButton = [OTTheme iconButton:OTIconMoreHoriz size:26 color:[OTTheme text] target:self action:@selector(showMore)];
    [self.view addSubview:self.moreButton];
}

- (void)buildProgress
{
    self.slider = [[OTSlider alloc] initWithFrame:CGRectZero];
    [self.slider addTarget:self action:@selector(sliderTouchDown) forControlEvents:UIControlEventTouchDown];
    [self.slider addTarget:self action:@selector(sliderChanged) forControlEvents:UIControlEventValueChanged];
    [self.slider addTarget:self action:@selector(sliderTouchUp) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchCancel];
    [self.view addSubview:self.slider];

    self.elapsedLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.elapsedLabel.font = [OTTheme labelMedium];
    self.elapsedLabel.textColor = [OTTheme text];
    [self.view addSubview:self.elapsedLabel];

    self.remainingLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.remainingLabel.font = [OTTheme labelMedium];
    self.remainingLabel.textColor = [OTTheme text];
    self.remainingLabel.textAlignment = NSTextAlignmentRight;
    [self.view addSubview:self.remainingLabel];

    self.formatChip = OTFormatChipView(@"WEBM", OTIconEqualizer);
    self.formatChip.hidden = YES;
    [self.view addSubview:self.formatChip];
    self.formatLabel = (UILabel *)[self.formatChip viewWithTag:2];
}

- (void)buildTransport
{
    self.prevButton = [OTTheme iconButton:OTIconPrev size:34 color:[OTTheme text] target:self action:@selector(playPrevious)];
    [self.view addSubview:self.prevButton];

    self.playButton = [OTTheme iconButton:OTIconPlay size:44 color:[OTTheme text] target:self action:@selector(togglePlayPause)];
    [self.view addSubview:self.playButton];

    self.playSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    self.playSpinner.color = [OTTheme text];
    self.playSpinner.hidesWhenStopped = YES;
    [self.playButton addSubview:self.playSpinner];

    self.nextButton = [OTTheme iconButton:OTIconNext size:34 color:[OTTheme text] target:self action:@selector(playNext)];
    [self.view addSubview:self.nextButton];
}

- (UIButton *)circleButtonWithIcon:(OTIcon)icon action:(SEL)action
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.backgroundColor = [[OTTheme surfaceHigh] colorWithAlphaComponent:0.85];
    button.layer.cornerRadius = 26.0;
    button.tintColor = [OTTheme text];
    [button setImage:[OTTheme icon:icon size:24] forState:UIControlStateNormal];
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (void)buildBottomRow
{
    self.metadataLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.metadataLabel.font = [OTTheme labelSmall];
    self.metadataLabel.textColor = [OTTheme secondaryText];
    self.metadataLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.metadataLabel];

    self.queueButton = [self circleButtonWithIcon:OTIconQueue action:@selector(showQueue)];
    [self.view addSubview:self.queueButton];

    self.lyricsButton = [self circleButtonWithIcon:OTIconLyrics action:@selector(showLyrics)];
    [self.view addSubview:self.lyricsButton];

    self.outputChip = [[OTOutputChip alloc] initWithFrame:CGRectZero];
    [self.outputChip addTarget:self action:@selector(showOutputInfo) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.outputChip];
    [self refreshOutputChip];
}

- (void)buildPanels
{
    self.panelDim = [[UIView alloc] initWithFrame:self.view.bounds];
    self.panelDim.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
    self.panelDim.alpha = 0.0;
    self.panelDim.hidden = YES;
    [self.view addSubview:self.panelDim];

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissPanels)];
    [self.panelDim addGestureRecognizer:tap];

    [self buildLyricsPanel];
    [self buildQueuePanel];
}

- (UIView *)panelWithTitle:(NSString *)title closeAction:(SEL)closeAction
{
    UIView *panel = [[UIView alloc] initWithFrame:CGRectZero];
    panel.backgroundColor = [OTTheme surface];
    panel.layer.cornerRadius = 28.0;
    panel.clipsToBounds = YES;
    panel.hidden = YES;

    UIView *grabber = [[UIView alloc] initWithFrame:CGRectMake(0, 10.0, 36.0, 4.0)];
    grabber.backgroundColor = [OTTheme outlineVariant];
    grabber.layer.cornerRadius = 2.0;
    grabber.tag = 1;
    [panel addSubview:grabber];

    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.font = [OTTheme font:24.0 weight:UIFontWeightBold];
    label.textColor = [OTTheme text];
    label.text = title;
    label.tag = 10;
    [panel addSubview:label];

    UIButton *close = [OTTheme iconButton:OTIconClose size:22 color:[OTTheme secondaryText] target:self action:closeAction];
    close.tag = 11;
    [panel addSubview:close];

    [self.view addSubview:panel];
    return panel;
}

- (void)buildLyricsPanel
{
    self.lyricsPanel = [self panelWithTitle:@"Letras" closeAction:@selector(hideLyrics)];

    self.lyricsStatusLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.lyricsStatusLabel.font = [OTTheme bodyMedium];
    self.lyricsStatusLabel.textColor = [OTTheme outline];
    self.lyricsStatusLabel.textAlignment = NSTextAlignmentLeft;
    self.lyricsStatusLabel.numberOfLines = 3;
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
    self.lyricsTextView.textContainerInset = UIEdgeInsetsMake(8, 24, 60, 24);
    self.lyricsTextView.tag = 14;
    [self.lyricsPanel addSubview:self.lyricsTextView];
}

- (void)buildQueuePanel
{
    self.queuePanel = [self panelWithTitle:@"Cola de reproducción" closeAction:@selector(hideQueue)];

    self.queueSubtitleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.queueSubtitleLabel.font = [OTTheme bodyMedium];
    self.queueSubtitleLabel.textColor = [OTTheme secondaryText];
    self.queueSubtitleLabel.tag = 12;
    [self.queuePanel addSubview:self.queueSubtitleLabel];

    UIButton *clear = [UIButton buttonWithType:UIButtonTypeCustom];
    clear.titleLabel.font = [OTTheme labelMedium];
    [clear setTitle:@"Vaciar" forState:UIControlStateNormal];
    [clear setTitleColor:[OTTheme primary] forState:UIControlStateNormal];
    [clear addTarget:self action:@selector(clearQueue) forControlEvents:UIControlEventTouchUpInside];
    clear.tag = 13;
    [self.queuePanel addSubview:clear];

    self.queueTable = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.queueTable.dataSource = self;
    self.queueTable.delegate = self;
    self.queueTable.backgroundColor = [OTTheme surface];
    self.queueTable.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.queueTable.rowHeight = 72.0;
    self.queueTable.contentInset = UIEdgeInsetsMake(0, 0, 24, 0);
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
    self.shadeView.frame = self.view.bounds;
    self.gradientView.frame = self.view.bounds;
    CAGradientLayer *gradient = (CAGradientLayer *)self.gradientView.layer.sublayers.firstObject;
    gradient.frame = self.gradientView.bounds;

    self.topBar.frame = CGRectMake(0, top, width, 48.0);
    self.closeButton.frame = CGRectMake(8.0, 2.0, 44.0, 44.0);
    self.topLabel.frame = CGRectMake(64.0, 2.0, width - 128.0, 44.0);

    CGFloat contentWidth = MIN(width - 96.0, 620.0);
    CGFloat contentX = (width - contentWidth) / 2.0;

    CGFloat bottom = height - 26.0;
    CGFloat outputHeight = 52.0;
    CGFloat outputY = bottom - outputHeight;
    CGSize outputSize = [self.outputChip sizeThatFits:CGSizeMake(contentWidth, 44.0)];
    self.outputChip.frame = CGRectMake(contentX + contentWidth - outputSize.width,
                                       outputY,
                                       outputSize.width,
                                       44.0);
    self.queueButton.frame = CGRectMake(contentX, outputY - 2.0, 52.0, 52.0);
    self.lyricsButton.frame = CGRectMake(contentX + 64.0, outputY - 2.0, 52.0, 52.0);

    CGFloat metadataY = outputY - 34.0;
    self.metadataLabel.frame = CGRectMake(contentX, metadataY, contentWidth, 20.0);

    CGFloat transportY = metadataY - 92.0;
    self.playButton.frame = CGRectMake(contentX + contentWidth / 2.0 - 34.0, transportY, 68.0, 68.0);
    self.playSpinner.center = CGPointMake(34.0, 34.0);
    self.prevButton.frame = CGRectMake(contentX + contentWidth / 2.0 - 130.0, transportY + 8.0, 56.0, 52.0);
    self.nextButton.frame = CGRectMake(contentX + contentWidth / 2.0 + 74.0, transportY + 8.0, 56.0, 52.0);

    CGFloat timesY = transportY - 38.0;
    self.elapsedLabel.frame = CGRectMake(contentX, timesY, 70.0, 22.0);
    self.remainingLabel.frame = CGRectMake(contentX + contentWidth - 70.0, timesY, 70.0, 22.0);
    CGSize chipText = [self.formatLabel sizeThatFits:CGSizeMake(120.0, 24.0)];
    CGFloat chipWidth = MAX(76.0, chipText.width + 42.0);
    self.formatChip.frame = CGRectMake(contentX + (contentWidth - chipWidth) / 2.0,
                                       timesY - 1.0,
                                       chipWidth,
                                       24.0);
    self.formatLabel.frame = CGRectMake(26.0, 0, chipWidth - 32.0, 24.0);

    CGFloat sliderY = timesY - 34.0;
    self.slider.frame = CGRectMake(contentX, sliderY, contentWidth, 28.0);

    CGFloat titleBlockY = sliderY - 108.0;
    CGFloat actionsWidth = 96.0;
    self.titleLabel.frame = CGRectMake(contentX, titleBlockY, contentWidth - actionsWidth, 42.0);
    self.artistLabel.frame = CGRectMake(contentX, titleBlockY + 46.0, contentWidth - actionsWidth, 24.0);
    self.favoriteButton.frame = CGRectMake(contentX + contentWidth - 92.0, titleBlockY - 8.0, 44.0, 44.0);
    self.moreButton.frame = CGRectMake(contentX + contentWidth - 48.0, titleBlockY - 8.0, 44.0, 44.0);

    CGFloat panelTop = MAX(top + 48.0, height * 0.24);
    CGRect panelFrame = CGRectMake(0, panelTop, width, height - panelTop);
    self.lyricsPanel.frame = panelFrame;
    self.queuePanel.frame = panelFrame;
    self.panelDim.frame = self.view.bounds;

    UIView *grabber = [self.lyricsPanel viewWithTag:1];
    grabber.frame = CGRectMake((width - 36.0) / 2.0, 10.0, 36.0, 4.0);
    UIView *lyricsTitle = [self.lyricsPanel viewWithTag:10];
    lyricsTitle.frame = CGRectMake(24.0, 24.0, width - 100.0, 36.0);
    UIView *lyricsClose = [self.lyricsPanel viewWithTag:11];
    lyricsClose.frame = CGRectMake(width - 56.0, 22.0, 44.0, 44.0);
    self.lyricsStatusLabel.frame = CGRectMake(64.0, 82.0, width - 88.0, 60.0);
    self.lyricsSpinner.center = CGPointMake(40.0, 100.0);
    self.lyricsTextView.frame = CGRectMake(0, 68.0, width, panelFrame.size.height - 68.0);

    UIView *queueGrabber = [self.queuePanel viewWithTag:1];
    queueGrabber.frame = CGRectMake((width - 36.0) / 2.0, 10.0, 36.0, 4.0);
    UIView *queueTitle = [self.queuePanel viewWithTag:10];
    queueTitle.frame = CGRectMake(24.0, 24.0, width - 180.0, 36.0);
    UIView *queueClose = [self.queuePanel viewWithTag:11];
    queueClose.frame = CGRectMake(width - 56.0, 22.0, 44.0, 44.0);
    self.queueSubtitleLabel.frame = CGRectMake(24.0, 60.0, width - 160.0, 20.0);
    UIView *queueClear = [self.queuePanel viewWithTag:13];
    queueClear.frame = CGRectMake(width - 116.0, 54.0, 92.0, 32.0);
    self.queueTable.frame = CGRectMake(0, 90.0, width, panelFrame.size.height - 90.0);
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
    [self.backgroundView setImageURL:item.thumbnailURL
                                size:900.0
                         placeholder:[OTTheme musicPlaceholder:900]];

    BOOL favorite = [[OTStore sharedStore] isFavorite:item];
    [self.favoriteButton setImage:[OTTheme icon:(favorite ? OTIconHeartFill : OTIconHeart) size:26]
                         forState:UIControlStateNormal];
    self.favoriteButton.tintColor = favorite ? [OTTheme primary] : [OTTheme text];

    [self updateFormatChip];
    [self updateMetadata];

    self.slider.maximumValue = MAX(1.0, player.duration > 0 ? player.duration : (double)item.duration);
    self.slider.value = 0;
    self.elapsedLabel.text = @"0:00";
    double initialDuration = player.duration > 0 ? player.duration : (double)item.duration;
    self.remainingLabel.text = [NSString stringWithFormat:@"-%@", [OTTheme formatTime:initialDuration]];
    [self updatePlayState];
    [self refreshOutputChip];

    self.currentLyricIndex = -1;
    self.lyricsItemId = nil;
    if (self.lyricsPanelVisible) {
        [self loadLyrics];
    }
    if (self.queuePanelVisible) {
        [self.queueTable reloadData];
        [self updateQueueSubtitle];
    }
}

- (void)updateFormatChip
{
    OTPlayer *player = [OTPlayer sharedPlayer];
    NSString *label = player.currentFormatLabel;
    self.formatChip.hidden = (label.length == 0);
    if (label.length > 0) {
        self.formatLabel.text = label;
    }
    [self.view setNeedsLayout];
}

- (NSString *)codecFromMimeType:(NSString *)mime
{
    NSRange range = [mime rangeOfString:@"codecs="];
    if (range.location == NSNotFound) {
        return nil;
    }
    NSString *codec = [mime substringFromIndex:range.location + range.length];
    codec = [codec stringByReplacingOccurrencesOfString:@"\"" withString:@""];
    NSRange semicolon = [codec rangeOfString:@";"];
    if (semicolon.location != NSNotFound) {
        codec = [codec substringToIndex:semicolon.location];
    }
    codec = [codec stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *lower = [codec lowercaseString];
    if ([lower hasPrefix:@"mp4a"]) {
        return @"AAC";
    }
    if ([lower hasPrefix:@"opus"]) {
        return @"OPUS";
    }
    if ([lower hasPrefix:@"vorbis"]) {
        return @"VORBIS";
    }
    if ([lower hasPrefix:@"ec-3"] || [lower hasPrefix:@"ac-3"]) {
        return @"DOLBY";
    }
    return [codec uppercaseString];
}

- (void)updateMetadata
{
    OTPlayer *player = [OTPlayer sharedPlayer];
    OTItem *item = player.currentItem;
    NSString *format = player.currentFormatLabel;
    NSString *mime = player.currentMimeType;
    if (format.length == 0) {
        self.metadataLabel.text = nil;
        return;
    }
    NSMutableArray *parts = [NSMutableArray array];
    [parts addObject:format];
    NSString *codec = [self codecFromMimeType:mime];
    if (codec.length > 0) {
        [parts addObject:codec];
    }
    double duration = player.duration > 0 ? player.duration : (double)item.duration;
    if (duration > 0) {
        [parts addObject:[OTTheme formatTime:duration]];
    }
    self.metadataLabel.text = [parts componentsJoinedByString:@"  •  "];
}

- (void)updatePlayState
{
    OTPlayer *player = [OTPlayer sharedPlayer];
    [self.playButton setImage:[OTTheme icon:(player.isPlaying ? OTIconPause : OTIconPlay) size:44]
                     forState:UIControlStateNormal];
    self.playButton.imageView.hidden = player.isLoading;
    if (player.isLoading) {
        [self.playSpinner startAnimating];
    } else {
        [self.playSpinner stopAnimating];
    }
}

- (void)refreshOutputChip
{
    AVAudioSession *session = [AVAudioSession sharedInstance];
    AVAudioSessionPortDescription *port = session.currentRoute.outputs.firstObject;
    NSString *name = port.portName.length > 0 ? port.portName : @"Altavoz";
    OTIcon icon = OTIconOutput;
    if ([port.portType isEqualToString:AVAudioSessionPortBluetoothA2DP] ||
        [port.portType isEqualToString:AVAudioSessionPortBluetoothHFP] ||
        [port.portType isEqualToString:AVAudioSessionPortBluetoothLE]) {
        icon = OTIconCast;
    } else if ([port.portType isEqualToString:AVAudioSessionPortHeadphones] ||
               [port.portType isEqualToString:AVAudioSessionPortHeadsetMic]) {
        icon = OTIconVolume;
    }
    [self.outputChip setTitle:name icon:icon];
}

#pragma mark - Notificaciones

- (void)trackChanged
{
    [self refreshWithTrack];
}

- (void)stateChanged
{
    [self updatePlayState];
    [self updateMetadata];
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
    self.remainingLabel.text = [NSString stringWithFormat:@"-%@", [OTTheme formatTime:MAX(0.0, duration - current)]];

    if (self.lyricsPanelVisible && self.lyricsSynced) {
        [self highlightLyricsAtTime:current];
    }
}

- (void)queueChanged
{
    if (self.queuePanelVisible) {
        [self.queueTable reloadData];
        [self updateQueueSubtitle];
    }
}

- (void)routeChanged
{
    [self refreshOutputChip];
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

- (void)toggleFavorite
{
    OTItem *item = [OTPlayer sharedPlayer].currentItem;
    if (!item) {
        return;
    }
    BOOL added = [[OTStore sharedStore] toggleFavorite:item];
    [self.favoriteButton setImage:[OTTheme icon:(added ? OTIconHeartFill : OTIconHeart) size:26]
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
            [OTTheme showToast:@"Descarga completada" inView:strongSelf.view];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"OTLibraryDidChangeNotification" object:nil];
        } else {
            [OTTheme showToast:(error.localizedDescription ?: @"No se pudo descargar") inView:strongSelf.view];
        }
    }];
}

- (void)showOutputInfo
{
    AVAudioSession *session = [AVAudioSession sharedInstance];
    AVAudioSessionPortDescription *port = session.currentRoute.outputs.firstObject;
    NSString *name = port.portName.length > 0 ? port.portName : @"Altavoz del dispositivo";
    OTDialogViewController *dialog =
        [OTDialogViewController dialogWithTitle:@"Salida de audio"
                                        message:[NSString stringWithFormat:@"Estás escuchando en %@.", name]
                                   confirmTitle:@"Entendido"
                                    cancelTitle:@"Cerrar"
                                     completion:nil];
    [dialog presentFrom:self];
}

#pragma mark - Slider

- (void)sliderTouchDown
{
    self.draggingSlider = YES;
}

- (void)sliderChanged
{
    self.elapsedLabel.text = [OTTheme formatTime:self.slider.value];
    double duration = [OTPlayer sharedPlayer].duration;
    self.remainingLabel.text = [NSString stringWithFormat:@"-%@",
                                [OTTheme formatTime:MAX(0.0, duration - self.slider.value)]];
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
    OTPlayer *player = [OTPlayer sharedPlayer];
    __weak typeof(self) weakSelf = self;
    NSMutableArray<OTSheetAction *> *actions = [NSMutableArray array];

    OTSheetAction *shuffle = [OTSheetAction actionWithTitle:@"Aleatorio"
                                                       subtitle:(player.shuffle ? @"Activado" : @"Desactivado")
                                                           icon:OTIconShuffle
                                                        handler:^{
        player.shuffle = !player.shuffle;
        [OTTheme showToast:(player.shuffle ? @"Aleatorio activado" : @"Aleatorio desactivado") inView:weakSelf.view];
    }];
    shuffle.selected = player.shuffle;
    [actions addObject:shuffle];

    NSArray *repeatNames = @[@"Desactivado", @"Repetir todo", @"Repetir una"];
    OTSheetAction *repeat = [OTSheetAction actionWithTitle:@"Repetición"
                                                     subtitle:repeatNames[player.repeatMode]
                                                         icon:OTIconRepeat
                                                      handler:^{
        [player cycleRepeatMode];
        [OTTheme showToast:repeatNames[player.repeatMode] inView:weakSelf.view];
    }];
    repeat.selected = (player.repeatMode != OTRepeatOff);
    [actions addObject:repeat];

    OTSheetAction *speed = [OTSheetAction actionWithTitle:@"Velocidad"
                                                    subtitle:[NSString stringWithFormat:@"%.2gx", player.playbackRate]
                                                        icon:OTIconSpeed
                                                     handler:^{
        [weakSelf showSpeed];
    }];
    [actions addObject:speed];

    OTSheetAction *sleep = [OTSheetAction actionWithTitle:@"Temporizador"
                                                    subtitle:([player sleepTimerActive]
                                                              ? [NSString stringWithFormat:@"%ld s restantes",
                                                                 (long)[player sleepTimerRemaining]]
                                                              : @"Apagado")
                                                        icon:OTIconSleep
                                                     handler:^{
        [weakSelf showSleepTimer];
    }];
    [actions addObject:sleep];

    [actions addObject:[OTSheetAction actionWithTitle:@"Añadir a la cola"
                                                 icon:OTIconQueue
                                              handler:^{
        [player addToQueue:item];
        [OTTheme showToast:@"Añadido a la cola" inView:weakSelf.view];
    }]];

    BOOL downloaded = [[OTStore sharedStore] isDownloaded:item];
    OTSheetAction *download = [OTSheetAction actionWithTitle:(downloaded ? @"Eliminar descarga" : @"Descargar")
                                                       icon:(downloaded ? OTIconTrash : OTIconDownload)
                                                    handler:^{
        [weakSelf toggleDownload];
    }];
    download.destructive = downloaded;
    [actions addObject:download];

    [actions addObject:[OTSheetAction actionWithTitle:@"Compartir"
                                                 icon:OTIconExternal
                                              handler:^{
        [weakSelf shareCurrent];
    }]];

    [actions addObject:[OTSheetAction actionWithTitle:@"Ver letras"
                                                 icon:OTIconLyrics
                                              handler:^{
        [weakSelf showLyrics];
    }]];

    [actions addObject:[OTSheetAction actionWithTitle:@"Cancelar"
                                                 icon:OTIconClose
                                              handler:nil]];

    OTSheetViewController *sheet = [OTSheetViewController sheetWithTitle:item.title
                                                                subtitle:[item displaySubtitle]
                                                                 actions:actions];
    [sheet presentFrom:self];
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
    NSArray *minutes = @[@5, @10, @15, @30, @60];
    __weak typeof(self) weakSelf = self;
    NSMutableArray<OTSheetAction *> *actions = [NSMutableArray array];
    for (NSNumber *value in minutes) {
        OTSheetAction *action = [OTSheetAction actionWithTitle:[NSString stringWithFormat:@"%@ minutos", value]
                                                          icon:OTIconSleep
                                                       handler:^{
            [[OTPlayer sharedPlayer] setSleepTimer:[value doubleValue] * 60.0];
            [OTTheme showToast:[NSString stringWithFormat:@"Temporizador: %@ min", value] inView:weakSelf.view];
        }];
        [actions addObject:action];
    }
    if ([[OTPlayer sharedPlayer] sleepTimerActive]) {
        OTSheetAction *off = [OTSheetAction actionWithTitle:@"Desactivar"
                                                       icon:OTIconClose
                                                    handler:^{
            [[OTPlayer sharedPlayer] cancelSleepTimer];
            [OTTheme showToast:@"Temporizador desactivado" inView:weakSelf.view];
        }];
        off.destructive = YES;
        [actions addObject:off];
    }
    [actions addObject:[OTSheetAction actionWithTitle:@"Cancelar" icon:OTIconClose handler:nil]];
    OTSheetViewController *sheet = [OTSheetViewController sheetWithTitle:@"Temporizador"
                                                                subtitle:@"Detener la reproducción tras…"
                                                                 actions:actions];
    [sheet presentFrom:self];
}

- (void)showSpeed
{
    NSArray *speeds = @[@0.5, @0.75, @1.0, @1.25, @1.5, @2.0];
    __weak typeof(self) weakSelf = self;
    NSMutableArray<OTSheetAction *> *actions = [NSMutableArray array];
    for (NSNumber *value in speeds) {
        NSString *title = [NSString stringWithFormat:@"%.2gx", value.doubleValue];
        OTSheetAction *action = [OTSheetAction actionWithTitle:title
                                                          icon:OTIconSpeed
                                                       handler:^{
            [OTPlayer sharedPlayer].playbackRate = value.floatValue;
            [OTTheme showToast:[NSString stringWithFormat:@"Velocidad %@", title] inView:weakSelf.view];
        }];
        action.selected = (fabs([OTPlayer sharedPlayer].playbackRate - value.floatValue) < 0.01);
        [actions addObject:action];
    }
    [actions addObject:[OTSheetAction actionWithTitle:@"Cancelar" icon:OTIconClose handler:nil]];
    OTSheetViewController *sheet = [OTSheetViewController sheetWithTitle:@"Velocidad de reproducción"
                                                                subtitle:nil
                                                                 actions:actions];
    [sheet presentFrom:self];
}

#pragma mark - Paneles

- (CGRect)panelTargetFrame
{
    CGFloat height = self.view.bounds.size.height;
    CGFloat panelTop = MAX(self.topLayoutGuide.length + 48.0, height * 0.24);
    return CGRectMake(0, panelTop, self.view.bounds.size.width, height - panelTop);
}

- (void)presentPanel:(UIView *)panel
{
    self.panelDim.hidden = NO;
    [self.view bringSubviewToFront:self.panelDim];
    [self.view bringSubviewToFront:panel];

    CGRect target = [self panelTargetFrame];
    CGRect start = target;
    start.origin.y = self.view.bounds.size.height;
    panel.frame = start;
    panel.hidden = NO;
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
        panel.frame = target;
        self.panelDim.alpha = 1.0;
    } completion:nil];
}

- (void)dismissPanel:(UIView *)panel
{
    CGRect end = panel.frame;
    end.origin.y = self.view.bounds.size.height;
    [UIView animateWithDuration:0.24
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
        panel.frame = end;
        self.panelDim.alpha = 0.0;
    } completion:^(BOOL finished) {
        panel.hidden = YES;
        self.panelDim.hidden = YES;
    }];
}

- (void)dismissPanels
{
    if (self.lyricsPanelVisible) {
        [self hideLyrics];
    }
    if (self.queuePanelVisible) {
        [self hideQueue];
    }
}

#pragma mark - Letras

- (void)showLyrics
{
    self.queuePanelVisible = NO;
    self.queuePanel.hidden = YES;
    self.lyricsPanelVisible = YES;
    [self presentPanel:self.lyricsPanel];
    [self loadLyrics];
}

- (void)hideLyrics
{
    if (!self.lyricsPanelVisible) {
        return;
    }
    self.lyricsPanelVisible = NO;
    [self dismissPanel:self.lyricsPanel];
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
        self.lyricsTextView.font = [OTTheme font:18.0 weight:UIFontWeightMedium];
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
    paragraph.lineSpacing = 16.0;
    paragraph.alignment = NSTextAlignmentLeft;
    [attributed addAttributes:@{NSFontAttributeName: [OTTheme font:21.0 weight:UIFontWeightSemibold],
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
        [attributed addAttribute:NSFontAttributeName value:[OTTheme font:21.0 weight:UIFontWeightSemibold] range:value.rangeValue];
    }
    if (index >= 0 && index < (NSInteger)self.lyricsRanges.count) {
        NSRange range = [self.lyricsRanges[index] rangeValue];
        [attributed addAttribute:NSForegroundColorAttributeName value:[OTTheme primary] range:range];
        [attributed addAttribute:NSFontAttributeName value:[OTTheme font:23.0 weight:UIFontWeightBold] range:range];
        self.lyricsTextView.attributedText = attributed;
        [self.lyricsTextView scrollRangeToVisible:range];
    }
}

#pragma mark - Cola

- (void)showQueue
{
    self.lyricsPanelVisible = NO;
    self.lyricsPanel.hidden = YES;
    self.queuePanelVisible = YES;
    [self updateQueueSubtitle];
    [self.queueTable reloadData];
    [self presentPanel:self.queuePanel];
}

- (void)hideQueue
{
    if (!self.queuePanelVisible) {
        return;
    }
    self.queuePanelVisible = NO;
    [self dismissPanel:self.queuePanel];
}

- (void)updateQueueSubtitle
{
    NSUInteger count = [OTPlayer sharedPlayer].queue.count;
    self.queueSubtitleLabel.text = [NSString stringWithFormat:@"%lu %@", (unsigned long)count,
                                    count == 1 ? @"canción" : @"canciones"];
}

- (void)clearQueue
{
    [[OTPlayer sharedPlayer] clearQueue];
    [self.queueTable reloadData];
    [self updateQueueSubtitle];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [OTPlayer sharedPlayer].queue.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 72.0;
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
        [self updateQueueSubtitle];
    }
}

@end

//
//  OTComponents.m
//  OpenTune 9
//

#import "OTComponents.h"
#import "OTTheme.h"
#import "OTPlayer.h"
#import "OTStore.h"
#import <objc/runtime.h>
#import <QuartzCore/QuartzCore.h>

static CGFloat const OTListItemHeight = 72.0;

#pragma mark - OTItemCell

@interface OTItemCell ()
@property (nonatomic, assign) BOOL showsArtwork;
@property (nonatomic, strong) OTMosaicView *mosaicView;
@end

@implementation OTItemCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [OTTheme background];
        self.contentView.backgroundColor = [OTTheme background];
        self.selectionStyle = UITableViewCellSelectionStyleNone;

        UIView *selected = [[UIView alloc] init];
        selected.backgroundColor = [OTTheme surfaceContainer];
        self.selectedBackgroundView = selected;

        _artworkView = [[OTImageView alloc] initWithFrame:CGRectZero];
        _artworkView.layer.cornerRadius = 8.0;
        _artworkView.clipsToBounds = YES;
        [self.contentView addSubview:_artworkView];

        _mosaicView = [[OTMosaicView alloc] initWithFrame:CGRectZero];
        _mosaicView.layer.cornerRadius = 8.0;
        _mosaicView.clipsToBounds = YES;
        _mosaicView.hidden = YES;
        [self.contentView addSubview:_mosaicView];

        _indexLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _indexLabel.font = [OTTheme labelLarge];
        _indexLabel.textColor = [OTTheme secondaryText];
        _indexLabel.textAlignment = NSTextAlignmentCenter;
        [self.contentView addSubview:_indexLabel];

        _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _titleLabel.font = [OTTheme titleMedium];
        _titleLabel.textColor = [OTTheme text];
        _titleLabel.numberOfLines = 1;
        [self.contentView addSubview:_titleLabel];

        _subtitleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _subtitleLabel.font = [OTTheme bodySmall];
        _subtitleLabel.textColor = [OTTheme secondaryText];
        _subtitleLabel.numberOfLines = 1;
        [self.contentView addSubview:_subtitleLabel];

        _durationLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _durationLabel.font = [OTTheme labelMedium];
        _durationLabel.textColor = [OTTheme secondaryText];
        _durationLabel.textAlignment = NSTextAlignmentRight;
        [self.contentView addSubview:_durationLabel];

        _moreButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_moreButton setImage:[OTTheme icon:OTIconMoreVert size:20] forState:UIControlStateNormal];
        _moreButton.tintColor = [OTTheme secondaryText];
        [_moreButton addTarget:self action:@selector(handleMore) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:_moreButton];
    }
    return self;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    [self.artworkView cancelLoading];
    self.artworkView.image = nil;
    self.mosaicURLs = nil;
    self.mosaicView.hidden = YES;
    self.moreHandler = nil;
    self.titleLabel.textColor = [OTTheme text];
}

- (void)configureWithItem:(OTItem *)item index:(NSInteger)index showsArtwork:(BOOL)showsArtwork
{
    self.item = item;
    self.showsArtwork = showsArtwork;
    self.titleLabel.text = item.title.length > 0 ? item.title : @"Sin título";
    self.subtitleLabel.text = [item displaySubtitle];
    self.durationLabel.text = item.durationText.length > 0 ? item.durationText : nil;
    self.indexLabel.text = index > 0 ? [NSString stringWithFormat:@"%ld", (long)index] : nil;
    self.moreButton.hidden = (self.moreHandler == nil);

    BOOL hasMosaic = (self.mosaicURLs.count > 0);
    self.mosaicView.hidden = !hasMosaic;
    if (hasMosaic) {
        self.artworkView.hidden = YES;
        self.indexLabel.hidden = YES;
        [self.mosaicView setImageURLs:self.mosaicURLs];
    } else if (showsArtwork) {
        self.artworkView.hidden = NO;
        self.indexLabel.hidden = YES;
        [self.artworkView setImageURL:item.thumbnailURL
                                 size:56.0
                          placeholder:[OTTheme musicPlaceholder:56]];
    } else {
        self.artworkView.hidden = YES;
        self.indexLabel.hidden = (index <= 0);
    }
    [self setNeedsLayout];
}

- (void)setMoreHandler:(void (^)(OTItem *))moreHandler
{
    _moreHandler = [moreHandler copy];
    self.moreButton.hidden = (_moreHandler == nil);
}

- (void)setCurrentTrack:(BOOL)current
{
    self.titleLabel.textColor = current ? [OTTheme primary] : [OTTheme text];
}

- (void)handleMore
{
    if (self.moreHandler && self.item) {
        self.moreHandler(self.item);
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    CGFloat width = self.contentView.bounds.size.width;
    CGFloat height = self.contentView.bounds.size.height;
    CGFloat left = 16.0;

    if (!self.mosaicView.hidden) {
        self.mosaicView.frame = CGRectMake(left, (height - 56.0) / 2.0, 56.0, 56.0);
        left = 84.0;
    } else if (self.showsArtwork) {
        self.artworkView.frame = CGRectMake(left, (height - 56.0) / 2.0, 56.0, 56.0);
        left = 84.0;
    } else {
        self.indexLabel.frame = CGRectMake(8.0, 0, 28.0, height);
        left = 44.0;
    }

    self.moreButton.frame = CGRectMake(width - 44.0, (height - 44.0) / 2.0, 44.0, 44.0);
    CGFloat right = CGRectGetMinX(self.moreButton.frame) - 4.0;

    if (self.durationLabel.text.length > 0) {
        self.durationLabel.frame = CGRectMake(right - 48.0, 0, 44.0, height);
        right = CGRectGetMinX(self.durationLabel.frame) - 8.0;
    } else {
        self.durationLabel.frame = CGRectZero;
    }

    self.titleLabel.frame = CGRectMake(left, 14.0, MAX(20.0, right - left), 22.0);
    self.subtitleLabel.frame = CGRectMake(left, 38.0, MAX(20.0, right - left), 18.0);
}

@end


#pragma mark - OTMosaicView

@implementation OTMosaicView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [OTTheme surfaceHigh];
        for (NSInteger i = 0; i < 4; i++) {
            OTImageView *image = [[OTImageView alloc] initWithFrame:CGRectZero];
            image.contentMode = UIViewContentModeScaleAspectFill;
            image.clipsToBounds = YES;
            image.tag = 100 + i;
            [self addSubview:image];
        }
    }
    return self;
}

- (void)setImageURLs:(NSArray<NSString *> *)urls
{
    for (NSInteger i = 0; i < 4; i++) {
        OTImageView *image = (OTImageView *)[self viewWithTag:100 + i];
        if (i < (NSInteger)urls.count) {
            image.hidden = NO;
            [image setImageURL:urls[i] size:80.0 placeholder:[OTTheme musicPlaceholder:80]];
        } else {
            image.hidden = YES;
            image.image = nil;
        }
    }
    [self setNeedsLayout];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    CGFloat width = self.bounds.size.width;
    CGFloat height = self.bounds.size.height;
    CGFloat halfW = (width - 1.0) / 2.0;
    CGFloat halfH = (height - 1.0) / 2.0;
    for (NSInteger i = 0; i < 4; i++) {
        OTImageView *image = (OTImageView *)[self viewWithTag:100 + i];
        CGFloat x = (i % 2 == 0) ? 0.0 : halfW + 1.0;
        CGFloat y = (i < 2) ? 0.0 : halfH + 1.0;
        image.frame = CGRectMake(x, y, halfW, halfH);
    }
}

@end


#pragma mark - OTGridCell

@implementation OTGridCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.contentView.backgroundColor = [UIColor clearColor];

        _artworkView = [[OTImageView alloc] initWithFrame:CGRectZero];
        _artworkView.layer.cornerRadius = 12.0;
        _artworkView.clipsToBounds = YES;
        [self.contentView addSubview:_artworkView];

        _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _titleLabel.font = [OTTheme titleSmall];
        _titleLabel.textColor = [OTTheme text];
        _titleLabel.numberOfLines = 2;
        [self.contentView addSubview:_titleLabel];

        _subtitleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _subtitleLabel.font = [OTTheme labelSmall];
        _subtitleLabel.textColor = [OTTheme secondaryText];
        _subtitleLabel.numberOfLines = 1;
        [self.contentView addSubview:_subtitleLabel];
    }
    return self;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    [self.artworkView cancelLoading];
    self.artworkView.image = nil;
}

- (void)configureWithItem:(OTItem *)item width:(CGFloat)width
{
    self.item = item;
    CGFloat art = width;
    self.artworkView.frame = CGRectMake(0, 0, art, art);
    if (item.type == OTItemTypeArtist) {
        self.artworkView.layer.cornerRadius = art / 2.0;
    } else {
        self.artworkView.layer.cornerRadius = 12.0;
    }
    [self.artworkView setImageURL:item.thumbnailURL
                             size:art
                      placeholder:[OTTheme musicPlaceholder:art]];

    self.titleLabel.frame = CGRectMake(0, art + 8.0, width, 38.0);
    self.titleLabel.text = item.title.length > 0 ? item.title : @"Sin título";
    self.subtitleLabel.frame = CGRectMake(0, art + 47.0, width, 16.0);
    NSString *subtitle = [item displaySubtitle];
    if (item.type == OTItemTypePlaylist && subtitle.length == 0) {
        subtitle = @"Lista de reproducción";
    }
    self.subtitleLabel.text = subtitle;
}

@end


#pragma mark - OTCarouselCell

static CGFloat const OTCarouselItemWidth = 172.0;
static CGFloat const OTCarouselItemHeight = 236.0;

@interface OTCarouselCell () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>
@end

@implementation OTCarouselCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [OTTheme background];
        self.contentView.backgroundColor = [OTTheme background];
        self.selectionStyle = UITableViewCellSelectionStyleNone;

        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        layout.minimumLineSpacing = 12.0;
        layout.minimumInteritemSpacing = 12.0;
        layout.sectionInset = UIEdgeInsetsMake(0, 16, 0, 16);
        layout.itemSize = CGSizeMake(OTCarouselItemWidth, OTCarouselItemHeight);

        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
        _collectionView.backgroundColor = [OTTheme background];
        _collectionView.showsHorizontalScrollIndicator = NO;
        _collectionView.dataSource = self;
        _collectionView.delegate = self;
        [_collectionView registerClass:[OTGridCell class] forCellWithReuseIdentifier:@"OTGridCell"];
        [self.contentView addSubview:_collectionView];
    }
    return self;
}

- (void)setItems:(NSArray<OTItem *> *)items
{
    _items = [items copy];
    [self.collectionView reloadData];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.collectionView.frame = self.contentView.bounds;
}

- (void)refreshCurrentTrack
{
    [self.collectionView reloadData];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.items.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    OTGridCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"OTGridCell" forIndexPath:indexPath];
    OTItem *item = self.items[indexPath.item];
    [cell configureWithItem:item width:OTCarouselItemWidth];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.item < self.items.count && self.onSelectItem) {
        self.onSelectItem(self.items[indexPath.item]);
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(OTCarouselItemWidth, OTCarouselItemHeight);
}

@end


#pragma mark - OTSectionHeaderView

@implementation OTSectionHeaderView

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithReuseIdentifier:reuseIdentifier];
    if (self) {
        self.contentView.backgroundColor = [OTTheme background];

        _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _titleLabel.font = [OTTheme titleLarge];
        _titleLabel.textColor = [OTTheme text];
        [self.contentView addSubview:_titleLabel];

        _moreButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _moreButton.titleLabel.font = [OTTheme labelMedium];
        [_moreButton setTitle:@"Ver todo" forState:UIControlStateNormal];
        [_moreButton setTitleColor:[OTTheme secondaryText] forState:UIControlStateNormal];
        [_moreButton setImage:[OTTheme icon:OTIconChevronRight size:16] forState:UIControlStateNormal];
        _moreButton.tintColor = [OTTheme secondaryText];
        _moreButton.imageEdgeInsets = UIEdgeInsetsMake(0, 58, 0, -58);
        _moreButton.titleEdgeInsets = UIEdgeInsetsMake(0, -18, 0, 18);
        [_moreButton addTarget:self action:@selector(handleMore) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:_moreButton];
    }
    return self;
}

- (void)configureWithTitle:(NSString *)title showsMore:(BOOL)showsMore
{
    self.titleLabel.text = title;
    self.moreButton.hidden = !showsMore;
}

- (void)handleMore
{
    if (self.onMore) {
        self.onMore();
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    CGFloat width = self.contentView.bounds.size.width;
    self.titleLabel.frame = CGRectMake(16.0, 0, width - 160.0, self.contentView.bounds.size.height);
    self.moreButton.frame = CGRectMake(width - 108.0, 0, 96.0, self.contentView.bounds.size.height);
}

@end


#pragma mark - OTChipsView

@interface OTChipsView ()
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) NSMutableArray<UIButton *> *buttons;
@end

@implementation OTChipsView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
        _scrollView.showsHorizontalScrollIndicator = NO;
        _scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self addSubview:_scrollView];
        _buttons = [NSMutableArray array];
        _selectedIndex = 0;
    }
    return self;
}

- (void)setTitles:(NSArray<NSString *> *)titles selectedIndex:(NSInteger)selectedIndex
{
    [self setTitles:titles icons:nil selectedIndex:selectedIndex];
}

- (void)setTitles:(NSArray<NSString *> *)titles
            icons:(NSArray<NSNumber *> *)icons
    selectedIndex:(NSInteger)selectedIndex
{
    self.titles = titles;
    self.icons = icons;
    self.selectedIndex = selectedIndex;
    for (UIButton *button in self.buttons) {
        [button removeFromSuperview];
    }
    [self.buttons removeAllObjects];

    for (NSInteger i = 0; i < (NSInteger)titles.count; i++) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button setTitle:titles[i] forState:UIControlStateNormal];
        button.titleLabel.font = [OTTheme labelLarge];
        button.tag = i;
        button.layer.cornerRadius = 18.0;
        button.layer.borderWidth = 1.0;
        button.contentEdgeInsets = UIEdgeInsetsMake(0, 16, 0, 18);
        if (i < (NSInteger)icons.count && [icons[i] integerValue] >= 0) {
            OTIcon icon = (OTIcon)[icons[i] integerValue];
            [button setImage:[OTTheme icon:icon size:18] forState:UIControlStateNormal];
            button.imageEdgeInsets = UIEdgeInsetsMake(0, -4, 0, 6);
            button.titleEdgeInsets = UIEdgeInsetsMake(0, 4, 0, -4);
        }
        [button addTarget:self action:@selector(handleTap:) forControlEvents:UIControlEventTouchUpInside];
        [self.scrollView addSubview:button];
        [self.buttons addObject:button];
    }
    [self updateStyles];
    [self setNeedsLayout];
}

- (void)selectIndex:(NSInteger)index animated:(BOOL)animated
{
    if (index < 0 || index >= (NSInteger)self.buttons.count) {
        return;
    }
    self.selectedIndex = index;
    [self updateStyles];
    UIButton *button = self.buttons[index];
    CGRect frame = button.frame;
    CGFloat targetX = frame.origin.x - 16.0;
    CGFloat maxX = MAX(0.0, self.scrollView.contentSize.width - self.scrollView.bounds.size.width);
    targetX = MAX(0.0, MIN(targetX, maxX));
    [self.scrollView setContentOffset:CGPointMake(targetX, 0) animated:animated];
}

- (void)updateStyles
{
    for (UIButton *button in self.buttons) {
        BOOL selected = (button.tag == self.selectedIndex);
        if (selected) {
            button.backgroundColor = [OTTheme primaryContainer];
            button.layer.borderColor = [OTTheme primaryContainer].CGColor;
            [button setTitleColor:[OTTheme onPrimaryContainer] forState:UIControlStateNormal];
            button.tintColor = [OTTheme onPrimaryContainer];
        } else {
            button.backgroundColor = [OTTheme surfaceContainer];
            button.layer.borderColor = [OTTheme cardBorder].CGColor;
            [button setTitleColor:[OTTheme secondaryText] forState:UIControlStateNormal];
            button.tintColor = [OTTheme secondaryText];
        }
    }
}

- (void)handleTap:(UIButton *)button
{
    NSInteger index = button.tag;
    if (index == self.selectedIndex) {
        return;
    }
    [self selectIndex:index animated:YES];
    if (self.onSelect) {
        self.onSelect(index);
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.scrollView.frame = self.bounds;
    CGFloat x = 16.0;
    CGFloat height = self.bounds.size.height;
    for (UIButton *button in self.buttons) {
        CGSize size = [button sizeThatFits:CGSizeMake(CGFLOAT_MAX, height)];
        CGFloat width = MAX(64.0, size.width);
        button.frame = CGRectMake(x, (height - 36.0) / 2.0, width, 36.0);
        x += width + 8.0;
    }
    self.scrollView.contentSize = CGSizeMake(x + 8.0, height);
}

@end


#pragma mark - OTMiniPlayerView

@interface OTMiniPlayerView () <UIGestureRecognizerDelegate>
@property (nonatomic, strong) UITapGestureRecognizer *tapGesture;
@property (nonatomic, strong) UILabel *loadingLabel;
@end

@implementation OTMiniPlayerView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [OTTheme surfaceContainer];
        self.layer.cornerRadius = 16.0;
        self.layer.borderWidth = 1.0;
        self.layer.borderColor = [OTTheme cardBorder].CGColor;
        self.layer.masksToBounds = YES;

        _artworkView = [[OTImageView alloc] initWithFrame:CGRectZero];
        _artworkView.layer.cornerRadius = 10.0;
        _artworkView.clipsToBounds = YES;
        [self addSubview:_artworkView];

        _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _titleLabel.font = [OTTheme labelLarge];
        _titleLabel.textColor = [OTTheme text];
        [self addSubview:_titleLabel];

        _subtitleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _subtitleLabel.font = [OTTheme labelSmall];
        _subtitleLabel.textColor = [OTTheme secondaryText];
        [self addSubview:_subtitleLabel];

        _playButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_playButton setImage:[OTTheme icon:OTIconPlay size:26] forState:UIControlStateNormal];
        _playButton.tintColor = [OTTheme text];
        [_playButton addTarget:self action:@selector(handlePlay) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_playButton];

        _nextButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_nextButton setImage:[OTTheme icon:OTIconNext size:24] forState:UIControlStateNormal];
        _nextButton.tintColor = [OTTheme text];
        [_nextButton addTarget:self action:@selector(handleNext) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_nextButton];

        _progressTrack = [[UIView alloc] initWithFrame:CGRectZero];
        _progressTrack.backgroundColor = [OTTheme surfaceHighest];
        [self addSubview:_progressTrack];

        _progressFill = [[UIView alloc] initWithFrame:CGRectZero];
        _progressFill.backgroundColor = [OTTheme primary];
        [_progressTrack addSubview:_progressFill];

        _loadingLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _loadingLabel.text = @"Cargando…";
        _loadingLabel.font = [OTTheme labelSmall];
        _loadingLabel.textColor = [OTTheme primary];
        _loadingLabel.hidden = YES;
        [self addSubview:_loadingLabel];

        _tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleOpen)];
        _tapGesture.delegate = self;
        [self addGestureRecognizer:_tapGesture];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refresh) name:OTPlayerStateDidChangeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refresh) name:OTPlayerTrackDidChangeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshProgress) name:OTPlayerTimeDidChangeNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    return ![touch.view isKindOfClass:[UIControl class]];
}

- (void)refresh
{
    OTPlayer *player = [OTPlayer sharedPlayer];
    OTItem *item = player.currentItem;
    if (!item) {
        self.hidden = YES;
        return;
    }
    self.hidden = NO;
    self.titleLabel.text = item.title;
    self.subtitleLabel.text = [item displaySubtitle];
    [self.artworkView setImageURL:item.thumbnailURL size:48.0 placeholder:[OTTheme musicPlaceholder:48]];
    [self.playButton setImage:[OTTheme icon:(player.isPlaying ? OTIconPause : OTIconPlay) size:26]
                     forState:UIControlStateNormal];
    self.loadingLabel.hidden = !player.isLoading;
    self.playButton.hidden = player.isLoading;
    [self refreshProgress];
}

- (void)refreshProgress
{
    OTPlayer *player = [OTPlayer sharedPlayer];
    double duration = player.duration;
    double current = player.currentTime;
    CGFloat width = self.progressTrack.bounds.size.width;
    CGFloat progress = (duration > 0) ? (CGFloat)(current / duration) : 0.0;
    progress = MAX(0.0, MIN(1.0, progress));
    self.progressFill.frame = CGRectMake(0, 0, width * progress, self.progressTrack.bounds.size.height);
}

- (void)handlePlay
{
    [[OTPlayer sharedPlayer] togglePlayPause];
}

- (void)handleNext
{
    [[OTPlayer sharedPlayer] next];
}

- (void)handleOpen
{
    if (self.onOpen) {
        self.onOpen();
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    CGFloat width = self.bounds.size.width;
    CGFloat height = self.bounds.size.height;

    self.artworkView.frame = CGRectMake(8.0, 8.0, height - 16.0, height - 16.0);
    CGFloat textX = CGRectGetMaxX(self.artworkView.frame) + 12.0;
    CGFloat textRight = width - 84.0;
    self.titleLabel.frame = CGRectMake(textX, 10.0, MAX(20.0, textRight - textX), 20.0);
    self.subtitleLabel.frame = CGRectMake(textX, height - 30.0, MAX(20.0, textRight - textX), 16.0);
    self.loadingLabel.frame = CGRectMake(textX, 12.0, MAX(20.0, textRight - textX), 20.0);

    self.nextButton.frame = CGRectMake(width - 42.0, (height - 44.0) / 2.0 - 1.0, 40.0, 44.0);
    self.playButton.frame = CGRectMake(width - 82.0, (height - 44.0) / 2.0 - 1.0, 40.0, 44.0);

    self.progressTrack.frame = CGRectMake(8.0, height - 2.5, width - 16.0, 2.5);
    self.progressFill.frame = CGRectMake(0, 0, self.progressFill.frame.size.width, 2.5);
    [self refreshProgress];
}

@end


#pragma mark - OTEmptyView

@implementation OTEmptyView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _iconView = [[UIImageView alloc] initWithFrame:CGRectZero];
        _iconView.tintColor = [OTTheme primary];
        _iconView.contentMode = UIViewContentModeScaleAspectFit;
        _iconView.backgroundColor = [OTTheme surfaceContainer];
        _iconView.layer.cornerRadius = 40.0;
        _iconView.clipsToBounds = YES;
        [self addSubview:_iconView];

        _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _titleLabel.font = [OTTheme titleLarge];
        _titleLabel.textColor = [OTTheme text];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        [self addSubview:_titleLabel];

        _subtitleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _subtitleLabel.font = [OTTheme bodyMedium];
        _subtitleLabel.textColor = [OTTheme secondaryText];
        _subtitleLabel.textAlignment = NSTextAlignmentCenter;
        _subtitleLabel.numberOfLines = 0;
        [self addSubview:_subtitleLabel];

        _actionButton = OTPillButton(@"Reintentar", OTIconRefresh, YES);
        _actionButton.hidden = YES;
        [self addSubview:_actionButton];
    }
    return self;
}

- (void)configureWithIcon:(OTIcon)icon
                    title:(NSString *)title
                 subtitle:(NSString *)subtitle
              actionTitle:(NSString *)actionTitle
                   action:(void (^)(void))action
{
    self.iconView.image = [OTTheme icon:icon size:34];
    self.titleLabel.text = title;
    self.subtitleLabel.text = subtitle;
    if (actionTitle.length > 0 && action) {
        [self.actionButton setTitle:actionTitle forState:UIControlStateNormal];
        self.actionButton.hidden = NO;
        [self.actionButton removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
        [self.actionButton addTarget:self action:@selector(handleAction) forControlEvents:UIControlEventTouchUpInside];
        objc_setAssociatedObject(self.actionButton, "action", action, OBJC_ASSOCIATION_COPY_NONATOMIC);
    } else {
        self.actionButton.hidden = YES;
    }
    [self setNeedsLayout];
}

- (void)handleAction
{
    void (^action)(void) = objc_getAssociatedObject(self.actionButton, "action");
    if (action) {
        action();
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    CGFloat width = self.bounds.size.width;
    CGFloat centerY = self.bounds.size.height * 0.28;
    self.iconView.frame = CGRectMake((width - 80.0) / 2.0, centerY, 80.0, 80.0);
    self.titleLabel.frame = CGRectMake(24.0, centerY + 96.0, width - 48.0, 30.0);
    self.subtitleLabel.frame = CGRectMake(40.0, centerY + 132.0, width - 80.0, 44.0);
    CGSize size = [self.actionButton sizeThatFits:CGSizeMake(CGFLOAT_MAX, 40)];
    self.actionButton.frame = CGRectMake((width - MAX(140.0, size.width)) / 2.0,
                                         centerY + 186.0, MAX(140.0, size.width), 40.0);
}

@end


#pragma mark - OTHeaderView

@implementation OTHeaderView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [OTTheme background];
        _artworkView = [[OTImageView alloc] initWithFrame:CGRectZero];
        _artworkView.layer.cornerRadius = 16.0;
        _artworkView.clipsToBounds = YES;
        [self addSubview:_artworkView];

        _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _titleLabel.font = [OTTheme headlineMedium];
        _titleLabel.textColor = [OTTheme text];
        _titleLabel.numberOfLines = 3;
        [self addSubview:_titleLabel];

        _subtitleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _subtitleLabel.font = [OTTheme bodyMedium];
        _subtitleLabel.textColor = [OTTheme secondaryText];
        _subtitleLabel.numberOfLines = 2;
        [self addSubview:_subtitleLabel];

        _detailLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _detailLabel.font = [OTTheme labelMedium];
        _detailLabel.textColor = [OTTheme outline];
        _detailLabel.numberOfLines = 1;
        [self addSubview:_detailLabel];

        _playButton = OTPillButton(@"Reproducir", OTIconPlay, YES);
        [self addSubview:_playButton];

        _shuffleButton = OTPillButton(@"Aleatorio", OTIconShuffle, NO);
        [self addSubview:_shuffleButton];

        _downloadButton = OTRoundButton(OTIconDownload, 20);
        [self addSubview:_downloadButton];

        _moreButton = OTRoundButton(OTIconMoreVert, 20);
        [self addSubview:_moreButton];
    }
    return self;
}

- (void)configureWithItem:(OTItem *)item type:(OTItemType)type
{
    self.titleLabel.text = item.title;
    self.subtitleLabel.text = item.artistsText.length > 0 ? item.artistsText : [item displaySubtitle];
    if (type == OTItemTypeArtist) {
        self.subtitleLabel.text = item.playsText.length > 0 ? item.playsText : item.subtitle;
        self.detailLabel.text = nil;
    } else {
        self.detailLabel.text = item.playsText.length > 0 ? item.playsText : item.subtitle;
    }
    [self.artworkView setImageURL:item.thumbnailURL
                             size:320.0
                      placeholder:[OTTheme musicPlaceholder:320]];
    if (type == OTItemTypeArtist) {
        self.artworkView.layer.cornerRadius = 90.0;
    } else {
        self.artworkView.layer.cornerRadius = 16.0;
    }
    [self setNeedsLayout];
}

- (CGFloat)preferredHeightForWidth:(CGFloat)width
{
    return 292.0;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    CGFloat width = self.bounds.size.width;
    CGFloat art = width >= 700.0 ? 210.0 : 172.0;

    self.artworkView.frame = CGRectMake(16.0, 14.0, art, art);
    CGFloat textX = CGRectGetMaxX(self.artworkView.frame) + 20.0;
    CGFloat textWidth = width - textX - 24.0;

    self.titleLabel.frame = CGRectMake(textX, 16.0, textWidth, 66.0);
    self.subtitleLabel.frame = CGRectMake(textX, CGRectGetMaxY(self.titleLabel.frame) + 4.0, textWidth, 40.0);
    self.detailLabel.frame = CGRectMake(textX, CGRectGetMaxY(self.subtitleLabel.frame) + 2.0, textWidth, 18.0);

    CGFloat buttonY = CGRectGetMaxY(self.detailLabel.frame) + 14.0;
    CGSize playSize = [self.playButton sizeThatFits:CGSizeMake(CGFLOAT_MAX, 40)];
    self.playButton.frame = CGRectMake(textX, buttonY, MAX(134.0, playSize.width), 40.0);
    CGSize shuffleSize = [self.shuffleButton sizeThatFits:CGSizeMake(CGFLOAT_MAX, 40)];
    self.shuffleButton.frame = CGRectMake(CGRectGetMaxX(self.playButton.frame) + 8.0, buttonY,
                                          MAX(124.0, shuffleSize.width), 40.0);

    self.downloadButton.frame = CGRectMake(textX, buttonY + 48.0, 40.0, 40.0);
    self.moreButton.frame = CGRectMake(CGRectGetMaxX(self.downloadButton.frame) + 6.0, buttonY + 48.0, 40.0, 40.0);
}

@end


#pragma mark - OTAppBarView

@implementation OTAppBarView

- (instancetype)initWithTitle:(NSString *)title showsLogo:(BOOL)showsLogo
{
    self = [super initWithFrame:CGRectZero];
    if (self) {
        self.backgroundColor = [OTTheme background];
        _buttons = [NSMutableArray array];

        if (showsLogo) {
            _logoView = [[UIImageView alloc] initWithFrame:CGRectZero];
            _logoView.image = [OTTheme icon:OTIconMusicNote size:26];
            _logoView.tintColor = [OTTheme primary];
            _logoView.contentMode = UIViewContentModeScaleAspectFit;
            [self addSubview:_logoView];
        }

        _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _titleLabel.font = [OTTheme font:24.0 weight:UIFontWeightBold];
        _titleLabel.textColor = [OTTheme text];
        _titleLabel.text = title;
        [self addSubview:_titleLabel];
    }
    return self;
}

- (UIButton *)addButtonWithIcon:(OTIcon)icon target:(id)target action:(SEL)action
{
    UIButton *button = [OTTheme iconButton:icon size:23 color:[OTTheme secondaryText] target:target action:action];
    [self addSubview:button];
    [self.buttons addObject:button];
    return button;
}

- (UIButton *)addAvatarWithTarget:(id)target action:(SEL)action
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.backgroundColor = [OTTheme surfaceHigh];
    button.layer.cornerRadius = 18.0;
    button.clipsToBounds = YES;
    [button setImage:[OTTheme icon:OTIconUser size:20] forState:UIControlStateNormal];
    button.tintColor = [OTTheme secondaryText];
    if (target && action) {
        [button addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    }
    [self addSubview:button];
    [self.buttons addObject:button];
    return button;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    CGFloat width = self.bounds.size.width;
    CGFloat height = self.bounds.size.height;

    CGFloat x = 16.0;
    if (self.logoView) {
        self.logoView.frame = CGRectMake(x, (height - 28.0) / 2.0, 28.0, 28.0);
        x = CGRectGetMaxX(self.logoView.frame) + 8.0;
    }
    self.titleLabel.frame = CGRectMake(x, 0, width - x - 200.0, height);

    CGFloat right = width - 12.0;
    for (NSInteger i = (NSInteger)self.buttons.count - 1; i >= 0; i--) {
        UIButton *button = self.buttons[i];
        CGFloat size = (button.layer.cornerRadius >= 17.0) ? 36.0 : 42.0;
        button.frame = CGRectMake(right - size, (height - size) / 2.0, size, size);
        right = CGRectGetMinX(button.frame) - 2.0;
    }
}

@end


#pragma mark - OTQuickCardCell

@implementation OTQuickCardCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _cardView = [[UIView alloc] initWithFrame:self.contentView.bounds];
        _cardView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [OTTheme styleCard:_cardView radius:20.0];
        [self.contentView addSubview:_cardView];

        _iconCircle = [[UIView alloc] initWithFrame:CGRectZero];
        _iconCircle.layer.cornerRadius = 22.0;
        [_cardView addSubview:_iconCircle];

        _iconView = [[UIImageView alloc] initWithFrame:CGRectZero];
        _iconView.contentMode = UIViewContentModeScaleAspectFit;
        [_cardView addSubview:_iconView];

        _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _titleLabel.font = [OTTheme titleMedium];
        _titleLabel.textColor = [OTTheme text];
        _titleLabel.numberOfLines = 1;
        [_cardView addSubview:_titleLabel];
    }
    return self;
}

- (void)configureWithTitle:(NSString *)title icon:(OTIcon)icon tint:(UIColor *)tint
{
    self.titleLabel.text = title;
    self.iconView.image = [OTTheme icon:icon size:24];
    self.iconView.tintColor = tint;
    self.iconCircle.backgroundColor = [tint colorWithAlphaComponent:0.16];
    [self setNeedsLayout];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    CGFloat width = self.contentView.bounds.size.width;
    CGFloat height = self.contentView.bounds.size.height;
    self.cardView.frame = self.contentView.bounds;
    self.iconCircle.frame = CGRectMake(16.0, 16.0, 44.0, 44.0);
    self.iconView.frame = CGRectMake(26.0, 26.0, 24.0, 24.0);
    self.titleLabel.frame = CGRectMake(16.0, height - 40.0, width - 32.0, 26.0);
}

@end


#pragma mark - OTSwitch

@interface OTSwitch ()
@property (nonatomic, strong) UIView *track;
@property (nonatomic, strong) UIView *thumb;
@end

@implementation OTSwitch

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:CGRectMake(frame.origin.x, frame.origin.y, 48.0, 28.0)];
    if (self) {
        _track = [[UIView alloc] initWithFrame:self.bounds];
        _track.layer.cornerRadius = 14.0;
        _track.userInteractionEnabled = NO;
        [self addSubview:_track];

        _thumb = [[UIView alloc] initWithFrame:CGRectMake(3.0, 3.0, 22.0, 22.0)];
        _thumb.backgroundColor = [UIColor whiteColor];
        _thumb.layer.cornerRadius = 11.0;
        _thumb.userInteractionEnabled = NO;
        [self addSubview:_thumb];

        _on = NO;
        [self updateAppearanceAnimated:NO];
        [self addTarget:self action:@selector(handleTap) forControlEvents:UIControlEventTouchUpInside];
    }
    return self;
}

- (void)setOn:(BOOL)on
{
    [self setOn:on animated:NO];
}

- (void)setOn:(BOOL)on animated:(BOOL)animated
{
    if (_on == on) {
        return;
    }
    _on = on;
    [self updateAppearanceAnimated:animated];
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}

- (void)handleTap
{
    [self setOn:!_on animated:YES];
}

- (void)updateAppearanceAnimated:(BOOL)animated
{
    void (^changes)(void) = ^{
        self.track.backgroundColor = self->_on ? [OTTheme primary] : [OTTheme surfaceHighest];
        CGFloat x = self->_on ? 23.0 : 3.0;
        self.thumb.frame = CGRectMake(x, 3.0, 22.0, 22.0);
        self.thumb.backgroundColor = self->_on ? [OTTheme onPrimary] : [OTTheme outline];
    };
    if (animated) {
        [UIView animateWithDuration:0.18 animations:changes];
    } else {
        changes();
    }
}

@end


#pragma mark - OTSlider

@implementation OTSlider

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.minimumTrackTintColor = [OTTheme primary];
        self.maximumTrackTintColor = [OTTheme surfaceHighest];

        UIGraphicsBeginImageContextWithOptions(CGSizeMake(18.0, 18.0), NO, 0.0);
        CGContextRef ctx = UIGraphicsGetCurrentContext();
        CGContextSetFillColorWithColor(ctx, [OTTheme primary].CGColor);
        CGContextFillEllipseInRect(ctx, CGRectMake(1.0, 1.0, 16.0, 16.0));
        UIImage *thumb = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        [self setThumbImage:thumb forState:UIControlStateNormal];
        [self setThumbImage:thumb forState:UIControlStateHighlighted];
    }
    return self;
}

- (CGRect)trackRectForBounds:(CGRect)bounds
{
    return CGRectMake(0, (bounds.size.height - 4.0) / 2.0, bounds.size.width, 4.0);
}

- (CGRect)thumbRectForBounds:(CGRect)bounds trackRect:(CGRect)rect value:(float)value
{
    CGRect thumb = [super thumbRectForBounds:bounds trackRect:rect value:value];
    thumb.origin.y = (bounds.size.height - 18.0) / 2.0;
    thumb.size = CGSizeMake(18.0, 18.0);
    return thumb;
}

@end


#pragma mark - OTSheetViewController

@interface OTSheetAction ()
@end

@implementation OTSheetAction

+ (instancetype)actionWithTitle:(NSString *)title icon:(OTIcon)icon handler:(void (^)(void))handler
{
    return [self actionWithTitle:title subtitle:nil icon:icon handler:handler];
}

+ (instancetype)actionWithTitle:(NSString *)title
                       subtitle:(NSString *)subtitle
                           icon:(OTIcon)icon
                       handler:(void (^)(void))handler
{
    OTSheetAction *action = [[OTSheetAction alloc] init];
    action.title = title;
    action.subtitle = subtitle;
    action.icon = icon;
    action.handler = handler;
    return action;
}

@end


@interface OTSheetViewController ()
@property (nonatomic, copy) NSString *sheetTitle;
@property (nonatomic, copy) NSString *sheetSubtitle;
@property (nonatomic, strong) NSArray<OTSheetAction *> *actions;
@property (nonatomic, strong) UIView *dimView;
@property (nonatomic, strong) UIView *sheetView;
@property (nonatomic, assign) BOOL dismissing;
@end

@implementation OTSheetViewController

+ (instancetype)sheetWithTitle:(NSString *)title
                      subtitle:(NSString *)subtitle
                       actions:(NSArray<OTSheetAction *> *)actions
{
    OTSheetViewController *sheet = [[OTSheetViewController alloc] init];
    sheet.sheetTitle = title;
    sheet.sheetSubtitle = subtitle;
    sheet.actions = actions ?: @[];
    sheet.modalPresentationStyle = UIModalPresentationOverFullScreen;
    sheet.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    return sheet;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];

    self.dimView = [[UIView alloc] initWithFrame:self.view.bounds];
    self.dimView.backgroundColor = [OTTheme scrim];
    self.dimView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.dimView];

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissSheet)];
    [self.dimView addGestureRecognizer:tap];

    CGFloat screenWidth = self.view.bounds.size.width;
    CGFloat sheetWidth = MIN(screenWidth, 560.0);
    CGFloat rowHeight = 62.0;
    CGFloat headerHeight = (self.sheetTitle.length > 0) ? 74.0 : 24.0;
    CGFloat maxHeight = self.view.bounds.size.height * 0.82;
    CGFloat contentHeight = headerHeight + rowHeight * self.actions.count + 20.0;
    CGFloat height = MIN(maxHeight, contentHeight);

    self.sheetView = [[UIView alloc] initWithFrame:CGRectMake((screenWidth - sheetWidth) / 2.0,
                                                             self.view.bounds.size.height,
                                                             sheetWidth,
                                                             height)];
    self.sheetView.backgroundColor = [OTTheme surfaceContainer];
    self.sheetView.clipsToBounds = YES;
    self.sheetView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    // Solo las esquinas superiores redondeadas (iOS 9 no tiene maskedCorners).
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:self.sheetView.bounds
                                                  byRoundingCorners:(UIRectCornerTopLeft | UIRectCornerTopRight)
                                                        cornerRadii:CGSizeMake(28.0, 28.0)];
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    maskLayer.path = maskPath.CGPath;
    self.sheetView.layer.mask = maskLayer;
    [self.view addSubview:self.sheetView];

    UIView *handle = [[UIView alloc] initWithFrame:CGRectMake((sheetWidth - 36.0) / 2.0, 10.0, 36.0, 4.0)];
    handle.backgroundColor = [OTTheme outlineVariant];
    handle.layer.cornerRadius = 2.0;
    [self.sheetView addSubview:handle];

    if (self.sheetTitle.length > 0) {
        UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(24.0, 26.0, sheetWidth - 48.0, 28.0)];
        title.font = [OTTheme titleLarge];
        title.textColor = [OTTheme text];
        title.text = self.sheetTitle;
        [self.sheetView addSubview:title];

        if (self.sheetSubtitle.length > 0) {
            UILabel *subtitle = [[UILabel alloc] initWithFrame:CGRectMake(24.0, 50.0, sheetWidth - 48.0, 18.0)];
            subtitle.font = [OTTheme bodySmall];
            subtitle.textColor = [OTTheme secondaryText];
            subtitle.text = self.sheetSubtitle;
            [self.sheetView addSubview:subtitle];
        }
    }

    UIScrollView *scroll = [[UIScrollView alloc] initWithFrame:CGRectMake(0, headerHeight,
                                                                        sheetWidth, height - headerHeight)];
    scroll.showsVerticalScrollIndicator = NO;
    [self.sheetView addSubview:scroll];

    CGFloat y = 0.0;
    for (OTSheetAction *action in self.actions) {
        UIControl *row = [[UIControl alloc] initWithFrame:CGRectMake(0, y, sheetWidth, rowHeight)];
        row.tag = [self.actions indexOfObject:action];
        [row addTarget:self action:@selector(handleRow:) forControlEvents:UIControlEventTouchUpInside];

        UIView *highlight = [[UIView alloc] initWithFrame:row.bounds];
        highlight.backgroundColor = [OTTheme surfaceHigh];
        highlight.alpha = 0.0;
        highlight.userInteractionEnabled = NO;
        highlight.tag = 99;
        [row addSubview:highlight];

        UIImageView *icon = [[UIImageView alloc] initWithFrame:CGRectMake(24.0, 20.0, 22.0, 22.0)];
        icon.image = [OTTheme icon:action.icon size:22];
        icon.contentMode = UIViewContentModeScaleAspectFit;
        icon.tintColor = action.destructive ? [OTTheme error] : [OTTheme primary];
        [row addSubview:icon];

        UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(60.0, action.subtitle.length > 0 ? 12.0 : 0.0,
                                                                   sheetWidth - 100.0, action.subtitle.length > 0 ? 22.0 : rowHeight)];
        title.font = [OTTheme bodyLarge];
        title.textColor = action.destructive ? [OTTheme error] : [OTTheme text];
        title.text = action.title;
        [row addSubview:title];

        if (action.subtitle.length > 0) {
            UILabel *subtitle = [[UILabel alloc] initWithFrame:CGRectMake(60.0, 34.0, sheetWidth - 100.0, 18.0)];
            subtitle.font = [OTTheme bodySmall];
            subtitle.textColor = [OTTheme secondaryText];
            subtitle.text = action.subtitle;
            [row addSubview:subtitle];
        }

        if (action.selected) {
            UIImageView *check = [[UIImageView alloc] initWithFrame:CGRectMake(sheetWidth - 46.0, 21.0, 20.0, 20.0)];
            check.image = [OTTheme icon:OTIconCheck size:20];
            check.tintColor = [OTTheme primary];
            [row addSubview:check];
        }

        [scroll addSubview:row];
        y += rowHeight;
    }
    scroll.contentSize = CGSizeMake(sheetWidth, y);
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
        CGRect frame = self.sheetView.frame;
        frame.origin.y = self.view.bounds.size.height - frame.size.height;
        self.sheetView.frame = frame;
    } completion:nil];
}

- (void)handleRow:(UIControl *)row
{
    NSInteger index = row.tag;
    if (index < 0 || index >= (NSInteger)self.actions.count) {
        return;
    }
    OTSheetAction *action = self.actions[index];
    void (^handler)(void) = action.handler;
    [self dismissSheetAnimated:YES completion:^{
        if (handler) {
            handler();
        }
    }];
}

- (void)dismissSheet
{
    [self dismissSheetAnimated:YES completion:nil];
}

- (void)dismissSheetAnimated:(BOOL)animated completion:(void (^)(void))completion
{
    if (self.dismissing) {
        return;
    }
    self.dismissing = YES;
    void (^finish)(BOOL) = ^(BOOL finished) {
        [self dismissViewControllerAnimated:NO completion:completion];
    };
    if (animated) {
        [UIView animateWithDuration:0.22
                              delay:0
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:^{
            CGRect frame = self.sheetView.frame;
            frame.origin.y = self.view.bounds.size.height;
            self.sheetView.frame = frame;
            self.dimView.alpha = 0.0;
        } completion:finish];
    } else {
        finish(YES);
    }
}

- (void)presentFrom:(UIViewController *)controller
{
    [controller presentViewController:self animated:NO completion:nil];
}

@end


#pragma mark - OTDialogViewController

@interface OTDialogViewController () <UITextFieldDelegate>
@property (nonatomic, copy) NSString *dialogTitle;
@property (nonatomic, copy) NSString *dialogMessage;
@property (nonatomic, copy) NSString *confirmTitle;
@property (nonatomic, copy) NSString *cancelTitle;
@property (nonatomic, copy) NSString *placeholder;
@property (nonatomic, copy) NSString *initialValue;
@property (nonatomic, assign) BOOL isPrompt;
@property (nonatomic, copy) void (^confirmBlock)(NSString *text);
@property (nonatomic, copy) void (^decisionBlock)(BOOL confirmed);
@property (nonatomic, strong) UIView *dimView;
@property (nonatomic, strong) UIView *cardView;
@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, assign) BOOL dismissing;
@end

@implementation OTDialogViewController

+ (instancetype)dialogWithTitle:(NSString *)title
                        message:(NSString *)message
                   confirmTitle:(NSString *)confirmTitle
                    cancelTitle:(NSString *)cancelTitle
                     completion:(void (^)(BOOL confirmed))completion
{
    OTDialogViewController *dialog = [[OTDialogViewController alloc] init];
    dialog.dialogTitle = title;
    dialog.dialogMessage = message;
    dialog.confirmTitle = confirmTitle ?: @"Aceptar";
    dialog.cancelTitle = cancelTitle ?: @"Cancelar";
    dialog.decisionBlock = completion;
    dialog.modalPresentationStyle = UIModalPresentationOverFullScreen;
    dialog.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    return dialog;
}

+ (instancetype)promptWithTitle:(NSString *)title
                        message:(NSString *)message
                    placeholder:(NSString *)placeholder
                          value:(NSString *)value
                   confirmTitle:(NSString *)confirmTitle
                     completion:(void (^)(NSString *text))completion
{
    OTDialogViewController *dialog = [[OTDialogViewController alloc] init];
    dialog.dialogTitle = title;
    dialog.dialogMessage = message;
    dialog.placeholder = placeholder;
    dialog.initialValue = value;
    dialog.confirmTitle = confirmTitle ?: @"Crear";
    dialog.cancelTitle = @"Cancelar";
    dialog.isPrompt = YES;
    dialog.confirmBlock = completion;
    dialog.modalPresentationStyle = UIModalPresentationOverFullScreen;
    dialog.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    return dialog;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];

    self.dimView = [[UIView alloc] initWithFrame:self.view.bounds];
    self.dimView.backgroundColor = [OTTheme scrim];
    self.dimView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.dimView];

    CGFloat width = MIN(self.view.bounds.size.width - 56.0, 360.0);
    CGFloat y = 28.0;

    self.cardView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, 0)];
    self.cardView.backgroundColor = [OTTheme surfaceContainer];
    self.cardView.layer.cornerRadius = 24.0;
    self.cardView.layer.borderWidth = 1.0;
    self.cardView.layer.borderColor = [OTTheme cardBorder].CGColor;
    self.cardView.clipsToBounds = YES;
    self.cardView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin |
                                     UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [self.view addSubview:self.cardView];

    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(24.0, y, width - 48.0, 28.0)];
    title.font = [OTTheme titleLarge];
    title.textColor = [OTTheme text];
    title.text = self.dialogTitle;
    [self.cardView addSubview:title];
    y += 36.0;

    if (self.dialogMessage.length > 0) {
        UILabel *message = [[UILabel alloc] initWithFrame:CGRectMake(24.0, y, width - 48.0, 20.0)];
        message.font = [OTTheme bodyMedium];
        message.textColor = [OTTheme secondaryText];
        message.numberOfLines = 0;
        message.text = self.dialogMessage;
        CGSize size = [message sizeThatFits:CGSizeMake(width - 48.0, CGFLOAT_MAX)];
        message.frame = CGRectMake(24.0, y, width - 48.0, size.height);
        [self.cardView addSubview:message];
        y += size.height + 16.0;
    }

    if (self.isPrompt) {
        UIView *fieldBackground = [[UIView alloc] initWithFrame:CGRectMake(24.0, y, width - 48.0, 48.0)];
        fieldBackground.backgroundColor = [OTTheme surfaceHigh];
        fieldBackground.layer.cornerRadius = 12.0;
        [self.cardView addSubview:fieldBackground];

        self.textField = [[UITextField alloc] initWithFrame:CGRectMake(14.0, 0, width - 48.0 - 28.0, 48.0)];
        self.textField.font = [OTTheme bodyLarge];
        self.textField.textColor = [OTTheme text];
        self.textField.tintColor = [OTTheme primary];
        self.textField.attributedPlaceholder =
            [[NSAttributedString alloc] initWithString:(self.placeholder ?: @"")
                                            attributes:@{NSForegroundColorAttributeName: [OTTheme outline]}];
        self.textField.text = self.initialValue;
        self.textField.delegate = self;
        self.textField.returnKeyType = UIReturnKeyDone;
        [fieldBackground addSubview:self.textField];
        y += 64.0;
    }

    UIButton *cancel = [UIButton buttonWithType:UIButtonTypeCustom];
    cancel.frame = CGRectMake(width - 220.0, y, 80.0, 40.0);
    cancel.titleLabel.font = [OTTheme labelLarge];
    [cancel setTitle:self.cancelTitle forState:UIControlStateNormal];
    [cancel setTitleColor:[OTTheme secondaryText] forState:UIControlStateNormal];
    [cancel addTarget:self action:@selector(cancelTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.cardView addSubview:cancel];

    UIButton *confirm = [UIButton buttonWithType:UIButtonTypeCustom];
    confirm.frame = CGRectMake(width - 132.0, y, 108.0, 40.0);
    confirm.backgroundColor = [OTTheme primary];
    confirm.layer.cornerRadius = 20.0;
    confirm.titleLabel.font = [OTTheme labelLarge];
    [confirm setTitle:self.confirmTitle forState:UIControlStateNormal];
    [confirm setTitleColor:[OTTheme onPrimary] forState:UIControlStateNormal];
    [confirm addTarget:self action:@selector(confirmTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.cardView addSubview:confirm];

    y += 52.0;

    self.cardView.frame = CGRectMake((self.view.bounds.size.width - width) / 2.0,
                                     (self.view.bounds.size.height - y) / 2.0,
                                     width, y);
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (self.isPrompt) {
        [self.textField becomeFirstResponder];
    }
}

- (void)confirmTapped
{
    NSString *text = self.textField.text;
    void (^block)(NSString *) = self.confirmBlock;
    void (^decision)(BOOL) = self.decisionBlock;
    [self dismissAnimated:^{
        if (block) {
            block(text);
        }
        if (decision) {
            decision(YES);
        }
    }];
}

- (void)cancelTapped
{
    void (^decision)(BOOL) = self.decisionBlock;
    [self dismissAnimated:^{
        if (decision) {
            decision(NO);
        }
    }];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self confirmTapped];
    return YES;
}

- (void)dismissAnimated:(void (^)(void))completion
{
    if (self.dismissing) {
        return;
    }
    self.dismissing = YES;
    [self.view endEditing:YES];
    [self dismissViewControllerAnimated:NO completion:completion];
}

- (void)presentFrom:(UIViewController *)controller
{
    [controller presentViewController:self animated:NO completion:nil];
}

@end


#pragma mark - Factories

UIButton *OTPillButton(NSString *title, OTIcon icon, BOOL filled)
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.titleLabel.font = [OTTheme labelLarge];
    button.layer.cornerRadius = 20.0;
    button.contentEdgeInsets = UIEdgeInsetsMake(0, 18, 0, 22);
    button.titleEdgeInsets = UIEdgeInsetsMake(0, 8, 0, -8);

    if (filled) {
        button.backgroundColor = [OTTheme primary];
        [button setTitleColor:[OTTheme onPrimary] forState:UIControlStateNormal];
        button.tintColor = [OTTheme onPrimary];
    } else {
        button.backgroundColor = [OTTheme surfaceHigh];
        [button setTitleColor:[OTTheme text] forState:UIControlStateNormal];
        button.tintColor = [OTTheme text];
    }
    [button setTitle:title forState:UIControlStateNormal];
    if (icon != -1) {
        [button setImage:[OTTheme icon:icon size:18] forState:UIControlStateNormal];
    }
    return button;
}

UIButton *OTRoundButton(OTIcon icon, CGFloat size)
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.backgroundColor = [OTTheme surfaceHigh];
    button.layer.cornerRadius = 20.0;
    [button setImage:[OTTheme icon:icon size:size] forState:UIControlStateNormal];
    button.tintColor = [OTTheme text];
    return button;
}

UIView *OTFormatChipView(NSString *text, OTIcon icon)
{
    UIView *chip = [[UIView alloc] initWithFrame:CGRectZero];
    chip.backgroundColor = [OTTheme surfaceHigh];
    chip.layer.cornerRadius = 8.0;

    UIImageView *iconView = [[UIImageView alloc] initWithFrame:CGRectMake(8.0, 5.0, 14.0, 14.0)];
    iconView.image = [OTTheme icon:icon size:14];
    iconView.tintColor = [OTTheme secondaryText];
    iconView.tag = 1;
    [chip addSubview:iconView];

    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(26.0, 0, 44.0, 24.0)];
    label.font = [OTTheme labelSmall];
    label.textColor = [OTTheme secondaryText];
    label.text = text;
    label.tag = 2;
    [chip addSubview:label];
    return chip;
}

void OTAddTopShadow(UIView *view)
{
    view.layer.shadowColor = [UIColor blackColor].CGColor;
    view.layer.shadowOpacity = 0.28;
    view.layer.shadowRadius = 12.0;
    view.layer.shadowOffset = CGSizeMake(0, -2);
}

UIViewController *OTTopViewController(void)
{
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    if (!window) {
        for (UIWindow *candidate in [UIApplication sharedApplication].windows) {
            if (candidate.isKeyWindow) {
                window = candidate;
                break;
            }
        }
    }
    UIViewController *controller = window.rootViewController;
    while (controller.presentedViewController) {
        controller = controller.presentedViewController;
    }
    if ([controller isKindOfClass:[UINavigationController class]]) {
        controller = [(UINavigationController *)controller topViewController];
    }
    if ([controller isKindOfClass:[UITabBarController class]]) {
        controller = [(UITabBarController *)controller selectedViewController];
        if ([controller isKindOfClass:[UINavigationController class]]) {
            controller = [(UINavigationController *)controller topViewController];
        }
    }
    return controller;
}

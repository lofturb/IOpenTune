//
//  OTComponents.m
//  OpenTune 9
//

#import "OTComponents.h"
#import "OTTheme.h"
#import "OTPlayer.h"
#import "OTStore.h"
#import <objc/runtime.h>

#pragma mark - OTItemCell

@interface OTItemCell ()
@property (nonatomic, assign) BOOL showsArtwork;
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
        selected.backgroundColor = [OTTheme surfaceHigh];
        self.selectedBackgroundView = selected;

        _artworkView = [[OTImageView alloc] initWithFrame:CGRectZero];
        _artworkView.layer.cornerRadius = 8.0;
        _artworkView.clipsToBounds = YES;
        [self.contentView addSubview:_artworkView];

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

    if (showsArtwork) {
        self.artworkView.hidden = NO;
        self.indexLabel.hidden = YES;
        [self.artworkView setImageURL:item.thumbnailURL
                                 size:48.0
                          placeholder:[OTTheme musicPlaceholder:48]];
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

    if (self.showsArtwork) {
        self.artworkView.frame = CGRectMake(left, (height - 48.0) / 2.0, 48.0, 48.0);
        left = CGRectGetMaxX(self.artworkView.frame) + 12.0;
    } else {
        self.indexLabel.frame = CGRectMake(8.0, 0, 28.0, height);
        left = 44.0;
    }

    CGFloat right = width - 16.0;
    self.moreButton.frame = CGRectMake(width - 44.0, (height - 44.0) / 2.0, 44.0, 44.0);
    right = CGRectGetMinX(self.moreButton.frame);

    if (self.durationLabel.text.length > 0) {
        self.durationLabel.frame = CGRectMake(right - 46.0, 0, 40.0, height);
        right = CGRectGetMinX(self.durationLabel.frame) - 6.0;
    } else {
        self.durationLabel.frame = CGRectZero;
    }

    self.titleLabel.frame = CGRectMake(left, 12.0, MAX(20.0, right - left), 22.0);
    self.subtitleLabel.frame = CGRectMake(left, 34.0, MAX(20.0, right - left), 16.0);
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
        _artworkView.layer.cornerRadius = 10.0;
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
        self.artworkView.layer.cornerRadius = 10.0;
    }
    [self.artworkView setImageURL:item.thumbnailURL
                             size:art
                      placeholder:[OTTheme musicPlaceholder:art]];

    self.titleLabel.frame = CGRectMake(2.0, art + 8.0, width - 4.0, 36.0);
    self.titleLabel.text = item.title.length > 0 ? item.title : @"Sin título";
    self.subtitleLabel.frame = CGRectMake(2.0, art + 44.0, width - 4.0, 16.0);
    NSString *subtitle = [item displaySubtitle];
    if (item.type == OTItemTypePlaylist && subtitle.length == 0) {
        subtitle = @"Lista de reproducción";
    }
    self.subtitleLabel.text = subtitle;
}

@end


#pragma mark - OTCarouselCell

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
        layout.itemSize = CGSizeMake(142.0, 206.0);

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
    [cell configureWithItem:item width:142.0];
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
    return CGSizeMake(142.0, 206.0);
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
        _moreButton.imageEdgeInsets = UIEdgeInsetsMake(0, 62, 0, -62);
        _moreButton.titleEdgeInsets = UIEdgeInsetsMake(0, -16, 0, 18);
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
    self.moreButton.frame = CGRectMake(width - 116.0, 0, 100.0, self.contentView.bounds.size.height);
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
    self.titles = titles;
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
            button.backgroundColor = [OTTheme secondaryContainer];
            button.layer.borderColor = [UIColor clearColor].CGColor;
            [button setTitleColor:[OTTheme onSecondaryContainer] forState:UIControlStateNormal];
        } else {
            button.backgroundColor = [UIColor clearColor];
            button.layer.borderColor = [OTTheme separator].CGColor;
            [button setTitleColor:[OTTheme secondaryText] forState:UIControlStateNormal];
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
        CGFloat width = MAX(64.0, size.width + 32.0);
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
        self.layer.cornerRadius = 12.0;
        self.layer.borderWidth = 0.5;
        self.layer.borderColor = [OTTheme colorWithHex:0x3A383F].CGColor;
        self.layer.masksToBounds = YES;

        _artworkView = [[OTImageView alloc] initWithFrame:CGRectZero];
        _artworkView.layer.cornerRadius = 6.0;
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
        [_playButton setImage:[OTTheme icon:OTIconPlay size:24] forState:UIControlStateNormal];
        _playButton.tintColor = [OTTheme text];
        [_playButton addTarget:self action:@selector(handlePlay) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_playButton];

        _nextButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_nextButton setImage:[OTTheme icon:OTIconNext size:22] forState:UIControlStateNormal];
        _nextButton.tintColor = [OTTheme text];
        [_nextButton addTarget:self action:@selector(handleNext) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_nextButton];

        _progressTrack = [[UIView alloc] initWithFrame:CGRectZero];
        _progressTrack.backgroundColor = [OTTheme colorWithHex:0x3A383F];
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
    [self.artworkView setImageURL:item.thumbnailURL size:44.0 placeholder:[OTTheme musicPlaceholder:44]];
    [self.playButton setImage:[OTTheme icon:(player.isPlaying ? OTIconPause : OTIconPlay) size:24]
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
    CGFloat textX = CGRectGetMaxX(self.artworkView.frame) + 10.0;
    CGFloat textRight = width - 88.0;
    self.titleLabel.frame = CGRectMake(textX, 9.0, MAX(20.0, textRight - textX), 20.0);
    self.subtitleLabel.frame = CGRectMake(textX, height - 28.0, MAX(20.0, textRight - textX), 16.0);
    self.loadingLabel.frame = CGRectMake(textX, 11.0, MAX(20.0, textRight - textX), 20.0);

    self.nextButton.frame = CGRectMake(width - 42.0, (height - 44.0) / 2.0, 40.0, 44.0);
    self.playButton.frame = CGRectMake(width - 80.0, (height - 44.0) / 2.0, 40.0, 44.0);

    self.progressTrack.frame = CGRectMake(12.0, height - 3.0, width - 24.0, 2.0);
    self.progressFill.frame = CGRectMake(0, 0, self.progressFill.frame.size.width, 2.0);
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
        _iconView.tintColor = [OTTheme outline];
        _iconView.contentMode = UIViewContentModeScaleAspectFit;
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

        _actionButton = [OTTheme iconButton:OTIconRefresh size:22 color:[OTTheme primary] target:nil action:nil];
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
    self.iconView.image = [OTTheme icon:icon size:56];
    self.titleLabel.text = title;
    self.subtitleLabel.text = subtitle;
    if (actionTitle.length > 0 && action) {
        [self.actionButton setImage:nil forState:UIControlStateNormal];
        [self.actionButton setTitle:actionTitle forState:UIControlStateNormal];
        self.actionButton.titleLabel.font = [OTTheme labelLarge];
        [self.actionButton setTitleColor:[OTTheme primary] forState:UIControlStateNormal];
        self.actionButton.hidden = NO;
        [self.actionButton removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
        [self.actionButton addTarget:self action:@selector(handleAction) forControlEvents:UIControlEventTouchUpInside];
        self.actionButton.frame = CGRectMake(0, 0, 220, 40);
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
    CGFloat centerY = self.bounds.size.height * 0.30;
    self.iconView.frame = CGRectMake((width - 56.0) / 2.0, centerY, 56.0, 56.0);
    self.titleLabel.frame = CGRectMake(24.0, centerY + 72.0, width - 48.0, 30.0);
    self.subtitleLabel.frame = CGRectMake(40.0, centerY + 106.0, width - 80.0, 44.0);
    self.actionButton.frame = CGRectMake((width - 220.0) / 2.0, centerY + 156.0, 220.0, 40.0);
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
        _artworkView.layer.cornerRadius = 12.0;
        _artworkView.clipsToBounds = YES;
        [self addSubview:_artworkView];

        _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _titleLabel.font = [OTTheme headlineSmall];
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
                             size:180.0
                      placeholder:[OTTheme musicPlaceholder:180]];
    if (type == OTItemTypeArtist) {
        self.artworkView.layer.cornerRadius = 90.0;
    } else {
        self.artworkView.layer.cornerRadius = 12.0;
    }
    [self setNeedsLayout];
}

- (CGFloat)preferredHeightForWidth:(CGFloat)width
{
    return 276.0;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    CGFloat width = self.bounds.size.width;
    CGFloat art = width >= 700.0 ? 200.0 : 168.0;

    self.artworkView.frame = CGRectMake(16.0, 12.0, art, art);
    CGFloat textX = CGRectGetMaxX(self.artworkView.frame) + 20.0;
    CGFloat textWidth = self.bounds.size.width - textX - 24.0;

    self.titleLabel.frame = CGRectMake(textX, 16.0, textWidth, art > 172 ? 66.0 : 62.0);
    self.subtitleLabel.frame = CGRectMake(textX, CGRectGetMaxY(self.titleLabel.frame) + 4.0, textWidth, 40.0);
    self.detailLabel.frame = CGRectMake(textX, CGRectGetMaxY(self.subtitleLabel.frame) + 2.0, textWidth, 18.0);

    CGFloat buttonY = CGRectGetMaxY(self.detailLabel.frame) + 12.0;
    CGSize playSize = [self.playButton sizeThatFits:CGSizeMake(CGFLOAT_MAX, 40)];
    self.playButton.frame = CGRectMake(textX, buttonY, MAX(130.0, playSize.width), 40.0);
    CGSize shuffleSize = [self.shuffleButton sizeThatFits:CGSizeMake(CGFLOAT_MAX, 40)];
    self.shuffleButton.frame = CGRectMake(CGRectGetMaxX(self.playButton.frame) + 8.0, buttonY,
                                          MAX(120.0, shuffleSize.width), 40.0);

    self.downloadButton.frame = CGRectMake(textX, buttonY + 48.0, 40.0, 40.0);
    self.moreButton.frame = CGRectMake(CGRectGetMaxX(self.downloadButton.frame) + 4.0, buttonY + 48.0, 40.0, 40.0);
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

void OTAddTopShadow(UIView *view)
{
    view.layer.shadowColor = [UIColor blackColor].CGColor;
    view.layer.shadowOpacity = 0.25;
    view.layer.shadowRadius = 10.0;
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

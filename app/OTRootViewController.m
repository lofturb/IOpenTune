//
//  OTRootViewController.m
//  OpenTune 9
//

#import "OTRootViewController.h"
#import "OTTheme.h"
#import "OTComponents.h"
#import "OTPlayer.h"
#import "OTHomeViewController.h"
#import "OTSearchViewController.h"
#import "OTMoodViewController.h"
#import "OTLibraryViewController.h"
#import "OTPlayerViewController.h"

NSString *const OTBottomInsetDidChangeNotification = @"OTBottomInsetDidChangeNotification";

static CGFloat gBottomInset = 96.0;

CGFloat OTBottomInset(void)
{
    return gBottomInset;
}

@interface OTTabButton : UIControl
@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, strong) UILabel *label;
@property (nonatomic, assign) OTIcon icon;
- (instancetype)initWithIcon:(OTIcon)icon title:(NSString *)title;
- (void)setSelectedAppearance:(BOOL)selected;
@end

@implementation OTTabButton

- (instancetype)initWithIcon:(OTIcon)icon title:(NSString *)title
{
    self = [super initWithFrame:CGRectZero];
    if (self) {
        _icon = icon;
        _iconView = [[UIImageView alloc] initWithFrame:CGRectZero];
        _iconView.contentMode = UIViewContentModeScaleAspectFit;
        _iconView.image = [OTTheme icon:icon size:24];
        _iconView.userInteractionEnabled = NO;
        [self addSubview:_iconView];

        _label = [[UILabel alloc] initWithFrame:CGRectZero];
        _label.text = title;
        _label.font = [OTTheme font:10.5 weight:UIFontWeightMedium];
        _label.textAlignment = NSTextAlignmentCenter;
        _label.userInteractionEnabled = NO;
        [self addSubview:_label];

        [self setSelectedAppearance:NO];
    }
    return self;
}

- (void)setSelectedAppearance:(BOOL)selected
{
    UIColor *color = selected ? [OTTheme onSecondaryContainer] : [OTTheme secondaryText];
    self.iconView.tintColor = color;
    self.label.textColor = color;
    self.iconView.image = [OTTheme icon:self.icon size:24 weight:selected ? 2.2 : 1.9];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    CGFloat width = self.bounds.size.width;
    self.iconView.frame = CGRectMake((width - 24.0) / 2.0, 5.0, 24.0, 24.0);
    self.label.frame = CGRectMake(0, 31.0, width, 14.0);
}

@end


@interface OTRootViewController ()

@property (nonatomic, strong) UIView *contentContainer;
@property (nonatomic, strong) NSArray<UINavigationController *> *navControllers;
@property (nonatomic, strong) NSArray<OTTabButton *> *tabButtons;
@property (nonatomic, strong) UIView *barView;
@property (nonatomic, strong) UIView *pillView;
@property (nonatomic, strong) OTMiniPlayerView *miniPlayer;
@property (nonatomic, assign) NSInteger selectedTab;
@property (nonatomic, assign) BOOL miniVisible;

@end

@implementation OTRootViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        _selectedTab = 0;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [OTTheme background];

    self.contentContainer = [[UIView alloc] initWithFrame:self.view.bounds];
    self.contentContainer.backgroundColor = [OTTheme background];
    self.contentContainer.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.contentContainer];

    [self buildTabs];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleTrackChange)
                                                 name:OTPlayerTrackDidChangeNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleTrackChange)
                                                 name:OTPlayerStateDidChangeNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleError:)
                                                 name:OTPlayerErrorNotification
                                               object:nil];

    dispatch_async(dispatch_get_main_queue(), ^{
        [self selectTab:0];
        [self handleTrackChange];
    });
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (void)buildTabs
{
    OTHomeViewController *home = [[OTHomeViewController alloc] init];
    OTSearchViewController *search = [[OTSearchViewController alloc] init];
    OTMoodViewController *mood = [[OTMoodViewController alloc] init];
    OTLibraryViewController *library = [[OTLibraryViewController alloc] init];

    NSMutableArray *navs = [NSMutableArray array];
    for (UIViewController *controller in @[home, search, mood, library]) {
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:controller];
        [nav setNavigationBarHidden:YES animated:NO];
        nav.view.backgroundColor = [OTTheme background];
        if ([nav respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
            nav.interactivePopGestureRecognizer.enabled = YES;
        }
        [navs addObject:nav];
    }
    self.navControllers = navs;

    CGFloat barHeight = 64.0;
    CGFloat side = 12.0;
    CGFloat bottom = 8.0;
    CGRect bounds = self.view.bounds;

    self.barView = [[UIView alloc] initWithFrame:CGRectMake(side,
                                                           bounds.size.height - bottom - barHeight,
                                                           bounds.size.width - side * 2,
                                                           barHeight)];
    self.barView.backgroundColor = [OTTheme surfaceContainer];
    self.barView.layer.cornerRadius = 28.0;
    self.barView.layer.borderWidth = 0.5;
    self.barView.layer.borderColor = [OTTheme colorWithHex:0x3A383F].CGColor;
    self.barView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    [self.view addSubview:self.barView];

    self.pillView = [[UIView alloc] initWithFrame:CGRectZero];
    self.pillView.backgroundColor = [OTTheme secondaryContainer];
    self.pillView.layer.cornerRadius = 22.0;
    self.pillView.userInteractionEnabled = NO;
    [self.barView addSubview:self.pillView];

    NSArray *titles = @[@"Inicio", @"Buscar", @"Géneros", @"Biblioteca"];
    NSArray *icons = @[@(OTIconHome), @(OTIconSearch), @(OTIconMood), @(OTIconLibrary)];
    NSMutableArray *buttons = [NSMutableArray array];
    for (NSInteger i = 0; i < 4; i++) {
        OTTabButton *button = [[OTTabButton alloc] initWithIcon:[icons[i] integerValue] title:titles[i]];
        button.tag = i;
        [button addTarget:self action:@selector(handleTabTap:) forControlEvents:UIControlEventTouchUpInside];
        [self.barView addSubview:button];
        [buttons addObject:button];
    }
    self.tabButtons = buttons;

    self.miniPlayer = [[OTMiniPlayerView alloc] initWithFrame:CGRectZero];
    self.miniPlayer.hidden = YES;
    __weak typeof(self) weakSelf = self;
    self.miniPlayer.onOpen = ^{
        [weakSelf openPlayer];
    };
    [self.view addSubview:self.miniPlayer];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];

    CGRect bounds = self.view.bounds;
    CGFloat barHeight = 64.0;
    CGFloat side = 12.0;
    CGFloat bottomMargin = 8.0;

    self.contentContainer.frame = bounds;
    self.barView.frame = CGRectMake(side,
                                    bounds.size.height - bottomMargin - barHeight,
                                    bounds.size.width - side * 2,
                                    barHeight);

    CGFloat itemWidth = self.barView.bounds.size.width / 4.0;
    for (NSInteger i = 0; i < (NSInteger)self.tabButtons.count; i++) {
        OTTabButton *button = self.tabButtons[i];
        button.frame = CGRectMake(itemWidth * i, 0, itemWidth, barHeight);
    }
    [self layoutPillAnimated:NO];

    CGFloat miniHeight = self.miniVisible ? 64.0 : 0.0;
    CGFloat miniY = CGRectGetMinY(self.barView.frame) - (self.miniVisible ? 76.0 : 0.0);
    self.miniPlayer.frame = CGRectMake(side + 4.0, miniY, bounds.size.width - (side + 4.0) * 2.0, miniHeight);
    self.miniPlayer.hidden = !self.miniVisible;

    CGFloat inset = bounds.size.height - miniY + 16.0;
    if (self.miniVisible) {
        inset = bounds.size.height - miniY + 16.0;
    } else {
        inset = bounds.size.height - CGRectGetMinY(self.barView.frame) + 16.0;
    }
    if (fabs(inset - gBottomInset) > 0.5) {
        gBottomInset = inset;
        [[NSNotificationCenter defaultCenter] postNotificationName:OTBottomInsetDidChangeNotification object:nil];
    }
    [self propagateBottomInset];
}

- (void)layoutPillAnimated:(BOOL)animated
{
    CGFloat itemWidth = self.barView.bounds.size.width / 4.0;
    CGRect target = CGRectMake(itemWidth * self.selectedTab + 6.0, 7.0, itemWidth - 12.0, 50.0);
    if (animated) {
        [UIView animateWithDuration:0.28
                              delay:0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
            self.pillView.frame = target;
        } completion:nil];
    } else {
        self.pillView.frame = target;
    }
}

- (void)handleTabTap:(OTTabButton *)button
{
    if (button.tag == self.selectedTab) {
        UINavigationController *nav = self.navControllers[self.selectedTab];
        [nav popToRootViewControllerAnimated:YES];
        return;
    }
    [self selectTab:button.tag];
}

- (void)selectTab:(NSInteger)index
{
    if (index < 0 || index >= (NSInteger)self.navControllers.count) {
        return;
    }
    if (self.selectedTab != index || self.contentContainer.subviews.count == 0) {
        for (UIViewController *child in self.childViewControllers) {
            [child willMoveToParentViewController:nil];
            [child.view removeFromSuperview];
            [child removeFromParentViewController];
        }
        UINavigationController *nav = self.navControllers[index];
        [self addChildViewController:nav];
        nav.view.frame = self.contentContainer.bounds;
        nav.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.contentContainer addSubview:nav.view];
        [nav didMoveToParentViewController:self];
    }

    self.selectedTab = index;
    for (NSInteger i = 0; i < (NSInteger)self.tabButtons.count; i++) {
        [self.tabButtons[i] setSelectedAppearance:(i == index)];
    }
    [self layoutPillAnimated:YES];
    [self propagateBottomInset];
}

- (void)propagateBottomInset
{
    for (UINavigationController *nav in self.navControllers) {
        for (UIViewController *controller in nav.viewControllers) {
            if ([controller respondsToSelector:NSSelectorFromString(@"updateBottomInset")]) {
                [controller performSelector:NSSelectorFromString(@"updateBottomInset")];
            }
        }
    }
}

- (void)handleTrackChange
{
    OTPlayer *player = [OTPlayer sharedPlayer];
    [self.miniPlayer refresh];
    BOOL visible = (player.currentItem != nil);
    if (visible != self.miniVisible) {
        self.miniVisible = visible;
        [self.view setNeedsLayout];
    }
}

- (void)handleError:(NSNotification *)notification
{
    NSString *message = notification.userInfo[@"message"];
    if (message.length > 0) {
        [OTTheme showToast:message inView:self.view];
    }
}

- (void)refreshBottomInset
{
    [self.view setNeedsLayout];
}

- (void)openPlayer
{
    if (![OTPlayer sharedPlayer].currentItem) {
        return;
    }
    if ([self.presentedViewController isKindOfClass:[OTPlayerViewController class]]) {
        return;
    }
    OTPlayerViewController *player = [[OTPlayerViewController alloc] init];
    player.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:player animated:YES completion:nil];
}

@end

//
//  OTMoodViewController.m
//  OpenTune 9
//

#import "OTMoodViewController.h"
#import "OTTheme.h"
#import "OTInnertube.h"
#import "OTRootViewController.h"

#import <math.h>

static UIColor *OTColorFromValue(NSUInteger value)
{
    CGFloat red = ((value >> 16) & 0xFF) / 255.0;
    CGFloat green = ((value >> 8) & 0xFF) / 255.0;
    CGFloat blue = (value & 0xFF) / 255.0;
    return [UIColor colorWithRed:red green:green blue:blue alpha:1.0];
}

@interface OTMoodViewController ()

@property (nonatomic, strong) NSArray<OTItem *> *moodItems;
@property (nonatomic, assign) CGFloat lastHeaderWidth;

@end

@implementation OTMoodViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.screenTitle = @"Géneros";
        _moodItems = @[];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.rightButton.hidden = YES;
    [self reloadContent];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    CGFloat width = self.view.bounds.size.width;
    if (self.moodItems.count > 0 && fabs(width - self.lastHeaderWidth) > 1.0) {
        [self installMoodHeader];
    }
}

#pragma mark - Carga

- (void)loadContent
{
    if (!self.loadedOnce) {
        [self showLoadingIndicator:YES];
    }
    __weak typeof(self) weakSelf = self;
    [[OTInnertube shared] browse:@"FEmusic_moods_and_genres" params:nil completion:^(NSDictionary *json, NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        if (error) {
            [strongSelf finishLoadingWithError:error];
            return;
        }
        NSArray<OTItem *> *moods = OTParseMoodButtons(json);
        if (moods.count > 0) {
            strongSelf.moodItems = moods;
            [strongSelf installMoodHeader];
        }
        NSArray<OTSection *> *sections = OTParseSections(json);
        [strongSelf setFeedSections:sections continuation:OTContinuationFromJSON(json) append:NO];
        weakSelf.paginationBlock = ^{
            [weakSelf loadMore];
        };
    }];
}

- (void)loadMore
{
    if (self.continuation.length == 0) {
        self.paginating = NO;
        return;
    }
    __weak typeof(self) weakSelf = self;
    [[OTInnertube shared] browseContinuation:self.continuation completion:^(NSDictionary *json, NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        if (error) {
            [strongSelf finishLoadingWithError:error];
            return;
        }
        NSArray<OTSection *> *sections = OTParseSections(json);
        [strongSelf setFeedSections:sections continuation:OTContinuationFromJSON(json) append:YES];
    }];
}

#pragma mark - Cabecera de animos

- (void)installMoodHeader
{
    CGFloat width = self.view.bounds.size.width;
    if (width <= 0) {
        return;
    }
    self.lastHeaderWidth = width;

    CGFloat padding = 16.0;
    CGFloat gap = 10.0;
    NSInteger columns = 2;
    CGFloat buttonWidth = (width - padding * 2.0 - gap * (columns - 1)) / columns;
    CGFloat buttonHeight = 54.0;
    NSInteger rows = (NSInteger)ceil((double)self.moodItems.count / (double)columns);
    CGFloat labelHeight = 44.0;
    CGFloat height = labelHeight + rows * (buttonHeight + gap) + 8.0;

    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, height)];
    header.backgroundColor = [OTTheme background];

    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(padding, 4.0, width - padding * 2.0, 36.0)];
    label.font = [OTTheme titleLarge];
    label.textColor = [OTTheme text];
    label.text = @"Ánimos y géneros";
    [header addSubview:label];

    NSArray *colors = @[
        [OTTheme colorWithHex:0x7A4E52],
        [OTTheme colorWithHex:0x4E5D78],
        [OTTheme colorWithHex:0x4F6B5A],
        [OTTheme colorWithHex:0x6B5A7A],
        [OTTheme colorWithHex:0x7A6440],
        [OTTheme colorWithHex:0x3F6266],
        [OTTheme colorWithHex:0x704A5E],
        [OTTheme colorWithHex:0x555F45]
    ];

    for (NSInteger i = 0; i < (NSInteger)self.moodItems.count; i++) {
        NSInteger row = i / columns;
        NSInteger column = i % columns;
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = CGRectMake(padding + column * (buttonWidth + gap),
                                  labelHeight + row * (buttonHeight + gap),
                                  buttonWidth,
                                  buttonHeight);
        button.tag = i;
        button.backgroundColor = colors[i % colors.count];
        if (self.moodItems[i].colorValue != 0) {
            button.backgroundColor = OTColorFromValue(self.moodItems[i].colorValue);
        }
        button.layer.cornerRadius = 12.0;
        button.clipsToBounds = YES;
        button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        button.titleEdgeInsets = UIEdgeInsetsMake(0, 16, 0, 12);
        button.titleLabel.font = [OTTheme font:15.0 weight:UIFontWeightSemibold];
        button.titleLabel.numberOfLines = 2;
        button.titleLabel.textAlignment = NSTextAlignmentLeft;
        [button setTitle:self.moodItems[i].title forState:UIControlStateNormal];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(moodTapped:) forControlEvents:UIControlEventTouchUpInside];
        [header addSubview:button];
    }

    self.tableHeaderView = header;
}

- (void)moodTapped:(UIButton *)sender
{
    if (sender.tag < 0 || sender.tag >= (NSInteger)self.moodItems.count) {
        return;
    }
    OTItem *item = self.moodItems[sender.tag];
    [self pushCollectionWithBrowseId:item.browseId
                              params:item.params
                               title:item.title
                                type:OTItemTypePlaylist
                          playlistId:nil];
}

@end

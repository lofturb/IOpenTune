//
//  OTHomeViewController.m
//  OpenTune 9
//

#import "OTHomeViewController.h"
#import "OTTheme.h"
#import "OTInnertube.h"
#import "OTRootViewController.h"
#import "OTSettingsViewController.h"

@interface OTHomeViewController ()

@property (nonatomic, strong) UIView *homeHeader;
@property (nonatomic, strong) UILabel *greetingLabel;
@property (nonatomic, strong) OTChipsView *chipsView;
@property (nonatomic, strong) NSArray<NSDictionary *> *chips;
@property (nonatomic, assign) NSInteger selectedChip;

@end

@implementation OTHomeViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.screenTitle = @"OpenTune";
        _chips = @[@{@"title": @"Todo", @"params": @""}];
        _selectedChip = 0;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.rightButton.hidden = NO;
    [self.rightButton setImage:[OTTheme icon:OTIconSettings size:22] forState:UIControlStateNormal];
    [self.rightButton removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
    [self.rightButton addTarget:self action:@selector(openSettings) forControlEvents:UIControlEventTouchUpInside];

    self.homeHeader = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 104.0)];
    self.homeHeader.backgroundColor = [OTTheme background];

    self.greetingLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.greetingLabel.font = [OTTheme headlineMedium];
    self.greetingLabel.textColor = [OTTheme text];
    self.greetingLabel.text = [self greeting];
    [self.homeHeader addSubview:self.greetingLabel];

    self.chipsView = [[OTChipsView alloc] initWithFrame:CGRectZero];
    __weak typeof(self) weakSelf = self;
    self.chipsView.onSelect = ^(NSInteger index) {
        [weakSelf selectChip:index];
    };
    [self.homeHeader addSubview:self.chipsView];

    self.tableHeaderView = self.homeHeader;
    [self layoutHomeHeader];

    [self reloadContent];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    [self layoutHomeHeader];
}

- (void)layoutHomeHeader
{
    CGFloat width = self.view.bounds.size.width;
    self.homeHeader.frame = CGRectMake(0, 0, width, 104.0);
    self.greetingLabel.frame = CGRectMake(16.0, 2.0, width - 32.0, 40.0);
    self.chipsView.frame = CGRectMake(0, 50.0, width, 44.0);
}

- (NSString *)greeting
{
    NSInteger hour = [[[NSCalendar currentCalendar] components:NSCalendarUnitHour fromDate:[NSDate date]] hour];
    if (hour < 12) {
        return @"Buenos días";
    }
    if (hour < 20) {
        return @"Buenas tardes";
    }
    return @"Buenas noches";
}

#pragma mark - Carga

- (void)loadContent
{
    if (!self.loadedOnce) {
        [self showLoadingIndicator:YES];
    }
    NSString *params = [self currentParams];
    __weak typeof(self) weakSelf = self;
    [[OTInnertube shared] browse:@"FEmusic_home" params:params completion:^(NSDictionary *json, NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        if (error) {
            [strongSelf finishLoadingWithError:error];
            return;
        }
        NSArray *chips = OTParseHomeChips(json);
        if (chips.count > 0) {
            [strongSelf updateChips:chips];
        }
        NSArray *sections = OTParseSections(json);
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
    [[OTInnertube shared] homeContinuation:self.continuation completion:^(NSArray<OTSection *> *sections, NSString *continuation, NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        if (error) {
            [strongSelf finishLoadingWithError:error];
            return;
        }
        [strongSelf setFeedSections:sections continuation:continuation append:YES];
    }];
}

- (NSString *)currentParams
{
    if (self.selectedChip < 0 || self.selectedChip >= (NSInteger)self.chips.count) {
        return nil;
    }
    NSString *params = self.chips[self.selectedChip][@"params"];
    return params.length > 0 ? params : nil;
}

- (void)updateChips:(NSArray<NSDictionary *> *)chips
{
    NSString *current = [self currentParams] ?: @"";
    self.chips = chips;
    NSInteger selected = 0;
    NSMutableArray *titles = [NSMutableArray array];
    for (NSInteger i = 0; i < (NSInteger)chips.count; i++) {
        [titles addObject:chips[i][@"title"] ?: @""];
        NSString *params = chips[i][@"params"] ?: @"";
        if ([params isEqualToString:current]) {
            selected = i;
        }
    }
    self.selectedChip = selected;
    [self.chipsView setTitles:titles selectedIndex:selected];
}

- (void)selectChip:(NSInteger)index
{
    if (index == self.selectedChip) {
        return;
    }
    self.selectedChip = index;
    self.sections = @[];
    self.loadedOnce = NO;
    [self.tableView reloadData];
    [self loadContent];
}

#pragma mark - Acciones

- (void)openSettings
{
    OTSettingsViewController *settings = [[OTSettingsViewController alloc] init];
    [self.navigationController pushViewController:settings animated:YES];
}

@end

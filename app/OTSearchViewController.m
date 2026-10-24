//
//  OTSearchViewController.m
//  OpenTune 9
//

#import "OTSearchViewController.h"
#import "OTTheme.h"
#import "OTInnertube.h"
#import "OTStore.h"
#import "OTRootViewController.h"

@interface OTSearchViewController () <UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UIView *searchContainer;
@property (nonatomic, strong) UITextField *searchField;
@property (nonatomic, strong) OTChipsView *chipsView;
@property (nonatomic, strong) UITableView *suggestionsTable;
@property (nonatomic, strong) NSArray<NSString *> *overlayItems;
@property (nonatomic, copy) NSString *overlayTitle;
@property (nonatomic, copy) NSString *query;
@property (nonatomic, assign) OTSearchFilter filter;
@property (nonatomic, strong) NSTimer *suggestionTimer;
@property (nonatomic, copy) NSString *pendingSuggestionQuery;

@end

@implementation OTSearchViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.screenTitle = @"Buscar";
        _filter = OTSearchFilterAll;
        _overlayItems = @[];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.searchContainer = [[UIView alloc] initWithFrame:CGRectZero];
    self.searchContainer.backgroundColor = [OTTheme background];
    [self.view addSubview:self.searchContainer];

    UIView *fieldBackground = [[UIView alloc] initWithFrame:CGRectZero];
    fieldBackground.backgroundColor = [OTTheme surfaceHigh];
    fieldBackground.layer.cornerRadius = 24.0;
    fieldBackground.tag = 100;
    [self.searchContainer addSubview:fieldBackground];

    UIImageView *searchIcon = [[UIImageView alloc] initWithFrame:CGRectMake(16, 12, 20, 20)];
    searchIcon.image = [OTTheme icon:OTIconSearch size:20];
    searchIcon.tintColor = [OTTheme secondaryText];
    [fieldBackground addSubview:searchIcon];

    self.searchField = [[UITextField alloc] initWithFrame:CGRectZero];
    self.searchField.font = [OTTheme bodyLarge];
    self.searchField.textColor = [OTTheme text];
    self.searchField.tintColor = [OTTheme primary];
    self.searchField.attributedPlaceholder =
        [[NSAttributedString alloc] initWithString:@"Busca canciones, álbumes, artistas…"
                                        attributes:@{NSForegroundColorAttributeName: [OTTheme outline]}];
    self.searchField.returnKeyType = UIReturnKeySearch;
    self.searchField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.searchField.delegate = self;
    self.searchField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.searchField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    [self.searchField addTarget:self
                         action:@selector(textChanged:)
               forControlEvents:UIControlEventEditingChanged];
    [fieldBackground addSubview:self.searchField];

    self.chipsView = [[OTChipsView alloc] initWithFrame:CGRectZero];
    [self.chipsView setTitles:@[@"Todo", @"Canciones", @"Vídeos", @"Álbumes", @"Artistas", @"Listas"]
                selectedIndex:0];
    __weak typeof(self) weakSelf = self;
    self.chipsView.onSelect = ^(NSInteger index) {
        [weakSelf filterChanged:index];
    };
    [self.view addSubview:self.chipsView];

    self.suggestionsTable = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.suggestionsTable.dataSource = self;
    self.suggestionsTable.delegate = self;
    self.suggestionsTable.backgroundColor = [OTTheme surfaceContainer];
    self.suggestionsTable.separatorColor = [OTTheme colorWithHex:0x2C2A31];
    self.suggestionsTable.separatorInset = UIEdgeInsetsMake(0, 52, 0, 16);
    self.suggestionsTable.rowHeight = 52.0;
    self.suggestionsTable.hidden = YES;
    self.suggestionsTable.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:self.suggestionsTable];

    self.rightButton.hidden = YES;

    [self reloadContent];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    CGFloat width = self.view.bounds.size.width;
    CGFloat top = self.topLayoutGuide.length + 56.0;
    self.searchContainer.frame = CGRectMake(0, top, width, 56.0);

    UIView *fieldBackground = [self.searchContainer viewWithTag:100];
    fieldBackground.frame = CGRectMake(16.0, 6.0, width - 32.0, 44.0);
    self.searchField.frame = CGRectMake(46.0, 0, width - 32.0 - 46.0 - 40.0, 44.0);

    self.chipsView.frame = CGRectMake(0, top + 56.0, width, 44.0);
    CGFloat tableY = top + 100.0;
    self.tableView.frame = CGRectMake(0, tableY, width, self.view.bounds.size.height - tableY);
    self.suggestionsTable.frame = self.tableView.frame;
    self.emptyView.frame = CGRectMake(0, tableY, width, self.view.bounds.size.height - tableY - 80.0);
    self.spinner.center = CGPointMake(width / 2.0, self.view.bounds.size.height / 2.0 - 40.0);
}

- (void)updateBottomInset
{
    [super updateBottomInset];
    if (self.suggestionsTable) {
        self.suggestionsTable.contentInset = UIEdgeInsetsMake(0, 0, OTBottomInset(), 0);
        self.suggestionsTable.scrollIndicatorInsets = self.suggestionsTable.contentInset;
    }
}

#pragma mark - Carga

- (void)loadContent
{
    if (self.query.length == 0) {
        [self.spinner stopAnimating];
        [self setFeedSections:@[] continuation:nil append:NO];
        [self showOverlayWithRecent];
        return;
    }

    if (!self.loadedOnce) {
        [self showLoadingIndicator:YES];
    }
    __weak typeof(self) weakSelf = self;
    [[OTInnertube shared] search:self.query filter:self.filter completion:^(NSArray<OTSection *> *sections, NSString *continuation, NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        if (error) {
            [strongSelf finishLoadingWithError:error];
            return;
        }
        [strongSelf hideOverlay];
        [strongSelf setFeedSections:sections continuation:continuation append:NO];
        if (sections.count == 0) {
            [strongSelf showEmptyMessage:@"Sin resultados"
                                subtitle:[NSString stringWithFormat:@"No encontramos nada para «%@».", strongSelf.query]];
        }
        strongSelf.paginationBlock = ^{
            [strongSelf loadMore];
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
    [[OTInnertube shared] searchContinuation:self.continuation completion:^(NSArray<OTSection *> *sections, NSString *continuation, NSError *error) {
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

- (void)filterChanged:(NSInteger)index
{
    self.filter = (OTSearchFilter)index;
    if (self.query.length > 0) {
        self.sections = @[];
        self.loadedOnce = NO;
        [self.tableView reloadData];
        [self loadContent];
    }
}

#pragma mark - Campo de busqueda

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self submitSearch:textField.text];
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    if (self.query.length == 0) {
        [self showOverlayWithRecent];
    } else {
        [self requestSuggestionsForQuery:textField.text];
    }
}

- (void)textChanged:(UITextField *)textField
{
    NSString *text = [textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (text.length == 0) {
        [self.suggestionTimer invalidate];
        self.overlayItems = [[[OTStore sharedStore] searchHistory] copy];
        self.overlayTitle = @"Búsquedas recientes";
        [self.suggestionsTable reloadData];
        [self showOverlayWithRecent];
        return;
    }
    [self requestSuggestionsForQuery:text];
}

- (void)requestSuggestionsForQuery:(NSString *)text
{
    [self.suggestionTimer invalidate];
    self.pendingSuggestionQuery = text;
    __weak typeof(self) weakSelf = self;
    self.suggestionTimer = [NSTimer scheduledTimerWithTimeInterval:0.28
                                                            target:weakSelf
                                                          selector:@selector(fireSuggestions:)
                                                          userInfo:nil
                                                           repeats:NO];
}

- (void)fireSuggestions:(NSTimer *)timer
{
    NSString *text = self.pendingSuggestionQuery;
    if (text.length == 0) {
        return;
    }
    __weak typeof(self) weakSelf = self;
    [[OTInnertube shared] searchSuggestions:text completion:^(NSArray<NSString *> *suggestions, NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        if (![strongSelf.pendingSuggestionQuery isEqualToString:text]) {
            return;
        }
        strongSelf.overlayItems = suggestions ?: @[];
        strongSelf.overlayTitle = @"Sugerencias";
        [strongSelf.suggestionsTable reloadData];
        if (suggestions.count > 0) {
            [strongSelf showOverlay];
        }
    }];
}

- (void)submitSearch:(NSString *)text
{
    NSString *trimmed = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (trimmed.length == 0) {
        return;
    }
    [self.searchField resignFirstResponder];
    self.searchField.text = trimmed;
    self.query = trimmed;
    [[OTStore sharedStore] addSearchTerm:trimmed];
    [self hideOverlay];
    self.sections = @[];
    self.loadedOnce = NO;
    [self.tableView reloadData];
    [self loadContent];
}

- (void)showOverlayWithRecent
{
    NSArray *history = [[OTStore sharedStore] searchHistory];
    if (history.count == 0) {
        [self hideOverlay];
        return;
    }
    self.overlayItems = history;
    self.overlayTitle = @"Búsquedas recientes";
    [self.suggestionsTable reloadData];
    [self showOverlay];
}

- (void)showOverlay
{
    self.suggestionsTable.hidden = NO;
    [self.view bringSubviewToFront:self.suggestionsTable];
}

- (void)hideOverlay
{
    self.suggestionsTable.hidden = YES;
}

#pragma mark - Tabla de sugerencias

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (tableView == self.suggestionsTable) {
        return 1;
    }
    return [super numberOfSectionsInTableView:tableView];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == self.suggestionsTable) {
        return self.overlayItems.count;
    }
    return [super tableView:tableView numberOfRowsInSection:section];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.suggestionsTable) {
        return 52.0;
    }
    return [super tableView:tableView heightForRowAtIndexPath:indexPath];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (tableView == self.suggestionsTable) {
        return 44.0;
    }
    return [super tableView:tableView heightForHeaderInSection:section];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (tableView != self.suggestionsTable) {
        return [super tableView:tableView viewForHeaderInSection:section];
    }
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, 44.0)];
    header.backgroundColor = [OTTheme surfaceContainer];

    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(16.0, 0, tableView.bounds.size.width - 120.0, 44.0)];
    label.font = [OTTheme labelLarge];
    label.textColor = [OTTheme secondaryText];
    label.text = self.overlayTitle;
    [header addSubview:label];

    if ([self.overlayTitle isEqualToString:@"Búsquedas recientes"]) {
        UIButton *clear = [UIButton buttonWithType:UIButtonTypeCustom];
        clear.frame = CGRectMake(tableView.bounds.size.width - 80.0, 0, 68.0, 44.0);
        clear.titleLabel.font = [OTTheme labelMedium];
        [clear setTitle:@"Borrar" forState:UIControlStateNormal];
        [clear setTitleColor:[OTTheme primary] forState:UIControlStateNormal];
        [clear addTarget:self action:@selector(clearHistory) forControlEvents:UIControlEventTouchUpInside];
        [header addSubview:clear];
    }
    return header;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView != self.suggestionsTable) {
        return [super tableView:tableView cellForRowAtIndexPath:indexPath];
    }
    static NSString *identifier = @"OTSuggestionCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
        cell.backgroundColor = [OTTheme surfaceContainer];
        cell.textLabel.textColor = [OTTheme text];
        cell.textLabel.font = [OTTheme bodyLarge];
        cell.imageView.image = [OTTheme icon:OTIconSearch size:18];
        cell.imageView.tintColor = [OTTheme secondaryText];
        UIView *selected = [[UIView alloc] init];
        selected.backgroundColor = [OTTheme surfaceHigh];
        cell.selectedBackgroundView = selected;
    }
    cell.textLabel.text = self.overlayItems[indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView != self.suggestionsTable) {
        [super tableView:tableView didSelectRowAtIndexPath:indexPath];
        return;
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSString *term = self.overlayItems[indexPath.row];
    [self submitSearch:term];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    if (scrollView == self.suggestionsTable) {
        [self.searchField resignFirstResponder];
    }
}

- (void)clearHistory
{
    [[OTStore sharedStore] clearSearchHistory];
    [self hideOverlay];
}

@end

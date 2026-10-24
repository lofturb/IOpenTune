//
//  OTFeedViewController.m
//  OpenTune 9
//

#import "OTFeedViewController.h"
#import "OTTheme.h"
#import "OTPlayer.h"
#import "OTStore.h"
#import "OTInnertube.h"
#import "OTDownloads.h"
#import "OTRootViewController.h"
#import "OTCollectionViewController.h"

@interface OTFeedViewController ()
@property (nonatomic, strong) NSMutableSet *registeredObservers;
@end

@implementation OTFeedViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        _sections = @[];
        _screenTitle = @"";
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [OTTheme background];
    self.automaticallyAdjustsScrollViewInsets = NO;

    self.topBar = [[UIView alloc] initWithFrame:CGRectZero];
    self.topBar.backgroundColor = [OTTheme background];
    [self.view addSubview:self.topBar];

    self.topTitleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.topTitleLabel.font = [OTTheme headlineSmall];
    self.topTitleLabel.textColor = [OTTheme text];
    self.topTitleLabel.text = self.screenTitle;
    [self.topBar addSubview:self.topTitleLabel];

    self.leftButton = [OTTheme iconButton:OTIconBack size:22 color:[OTTheme text] target:self action:@selector(handleLeft)];
    self.leftButton.hidden = YES;
    [self.topBar addSubview:self.leftButton];

    self.rightButton = [OTTheme iconButton:OTIconMoreVert size:22 color:[OTTheme text] target:nil action:nil];
    self.rightButton.hidden = YES;
    [self.topBar addSubview:self.rightButton];

    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.backgroundColor = [OTTheme background];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.rowHeight = 64.0;
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, OTBottomInset(), 0);
    self.tableView.scrollIndicatorInsets = self.tableView.contentInset;
    [self.tableView registerClass:[OTItemCell class] forCellReuseIdentifier:@"OTItemCell"];
    [self.tableView registerClass:[OTCarouselCell class] forCellReuseIdentifier:@"OTCarouselCell"];
    [self.tableView registerClass:[OTSectionHeaderView class] forHeaderFooterViewReuseIdentifier:@"OTSectionHeader"];
    [self.view addSubview:self.tableView];

    self.refreshControl = [[UIRefreshControl alloc] init];
    self.refreshControl.tintColor = [OTTheme primary];
    [self.refreshControl addTarget:self action:@selector(handleRefresh) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:self.refreshControl];

    self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    self.spinner.color = [OTTheme primary];
    self.spinner.hidesWhenStopped = YES;
    [self.view addSubview:self.spinner];

    self.emptyView = [[OTEmptyView alloc] initWithFrame:CGRectZero];
    self.emptyView.hidden = YES;
    [self.view addSubview:self.emptyView];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateBottomInset)
                                                 name:OTBottomInsetDidChangeNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleTrackChanged)
                                                 name:OTPlayerTrackDidChangeNotification
                                               object:nil];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    CGFloat width = self.view.bounds.size.width;
    CGFloat top = self.topLayoutGuide.length;
    CGFloat barHeight = top + 56.0;
    self.topBar.frame = CGRectMake(0, 0, width, barHeight);
    self.topTitleLabel.frame = CGRectMake(16.0, top + 8.0, width - 120.0, 40.0);
    self.leftButton.frame = CGRectMake(4.0, top + 6.0, 44.0, 44.0);
    self.rightButton.frame = CGRectMake(width - 48.0, top + 6.0, 44.0, 44.0);
    self.tableView.frame = CGRectMake(0, barHeight, width, self.view.bounds.size.height - barHeight);
    self.spinner.center = CGPointMake(width / 2.0, self.view.bounds.size.height / 2.0 - 40.0);
    self.emptyView.frame = CGRectMake(0, barHeight, width, self.view.bounds.size.height - barHeight - 80.0);
    [self updateBottomInset];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setScreenTitle:(NSString *)screenTitle
{
    _screenTitle = [screenTitle copy];
    self.topTitleLabel.text = screenTitle;
}

- (void)setTableHeaderView:(UIView *)tableHeaderView
{
    _tableHeaderView = tableHeaderView;
    self.tableView.tableHeaderView = tableHeaderView;
}

- (void)handleLeft
{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Carga (subclases)

- (void)loadContent
{
}

- (void)didSelectItem:(OTItem *)item inSection:(OTSection *)section
{
}

- (void)reloadContent
{
    self.sections = @[];
    self.continuation = nil;
    self.loadedOnce = NO;
    self.emptyView.hidden = YES;
    [self.tableView reloadData];
    [self loadContent];
}

- (void)handleRefresh
{
    [self reloadContent];
}

- (void)setFeedSections:(NSArray<OTSection *> *)sections continuation:(NSString *)continuation append:(BOOL)append
{
    if (append && self.sections.count > 0 && sections.count > 0) {
        NSMutableArray *merged = [self.sections mutableCopy];
        for (OTSection *section in sections) {
            OTSection *last = [merged lastObject];
            NSString *lastTitle = last.title ?: @"";
            NSString *newTitle = section.title ?: @"";
            if (last && [lastTitle isEqualToString:newTitle] && last.style == section.style) {
                NSMutableArray *items = [last.items mutableCopy];
                NSMutableSet *ids = [NSMutableSet set];
                for (OTItem *item in items) {
                    if (item.itemId.length > 0) [ids addObject:item.itemId];
                }
                for (OTItem *item in section.items) {
                    if (item.itemId.length > 0 && [ids containsObject:item.itemId]) continue;
                    if (item.itemId.length > 0) [ids addObject:item.itemId];
                    [items addObject:item];
                }
                last.items = items;
            } else {
                [merged addObject:section];
            }
        }
        self.sections = merged;
    } else if (append) {
        self.sections = sections.count > 0 ? sections : self.sections;
    } else {
        self.sections = sections ?: @[];
    }
    self.continuation = continuation;
    self.loadedOnce = YES;
    self.paginating = NO;
    [self.tableView reloadData];
    [self.refreshControl endRefreshing];
    [self.spinner stopAnimating];
    self.emptyView.hidden = (self.sections.count > 0);
    [self updateBottomInset];
}

- (void)finishLoadingWithError:(NSError *)error
{
    [self.refreshControl endRefreshing];
    [self.spinner stopAnimating];
    self.loadedOnce = YES;
    self.paginating = NO;
    if (self.sections.count == 0) {
        NSString *message = error.localizedDescription ?: @"No se pudo cargar el contenido";
        [self showEmptyMessage:@"Sin conexión" subtitle:message];
    } else if (error) {
        [OTTheme showToast:error.localizedDescription inView:self.view];
    }
}

- (void)showEmptyMessage:(NSString *)title subtitle:(NSString *)subtitle
{
    self.emptyView.hidden = NO;
    __weak typeof(self) weakSelf = self;
    [self.emptyView configureWithIcon:OTIconWifi
                                title:title
                             subtitle:subtitle
                          actionTitle:@"Reintentar"
                               action:^{
        [weakSelf reloadContent];
    }];
}

- (void)showLoadingIndicator:(BOOL)show
{
    self.loading = show;
    if (show) {
        [self.spinner startAnimating];
        self.emptyView.hidden = YES;
    } else {
        [self.spinner stopAnimating];
    }
}

#pragma mark - Tabla

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    OTSection *entry = self.sections[section];
    return entry.style == OTSectionStyleCarousel ? 1 : entry.items.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OTSection *entry = self.sections[indexPath.section];
    return entry.style == OTSectionStyleCarousel ? 206.0 : 64.0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    OTSection *entry = self.sections[section];
    if (entry.title.length == 0) {
        UIView *empty = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, 8.0)];
        empty.backgroundColor = [OTTheme background];
        return empty;
    }
    OTSectionHeaderView *header = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"OTSectionHeader"];
    BOOL showsMore = (entry.browseId.length > 0);
    [header configureWithTitle:entry.title showsMore:showsMore];
    __weak typeof(self) weakSelf = self;
    header.onMore = ^{
        [weakSelf openSection:entry];
    };
    return header;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    OTSection *entry = self.sections[section];
    return entry.title.length > 0 ? 52.0 : 8.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OTSection *section = self.sections[indexPath.section];
    if (section.style == OTSectionStyleCarousel) {
        OTCarouselCell *cell = [tableView dequeueReusableCellWithIdentifier:@"OTCarouselCell" forIndexPath:indexPath];
        [cell setItems:section.items];
        __weak typeof(self) weakSelf = self;
        cell.onSelectItem = ^(OTItem *item) {
            [weakSelf presentItem:item];
        };
        return cell;
    }

    OTItemCell *cell = [tableView dequeueReusableCellWithIdentifier:@"OTItemCell" forIndexPath:indexPath];
    OTItem *item = section.items[indexPath.row];
    [cell configureWithItem:item index:0 showsArtwork:YES];
    if (section.title.length > 0 && [section.title isEqualToString:@"Mejor resultado"]) {
        cell.subtitleLabel.text = item.subtitle;
    }
    [cell setCurrentTrack:[self isCurrentItem:item]];
    __weak typeof(self) weakSelf = self;
    cell.moreHandler = ^(OTItem *selected) {
        [weakSelf showMenuForItem:selected sourceView:cell.moreButton];
    };
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    OTSection *section = self.sections[indexPath.section];
    if (section.style == OTSectionStyleCarousel) {
        return;
    }
    OTItem *item = section.items[indexPath.row];
    if (item.type == OTItemTypeSong || item.type == OTItemTypeVideo) {
        [self playItems:section.items startingAt:item];
    } else {
        [self presentItem:item];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (!self.continuation || self.paginating || self.loading) {
        return;
    }
    CGFloat offset = scrollView.contentOffset.y + scrollView.bounds.size.height;
    if (offset > scrollView.contentSize.height - 500.0) {
        if (self.paginationBlock) {
            self.paginating = YES;
            self.paginationBlock();
        }
    }
}

- (void)handleTrackChanged
{
    [self.tableView reloadData];
}

#pragma mark - Acciones

- (BOOL)isCurrentItem:(OTItem *)item
{
    OTItem *current = [OTPlayer sharedPlayer].currentItem;
    return current && item.itemId.length > 0 && [current.itemId isEqualToString:item.itemId];
}

- (void)playItems:(NSArray<OTItem *> *)items startingAt:(OTItem *)item
{
    NSMutableArray *playable = [NSMutableArray array];
    for (OTItem *entry in items) {
        if (entry.isPlayable) {
            [playable addObject:entry];
        }
    }
    if (playable.count == 0) {
        return;
    }
    [[OTPlayer sharedPlayer] playItem:item inQueue:playable];
}

- (void)presentItem:(OTItem *)item
{
    if (item.type == OTItemTypeSong || item.type == OTItemTypeVideo) {
        [self playItems:@[item] startingAt:item];
        return;
    }
    NSString *browseId = item.browseId.length > 0 ? item.browseId : item.itemId;
    NSString *playlistId = item.playlistId.length > 0 ? item.playlistId : nil;
    if (item.type == OTItemTypePlaylist && playlistId.length == 0) {
        playlistId = browseId;
    }
    [self pushCollectionWithBrowseId:browseId
                              params:item.params
                               title:item.title
                                type:item.type
                          playlistId:playlistId];
}

- (void)pushCollectionWithBrowseId:(NSString *)browseId
                            params:(NSString *)params
                             title:(NSString *)title
                              type:(OTItemType)type
                        playlistId:(NSString *)playlistId
{
    OTCollectionViewController *controller = [[OTCollectionViewController alloc] init];
    controller.browseId = browseId;
    controller.params = params;
    controller.playlistId = playlistId;
    controller.collectionType = type;
    controller.collectionTitle = title;
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)openSection:(OTSection *)section
{
    if (section.browseId.length > 0) {
        OTItemType type = OTItemTypePlaylist;
        if (section.items.count > 0) {
            OTItem *first = section.items[0];
            type = first.type;
            if (type == OTItemTypeSong) {
                type = OTItemTypePlaylist;
            }
        }
        NSString *playlistId = nil;
        if (type == OTItemTypePlaylist) {
            playlistId = section.browseId;
        }
        [self pushCollectionWithBrowseId:section.browseId
                                  params:section.params
                                   title:section.title
                                    type:type
                              playlistId:playlistId];
        return;
    }
    if (section.items.count > 0) {
        [self playItems:section.items startingAt:section.items[0]];
    }
}

#pragma mark - Menu

- (void)showMenuForItem:(OTItem *)item sourceView:(UIView *)sourceView
{
    if (!item) {
        return;
    }
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:item.title
                                                                  message:[item displaySubtitle]
                                                           preferredStyle:UIAlertControllerStyleActionSheet];
    __weak typeof(self) weakSelf = self;

    if (item.isPlayable) {
        [sheet addAction:[UIAlertAction actionWithTitle:@"Reproducir"
                                                   style:UIAlertActionStyleDefault
                                                 handler:^(UIAlertAction *action) {
            [weakSelf playItems:@[item] startingAt:item];
        }]];
        [sheet addAction:[UIAlertAction actionWithTitle:@"Añadir a la cola"
                                                   style:UIAlertActionStyleDefault
                                                 handler:^(UIAlertAction *action) {
            [[OTPlayer sharedPlayer] addToQueue:item];
            [OTTheme showToast:@"Añadido a la cola" inView:weakSelf.view];
        }]];
    }

    [sheet addAction:[UIAlertAction actionWithTitle:@"Añadir a lista de reproducción"
                                               style:UIAlertActionStyleDefault
                                             handler:^(UIAlertAction *action) {
        [weakSelf showPlaylistPickerForItem:item];
    }]];

    BOOL favorite = [[OTStore sharedStore] isFavorite:item];
    [sheet addAction:[UIAlertAction actionWithTitle:(favorite ? @"Quitar de favoritos" : @"Añadir a favoritos")
                                               style:UIAlertActionStyleDefault
                                             handler:^(UIAlertAction *action) {
        BOOL added = [[OTStore sharedStore] toggleFavorite:item];
        [OTTheme showToast:(added ? @"Añadido a favoritos" : @"Quitado de favoritos") inView:weakSelf.view];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"OTLibraryDidChangeNotification" object:nil];
    }]];

    BOOL downloaded = [[OTStore sharedStore] isDownloaded:item];
    if (item.isPlayable) {
        if (downloaded) {
            [sheet addAction:[UIAlertAction actionWithTitle:@"Eliminar descarga"
                                                       style:UIAlertActionStyleDestructive
                                                     handler:^(UIAlertAction *action) {
                [[OTStore sharedStore] removeDownloadForItem:item];
                [OTTheme showToast:@"Descarga eliminada" inView:weakSelf.view];
            }]];
        } else {
            [sheet addAction:[UIAlertAction actionWithTitle:@"Descargar"
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction *action) {
                [weakSelf downloadItem:item];
            }]];
        }
        [sheet addAction:[UIAlertAction actionWithTitle:@"Compartir"
                                                   style:UIAlertActionStyleDefault
                                                 handler:^(UIAlertAction *action) {
            [weakSelf shareItem:item sourceView:sourceView];
        }]];
    }

    [sheet addAction:[UIAlertAction actionWithTitle:@"Cancelar" style:UIAlertActionStyleCancel handler:nil]];

    if (sheet.popoverPresentationController) {
        sheet.popoverPresentationController.sourceView = sourceView ?: self.view;
        sheet.popoverPresentationController.sourceRect = sourceView ? sourceView.bounds : self.view.bounds;
    }
    [self presentViewController:sheet animated:YES completion:nil];
}

- (void)showPlaylistPickerForItem:(OTItem *)item
{
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:@"Añadir a lista"
                                                                  message:item.title
                                                           preferredStyle:UIAlertControllerStyleActionSheet];
    __weak typeof(self) weakSelf = self;
    for (OTPlaylist *playlist in [[OTStore sharedStore] playlists]) {
        [sheet addAction:[UIAlertAction actionWithTitle:playlist.name
                                                   style:UIAlertActionStyleDefault
                                                 handler:^(UIAlertAction *action) {
            BOOL added = [[OTStore sharedStore] addItem:item toPlaylistWithId:playlist.playlistId];
            [OTTheme showToast:(added ? @"Añadido a la lista" : @"Ya estaba en la lista") inView:weakSelf.view];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"OTLibraryDidChangeNotification" object:nil];
        }]];
    }
    [sheet addAction:[UIAlertAction actionWithTitle:@"Nueva lista…"
                                               style:UIAlertActionStyleDefault
                                             handler:^(UIAlertAction *action) {
        [weakSelf promptNewPlaylistWithItem:item];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:@"Cancelar" style:UIAlertActionStyleCancel handler:nil]];

    if (sheet.popoverPresentationController) {
        sheet.popoverPresentationController.sourceView = self.view;
        sheet.popoverPresentationController.sourceRect = CGRectMake(self.view.bounds.size.width / 2.0,
                                                                    self.view.bounds.size.height / 2.0, 1, 1);
    }
    [self presentViewController:sheet animated:YES completion:nil];
}

- (void)promptNewPlaylistWithItem:(OTItem *)item
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Nueva lista"
                                                                    message:@"Ponle un nombre"
                                                             preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"Mi lista";
    }];
    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:@"Crear" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSString *name = alert.textFields.firstObject.text;
        OTPlaylist *playlist = [[OTStore sharedStore] createPlaylistNamed:name];
        [[OTStore sharedStore] addItem:item toPlaylistWithId:playlist.playlistId];
        [OTTheme showToast:@"Lista creada" inView:weakSelf.view];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"OTLibraryDidChangeNotification" object:nil];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancelar" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)downloadItem:(OTItem *)item
{
    [OTTheme showToast:@"Descargando…" inView:self.view];
    __weak typeof(self) weakSelf = self;
    [[OTDownloads sharedDownloads] downloadItem:item progress:nil completion:^(BOOL success, NSError *error, NSString *path) {
        if (success) {
            [OTTheme showToast:@"Descarga completada" inView:weakSelf.view];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"OTLibraryDidChangeNotification" object:nil];
        } else {
            [OTTheme showToast:(error.localizedDescription ?: @"No se pudo descargar") inView:weakSelf.view];
        }
    }];
}

- (void)shareItem:(OTItem *)item sourceView:(UIView *)sourceView
{
    NSString *urlString = [NSString stringWithFormat:@"https://music.youtube.com/watch?v=%@", item.itemId];
    NSURL *url = [NSURL URLWithString:urlString];
    if (!url) {
        return;
    }
    UIActivityViewController *activity = [[UIActivityViewController alloc] initWithActivityItems:@[url]
                                                                           applicationActivities:nil];
    if (activity.popoverPresentationController) {
        activity.popoverPresentationController.sourceView = sourceView ?: self.view;
        activity.popoverPresentationController.sourceRect = sourceView ? sourceView.bounds : self.view.bounds;
    }
    [self presentViewController:activity animated:YES completion:nil];
}

#pragma mark - Insets

- (void)updateBottomInset
{
    if (!self.isViewLoaded) {
        return;
    }
    CGFloat inset = OTBottomInset();
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, inset, 0);
    self.tableView.scrollIndicatorInsets = self.tableView.contentInset;
}

@end

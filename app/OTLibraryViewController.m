//
//  OTLibraryViewController.m
//  OpenTune 9
//

#import "OTLibraryViewController.h"
#import "OTTheme.h"
#import "OTStore.h"
#import "OTPlayer.h"
#import "OTRootViewController.h"
#import "OTSettingsViewController.h"
#import "OTComponents.h"

typedef NS_ENUM(NSInteger, OTLibraryTab) {
    OTLibraryTabFavorites = 0,
    OTLibraryTabDownloads,
    OTLibraryTabPlaylists,
    OTLibraryTabHistory,
    OTLibraryTabStats
};

@interface OTLibraryViewController () <UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic, strong) OTAppBarView *appBar;
@property (nonatomic, strong) OTChipsView *chipsView;
@property (nonatomic, assign) OTLibraryTab tab;

@property (nonatomic, strong) UIView *headerContainer;
@property (nonatomic, strong) UIView *sortCard;
@property (nonatomic, strong) UILabel *sortLabel;
@property (nonatomic, strong) UIButton *reverseButton;
@property (nonatomic, strong) UICollectionView *quickGrid;

@property (nonatomic, assign) NSInteger sortMode;
@property (nonatomic, assign) BOOL sortAscending;
@property (nonatomic, assign) CGFloat headerHeight;

@end

@implementation OTLibraryViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.screenTitle = @"Biblioteca";
        _tab = OTLibraryTabFavorites;
        _sortMode = 0;
        _sortAscending = NO;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.topTitleLabel.hidden = YES;

    self.appBar = [[OTAppBarView alloc] initWithTitle:@"OpenTune" showsLogo:YES];
    [self.appBar addButtonWithIcon:OTIconHistory target:self action:@selector(openHistory)];
    [self.appBar addButtonWithIcon:OTIconStats target:self action:@selector(openStats)];
    [self.appBar addButtonWithIcon:OTIconBell target:self action:@selector(openNotifications)];
    [self.appBar addButtonWithIcon:OTIconPlus target:self action:@selector(createPlaylist)];
    [self.appBar addAvatarWithTarget:self action:@selector(openSettings)];
    [self.topBar addSubview:self.appBar];

    self.chipsView = [[OTChipsView alloc] initWithFrame:CGRectZero];
    [self.chipsView setTitles:@[@"Favoritos", @"Descargas", @"Listas", @"Historial", @"Mi top"]
                        icons:@[@(OTIconHeart), @(OTIconDownload), @(OTIconPlaylist),
                                @(OTIconHistory), @(OTIconTrending)]
                selectedIndex:self.tab];
    __weak typeof(self) weakSelf = self;
    self.chipsView.onSelect = ^(NSInteger index) {
        [weakSelf selectTab:(OTLibraryTab)index];
    };
    [self.view addSubview:self.chipsView];

    [self buildHeader];

    self.rightButton.hidden = YES;

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(libraryChanged)
                                                 name:@"OTLibraryDidChangeNotification"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(selectTabFromNotification:)
                                                 name:OTLibrarySelectTabNotification
                                               object:nil];

    [self reloadContent];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self reloadContent];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    CGFloat width = self.view.bounds.size.width;
    CGFloat top = self.topLayoutGuide.length;
    self.appBar.frame = self.topBar.bounds;
    self.chipsView.frame = CGRectMake(0, top + 60.0, width, 48.0);
    CGFloat tableY = top + 108.0;
    self.tableView.frame = CGRectMake(0, tableY, width, self.view.bounds.size.height - tableY);
    self.emptyView.frame = CGRectMake(0, tableY, width, self.view.bounds.size.height - tableY - 80.0);
    self.spinner.center = CGPointMake(width / 2.0, self.view.bounds.size.height / 2.0);
    [self layoutHeaderForWidth:width];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Cabecera (orden + tarjetas rapidas)

- (void)buildHeader
{
    self.headerContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 300.0)];
    self.headerContainer.backgroundColor = [OTTheme background];

    self.sortCard = [[UIView alloc] initWithFrame:CGRectZero];
    [OTTheme styleCard:self.sortCard radius:18.0];
    [self.headerContainer addSubview:self.sortCard];

    self.sortLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.sortLabel.font = [OTTheme titleMedium];
    self.sortLabel.textColor = [OTTheme primary];
    self.sortLabel.text = @"Fecha añadida";
    [self.sortCard addSubview:self.sortLabel];

    UIImageView *sortIcon = [[UIImageView alloc] initWithFrame:CGRectZero];
    sortIcon.image = [OTTheme icon:OTIconChevronDown size:18];
    sortIcon.tintColor = [OTTheme primary];
    sortIcon.tag = 2;
    sortIcon.contentMode = UIViewContentModeScaleAspectFit;
    [self.sortCard addSubview:sortIcon];

    self.reverseButton = [OTTheme iconButton:OTIconLock size:20
                                       color:[OTTheme secondaryText]
                                      target:self
                                      action:@selector(toggleSortDirection)];
    [self.sortCard addSubview:self.reverseButton];

    UIControl *sortTap = [[UIControl alloc] initWithFrame:CGRectZero];
    sortTap.tag = 3;
    [sortTap addTarget:self action:@selector(showSortOptions) forControlEvents:UIControlEventTouchUpInside];
    [self.sortCard addSubview:sortTap];

    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionVertical;
    layout.minimumLineSpacing = 12.0;
    layout.minimumInteritemSpacing = 12.0;
    layout.sectionInset = UIEdgeInsetsMake(0, 16, 0, 16);
    self.quickGrid = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    self.quickGrid.backgroundColor = [OTTheme background];
    self.quickGrid.scrollEnabled = NO;
    self.quickGrid.dataSource = self;
    self.quickGrid.delegate = self;
    [self.quickGrid registerClass:[OTQuickCardCell class] forCellWithReuseIdentifier:@"OTQuickCardCell"];
    [self.headerContainer addSubview:self.quickGrid];

    self.tableHeaderView = self.headerContainer;
}

- (void)layoutHeaderForWidth:(CGFloat)width
{
    CGFloat side = 16.0;
    CGFloat sortHeight = 58.0;
    CGFloat gridWidth = width - side * 2.0;
    CGFloat itemWidth = (gridWidth - 12.0) / 2.0;
    CGFloat itemHeight = 124.0;
    CGFloat gridHeight = itemHeight * 2.0 + 12.0;
    CGFloat height = 12.0 + sortHeight + 14.0 + gridHeight + 8.0;

    self.sortCard.frame = CGRectMake(side, 12.0, gridWidth, sortHeight);
    self.sortLabel.frame = CGRectMake(20.0, 0, gridWidth - 140.0, sortHeight);
    UIImageView *sortIcon = (UIImageView *)[self.sortCard viewWithTag:2];
    CGSize labelSize = [self.sortLabel sizeThatFits:CGSizeMake(gridWidth - 140.0, sortHeight)];
    sortIcon.frame = CGRectMake(20.0 + labelSize.width + 8.0, (sortHeight - 18.0) / 2.0, 18.0, 18.0);
    self.reverseButton.frame = CGRectMake(gridWidth - 52.0, 7.0, 44.0, 44.0);
    UIControl *sortTap = (UIControl *)[self.sortCard viewWithTag:3];
    sortTap.frame = CGRectMake(0, 0, gridWidth - 60.0, sortHeight);

    self.quickGrid.frame = CGRectMake(side, 12.0 + sortHeight + 14.0, gridWidth, gridHeight);
    UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)self.quickGrid.collectionViewLayout;
    layout.itemSize = CGSizeMake(itemWidth, itemHeight);
    [layout invalidateLayout];

    if (fabs(height - self.headerHeight) > 0.5) {
        self.headerHeight = height;
        CGRect frame = self.headerContainer.frame;
        frame.size.width = width;
        frame.size.height = height;
        self.headerContainer.frame = frame;
        self.tableView.tableHeaderView = self.headerContainer;
    }
}

#pragma mark - Pestanas

- (void)libraryChanged
{
    [self reloadContent];
}

- (void)selectTabFromNotification:(NSNotification *)notification
{
    NSInteger index = [notification.userInfo[@"index"] integerValue];
    if (index < 0 || index > 4) {
        return;
    }
    [self.chipsView selectIndex:index animated:YES];
    [self selectTab:(OTLibraryTab)index];
}

- (void)selectTab:(OTLibraryTab)tab
{
    if (tab == self.tab) {
        return;
    }
    self.tab = tab;
    [self reloadContent];
}

#pragma mark - Contenido

- (NSArray<OTItem *> *)sortedItems:(NSArray<OTItem *> *)items
{
    NSMutableArray *result = [items mutableCopy];
    if (self.sortMode == 1) {
        [result sortUsingComparator:^NSComparisonResult(OTItem *a, OTItem *b) {
            return [a.title localizedCaseInsensitiveCompare:b.title];
        }];
    } else if (self.sortMode == 2) {
        [result sortUsingComparator:^NSComparisonResult(OTItem *a, OTItem *b) {
            return [[a displaySubtitle] localizedCaseInsensitiveCompare:[b displaySubtitle]];
        }];
    }
    if (self.sortAscending) {
        return [[result reverseObjectEnumerator] allObjects];
    }
    return result;
}

- (void)loadContent
{
    OTStore *store = [OTStore sharedStore];
    NSMutableArray<OTSection *> *sections = [NSMutableArray array];
    NSString *emptyTitle = nil;
    NSString *emptySubtitle = nil;
    OTIcon emptyIcon = OTIconHeart;

    switch (self.tab) {
        case OTLibraryTabFavorites: {
            NSArray<OTItem *> *items = [self sortedItems:[store favoriteItems]];
            if (items.count > 0) {
                [sections addObject:[OTSection sectionWithTitle:@"Canciones que te gustan"
                                                          items:items
                                                          style:OTSectionStyleList]];
            } else {
                emptyTitle = @"Aún no hay favoritos";
                emptySubtitle = @"Toca el corazón de una canción para guardarla aquí.";
                emptyIcon = OTIconHeart;
            }
            break;
        }
        case OTLibraryTabDownloads: {
            NSArray<OTItem *> *items = [self sortedItems:[store downloadedItems]];
            if (items.count > 0) {
                NSString *title = [NSString stringWithFormat:@"Descargas · %@",
                                   [OTTheme formatBytes:[store downloadsSize]]];
                [sections addObject:[OTSection sectionWithTitle:title
                                                          items:items
                                                          style:OTSectionStyleList]];
            } else {
                emptyTitle = @"Sin descargas";
                emptySubtitle = @"Las canciones que descargues aparecerán aquí.";
                emptyIcon = OTIconDownload;
            }
            break;
        }
        case OTLibraryTabPlaylists: {
            NSArray<OTPlaylist *> *playlists = [store playlists];
            NSMutableArray<OTItem *> *items = [NSMutableArray array];
            for (OTPlaylist *playlist in playlists) {
                OTItem *item = [[OTItem alloc] init];
                item.itemId = playlist.playlistId;
                item.browseId = playlist.playlistId;
                item.playlistId = playlist.playlistId;
                item.title = playlist.name;
                item.subtitle = [NSString stringWithFormat:@"%lu %@",
                                 (unsigned long)playlist.items.count,
                                 playlist.items.count == 1 ? @"canción" : @"canciones"];
                item.type = OTItemTypePlaylist;
                NSMutableArray *urls = [NSMutableArray array];
                for (OTItem *track in playlist.items) {
                    if (track.thumbnailURL.length > 0) {
                        [urls addObject:track.thumbnailURL];
                    }
                    if (urls.count >= 4) {
                        break;
                    }
                }
                item.mosaicURLs = urls;
                if (playlist.items.count > 0) {
                    item.thumbnailURL = playlist.items.firstObject.thumbnailURL;
                }
                [items addObject:item];
            }
            if (items.count > 0) {
                [sections addObject:[OTSection sectionWithTitle:@"Tus listas"
                                                          items:items
                                                          style:OTSectionStyleList]];
            } else {
                emptyTitle = @"Sin listas de reproducción";
                emptySubtitle = @"Crea tu primera lista con el botón +.";
                emptyIcon = OTIconPlaylist;
            }
            break;
        }
        case OTLibraryTabHistory: {
            NSArray<OTItem *> *items = [self sortedItems:[store historyItems]];
            if (items.count > 0) {
                [sections addObject:[OTSection sectionWithTitle:@"Escuchado recientemente"
                                                          items:items
                                                          style:OTSectionStyleList]];
            } else {
                emptyTitle = @"Sin historial";
                emptySubtitle = @"Las canciones que escuches aparecerán aquí.";
                emptyIcon = OTIconClock;
            }
            break;
        }
        case OTLibraryTabStats: {
            NSArray<NSDictionary *> *top = [store topItems:20];
            NSMutableArray<OTItem *> *items = [NSMutableArray array];
            for (NSDictionary *entry in top) {
                OTItem *item = [[OTItem alloc] init];
                item.itemId = OTSafeString(entry[@"itemId"]);
                item.title = OTSafeString(entry[@"title"]);
                item.artistsText = OTSafeString(entry[@"artist"]);
                item.subtitle = OTSafeString(entry[@"artist"]);
                item.thumbnailURL = OTSafeString(entry[@"thumbnail"]);
                item.type = OTItemTypeSong;
                NSInteger count = [entry[@"count"] integerValue];
                item.playsText = [NSString stringWithFormat:@"%ld %@",
                                  (long)count,
                                  count == 1 ? @"reproducción" : @"reproducciones"];
                [items addObject:item];
            }
            if (items.count > 0) {
                [sections addObject:[OTSection sectionWithTitle:
                                   [NSString stringWithFormat:@"Más escuchadas · %ld reproducciones",
                                    (long)[store totalPlays]]
                                                          items:items
                                                          style:OTSectionStyleList]];
            } else {
                emptyTitle = @"Sin estadísticas";
                emptySubtitle = @"Escucha música para ver aquí tus canciones más reproducidas.";
                emptyIcon = OTIconStats;
            }
            break;
        }
    }

    [self setFeedSections:sections continuation:nil append:NO];

    if (sections.count == 0) {
        self.emptyView.hidden = NO;
        [self.emptyView configureWithIcon:emptyIcon
                                    title:emptyTitle
                                 subtitle:emptySubtitle
                              actionTitle:nil
                                   action:nil];
    } else {
        self.emptyView.hidden = YES;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    OTSection *section = self.sections[indexPath.section];
    if (section.style == OTSectionStyleList) {
        OTItem *item = section.items[indexPath.row];
        if (item.playsText.length > 0 && [cell isKindOfClass:[OTItemCell class]]) {
            OTItemCell *itemCell = (OTItemCell *)cell;
            itemCell.subtitleLabel.text = item.playsText;
        }
    }
    return cell;
}

#pragma mark - Tarjetas rapidas

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return 4;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    OTQuickCardCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"OTQuickCardCell"
                                                                     forIndexPath:indexPath];
    NSArray *titles = @[@"Favorito", @"Descargado", @"En caché", @"Mi top 50"];
    NSArray *icons = @[@(OTIconHeart), @(OTIconDone), @(OTIconSync), @(OTIconTrending)];
    NSArray *tints = @[[OTTheme primary], [OTTheme secondary], [OTTheme tertiary], [OTTheme error]];
    [cell configureWithTitle:titles[indexPath.item]
                        icon:[icons[indexPath.item] integerValue]
                        tint:tints[indexPath.item]];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *targets = @[@(OTLibraryTabFavorites), @(OTLibraryTabDownloads),
                         @(OTLibraryTabDownloads), @(OTLibraryTabStats)];
    NSInteger index = [targets[indexPath.item] integerValue];
    [self.chipsView selectIndex:index animated:YES];
    [self selectTab:(OTLibraryTab)index];
}

#pragma mark - Orden

- (void)showSortOptions
{
    NSArray *names = @[@"Fecha añadida", @"Título", @"Artista"];
    __weak typeof(self) weakSelf = self;
    NSMutableArray<OTSheetAction *> *actions = [NSMutableArray array];
    for (NSInteger i = 0; i < (NSInteger)names.count; i++) {
        OTSheetAction *action = [OTSheetAction actionWithTitle:names[i]
                                                          icon:OTIconSort
                                                       handler:^{
            weakSelf.sortMode = i;
            weakSelf.sortLabel.text = names[i];
            [weakSelf reloadContent];
        }];
        action.selected = (i == self.sortMode);
        [actions addObject:action];
    }
    [actions addObject:[OTSheetAction actionWithTitle:@"Cancelar" icon:OTIconClose handler:nil]];
    OTSheetViewController *sheet = [OTSheetViewController sheetWithTitle:@"Ordenar por"
                                                                subtitle:nil
                                                                 actions:actions];
    [sheet presentFrom:self];
}

- (void)toggleSortDirection
{
    self.sortAscending = !self.sortAscending;
    [OTTheme showToast:(self.sortAscending ? @"Orden ascendente" : @"Orden descendente") inView:self.view];
    [self reloadContent];
}

#pragma mark - Edicion

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.tab == OTLibraryTabFavorites ||
        self.tab == OTLibraryTabDownloads ||
        self.tab == OTLibraryTabPlaylists) {
        return YES;
    }
    return NO;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle != UITableViewCellEditingStyleDelete) {
        return;
    }
    OTSection *section = self.sections[indexPath.section];
    OTItem *item = section.items[indexPath.row];
    OTStore *store = [OTStore sharedStore];
    if (self.tab == OTLibraryTabFavorites) {
        [store toggleFavorite:item];
    } else if (self.tab == OTLibraryTabDownloads) {
        [store removeDownloadForItem:item];
    } else if (self.tab == OTLibraryTabPlaylists) {
        [store deletePlaylistWithId:item.playlistId];
    }
    [self reloadContent];
}

#pragma mark - Acciones

- (void)createPlaylist
{
    __weak typeof(self) weakSelf = self;
    OTDialogViewController *dialog =
        [OTDialogViewController promptWithTitle:@"Nueva lista"
                                        message:@"Ponle un nombre"
                                    placeholder:@"Mi lista"
                                          value:nil
                                   confirmTitle:@"Crear"
                                     completion:^(NSString *text) {
        NSString *name = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (name.length == 0) {
            name = @"Mi lista";
        }
        [[OTStore sharedStore] createPlaylistNamed:name];
        [weakSelf reloadContent];
        [OTTheme showToast:@"Lista creada" inView:weakSelf.view];
    }];
    [dialog presentFrom:self];
}

- (void)openHistory
{
    [self.chipsView selectIndex:3 animated:YES];
    [self selectTab:OTLibraryTabHistory];
}

- (void)openStats
{
    [self.chipsView selectIndex:4 animated:YES];
    [self selectTab:OTLibraryTabStats];
}

- (void)openNotifications
{
    [OTTheme showToast:@"No tienes notificaciones nuevas" inView:self.view];
}

- (void)openSettings
{
    OTSettingsViewController *settings = [[OTSettingsViewController alloc] init];
    [self.navigationController pushViewController:settings animated:YES];
}

@end

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

typedef NS_ENUM(NSInteger, OTLibraryTab) {
    OTLibraryTabFavorites = 0,
    OTLibraryTabDownloads,
    OTLibraryTabPlaylists,
    OTLibraryTabHistory,
    OTLibraryTabStats
};

@interface OTLibraryViewController ()

@property (nonatomic, strong) OTChipsView *chipsView;
@property (nonatomic, assign) OTLibraryTab tab;

@end

@implementation OTLibraryViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.screenTitle = @"Biblioteca";
        _tab = OTLibraryTabFavorites;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.chipsView = [[OTChipsView alloc] initWithFrame:CGRectZero];
    [self.chipsView setTitles:@[@"Favoritos", @"Descargas", @"Listas", @"Historial", @"Estadísticas"]
                selectedIndex:self.tab];
    __weak typeof(self) weakSelf = self;
    self.chipsView.onSelect = ^(NSInteger index) {
        [weakSelf selectTab:(OTLibraryTab)index];
    };
    [self.view addSubview:self.chipsView];

    self.rightButton.hidden = NO;
    [self updateRightButton];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(libraryChanged)
                                                 name:@"OTLibraryDidChangeNotification"
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
    CGFloat top = self.topLayoutGuide.length + 56.0;
    self.chipsView.frame = CGRectMake(0, top, width, 44.0);
    CGFloat tableY = top + 44.0;
    self.tableView.frame = CGRectMake(0, tableY, width, self.view.bounds.size.height - tableY);
    self.emptyView.frame = CGRectMake(0, tableY, width, self.view.bounds.size.height - tableY - 80.0);
    self.spinner.center = CGPointMake(width / 2.0, self.view.bounds.size.height / 2.0);
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)libraryChanged
{
    [self reloadContent];
}

- (void)updateRightButton
{
    [self.rightButton removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
    if (self.tab == OTLibraryTabPlaylists) {
        [self.rightButton setImage:[OTTheme icon:OTIconPlus size:22] forState:UIControlStateNormal];
        [self.rightButton addTarget:self action:@selector(createPlaylist) forControlEvents:UIControlEventTouchUpInside];
    } else {
        [self.rightButton setImage:[OTTheme icon:OTIconSettings size:22] forState:UIControlStateNormal];
        [self.rightButton addTarget:self action:@selector(openSettings) forControlEvents:UIControlEventTouchUpInside];
    }
}

- (void)selectTab:(OTLibraryTab)tab
{
    if (tab == self.tab) {
        return;
    }
    self.tab = tab;
    [self updateRightButton];
    [self reloadContent];
}

#pragma mark - Contenido

- (void)loadContent
{
    OTStore *store = [OTStore sharedStore];
    NSMutableArray<OTSection *> *sections = [NSMutableArray array];
    NSString *emptyTitle = nil;
    NSString *emptySubtitle = nil;
    OTIcon emptyIcon = OTIconHeart;

    switch (self.tab) {
        case OTLibraryTabFavorites: {
            NSArray<OTItem *> *items = [store favoriteItems];
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
            NSArray<OTItem *> *items = [store downloadedItems];
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
            NSArray<OTItem *> *items = [store historyItems];
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
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Nueva lista"
                                                                    message:@"Ponle un nombre"
                                                             preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"Mi lista";
        textField.autocapitalizationType = UITextAutocapitalizationTypeSentences;
    }];
    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:@"Crear" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSString *name = alert.textFields.firstObject.text;
        if (name.length == 0) {
            name = @"Mi lista";
        }
        [[OTStore sharedStore] createPlaylistNamed:name];
        [weakSelf reloadContent];
        [OTTheme showToast:@"Lista creada" inView:weakSelf.view];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancelar" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)openSettings
{
    OTSettingsViewController *settings = [[OTSettingsViewController alloc] init];
    [self.navigationController pushViewController:settings animated:YES];
}

@end

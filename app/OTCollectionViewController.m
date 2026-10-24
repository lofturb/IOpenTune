//
//  OTCollectionViewController.m
//  OpenTune 9
//

#import "OTCollectionViewController.h"
#import "OTTheme.h"
#import "OTInnertube.h"
#import "OTStore.h"
#import "OTPlayer.h"
#import "OTDownloads.h"
#import "OTRootViewController.h"

@interface OTCollectionViewController ()

@property (nonatomic, strong) OTHeaderView *headerView;
@property (nonatomic, strong) OTItem *headerItem;

@end

@implementation OTCollectionViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        _collectionType = OTItemTypePlaylist;
        _collectionTitle = @"";
        _screenTitle = @"";
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.screenTitle = @"";
    self.leftButton.hidden = NO;
    self.rightButton.hidden = YES;

    self.headerView = [[OTHeaderView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 276.0)];
    [self.headerView.playButton addTarget:self action:@selector(playAll) forControlEvents:UIControlEventTouchUpInside];
    [self.headerView.shuffleButton addTarget:self action:@selector(shuffleAll) forControlEvents:UIControlEventTouchUpInside];
    [self.headerView.downloadButton addTarget:self action:@selector(downloadAll) forControlEvents:UIControlEventTouchUpInside];
    [self.headerView.moreButton addTarget:self action:@selector(showHeaderMenu) forControlEvents:UIControlEventTouchUpInside];

    [self reloadContent];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    if (self.headerView.superview == self.tableView) {
        CGFloat width = self.view.bounds.size.width;
        self.headerView.frame = CGRectMake(0, 0, width, [self.headerView preferredHeightForWidth:width]);
    }
}

#pragma mark - Carga

- (BOOL)isLocalPlaylist
{
    return [self.playlistId hasPrefix:@"local-"];
}

- (void)loadContent
{
    if (self.isLocalPlaylist) {
        [self loadLocalPlaylist];
        return;
    }

    if (!self.loadedOnce) {
        [self showLoadingIndicator:YES];
    }

    NSString *browseId = self.browseId;
    if (self.collectionType == OTItemTypePlaylist && self.playlistId.length > 0) {
        browseId = [self.playlistId hasPrefix:@"VL"] ? self.playlistId : [@"VL" stringByAppendingString:self.playlistId];
    }
    if (browseId.length == 0) {
        [self finishLoadingWithError:[NSError errorWithDomain:@"OpenTune"
                                                        code:1
                                                    userInfo:@{NSLocalizedDescriptionKey: @"Contenido sin identificador"}]];
        return;
    }

    __weak typeof(self) weakSelf = self;
    [[OTInnertube shared] browse:browseId params:self.params completion:^(NSDictionary *json, NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        if (error) {
            [strongSelf finishLoadingWithError:error];
            return;
        }
        OTItem *header = OTParseCollectionHeader(json, strongSelf.collectionType);
        if (!header) {
            header = [[OTItem alloc] init];
            header.title = strongSelf.collectionTitle;
            header.type = strongSelf.collectionType;
        }
        [strongSelf installHeaderWithItem:header];
        NSArray<OTSection *> *sections = OTParseSections(json);
        [strongSelf setFeedSections:sections continuation:OTContinuationFromJSON(json) append:NO];
        if (sections.count == 0) {
            [strongSelf showEmptyMessage:@"Contenido vacío" subtitle:@"No hay nada que mostrar aquí."];
        }
        strongSelf.paginationBlock = ^{
            [strongSelf loadMore];
        };
    }];
}

- (void)loadLocalPlaylist
{
    OTPlaylist *playlist = [[OTStore sharedStore] playlistWithId:self.playlistId];
    if (!playlist) {
        [self finishLoadingWithError:[NSError errorWithDomain:@"OpenTune"
                                                        code:2
                                                    userInfo:@{NSLocalizedDescriptionKey: @"La lista ya no existe"}]];
        return;
    }

    OTItem *header = [[OTItem alloc] init];
    header.title = playlist.name;
    header.subtitle = [NSString stringWithFormat:@"%lu %@",
                       (unsigned long)playlist.items.count,
                       playlist.items.count == 1 ? @"canción" : @"canciones"];
    header.artistsText = header.subtitle;
    header.type = OTItemTypePlaylist;
    if (playlist.items.count > 0) {
        header.thumbnailURL = playlist.items.firstObject.thumbnailURL;
    }
    [self installHeaderWithItem:header];

    if (playlist.items.count > 0) {
        OTSection *section = [OTSection sectionWithTitle:@"Canciones"
                                                    items:playlist.items
                                                    style:OTSectionStyleList];
        [self setFeedSections:@[section] continuation:nil append:NO];
    } else {
        [self setFeedSections:@[] continuation:nil append:NO];
        [self showEmptyMessage:@"Lista vacía"
                     subtitle:@"Añade canciones desde el menú de cualquier canción."];
    }
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
        [strongSelf setFeedSections:OTParseSections(json)
                       continuation:OTContinuationFromJSON(json)
                             append:YES];
    }];
}

- (void)installHeaderWithItem:(OTItem *)item
{
    self.headerItem = item;
    if (item.title.length == 0) {
        item.title = self.collectionTitle;
    }
    [self.headerView configureWithItem:item type:self.collectionType];
    self.headerView.frame = CGRectMake(0, 0, self.view.bounds.size.width,
                                       [self.headerView preferredHeightForWidth:self.view.bounds.size.width]);
    self.tableHeaderView = self.headerView;
}

#pragma mark - Reproduccion

- (NSArray<OTItem *> *)allPlayableItems
{
    NSMutableArray *items = [NSMutableArray array];
    NSMutableSet *seen = [NSMutableSet set];
    for (OTSection *section in self.sections) {
        for (OTItem *item in section.items) {
            if (!item.isPlayable || item.itemId.length == 0) {
                continue;
            }
            if ([seen containsObject:item.itemId]) {
                continue;
            }
            [seen addObject:item.itemId];
            [items addObject:item];
        }
    }
    return items;
}

- (void)playAll
{
    NSArray *items = [self allPlayableItems];
    if (items.count == 0) {
        [OTTheme showToast:@"No hay canciones para reproducir" inView:self.view];
        return;
    }
    [OTPlayer sharedPlayer].shuffle = NO;
    [[OTPlayer sharedPlayer] setQueue:items startIndex:0];
}

- (void)shuffleAll
{
    NSArray *items = [self allPlayableItems];
    if (items.count == 0) {
        [OTTheme showToast:@"No hay canciones para reproducir" inView:self.view];
        return;
    }
    [OTPlayer sharedPlayer].shuffle = YES;
    NSInteger start = items.count > 1 ? arc4random_uniform((uint32_t)items.count) : 0;
    [[OTPlayer sharedPlayer] setQueue:items startIndex:start];
}

- (void)downloadAll
{
    NSArray *items = [self allPlayableItems];
    if (items.count == 0) {
        [OTTheme showToast:@"No hay canciones para descargar" inView:self.view];
        return;
    }
    [OTTheme showToast:[NSString stringWithFormat:@"Descargando %lu canciones…", (unsigned long)items.count]
                inView:self.view];
    [self downloadItems:items atIndex:0];
}

- (void)downloadItems:(NSArray<OTItem *> *)items atIndex:(NSInteger)index
{
    if (index >= (NSInteger)items.count) {
        [OTTheme showToast:@"Descargas completadas" inView:self.view];
        return;
    }
    OTItem *item = items[index];
    if ([[OTStore sharedStore] isDownloaded:item]) {
        [self downloadItems:items atIndex:index + 1];
        return;
    }
    __weak typeof(self) weakSelf = self;
    [[OTDownloads sharedDownloads] downloadItem:item progress:nil completion:^(BOOL success, NSError *error, NSString *path) {
        [weakSelf downloadItems:items atIndex:index + 1];
    }];
}

- (void)showHeaderMenu
{
    OTItem *item = self.headerItem;
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:item.title
                                                                  message:[item displaySubtitle]
                                                           preferredStyle:UIAlertControllerStyleActionSheet];
    __weak typeof(self) weakSelf = self;
    [sheet addAction:[UIAlertAction actionWithTitle:@"Añadir todo a la cola"
                                               style:UIAlertActionStyleDefault
                                             handler:^(UIAlertAction *action) {
        NSArray *items = [weakSelf allPlayableItems];
        for (OTItem *entry in items) {
            [[OTPlayer sharedPlayer] addToQueue:entry];
        }
        [OTTheme showToast:@"Añadido a la cola" inView:weakSelf.view];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:@"Descargar todo"
                                               style:UIAlertActionStyleDefault
                                             handler:^(UIAlertAction *action) {
        [weakSelf downloadAll];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:@"Compartir"
                                               style:UIAlertActionStyleDefault
                                             handler:^(UIAlertAction *action) {
        [weakSelf shareCollection];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:@"Cancelar" style:UIAlertActionStyleCancel handler:nil]];
    if (sheet.popoverPresentationController) {
        sheet.popoverPresentationController.sourceView = self.headerView.moreButton;
        sheet.popoverPresentationController.sourceRect = self.headerView.moreButton.bounds;
    }
    [self presentViewController:sheet animated:YES completion:nil];
}

- (void)shareCollection
{
    NSString *urlString = nil;
    if (self.isLocalPlaylist) {
        [OTTheme showToast:@"Las listas locales no se pueden compartir" inView:self.view];
        return;
    }
    if (self.collectionType == OTItemTypePlaylist) {
        NSString *identifier = self.playlistId.length > 0 ? self.playlistId : self.browseId;
        if ([identifier hasPrefix:@"VL"]) {
            identifier = [identifier substringFromIndex:2];
        }
        urlString = [NSString stringWithFormat:@"https://music.youtube.com/playlist?list=%@", identifier];
    } else if (self.collectionType == OTItemTypeAlbum) {
        urlString = [NSString stringWithFormat:@"https://music.youtube.com/browse/%@", self.browseId];
    } else {
        urlString = [NSString stringWithFormat:@"https://music.youtube.com/channel/%@", self.browseId];
    }
    NSURL *url = [NSURL URLWithString:urlString];
    if (!url) {
        return;
    }
    UIActivityViewController *activity = [[UIActivityViewController alloc] initWithActivityItems:@[url]
                                                                           applicationActivities:nil];
    if (activity.popoverPresentationController) {
        activity.popoverPresentationController.sourceView = self.headerView.moreButton;
        activity.popoverPresentationController.sourceRect = self.headerView.moreButton.bounds;
    }
    [self presentViewController:activity animated:YES completion:nil];
}

@end

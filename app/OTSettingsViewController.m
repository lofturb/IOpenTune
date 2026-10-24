//
//  OTSettingsViewController.m
//  OpenTune 9
//

#import "OTSettingsViewController.h"
#import "OTTheme.h"
#import "OTStore.h"
#import "OTInnertube.h"
#import "OTImageCache.h"

@interface OTSettingsViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UIView *topBar;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UITableView *tableView;

@end

@implementation OTSettingsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [OTTheme background];

    self.topBar = [[UIView alloc] initWithFrame:CGRectZero];
    self.topBar.backgroundColor = [OTTheme background];
    [self.view addSubview:self.topBar];

    UIButton *back = [OTTheme iconButton:OTIconBack size:22 color:[OTTheme text] target:self action:@selector(goBack)];
    back.frame = CGRectMake(4, 6, 44, 44);
    [self.topBar addSubview:back];

    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.titleLabel.font = [OTTheme headlineSmall];
    self.titleLabel.textColor = [OTTheme text];
    self.titleLabel.text = @"Ajustes";
    [self.topBar addSubview:self.titleLabel];

    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.backgroundColor = [OTTheme background];
    self.tableView.separatorColor = [OTTheme separator];
    self.tableView.rowHeight = 56.0;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:self.tableView];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    CGFloat width = self.view.bounds.size.width;
    CGFloat top = self.topLayoutGuide.length;
    self.topBar.frame = CGRectMake(0, 0, width, top + 56.0);
    self.titleLabel.frame = CGRectMake(56.0, top + 8.0, width - 72.0, 40.0);
    self.tableView.frame = CGRectMake(0, top + 56.0, width, self.view.bounds.size.height - top - 56.0);
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (void)goBack
{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Tabla

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 5;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case 0: return 1;   // cuenta
        case 1: return 2;   // apariencia
        case 2: return 2;   // reproduccion
        case 3: return 3;   // datos
        default: return 3;  // informacion
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case 0: return @"Cuenta";
        case 1: return @"Apariencia";
        case 2: return @"Reproducción";
        case 3: return @"Datos";
        default: return @"Información";
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, 40.0)];
    header.backgroundColor = [OTTheme background];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(20.0, 12.0, tableView.bounds.size.width - 40.0, 20.0)];
    label.font = [OTTheme labelLarge];
    label.textColor = [OTTheme primary];
    label.text = [[self tableView:tableView titleForHeaderInSection:section] uppercaseString];
    [header addSubview:label];
    return header;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 40.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 8.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifier = @"OTSettingsCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:identifier];
        cell.backgroundColor = [OTTheme surface];
        cell.textLabel.textColor = [OTTheme text];
        cell.textLabel.font = [OTTheme bodyLarge];
        cell.detailTextLabel.textColor = [OTTheme secondaryText];
        cell.detailTextLabel.font = [OTTheme bodyMedium];
        UIView *selected = [[UIView alloc] init];
        selected.backgroundColor = [OTTheme surfaceHigh];
        cell.selectedBackgroundView = selected;
    }
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.accessoryView = nil;
    cell.textLabel.text = @"";
    cell.detailTextLabel.text = @"";

    OTStore *store = [OTStore sharedStore];

    if (indexPath.section == 0) {
        BOOL loggedIn = [[OTInnertube shared] isLoggedIn];
        cell.textLabel.text = loggedIn ? @"Cerrar sesión" : @"Iniciar sesión";
        cell.detailTextLabel.text = loggedIn ? @"Sesión iniciada" : @"Sin sesión";
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else if (indexPath.section == 1) {
        if (indexPath.row == 0) {
            cell.textLabel.text = @"Color de acento";
            cell.detailTextLabel.text = @"";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            UIView *dot = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 22, 22)];
            dot.backgroundColor = [OTTheme primary];
            dot.layer.cornerRadius = 11.0;
            cell.accessoryView = dot;
        } else {
            cell.textLabel.text = @"Negro puro";
            UISwitch *toggle = [[UISwitch alloc] initWithFrame:CGRectZero];
            toggle.onTintColor = [OTTheme primary];
            toggle.on = [OTTheme pureBlack];
            [toggle addTarget:self action:@selector(pureBlackChanged:) forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = toggle;
        }
    } else if (indexPath.section == 2) {
        if (indexPath.row == 0) {
            cell.textLabel.text = @"Calidad de audio";
            NSArray *names = @[@"Baja", @"Alta", @"Máxima"];
            cell.detailTextLabel.text = names[[store audioQuality]];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        } else {
            cell.textLabel.text = @"Descargas";
            cell.detailTextLabel.text = [OTTheme formatBytes:[store downloadsSize]];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
    } else if (indexPath.section == 3) {
        if (indexPath.row == 0) {
            cell.textLabel.text = @"Borrar historial";
        } else if (indexPath.row == 1) {
            cell.textLabel.text = @"Borrar búsquedas";
        } else {
            cell.textLabel.text = @"Borrar caché de imágenes";
            cell.detailTextLabel.text = [OTTheme formatBytes:[[OTImageCache sharedCache] diskUsage]];
        }
        cell.textLabel.textColor = [OTTheme error];
    } else {
        if (indexPath.row == 0) {
            cell.textLabel.text = @"Versión";
            cell.textLabel.textColor = [OTTheme text];
            NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"] ?: @"1.0";
            cell.detailTextLabel.text = version;
        } else if (indexPath.row == 1) {
            cell.textLabel.text = @"Licencia";
            cell.textLabel.textColor = [OTTheme text];
            cell.detailTextLabel.text = @"GPL-3.0";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        } else {
            cell.textLabel.text = @"Acerca de OpenTune 9";
            cell.textLabel.textColor = [OTTheme text];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (indexPath.section == 0) {
        if ([[OTInnertube shared] isLoggedIn]) {
            [self confirmLogout];
        } else {
            [self showLogin];
        }
        return;
    }

    if (indexPath.section == 1) {
        if (indexPath.row == 0) {
            [self showAccentPicker];
        }
        return;
    }

    if (indexPath.section == 2) {
        if (indexPath.row == 0) {
            [self showQualityPicker];
        } else {
            [self showDownloadsManager];
        }
        return;
    }

    if (indexPath.section == 3) {
        if (indexPath.row == 0) {
            [self confirmClearHistory];
        } else if (indexPath.row == 1) {
            [self confirmClearSearches];
        } else {
            [self confirmClearCache];
        }
        return;
    }

    if (indexPath.section == 4) {
        if (indexPath.row == 1) {
            [self showLicense];
        } else if (indexPath.row == 2) {
            [self showAbout];
        }
    }
}

#pragma mark - Cuenta

- (void)showLogin
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Iniciar sesión"
                                                                   message:@"Pega la cookie SAPISID de music.youtube.com.\n\nEn un navegador de escritorio abre music.youtube.com, entra en tu cuenta y copia el valor de la cookie SAPISID (o la cadena completa con SAPISID=…)."
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"SAPISID=…";
        textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        textField.autocorrectionType = UITextAutocorrectionTypeNo;
    }];
    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:@"Guardar" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSString *text = alert.textFields.firstObject.text ?: @"";
        text = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (text.length == 0) {
            return;
        }
        if ([text rangeOfString:@"="].location == NSNotFound) {
            text = [@"SAPISID=" stringByAppendingString:text];
        }
        [OTInnertube shared].cookie = text;
        [weakSelf.tableView reloadData];
        [OTTheme showToast:@"Sesión iniciada" inView:weakSelf.view];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancelar" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)confirmLogout
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Cerrar sesión"
                                                                   message:@"Se eliminará la cookie guardada de este dispositivo."
                                                            preferredStyle:UIAlertControllerStyleAlert];
    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:@"Cerrar sesión" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        [[OTInnertube shared] clearLogin];
        [weakSelf.tableView reloadData];
        [OTTheme showToast:@"Sesión cerrada" inView:weakSelf.view];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancelar" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Apariencia

- (void)showAccentPicker
{
    NSArray *colors = @[
        @{@"name": @"Rosa OpenTune", @"hex": @0xED5564},
        @{@"name": @"Naranja", @"hex": @0xFF7A59},
        @{@"name": @"Ámbar", @"hex": @0xF5C542},
        @{@"name": @"Verde", @"hex": @0x4CAF7D},
        @{@"name": @"Azul", @"hex": @0x4A9DE0},
        @{@"name": @"Violeta", @"hex": @0x9B7BE0},
        @{@"name": @"Magenta", @"hex": @0xE05A9C},
        @{@"name": @"Gris", @"hex": @0x8A94A6}
    ];
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:@"Color de acento"
                                                                  message:nil
                                                           preferredStyle:UIAlertControllerStyleActionSheet];
    __weak typeof(self) weakSelf = self;
    for (NSDictionary *entry in colors) {
        [sheet addAction:[UIAlertAction actionWithTitle:entry[@"name"]
                                                   style:UIAlertActionStyleDefault
                                                 handler:^(UIAlertAction *action) {
            NSUInteger hex = [entry[@"hex"] unsignedIntegerValue];
            [OTTheme setAccentHex:hex];
            [[OTStore sharedStore] setSetting:@(hex) forKey:@"ot.accent"];
            [weakSelf.tableView reloadData];
            [OTTheme showToast:@"Color actualizado" inView:weakSelf.view];
        }]];
    }
    [sheet addAction:[UIAlertAction actionWithTitle:@"Cancelar" style:UIAlertActionStyleCancel handler:nil]];
    if (sheet.popoverPresentationController) {
        sheet.popoverPresentationController.sourceView = self.view;
        sheet.popoverPresentationController.sourceRect = CGRectMake(self.view.bounds.size.width / 2.0,
                                                                    self.view.bounds.size.height / 2.0, 1, 1);
    }
    [self presentViewController:sheet animated:YES completion:nil];
}

- (void)pureBlackChanged:(UISwitch *)sender
{
    [OTTheme setPureBlack:sender.on];
    [[OTStore sharedStore] setSetting:@(sender.on) forKey:@"ot.pureBlack"];
    [self.tableView reloadData];
}

#pragma mark - Reproduccion

- (void)showQualityPicker
{
    NSArray *names = @[@"Baja (ahorra datos)", @"Alta", @"Máxima"];
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:@"Calidad de audio"
                                                                  message:@"La calidad real depende de la pista disponible."
                                                           preferredStyle:UIAlertControllerStyleActionSheet];
    __weak typeof(self) weakSelf = self;
    for (NSInteger i = 0; i < (NSInteger)names.count; i++) {
        [sheet addAction:[UIAlertAction actionWithTitle:names[i]
                                                   style:UIAlertActionStyleDefault
                                                 handler:^(UIAlertAction *action) {
            [[OTStore sharedStore] setAudioQuality:i];
            [weakSelf.tableView reloadData];
        }]];
    }
    [sheet addAction:[UIAlertAction actionWithTitle:@"Cancelar" style:UIAlertActionStyleCancel handler:nil]];
    if (sheet.popoverPresentationController) {
        sheet.popoverPresentationController.sourceView = self.view;
        sheet.popoverPresentationController.sourceRect = CGRectMake(self.view.bounds.size.width / 2.0,
                                                                    self.view.bounds.size.height / 2.0, 1, 1);
    }
    [self presentViewController:sheet animated:YES completion:nil];
}

- (void)showDownloadsManager
{
    NSArray<OTItem *> *items = [[OTStore sharedStore] downloadedItems];
    if (items.count == 0) {
        [OTTheme showToast:@"No hay descargas" inView:self.view];
        return;
    }
    NSString *message = [NSString stringWithFormat:@"%lu canciones · %@",
                         (unsigned long)items.count,
                         [OTTheme formatBytes:[[OTStore sharedStore] downloadsSize]]];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Descargas"
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:@"Eliminar todas" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        for (OTItem *item in items) {
            [[OTStore sharedStore] removeDownloadForItem:item];
        }
        [weakSelf.tableView reloadData];
        [OTTheme showToast:@"Descargas eliminadas" inView:weakSelf.view];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cerrar" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Datos

- (void)confirmClearHistory
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Borrar historial"
                                                                   message:@"¿Vaciar el historial de reproducción?"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:@"Borrar" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        [[OTStore sharedStore] clearHistory];
        [OTTheme showToast:@"Historial borrado" inView:weakSelf.view];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancelar" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)confirmClearSearches
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Borrar búsquedas"
                                                                   message:@"¿Vaciar el historial de búsquedas?"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:@"Borrar" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        [[OTStore sharedStore] clearSearchHistory];
        [OTTheme showToast:@"Búsquedas borradas" inView:weakSelf.view];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancelar" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)confirmClearCache
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Borrar caché"
                                                                   message:@"Se eliminarán las portadas descargadas."
                                                            preferredStyle:UIAlertControllerStyleAlert];
    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:@"Borrar" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        [[OTImageCache sharedCache] clearMemoryCache];
        [[OTImageCache sharedCache] clearDiskCache];
        [weakSelf.tableView reloadData];
        [OTTheme showToast:@"Caché borrada" inView:weakSelf.view];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancelar" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Informacion

- (void)showLicense
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Licencia"
                                                                   message:@"OpenTune 9 se distribuye bajo la GNU General Public License v3.0.\n\nEste proyecto es un port no oficial de OpenTune, creado por Arturo254, para iPad mini 1 con iOS 9."
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cerrar" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showAbout
{
    NSString *message = @"OpenTune 9\n\nCliente de YouTube Music para iPad mini 1 (iOS 9, armv7).\n\nInspirado en OpenTune de Arturo254.\n\nReproductor basado en AVPlayer. Letras por LRCLIB y YouTube Music.";
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Acerca de"
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cerrar" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end

//
//  OTSettingsViewController.m
//  OpenTune 9
//

#import "OTSettingsViewController.h"
#import "OTTheme.h"
#import "OTStore.h"
#import "OTInnertube.h"
#import "OTImageCache.h"
#import "OTRootViewController.h"
#import "OTComponents.h"

typedef NS_ENUM(NSInteger, OTSettingsAction) {
    OTSettingsActionAppearance = 100,
    OTSettingsActionPureBlack,
    OTSettingsActionPlayerAudio,
    OTSettingsActionDownloads,
    OTSettingsActionClearHistory,
    OTSettingsActionClearSearches,
    OTSettingsActionClearCache,
    OTSettingsActionAccount,
    OTSettingsActionVersion,
    OTSettingsActionLicense,
    OTSettingsActionAbout,
    OTSettingsActionPrivacy,
    OTSettingsActionDiscord,
    OTSettingsActionIntegrations,
    OTSettingsActionTogether
};

#pragma mark - Fila de ajuste

@interface OTSettingsRow : UIControl

@property (nonatomic, strong) UIView *iconCircle;
@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, strong) UIImageView *chevronView;
@property (nonatomic, strong) UILabel *valueLabel;
@property (nonatomic, strong) OTSwitch *toggle;

- (instancetype)initWithTitle:(NSString *)title
                     subtitle:(NSString *)subtitle
                         icon:(OTIcon)icon
                         tint:(UIColor *)tint;

@end

@implementation OTSettingsRow

- (instancetype)initWithTitle:(NSString *)title
                     subtitle:(NSString *)subtitle
                         icon:(OTIcon)icon
                         tint:(UIColor *)tint
{
    self = [super initWithFrame:CGRectZero];
    if (self) {
        self.backgroundColor = [OTTheme surfaceContainer];
        self.layer.cornerRadius = 20.0;
        self.layer.borderWidth = 1.0;
        self.layer.borderColor = [OTTheme cardBorder].CGColor;
        self.clipsToBounds = YES;

        _iconCircle = [[UIView alloc] initWithFrame:CGRectZero];
        _iconCircle.backgroundColor = [tint colorWithAlphaComponent:0.16];
        _iconCircle.layer.cornerRadius = 22.0;
        _iconCircle.userInteractionEnabled = NO;
        [self addSubview:_iconCircle];

        _iconView = [[UIImageView alloc] initWithFrame:CGRectZero];
        _iconView.image = [OTTheme icon:icon size:22];
        _iconView.tintColor = tint;
        _iconView.contentMode = UIViewContentModeScaleAspectFit;
        _iconView.userInteractionEnabled = NO;
        [self addSubview:_iconView];

        _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _titleLabel.font = [OTTheme font:17.0 weight:UIFontWeightSemibold];
        _titleLabel.textColor = [OTTheme text];
        _titleLabel.text = title;
        _titleLabel.userInteractionEnabled = NO;
        [self addSubview:_titleLabel];

        _subtitleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _subtitleLabel.font = [OTTheme bodySmall];
        _subtitleLabel.textColor = [OTTheme secondaryText];
        _subtitleLabel.text = subtitle;
        _subtitleLabel.userInteractionEnabled = NO;
        [self addSubview:_subtitleLabel];

        _chevronView = [[UIImageView alloc] initWithFrame:CGRectZero];
        _chevronView.image = [OTTheme icon:OTIconChevronRight size:20];
        _chevronView.tintColor = [OTTheme outline];
        _chevronView.contentMode = UIViewContentModeScaleAspectFit;
        _chevronView.userInteractionEnabled = NO;
        [self addSubview:_chevronView];

        _valueLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _valueLabel.font = [OTTheme bodyMedium];
        _valueLabel.textColor = [OTTheme secondaryText];
        _valueLabel.textAlignment = NSTextAlignmentRight;
        _valueLabel.hidden = YES;
        _valueLabel.userInteractionEnabled = NO;
        [self addSubview:_valueLabel];

        _toggle = [[OTSwitch alloc] initWithFrame:CGRectZero];
        _toggle.hidden = YES;
        [self addSubview:_toggle];

        [self addTarget:self action:@selector(pressIn) forControlEvents:UIControlEventTouchDown];
        [self addTarget:self action:@selector(pressOut)
               forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchCancel];
    }
    return self;
}

- (void)pressIn
{
    self.backgroundColor = [OTTheme surfaceHigh];
}

- (void)pressOut
{
    self.backgroundColor = [OTTheme surfaceContainer];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    CGFloat width = self.bounds.size.width;
    CGFloat height = self.bounds.size.height;
    self.iconCircle.frame = CGRectMake(16.0, (height - 44.0) / 2.0, 44.0, 44.0);
    self.iconView.frame = CGRectMake(27.0, (height - 22.0) / 2.0, 22.0, 22.0);

    CGFloat right = width - 20.0;
    if (!self.toggle.hidden) {
        self.toggle.frame = CGRectMake(width - 68.0, (height - 28.0) / 2.0, 48.0, 28.0);
        right = CGRectGetMinX(self.toggle.frame) - 12.0;
    } else if (!self.valueLabel.hidden) {
        CGSize size = [self.valueLabel sizeThatFits:CGSizeMake(160.0, 24.0)];
        self.valueLabel.frame = CGRectMake(right - size.width, 0, size.width, height);
        right = CGRectGetMinX(self.valueLabel.frame) - 10.0;
    }
    self.chevronView.frame = CGRectMake(right - 20.0, (height - 20.0) / 2.0, 20.0, 20.0);

    CGFloat textX = 76.0;
    CGFloat textWidth = MAX(40.0, right - textX - 28.0);
    if (self.subtitleLabel.text.length > 0) {
        self.titleLabel.frame = CGRectMake(textX, 13.0, textWidth, 24.0);
        self.subtitleLabel.frame = CGRectMake(textX, 38.0, textWidth, 18.0);
    } else {
        self.titleLabel.frame = CGRectMake(textX, 0, textWidth, height);
        self.subtitleLabel.frame = CGRectZero;
    }
}

@end


#pragma mark - Tarjeta de la rejilla

@interface OTSettingsCard : UIControl

@property (nonatomic, strong) UIView *iconCircle;
@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, strong) UILabel *titleLabel;

- (instancetype)initWithTitle:(NSString *)title icon:(OTIcon)icon tint:(UIColor *)tint;

@end

@implementation OTSettingsCard

- (instancetype)initWithTitle:(NSString *)title icon:(OTIcon)icon tint:(UIColor *)tint
{
    self = [super initWithFrame:CGRectZero];
    if (self) {
        [OTTheme styleCard:self radius:22.0];

        _iconCircle = [[UIView alloc] initWithFrame:CGRectZero];
        _iconCircle.backgroundColor = [tint colorWithAlphaComponent:0.16];
        _iconCircle.layer.cornerRadius = 24.0;
        _iconCircle.userInteractionEnabled = NO;
        [self addSubview:_iconCircle];

        _iconView = [[UIImageView alloc] initWithFrame:CGRectZero];
        _iconView.image = [OTTheme icon:icon size:26];
        _iconView.tintColor = tint;
        _iconView.contentMode = UIViewContentModeScaleAspectFit;
        _iconView.userInteractionEnabled = NO;
        [self addSubview:_iconView];

        _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _titleLabel.font = [OTTheme font:18.0 weight:UIFontWeightSemibold];
        _titleLabel.textColor = [OTTheme text];
        _titleLabel.text = title;
        _titleLabel.numberOfLines = 1;
        _titleLabel.userInteractionEnabled = NO;
        [self addSubview:_titleLabel];

        [self addTarget:self action:@selector(pressIn) forControlEvents:UIControlEventTouchDown];
        [self addTarget:self action:@selector(pressOut)
               forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchCancel];
    }
    return self;
}

- (void)pressIn
{
    self.backgroundColor = [OTTheme surfaceHigh];
}

- (void)pressOut
{
    self.backgroundColor = [OTTheme surfaceContainer];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    CGFloat width = self.bounds.size.width;
    CGFloat height = self.bounds.size.height;
    self.iconCircle.frame = CGRectMake(16.0, 16.0, 48.0, 48.0);
    self.iconView.frame = CGRectMake(27.0, 27.0, 26.0, 26.0);
    self.titleLabel.frame = CGRectMake(16.0, height - 44.0, width - 32.0, 28.0);
}

@end


#pragma mark - Ajustes

@interface OTSettingsViewController () <UITextFieldDelegate>

@property (nonatomic, strong) UIView *topBar;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *contentView;

@property (nonatomic, strong) UIView *appCard;
@property (nonatomic, strong) UILabel *versionChip;
@property (nonatomic, strong) NSMutableArray<OTSettingsCard *> *gridCards;
@property (nonatomic, strong) NSMutableArray<UIButton *> *chips;
@property (nonatomic, strong) NSMutableArray<OTSettingsRow *> *rows;
@property (nonatomic, strong) NSMutableArray<UILabel *> *sectionLabels;

@property (nonatomic, strong) OTSettingsRow *qualityRow;
@property (nonatomic, strong) OTSettingsRow *downloadsRow;
@property (nonatomic, strong) OTSettingsRow *cacheRow;
@property (nonatomic, strong) OTSettingsRow *accountRow;
@property (nonatomic, strong) OTSettingsRow *versionRow;
@property (nonatomic, strong) OTSwitch *pureBlackSwitch;

@end

@implementation OTSettingsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [OTTheme background];

    self.topBar = [[UIView alloc] initWithFrame:CGRectZero];
    self.topBar.backgroundColor = [OTTheme background];
    [self.view addSubview:self.topBar];

    UIButton *back = [OTTheme iconButton:OTIconBack size:24 color:[OTTheme text] target:self action:@selector(goBack)];
    back.tag = 1;
    [self.topBar addSubview:back];

    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.titleLabel.font = [OTTheme font:40.0 weight:UIFontWeightBold];
    self.titleLabel.textColor = [OTTheme text];
    self.titleLabel.text = @"Ajustes";
    [self.topBar addSubview:self.titleLabel];

    self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectZero];
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.backgroundColor = [OTTheme background];
    [self.view addSubview:self.scrollView];

    self.contentView = [[UIView alloc] initWithFrame:CGRectZero];
    self.contentView.backgroundColor = [OTTheme background];
    [self.scrollView addSubview:self.contentView];

    self.gridCards = [NSMutableArray array];
    self.chips = [NSMutableArray array];
    self.rows = [NSMutableArray array];
    self.sectionLabels = [NSMutableArray array];

    [self buildContent];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(bottomInsetChanged)
                                                 name:OTBottomInsetDidChangeNotification
                                               object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self refreshValues];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (void)goBack
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)bottomInsetChanged
{
    [self.view setNeedsLayout];
}

#pragma mark - Construccion

- (void)buildContent
{
    // Tarjeta de la aplicacion.
    self.appCard = [[UIView alloc] initWithFrame:CGRectZero];
    [OTTheme styleCard:self.appCard radius:24.0];
    [self.contentView addSubview:self.appCard];

    UIView *appIcon = [[UIView alloc] initWithFrame:CGRectZero];
    appIcon.backgroundColor = [OTTheme primaryContainer];
    appIcon.layer.cornerRadius = 18.0;
    appIcon.tag = 1;
    [self.appCard addSubview:appIcon];

    UIImageView *note = [[UIImageView alloc] initWithFrame:CGRectZero];
    note.image = [OTTheme icon:OTIconMusicNote size:30];
    note.tintColor = [OTTheme onPrimaryContainer];
    note.contentMode = UIViewContentModeScaleAspectFit;
    note.tag = 2;
    [self.appCard addSubview:note];

    UILabel *appName = [[UILabel alloc] initWithFrame:CGRectZero];
    appName.font = [OTTheme font:28.0 weight:UIFontWeightBold];
    appName.textColor = [OTTheme text];
    appName.text = @"OpenTune";
    appName.tag = 3;
    [self.appCard addSubview:appName];

    self.versionChip = [[UILabel alloc] initWithFrame:CGRectZero];
    self.versionChip.font = [OTTheme labelMedium];
    self.versionChip.textColor = [OTTheme onSecondaryContainer];
    self.versionChip.backgroundColor = [OTTheme secondaryContainer];
    self.versionChip.textAlignment = NSTextAlignmentCenter;
    self.versionChip.layer.cornerRadius = 9.0;
    self.versionChip.clipsToBounds = YES;
    self.versionChip.tag = 4;
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"] ?: @"1.0";
    self.versionChip.text = [NSString stringWithFormat:@"v%@", version];
    [self.appCard addSubview:self.versionChip];

    // Rejilla 2x2.
    NSArray *gridTitles = @[@"Apariencia", @"Reproductor y audio", @"Almacenamiento", @"Privacidad"];
    NSArray *gridIcons = @[@(OTIconPalette), @(OTIconPlay), @(OTIconStorage), @(OTIconShield)];
    NSArray *gridTints = @[[OTTheme primary], [OTTheme secondary], [OTTheme tertiary], [OTTheme error]];
    NSArray *gridActions = @[@(OTSettingsActionAppearance), @(OTSettingsActionPlayerAudio),
                             @(OTSettingsActionDownloads), @(OTSettingsActionPrivacy)];
    for (NSInteger i = 0; i < 4; i++) {
        OTSettingsCard *card = [[OTSettingsCard alloc] initWithTitle:gridTitles[i]
                                                               icon:[gridIcons[i] integerValue]
                                                               tint:gridTints[i]];
        card.tag = [gridActions[i] integerValue];
        [card addTarget:self action:@selector(handleAction:) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:card];
        [self.gridCards addObject:card];
    }

    // Chips.
    NSArray *chipTitles = @[@"Discord", @"Integraciones", @"Juntos"];
    NSArray *chipIcons = @[@(OTIconDiscord), @(OTIconPuzzle), @(OTIconFlame)];
    NSArray *chipTints = @[[OTTheme colorWithHex:0x7289DA], [OTTheme secondary], [OTTheme error]];
    NSArray *chipActions = @[@(OTSettingsActionDiscord), @(OTSettingsActionIntegrations),
                             @(OTSettingsActionTogether)];
    for (NSInteger i = 0; i < 3; i++) {
        UIButton *chip = [UIButton buttonWithType:UIButtonTypeCustom];
        chip.backgroundColor = [OTTheme surfaceContainer];
        chip.layer.cornerRadius = 18.0;
        chip.layer.borderWidth = 1.0;
        chip.layer.borderColor = [OTTheme cardBorder].CGColor;
        chip.titleLabel.font = [OTTheme labelLarge];
        chip.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        chip.contentEdgeInsets = UIEdgeInsetsMake(0, 16, 0, 14);
        chip.imageEdgeInsets = UIEdgeInsetsMake(0, -6, 0, 8);
        chip.titleEdgeInsets = UIEdgeInsetsMake(0, 6, 0, -6);
        [chip setTitle:chipTitles[i] forState:UIControlStateNormal];
        [chip setTitleColor:[OTTheme text] forState:UIControlStateNormal];
        [chip setImage:[OTTheme icon:[chipIcons[i] integerValue] size:20] forState:UIControlStateNormal];
        chip.tintColor = chipTints[i];
        chip.tag = [chipActions[i] integerValue];
        [chip addTarget:self action:@selector(handleAction:) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:chip];
        [self.chips addObject:chip];
    }

    // Secciones.
    [self addSection:@"Interfaz de usuario"];
    OTSettingsRow *appearance = [self addRowWithTitle:@"Apariencia"
                                             subtitle:@"Tema oscuro"
                                                 icon:OTIconPalette
                                                 tint:[OTTheme primary]
                                               action:OTSettingsActionAppearance];
    (void)appearance;
    OTSettingsRow *pureBlack = [self addRowWithTitle:@"Negro puro"
                                            subtitle:@"Fondos completamente negros"
                                                icon:OTIconLock
                                                tint:[OTTheme secondary]
                                              action:OTSettingsActionPureBlack];
    self.pureBlackSwitch = pureBlack.toggle;
    self.pureBlackSwitch.hidden = NO;
    pureBlack.chevronView.hidden = YES;
    [self.pureBlackSwitch addTarget:self action:@selector(pureBlackChanged:)
                   forControlEvents:UIControlEventValueChanged];

    [self addSection:@"Reproductor y contenido"];
    self.qualityRow = [self addRowWithTitle:@"Reproductor y audio"
                                   subtitle:@"Calidad de audio"
                                       icon:OTIconPlay
                                       tint:[OTTheme secondary]
                                     action:OTSettingsActionPlayerAudio];
    self.downloadsRow = [self addRowWithTitle:@"Descargas"
                                     subtitle:@"Administrar descargas"
                                         icon:OTIconDownload
                                         tint:[OTTheme tertiary]
                                       action:OTSettingsActionDownloads];

    [self addSection:@"Datos y almacenamiento"];
    [self addRowWithTitle:@"Borrar historial"
                 subtitle:@"Vaciar las canciones escuchadas"
                     icon:OTIconHistory
                     tint:[OTTheme error]
                   action:OTSettingsActionClearHistory];
    [self addRowWithTitle:@"Borrar búsquedas"
                 subtitle:@"Vaciar el historial de búsqueda"
                     icon:OTIconSearch
                     tint:[OTTheme error]
                   action:OTSettingsActionClearSearches];
    self.cacheRow = [self addRowWithTitle:@"Borrar caché de imágenes"
                                 subtitle:@"Portadas descargadas"
                                     icon:OTIconStorage
                                     tint:[OTTheme error]
                                   action:OTSettingsActionClearCache];

    [self addSection:@"Cuenta"];
    self.accountRow = [self addRowWithTitle:@"Cuenta"
                                   subtitle:@"Sesión de YouTube Music"
                                       icon:OTIconAccountCircle
                                       tint:[OTTheme primary]
                                     action:OTSettingsActionAccount];

    [self addSection:@"Información"];
    self.versionRow = [self addRowWithTitle:@"Versión"
                                   subtitle:nil
                                       icon:OTIconPuzzle
                                       tint:[OTTheme secondary]
                                     action:OTSettingsActionVersion];
    self.versionRow.valueLabel.hidden = NO;
    self.versionRow.chevronView.hidden = YES;
    NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"] ?: @"1.0";
    self.versionRow.valueLabel.text = appVersion;
    [self addRowWithTitle:@"Licencia"
                 subtitle:@"GPL-3.0"
                     icon:OTIconShield
                     tint:[OTTheme tertiary]
                   action:OTSettingsActionLicense];
    [self addRowWithTitle:@"Acerca de OpenTune 9"
                 subtitle:@"Port para iPad mini 1 / iOS 9"
                     icon:OTIconMusicNote
                     tint:[OTTheme primary]
                   action:OTSettingsActionAbout];
}

- (void)addSection:(NSString *)title
{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.font = [OTTheme labelLarge];
    label.textColor = [OTTheme secondaryText];
    label.attributedText = [[NSAttributedString alloc] initWithString:[title uppercaseString]
                                                           attributes:@{
        NSFontAttributeName: [OTTheme labelLarge],
        NSForegroundColorAttributeName: [OTTheme secondaryText],
        NSKernAttributeName: @(1.1)
    }];
    [self.contentView addSubview:label];
    [self.sectionLabels addObject:label];
}

- (OTSettingsRow *)addRowWithTitle:(NSString *)title
                          subtitle:(NSString *)subtitle
                              icon:(OTIcon)icon
                              tint:(UIColor *)tint
                            action:(OTSettingsAction)action
{
    OTSettingsRow *row = [[OTSettingsRow alloc] initWithTitle:title subtitle:subtitle icon:icon tint:tint];
    row.tag = action;
    [row addTarget:self action:@selector(handleAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:row];
    [self.rows addObject:row];
    return row;
}

#pragma mark - Layout

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];

    CGFloat width = self.view.bounds.size.width;
    CGFloat top = self.topLayoutGuide.length;
    self.topBar.frame = CGRectMake(0, 0, width, top + 108.0);
    UIButton *back = (UIButton *)[self.topBar viewWithTag:1];
    back.frame = CGRectMake(10.0, top + 6.0, 44.0, 44.0);
    self.titleLabel.frame = CGRectMake(24.0, top + 54.0, width - 48.0, 50.0);

    self.scrollView.frame = CGRectMake(0, top + 104.0, width, self.view.bounds.size.height - top - 104.0);
    self.scrollView.contentInset = UIEdgeInsetsMake(0, 0, OTBottomInset() + 24.0, 0);
    self.scrollView.scrollIndicatorInsets = self.scrollView.contentInset;

    CGFloat side = 24.0;
    CGFloat contentWidth = width - side * 2.0;
    CGFloat y = 8.0;

    self.appCard.frame = CGRectMake(side, y, contentWidth, 108.0);
    UIView *appIcon = [self.appCard viewWithTag:1];
    appIcon.frame = CGRectMake(20.0, 22.0, 64.0, 64.0);
    UIImageView *note = (UIImageView *)[self.appCard viewWithTag:2];
    note.frame = CGRectMake(37.0, 39.0, 30.0, 30.0);
    UILabel *appName = (UILabel *)[self.appCard viewWithTag:3];
    appName.frame = CGRectMake(100.0, 22.0, contentWidth - 120.0, 38.0);
    self.versionChip.frame = CGRectMake(100.0, 62.0, 78.0, 24.0);
    y += 108.0 + 16.0;

    CGFloat gap = 12.0;
    CGFloat cardWidth = (contentWidth - gap) / 2.0;
    CGFloat cardHeight = 132.0;
    for (NSInteger i = 0; i < (NSInteger)self.gridCards.count; i++) {
        CGFloat x = side + (i % 2) * (cardWidth + gap);
        CGFloat rowY = y + (i / 2) * (cardHeight + gap);
        self.gridCards[i].frame = CGRectMake(x, rowY, cardWidth, cardHeight);
    }
    y += cardHeight * 2.0 + gap + 20.0;

    CGFloat chipGap = 10.0;
    CGFloat chipWidth = (contentWidth - chipGap * 2.0) / 3.0;
    for (NSInteger i = 0; i < (NSInteger)self.chips.count; i++) {
        self.chips[i].frame = CGRectMake(side + i * (chipWidth + chipGap), y, chipWidth, 48.0);
    }
    y += 48.0 + 24.0;

    NSInteger sectionIndex = 0;
    NSInteger rowIndex = 0;
    NSInteger sectionCounts[8] = {2, 2, 3, 1, 3, 0, 0, 0};
    for (NSInteger i = 0; i < (NSInteger)self.rows.count; i++) {
        if (i == 0 || rowIndex >= sectionCounts[sectionIndex]) {
            if (i > 0) {
                sectionIndex++;
                rowIndex = 0;
            }
            if (sectionIndex < (NSInteger)self.sectionLabels.count) {
                UILabel *label = self.sectionLabels[sectionIndex];
                label.frame = CGRectMake(side + 4.0, y, contentWidth - 8.0, 32.0);
                y += 40.0;
            }
        }
        OTSettingsRow *row = self.rows[i];
        row.frame = CGRectMake(side, y, contentWidth, 72.0);
        y += 72.0 + 8.0;
        rowIndex++;
    }

    y += 12.0;
    self.contentView.frame = CGRectMake(0, 0, width, y);
    self.scrollView.contentSize = CGSizeMake(width, y);
}

#pragma mark - Acciones

- (void)handleAction:(UIControl *)sender
{
    OTSettingsAction action = (OTSettingsAction)sender.tag;
    switch (action) {
        case OTSettingsActionAppearance:
            [self showAccentPicker];
            break;
        case OTSettingsActionPureBlack:
            [self.pureBlackSwitch setOn:!self.pureBlackSwitch.isOn animated:YES];
            [self pureBlackChanged:self.pureBlackSwitch];
            break;
        case OTSettingsActionPlayerAudio:
            [self showQualityPicker];
            break;
        case OTSettingsActionDownloads:
            [self showDownloadsManager];
            break;
        case OTSettingsActionClearHistory:
            [self confirmClearHistory];
            break;
        case OTSettingsActionClearSearches:
            [self confirmClearSearches];
            break;
        case OTSettingsActionClearCache:
            [self confirmClearCache];
            break;
        case OTSettingsActionAccount:
            if ([[OTInnertube shared] isLoggedIn]) {
                [self confirmLogout];
            } else {
                [self showLogin];
            }
            break;
        case OTSettingsActionVersion:
            break;
        case OTSettingsActionLicense:
            [self showLicense];
            break;
        case OTSettingsActionAbout:
            [self showAbout];
            break;
        case OTSettingsActionPrivacy:
            [self showPrivacyInfo];
            break;
        case OTSettingsActionDiscord:
            [self showInfoWithTitle:@"Discord"
                            message:@"Únete a la comunidad de OpenTune para compartir música, ideas y novedades."];
            break;
        case OTSettingsActionIntegrations:
            [self showInfoWithTitle:@"Integraciones"
                            message:@"Conecta OpenTune con Last.fm, Discord y otros servicios desde la app original."];
            break;
        case OTSettingsActionTogether:
            [self showInfoWithTitle:@"Juntos"
                            message:@"Escucha música al mismo tiempo con tus amigos usando Music Together."];
            break;
        default:
            break;
    }
}

- (void)refreshValues
{
    OTStore *store = [OTStore sharedStore];
    NSArray *names = @[@"Baja", @"Alta", @"Máxima"];
    self.qualityRow.subtitleLabel.text = [NSString stringWithFormat:@"Calidad de audio · %@",
                                          names[[store audioQuality]]];
    self.downloadsRow.subtitleLabel.text = [NSString stringWithFormat:@"%@ descargados",
                                            [OTTheme formatBytes:[store downloadsSize]]];
    self.cacheRow.subtitleLabel.text = [NSString stringWithFormat:@"%@ en caché",
                                        [OTTheme formatBytes:[[OTImageCache sharedCache] diskUsage]]];
    self.accountRow.titleLabel.text = [[OTInnertube shared] isLoggedIn] ? @"Cerrar sesión" : @"Iniciar sesión";
    self.accountRow.subtitleLabel.text = [[OTInnertube shared] isLoggedIn]
        ? @"Sesión iniciada" : @"Recomendada para reproducir";
    [self.pureBlackSwitch setOn:[OTTheme pureBlack] animated:NO];
}

#pragma mark - Cuenta

- (void)showLogin
{
    __weak typeof(self) weakSelf = self;
    OTDialogViewController *dialog =
        [OTDialogViewController promptWithTitle:@"Iniciar sesión"
                                        message:@"YouTube exige una sesión para reproducir la mayoría de canciones (control anti-bot).\n\n1) En un ordenador entra en music.youtube.com con tu cuenta.\n2) Pulsa F12 → Application/Storage → Cookies → music.youtube.com.\n3) Copia el valor de SAPISID y pégalo aquí."
                                    placeholder:@"SAPISID=…"
                                          value:nil
                                   confirmTitle:@"Guardar"
                                     completion:^(NSString *text) {
        NSString *value = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (value.length == 0) {
            return;
        }
        if ([value rangeOfString:@"="].location == NSNotFound) {
            value = [@"SAPISID=" stringByAppendingString:value];
        }
        [OTInnertube shared].cookie = value;
        [weakSelf refreshValues];
        [[OTInnertube shared] validateLoginWithCompletion:^(BOOL valid, NSError *error) {
            if (valid) {
                [OTTheme showToast:@"Sesión iniciada" inView:weakSelf.view];
            } else {
                [OTTheme showToast:@"Cookie guardada, pero YouTube no confirmó la sesión" inView:weakSelf.view];
            }
        }];
    }];
    [dialog presentFrom:self];
}

- (void)confirmLogout
{
    __weak typeof(self) weakSelf = self;
    OTDialogViewController *dialog =
        [OTDialogViewController dialogWithTitle:@"Cerrar sesión"
                                        message:@"Se eliminará la cookie guardada de este dispositivo."
                                   confirmTitle:@"Cerrar sesión"
                                    cancelTitle:@"Cancelar"
                                     completion:^(BOOL confirmed) {
        if (!confirmed) {
            return;
        }
        [[OTInnertube shared] clearLogin];
        [weakSelf refreshValues];
        [OTTheme showToast:@"Sesión cerrada" inView:weakSelf.view];
    }];
    [dialog presentFrom:self];
}

#pragma mark - Apariencia

- (void)showAccentPicker
{
    NSArray *colors = @[
        @{@"name": @"Lavanda", @"hex": @0xA9B8FF},
        @{@"name": @"Rosa OpenTune", @"hex": @0xED5564},
        @{@"name": @"Naranja", @"hex": @0xFF7A59},
        @{@"name": @"Ámbar", @"hex": @0xF5C542},
        @{@"name": @"Verde", @"hex": @0x4CAF7D},
        @{@"name": @"Azul", @"hex": @0x4A9DE0},
        @{@"name": @"Violeta", @"hex": @0x9B7BE0},
        @{@"name": @"Magenta", @"hex": @0xE05A9C}
    ];
    __weak typeof(self) weakSelf = self;
    NSMutableArray<OTSheetAction *> *actions = [NSMutableArray array];
    for (NSDictionary *entry in colors) {
        OTSheetAction *action = [OTSheetAction actionWithTitle:entry[@"name"]
                                                          icon:OTIconPalette
                                                       handler:^{
            NSUInteger hex = [entry[@"hex"] unsignedIntegerValue];
            [OTTheme setAccentHex:hex];
            [[OTStore sharedStore] setSetting:@(hex) forKey:@"ot.accent"];
            [weakSelf refreshValues];
            [OTTheme showToast:@"Color actualizado" inView:weakSelf.view];
        }];
        action.selected = ([OTTheme accentHex] == [entry[@"hex"] unsignedIntegerValue]);
        [actions addObject:action];
    }
    [actions addObject:[OTSheetAction actionWithTitle:@"Cancelar" icon:OTIconClose handler:nil]];
    OTSheetViewController *sheet = [OTSheetViewController sheetWithTitle:@"Color de acento"
                                                                subtitle:@"Elige el color principal de OpenTune"
                                                                 actions:actions];
    [sheet presentFrom:self];
}

- (void)pureBlackChanged:(OTSwitch *)sender
{
    [OTTheme setPureBlack:sender.isOn];
    [[OTStore sharedStore] setSetting:@(sender.isOn) forKey:@"ot.pureBlack"];
    [self.view setNeedsLayout];
}

#pragma mark - Reproduccion

- (void)showQualityPicker
{
    NSArray *names = @[@"Baja (ahorra datos)", @"Alta", @"Máxima"];
    __weak typeof(self) weakSelf = self;
    NSMutableArray<OTSheetAction *> *actions = [NSMutableArray array];
    for (NSInteger i = 0; i < (NSInteger)names.count; i++) {
        OTSheetAction *action = [OTSheetAction actionWithTitle:names[i]
                                                          icon:OTIconEqualizer
                                                       handler:^{
            [[OTStore sharedStore] setAudioQuality:i];
            [weakSelf refreshValues];
            [OTTheme showToast:@"Calidad actualizada" inView:weakSelf.view];
        }];
        action.selected = (i == [[OTStore sharedStore] audioQuality]);
        [actions addObject:action];
    }
    [actions addObject:[OTSheetAction actionWithTitle:@"Cancelar" icon:OTIconClose handler:nil]];
    OTSheetViewController *sheet = [OTSheetViewController sheetWithTitle:@"Calidad de audio"
                                                                subtitle:@"La calidad real depende de la pista disponible"
                                                                 actions:actions];
    [sheet presentFrom:self];
}

- (void)showDownloadsManager
{
    NSArray<OTItem *> *items = [[OTStore sharedStore] downloadedItems];
    if (items.count == 0) {
        [OTTheme showToast:@"No hay descargas" inView:self.view];
        return;
    }
    __weak typeof(self) weakSelf = self;
    NSString *subtitle = [NSString stringWithFormat:@"%lu canciones · %@",
                          (unsigned long)items.count,
                          [OTTheme formatBytes:[[OTStore sharedStore] downloadsSize]]];
    NSMutableArray<OTSheetAction *> *actions = [NSMutableArray array];
    OTSheetAction *remove = [OTSheetAction actionWithTitle:@"Eliminar todas las descargas"
                                                      icon:OTIconTrash
                                                   handler:^{
        for (OTItem *item in items) {
            [[OTStore sharedStore] removeDownloadForItem:item];
        }
        [weakSelf refreshValues];
        [OTTheme showToast:@"Descargas eliminadas" inView:weakSelf.view];
    }];
    remove.destructive = YES;
    [actions addObject:remove];
    [actions addObject:[OTSheetAction actionWithTitle:@"Cerrar" icon:OTIconClose handler:nil]];
    OTSheetViewController *sheet = [OTSheetViewController sheetWithTitle:@"Descargas"
                                                                subtitle:subtitle
                                                                 actions:actions];
    [sheet presentFrom:self];
}

#pragma mark - Datos

- (void)confirmClearHistory
{
    __weak typeof(self) weakSelf = self;
    OTDialogViewController *dialog =
        [OTDialogViewController dialogWithTitle:@"Borrar historial"
                                        message:@"¿Vaciar el historial de reproducción?"
                                   confirmTitle:@"Borrar"
                                    cancelTitle:@"Cancelar"
                                     completion:^(BOOL confirmed) {
        if (!confirmed) {
            return;
        }
        [[OTStore sharedStore] clearHistory];
        [OTTheme showToast:@"Historial borrado" inView:weakSelf.view];
    }];
    [dialog presentFrom:self];
}

- (void)confirmClearSearches
{
    __weak typeof(self) weakSelf = self;
    OTDialogViewController *dialog =
        [OTDialogViewController dialogWithTitle:@"Borrar búsquedas"
                                        message:@"¿Vaciar el historial de búsquedas?"
                                   confirmTitle:@"Borrar"
                                    cancelTitle:@"Cancelar"
                                     completion:^(BOOL confirmed) {
        if (!confirmed) {
            return;
        }
        [[OTStore sharedStore] clearSearchHistory];
        [OTTheme showToast:@"Búsquedas borradas" inView:weakSelf.view];
    }];
    [dialog presentFrom:self];
}

- (void)confirmClearCache
{
    __weak typeof(self) weakSelf = self;
    OTDialogViewController *dialog =
        [OTDialogViewController dialogWithTitle:@"Borrar caché"
                                        message:@"Se eliminarán las portadas descargadas."
                                   confirmTitle:@"Borrar"
                                    cancelTitle:@"Cancelar"
                                     completion:^(BOOL confirmed) {
        if (!confirmed) {
            return;
        }
        [[OTImageCache sharedCache] clearMemoryCache];
        [[OTImageCache sharedCache] clearDiskCache];
        [weakSelf refreshValues];
        [OTTheme showToast:@"Caché borrada" inView:weakSelf.view];
    }];
    [dialog presentFrom:self];
}

#pragma mark - Informacion

- (void)showInfoWithTitle:(NSString *)title message:(NSString *)message
{
    OTDialogViewController *dialog =
        [OTDialogViewController dialogWithTitle:title
                                        message:message
                                   confirmTitle:@"Entendido"
                                    cancelTitle:@"Cerrar"
                                     completion:nil];
    [dialog presentFrom:self];
}

- (void)showPrivacyInfo
{
    [self showInfoWithTitle:@"Privacidad"
                    message:@"OpenTune 9 no recopila datos personales. Las cookies y el historial se guardan solo en este dispositivo."];
}

- (void)showLicense
{
    [self showInfoWithTitle:@"Licencia"
                    message:@"OpenTune 9 se distribuye bajo la GNU General Public License v3.0.\n\nEste proyecto es un port no oficial de OpenTune, creado por Arturo254, para iPad mini 1 con iOS 9."];
}

- (void)showAbout
{
    [self showInfoWithTitle:@"Acerca de"
                    message:@"OpenTune 9\n\nCliente de YouTube Music para iPad mini 1 (iOS 9, armv7).\n\nInspirado en OpenTune de Arturo254.\n\nReproductor basado en AVPlayer. Letras por LRCLIB y YouTube Music."];
}

@end

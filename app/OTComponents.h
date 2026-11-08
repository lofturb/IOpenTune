//
//  OTComponents.h
//  OpenTune 9
//

#import <UIKit/UIKit.h>
#import "OTTheme.h"
#import "OTItem.h"
#import "OTImageCache.h"

@class OTItemCell;
@class OTGridCell;

#pragma mark - Celdas

@interface OTItemCell : UITableViewCell

@property (nonatomic, strong) OTImageView *artworkView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, strong) UILabel *durationLabel;
@property (nonatomic, strong) UILabel *indexLabel;
@property (nonatomic, strong) UIButton *moreButton;
@property (nonatomic, strong) OTItem *item;
@property (nonatomic, copy) void (^moreHandler)(OTItem *item);
// Para listas de reproducción: portada en mosaico 2x2.
@property (nonatomic, strong) NSArray<NSString *> *mosaicURLs;

- (void)configureWithItem:(OTItem *)item index:(NSInteger)index showsArtwork:(BOOL)showsArtwork;
- (void)setCurrentTrack:(BOOL)current;

@end


@interface OTGridCell : UICollectionViewCell

@property (nonatomic, strong) OTImageView *artworkView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, strong) OTItem *item;

- (void)configureWithItem:(OTItem *)item width:(CGFloat)width;

@end


@interface OTCarouselCell : UITableViewCell

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSArray<OTItem *> *items;
@property (nonatomic, copy) void (^onSelectItem)(OTItem *item);
@property (nonatomic, copy) void (^onMoreItem)(OTItem *item);

- (void)setItems:(NSArray<OTItem *> *)items;
- (void)refreshCurrentTrack;

@end


@interface OTSectionHeaderView : UITableViewHeaderFooterView

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIButton *moreButton;
@property (nonatomic, copy) void (^onMore)(void);

- (void)configureWithTitle:(NSString *)title showsMore:(BOOL)showsMore;

@end


@interface OTChipsView : UIView

@property (nonatomic, strong) NSArray<NSString *> *titles;
@property (nonatomic, strong) NSArray<NSNumber *> *icons;
@property (nonatomic, assign) NSInteger selectedIndex;
@property (nonatomic, copy) void (^onSelect)(NSInteger index);

- (void)setTitles:(NSArray<NSString *> *)titles selectedIndex:(NSInteger)selectedIndex;
- (void)setTitles:(NSArray<NSString *> *)titles
            icons:(NSArray<NSNumber *> *)icons
    selectedIndex:(NSInteger)selectedIndex;
- (void)selectIndex:(NSInteger)index animated:(BOOL)animated;

@end


#pragma mark - Mini reproductor

@interface OTMiniPlayerView : UIView

@property (nonatomic, strong) OTImageView *artworkView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, strong) UIButton *playButton;
@property (nonatomic, strong) UIButton *nextButton;
@property (nonatomic, strong) UIView *progressTrack;
@property (nonatomic, strong) UIView *progressFill;
@property (nonatomic, copy) void (^onOpen)(void);

- (void)refresh;
- (void)refreshProgress;

@end


#pragma mark - Estados vacíos y cabeceras

@interface OTEmptyView : UIView

@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, strong) UIButton *actionButton;

- (void)configureWithIcon:(OTIcon)icon
                    title:(NSString *)title
                 subtitle:(NSString *)subtitle
              actionTitle:(NSString *)actionTitle
                   action:(void (^)(void))action;

@end


@interface OTHeaderView : UIView

@property (nonatomic, strong) OTImageView *artworkView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, strong) UILabel *detailLabel;
@property (nonatomic, strong) UIButton *playButton;
@property (nonatomic, strong) UIButton *shuffleButton;
@property (nonatomic, strong) UIButton *downloadButton;
@property (nonatomic, strong) UIButton *moreButton;

- (void)configureWithItem:(OTItem *)item type:(OTItemType)type;
- (CGFloat)preferredHeightForWidth:(CGFloat)width;

@end


#pragma mark - Barra superior estilo OpenTune

@interface OTAppBarView : UIView

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIImageView *logoView;
@property (nonatomic, strong) NSMutableArray<UIButton *> *buttons;

- (instancetype)initWithTitle:(NSString *)title showsLogo:(BOOL)showsLogo;
- (UIButton *)addButtonWithIcon:(OTIcon)icon target:(id)target action:(SEL)action;
- (UIButton *)addAvatarWithTarget:(id)target action:(SEL)action;

@end


#pragma mark - Tarjeta rápida (biblioteca)

@interface OTQuickCardCell : UICollectionViewCell

@property (nonatomic, strong) UIView *cardView;
@property (nonatomic, strong) UIView *iconCircle;
@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, strong) UILabel *titleLabel;

- (void)configureWithTitle:(NSString *)title icon:(OTIcon)icon tint:(UIColor *)tint;

@end


#pragma mark - Mosaico 2x2

@interface OTMosaicView : UIView

- (void)setImageURLs:(NSArray<NSString *> *)urls;

@end


#pragma mark - Controles Material

@interface OTSwitch : UIControl

@property (nonatomic, assign, getter=isOn) BOOL on;

- (void)setOn:(BOOL)on animated:(BOOL)animated;

@end


@interface OTSlider : UISlider

@end


#pragma mark - Hoja inferior (sustituye a UIAlertController)

@interface OTSheetAction : NSObject

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subtitle;
@property (nonatomic, assign) OTIcon icon;
@property (nonatomic, assign) BOOL destructive;
@property (nonatomic, assign) BOOL selected;
@property (nonatomic, copy) void (^handler)(void);

+ (instancetype)actionWithTitle:(NSString *)title
                          icon:(OTIcon)icon
                       handler:(void (^)(void))handler;

+ (instancetype)actionWithTitle:(NSString *)title
                       subtitle:(NSString *)subtitle
                           icon:(OTIcon)icon
                       handler:(void (^)(void))handler;

@end


@interface OTSheetViewController : UIViewController

+ (instancetype)sheetWithTitle:(NSString *)title
                      subtitle:(NSString *)subtitle
                       actions:(NSArray<OTSheetAction *> *)actions;

- (void)presentFrom:(UIViewController *)controller;

@end


#pragma mark - Dialogo centrado

@interface OTDialogViewController : UIViewController

+ (instancetype)dialogWithTitle:(NSString *)title
                        message:(NSString *)message
                   confirmTitle:(NSString *)confirmTitle
                    cancelTitle:(NSString *)cancelTitle
                     completion:(void (^)(BOOL confirmed))completion;

+ (instancetype)promptWithTitle:(NSString *)title
                        message:(NSString *)message
                    placeholder:(NSString *)placeholder
                          value:(NSString *)value
                   confirmTitle:(NSString *)confirmTitle
                     completion:(void (^)(NSString *text))completion;

- (void)presentFrom:(UIViewController *)controller;

@end


#pragma mark - Fabricas

UIButton *OTPillButton(NSString *title, OTIcon icon, BOOL filled);
UIButton *OTRoundButton(OTIcon icon, CGFloat size);
UIView *OTFormatChipView(NSString *text, OTIcon icon);
void OTAddTopShadow(UIView *view);
UIViewController *OTTopViewController(void);

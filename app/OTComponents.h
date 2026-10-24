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

@interface OTItemCell : UITableViewCell

@property (nonatomic, strong) OTImageView *artworkView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, strong) UILabel *durationLabel;
@property (nonatomic, strong) UILabel *indexLabel;
@property (nonatomic, strong) UIButton *moreButton;
@property (nonatomic, strong) OTItem *item;
@property (nonatomic, copy) void (^moreHandler)(OTItem *item);

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
@property (nonatomic, assign) NSInteger selectedIndex;
@property (nonatomic, copy) void (^onSelect)(NSInteger index);

- (void)setTitles:(NSArray<NSString *> *)titles selectedIndex:(NSInteger)selectedIndex;
- (void)selectIndex:(NSInteger)index animated:(BOOL)animated;

@end


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


UIButton *OTPillButton(NSString *title, OTIcon icon, BOOL filled);
UIButton *OTRoundButton(OTIcon icon, CGFloat size);
void OTAddTopShadow(UIView *view);

UIViewController *OTTopViewController(void);

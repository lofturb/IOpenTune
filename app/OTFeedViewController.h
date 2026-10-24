//
//  OTFeedViewController.h
//  OpenTune 9
//

#import <UIKit/UIKit.h>
#import "OTItem.h"
#import "OTComponents.h"

@interface OTFeedViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray<OTSection *> *sections;
@property (nonatomic, copy) NSString *continuation;
@property (nonatomic, copy) NSString *screenTitle;
@property (nonatomic, strong) UIView *topBar;
@property (nonatomic, strong) UILabel *topTitleLabel;
@property (nonatomic, strong) UIButton *leftButton;
@property (nonatomic, strong) UIButton *rightButton;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;
@property (nonatomic, strong) OTEmptyView *emptyView;
@property (nonatomic, strong) UIView *tableHeaderView;
@property (nonatomic, assign) BOOL loading;
@property (nonatomic, assign) BOOL loadedOnce;
@property (nonatomic, assign) BOOL paginating;
@property (nonatomic, copy) void (^paginationBlock)(void);

// Para subclases
- (void)loadContent;
- (void)reloadContent;
- (void)didSelectItem:(OTItem *)item inSection:(OTSection *)section;
- (void)setFeedSections:(NSArray<OTSection *> *)sections
           continuation:(NSString *)continuation
                 append:(BOOL)append;
- (void)finishLoadingWithError:(NSError *)error;

// Utilidades compartidas
- (void)showMenuForItem:(OTItem *)item sourceView:(UIView *)sourceView;
- (void)playItems:(NSArray<OTItem *> *)items startingAt:(OTItem *)item;
- (void)presentItem:(OTItem *)item;
- (void)updateBottomInset;
- (void)showLoadingIndicator:(BOOL)show;
- (void)showEmptyMessage:(NSString *)title subtitle:(NSString *)subtitle;
- (void)pushCollectionWithBrowseId:(NSString *)browseId
                            params:(NSString *)params
                             title:(NSString *)title
                              type:(OTItemType)type
                        playlistId:(NSString *)playlistId;
- (BOOL)isCurrentItem:(OTItem *)item;

@end

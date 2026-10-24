//
//  OTRootViewController.h
//  OpenTune 9
//

#import <UIKit/UIKit.h>

extern NSString *const OTBottomInsetDidChangeNotification;

CGFloat OTBottomInset(void);

@interface OTRootViewController : UIViewController

- (void)selectTab:(NSInteger)index;
- (void)openPlayer;
- (void)refreshBottomInset;

@end

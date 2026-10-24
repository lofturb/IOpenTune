//
//  OTTheme.h
//  OpenTune 9 - port nativo de OpenTune (Material Design 3) para iOS 9
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, OTIcon) {
    OTIconHome = 0,
    OTIconSearch,
    OTIconLibrary,
    OTIconMood,
    OTIconSettings,
    OTIconMoreVert,
    OTIconMoreHoriz,
    OTIconPlay,
    OTIconPause,
    OTIconNext,
    OTIconPrev,
    OTIconShuffle,
    OTIconRepeat,
    OTIconRepeatOne,
    OTIconHeart,
    OTIconHeartFill,
    OTIconDownload,
    OTIconDone,
    OTIconQueue,
    OTIconLyrics,
    OTIconClose,
    OTIconBack,
    OTIconChevronRight,
    OTIconChevronDown,
    OTIconPlus,
    OTIconTrash,
    OTIconClock,
    OTIconCheck,
    OTIconAlbum,
    OTIconArtist,
    OTIconPlaylist,
    OTIconVideo,
    OTIconRefresh,
    OTIconUser,
    OTIconStats,
    OTIconSleep,
    OTIconSpeed,
    OTIconWifi,
    OTIconExternal,
    OTIconSort,
    OTIconCast,
    OTIconVolume,
    OTIconMute,
    OTIconSeekBack,
    OTIconSeekForward,
    OTIconMic,
    OTIconGrid
};

// Colores del esquema M3 oscuro generado a partir de la semilla #ED5564.
@interface OTTheme : NSObject

+ (UIColor *)colorWithHex:(NSUInteger)hex;
+ (UIColor *)colorWithHex:(NSUInteger)hex alpha:(CGFloat)alpha;

// Superficies
+ (UIColor *)background;          // surface
+ (UIColor *)surface;             // surfaceContainerLow
+ (UIColor *)surfaceContainer;    // surfaceContainer
+ (UIColor *)surfaceHigh;         // surfaceContainerHigh
+ (UIColor *)surfaceHighest;      // surfaceContainerHighest
+ (UIColor *)navBackground;
+ (UIColor *)text;
+ (UIColor *)secondaryText;
+ (UIColor *)separator;
+ (UIColor *)outline;

// Acento (semilla configurable)
+ (UIColor *)primary;
+ (UIColor *)onPrimary;
+ (UIColor *)primaryContainer;
+ (UIColor *)onPrimaryContainer;
+ (UIColor *)secondary;
+ (UIColor *)secondaryContainer;
+ (UIColor *)onSecondaryContainer;
+ (UIColor *)tertiary;
+ (UIColor *)error;

+ (void)setAccentHex:(NSUInteger)hex;
+ (NSUInteger)accentHex;
+ (void)setPureBlack:(BOOL)pureBlack;
+ (BOOL)pureBlack;
+ (void)applyArtworkColor:(UIColor *)color;   // color dinamico desde la portada
+ (void)clearArtworkColor;

// Tipografia (escala M3)
+ (UIFont *)displaySmall;
+ (UIFont *)headlineSmall;
+ (UIFont *)headlineMedium;
+ (UIFont *)titleLarge;
+ (UIFont *)titleMedium;
+ (UIFont *)titleSmall;
+ (UIFont *)bodyLarge;
+ (UIFont *)bodyMedium;
+ (UIFont *)bodySmall;
+ (UIFont *)labelLarge;
+ (UIFont *)labelMedium;
+ (UIFont *)labelSmall;
+ (UIFont *)font:(CGFloat)size weight:(CGFloat)weight;

+ (UIImage *)icon:(OTIcon)icon size:(CGFloat)size;
+ (UIImage *)icon:(OTIcon)icon size:(CGFloat)size weight:(CGFloat)weight;
+ (UIImage *)brandMark:(CGFloat)size;
+ (UIImage *)musicPlaceholder:(CGFloat)size;

+ (UIButton *)iconButton:(OTIcon)icon
                    size:(CGFloat)size
                   color:(UIColor *)color
                  target:(id)target
                  action:(SEL)action;

+ (void)styleNavigationBar:(UINavigationBar *)bar;
+ (void)styleTableView:(UITableView *)tableView;
+ (void)styleCollectionView:(UICollectionView *)collectionView;
+ (void)roundCorners:(UIView *)view radius:(CGFloat)radius;
+ (void)applyShadow:(UIView *)view;

+ (void)showToast:(NSString *)text inView:(UIView *)view;
+ (void)showToast:(NSString *)text inView:(UIView *)view duration:(NSTimeInterval)duration;

+ (NSString *)formatTime:(double)seconds;
+ (NSString *)formatCount:(long long)count;
+ (NSString *)formatBytes:(unsigned long long)bytes;

+ (BOOL)isWide;
+ (CGFloat)contentWidthForWidth:(CGFloat)width;
+ (CGFloat)columnsForWidth:(CGFloat)width;

@end

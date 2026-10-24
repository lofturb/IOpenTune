//
//  OTImageCache.h
//  OpenTune 9
//

#import <UIKit/UIKit.h>

@interface OTImageCache : NSObject

+ (instancetype)sharedCache;

- (UIImage *)cachedImageForURLString:(NSString *)urlString size:(CGFloat)size;
- (void)imageForURLString:(NSString *)urlString
                     size:(CGFloat)size
               completion:(void (^)(UIImage *image))completion;
- (void)clearMemoryCache;
- (void)clearDiskCache;
- (unsigned long long)diskUsage;

@end


@interface OTImageView : UIImageView

@property (nonatomic, copy) NSString *imageURLString;

- (void)setImageURL:(NSString *)urlString placeholder:(UIImage *)placeholder;
- (void)setImageURL:(NSString *)urlString size:(CGFloat)size placeholder:(UIImage *)placeholder;
- (void)cancelLoading;

@end

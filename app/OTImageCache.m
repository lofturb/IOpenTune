//
//  OTImageCache.m
//  OpenTune 9
//

#import "OTImageCache.h"
#import "OTTheme.h"
#import <CommonCrypto/CommonDigest.h>
#import <ImageIO/ImageIO.h>

static NSString *OTSHA1(NSString *string)
{
    const char *cstr = [string UTF8String];
    unsigned char digest[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(cstr, (CC_LONG)strlen(cstr), digest);
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++) {
        [output appendFormat:@"%02x", digest[i]];
    }
    return output;
}

@interface OTImageCache ()
@property (nonatomic, strong) NSCache *memoryCache;
@property (nonatomic, strong) NSOperationQueue *decodeQueue;
@property (nonatomic, strong) NSMutableDictionary *pending;
@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, copy) NSString *diskDirectory;
@end

@implementation OTImageCache

+ (instancetype)sharedCache
{
    static OTImageCache *cache = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cache = [[OTImageCache alloc] init];
    });
    return cache;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _memoryCache = [[NSCache alloc] init];
        _memoryCache.countLimit = 160;
        _memoryCache.totalCostLimit = 40 * 1024 * 1024;
        _decodeQueue = [[NSOperationQueue alloc] init];
        _decodeQueue.maxConcurrentOperationCount = 4;
        _pending = [NSMutableDictionary dictionary];
        _session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];

        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString *caches = paths.count > 0 ? paths[0] : NSTemporaryDirectory();
        _diskDirectory = [caches stringByAppendingPathComponent:@"Arte"];
        [[NSFileManager defaultManager] createDirectoryAtPath:_diskDirectory
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:NULL];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleMemoryWarning)
                                                     name:UIApplicationDidReceiveMemoryWarningNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)handleMemoryWarning
{
    [self.memoryCache removeAllObjects];
}

- (NSString *)cacheKeyForURL:(NSString *)url size:(CGFloat)size
{
    NSInteger px = (NSInteger)MAX(64.0, size * [UIScreen mainScreen].scale);
    return [NSString stringWithFormat:@"%@#%ld", url, (long)px];
}

- (UIImage *)cachedImageForURLString:(NSString *)urlString size:(CGFloat)size
{
    if (urlString.length == 0) {
        return nil;
    }
    return [self.memoryCache objectForKey:[self cacheKeyForURL:urlString size:size]];
}

- (void)imageForURLString:(NSString *)urlString
                     size:(CGFloat)size
               completion:(void (^)(UIImage *image))completion
{
    if (completion == nil) {
        return;
    }
    if (urlString.length == 0) {
        completion(nil);
        return;
    }

    NSString *key = [self cacheKeyForURL:urlString size:size];
    UIImage *cached = [self.memoryCache objectForKey:key];
    if (cached) {
        completion(cached);
        return;
    }

    NSMutableArray *waiters = self.pending[key];
    if (waiters) {
        [waiters addObject:[completion copy]];
        return;
    }
    waiters = [NSMutableArray arrayWithObject:[completion copy]];
    self.pending[key] = waiters;

    NSInteger px = (NSInteger)MAX(64.0, size * [UIScreen mainScreen].scale);
    NSString *fileName = [NSString stringWithFormat:@"%@-%ld.img", OTSHA1(urlString), (long)px];
    NSString *diskPath = [self.diskDirectory stringByAppendingPathComponent:fileName];

    NSData *diskData = [NSData dataWithContentsOfFile:diskPath];
    if (diskData.length > 0) {
        __weak typeof(self) weakSelf = self;
        [self.decodeQueue addOperationWithBlock:^{
            UIImage *image = [OTImageCache decodeData:diskData maxPixelSize:px];
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf finishKey:key image:image];
            });
        }];
        return;
    }

    NSURL *url = [NSURL URLWithString:urlString];
    if (!url) {
        [self finishKey:key image:nil];
        return;
    }

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setValue:@"Mozilla/5.0 (iPad; CPU OS 9_3 like Mac OS X) AppleWebKit/601.1.46 (KHTML, like Gecko) Version/9.0 Mobile/13E233 Safari/601.1"
                   forHTTPHeaderField:@"User-Agent"];
    [request setValue:@"image/webp,image/*,*/*;q=0.8" forHTTPHeaderField:@"Accept"];
    request.timeoutInterval = 20.0;

    __weak typeof(self) weakSelf = self;
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request
                                                completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (!data || data.length == 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf finishKey:key image:nil];
            });
            return;
        }
        [[NSFileManager defaultManager] createDirectoryAtPath:weakSelf.diskDirectory
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:NULL];
        [data writeToFile:diskPath atomically:YES];

        [weakSelf.decodeQueue addOperationWithBlock:^{
            UIImage *image = [OTImageCache decodeData:data maxPixelSize:px];
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf finishKey:key image:image];
            });
        }];
    }];
    [task resume];
}

- (void)finishKey:(NSString *)key image:(UIImage *)image
{
    if (image) {
        NSUInteger cost = (NSUInteger)(image.size.width * image.size.height * 4.0);
        [self.memoryCache setObject:image forKey:key cost:cost];
    }
    NSArray *waiters = self.pending[key];
    [self.pending removeObjectForKey:key];
    for (void (^block)(UIImage *) in waiters) {
        block(image);
    }
}

+ (UIImage *)decodeData:(NSData *)data maxPixelSize:(NSInteger)maxPixelSize
{
    if (!data) {
        return nil;
    }
    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
    if (source) {
        NSDictionary *options = @{
            (id)kCGImageSourceCreateThumbnailFromImageAlways: @YES,
            (id)kCGImageSourceCreateThumbnailWithTransform: @YES,
            (id)kCGImageSourceThumbnailMaxPixelSize: @(maxPixelSize)
        };
        CGImageRef thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, (__bridge CFDictionaryRef)options);
        if (thumbnail) {
            UIImage *image = [UIImage imageWithCGImage:thumbnail
                                                 scale:[UIScreen mainScreen].scale
                                           orientation:UIImageOrientationUp];
            CGImageRelease(thumbnail);
            CFRelease(source);
            return image;
        }
        CFRelease(source);
    }
    return [UIImage imageWithData:data];
}

- (void)clearMemoryCache
{
    [self.memoryCache removeAllObjects];
}

- (void)clearDiskCache
{
    [[NSFileManager defaultManager] removeItemAtPath:self.diskDirectory error:NULL];
    [[NSFileManager defaultManager] createDirectoryAtPath:self.diskDirectory
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:NULL];
    [self.memoryCache removeAllObjects];
}

- (unsigned long long)diskUsage
{
    unsigned long long total = 0;
    NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtPath:self.diskDirectory];
    for (NSString *file in enumerator) {
        NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:
                               [self.diskDirectory stringByAppendingPathComponent:file] error:NULL];
        total += attrs.fileSize;
    }
    return total;
}

@end

#pragma mark - OTImageView

@interface OTImageView ()
@property (nonatomic, copy) NSString *currentRequestURL;
@property (nonatomic, assign) CGFloat requestedSize;
@end

@implementation OTImageView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.contentMode = UIViewContentModeScaleAspectFill;
        self.clipsToBounds = YES;
        self.backgroundColor = [OTTheme surfaceHigh];
    }
    return self;
}

- (void)setImageURL:(NSString *)urlString placeholder:(UIImage *)placeholder
{
    [self setImageURL:urlString size:MAX(self.bounds.size.width, 64.0) placeholder:placeholder];
}

- (void)setImageURL:(NSString *)urlString size:(CGFloat)size placeholder:(UIImage *)placeholder
{
    self.imageURLString = urlString;
    [self cancelLoading];
    if (placeholder) {
        self.image = placeholder;
    }

    if (urlString.length == 0) {
        return;
    }

    NSString *requestURL = [urlString copy];
    self.currentRequestURL = requestURL;
    self.requestedSize = size;

    UIImage *cached = [[OTImageCache sharedCache] cachedImageForURLString:urlString size:size];
    if (cached) {
        self.image = cached;
        return;
    }

    __weak typeof(self) weakSelf = self;
    [[OTImageCache sharedCache] imageForURLString:urlString size:size completion:^(UIImage *image) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        if (![strongSelf.currentRequestURL isEqualToString:requestURL]) {
            return;
        }
        if (image) {
            strongSelf.image = image;
        }
    }];
}

- (void)cancelLoading
{
    self.currentRequestURL = nil;
}

@end

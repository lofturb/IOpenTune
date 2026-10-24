//
//  OTDownloads.m
//  OpenTune 9
//

#import "OTDownloads.h"
#import "OTInnertube.h"
#import "OTStore.h"

@interface OTDownloads () <NSURLSessionDataDelegate>
@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableData *> *buffers;
@property (nonatomic, strong) NSMutableDictionary<NSString *, OTDownloadProgress> *progressBlocks;
@property (nonatomic, strong) NSMutableDictionary<NSString *, OTDownloadCompletion> *completionBlocks;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSURLSessionDataTask *> *tasks;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSValue *> *expectedSizes;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *lastReported;
@property (nonatomic, strong) NSMutableDictionary<NSString *, OTItem *> *pendingItems;
@end

@implementation OTDownloads

+ (instancetype)sharedDownloads
{
    static OTDownloads *downloads = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        downloads = [[OTDownloads alloc] init];
    });
    return downloads;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _buffers = [NSMutableDictionary dictionary];
        _progressBlocks = [NSMutableDictionary dictionary];
        _completionBlocks = [NSMutableDictionary dictionary];
        _tasks = [NSMutableDictionary dictionary];
        _expectedSizes = [NSMutableDictionary dictionary];
        _lastReported = [NSMutableDictionary dictionary];
        _pendingItems = [NSMutableDictionary dictionary];

        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        config.timeoutIntervalForRequest = 30.0;
        config.timeoutIntervalForResource = 900.0;
        _session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    }
    return self;
}

- (BOOL)isDownloadingItem:(OTItem *)item
{
    return item.itemId.length > 0 && self.tasks[item.itemId] != nil;
}

- (void)downloadItem:(OTItem *)item
            progress:(OTDownloadProgress)progress
          completion:(OTDownloadCompletion)completion
{
    if (!item.isPlayable) {
        if (completion) {
            completion(NO, [NSError errorWithDomain:@"OTDownloads" code:-1
                                           userInfo:@{NSLocalizedDescriptionKey: @"Canción no válida"}], nil);
        }
        return;
    }
    if (self.tasks[item.itemId]) {
        if (completion) {
            completion(NO, [NSError errorWithDomain:@"OTDownloads" code:-2
                                           userInfo:@{NSLocalizedDescriptionKey: @"Ya se está descargando"}], nil);
        }
        return;
    }
    if ([[OTStore sharedStore] isDownloaded:item]) {
        if (completion) {
            completion(YES, nil, [[OTStore sharedStore] localPathForItem:item]);
        }
        return;
    }

    self.progressBlocks[item.itemId] = [progress copy];
    self.completionBlocks[item.itemId] = [completion copy];
    self.pendingItems[item.itemId] = item;

    __weak typeof(self) weakSelf = self;
    [[OTInnertube shared] streamURLForVideo:item.itemId completion:^(NSURL *url, NSString *mimeType, NSString *clientName, NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        if (!url) {
            [strongSelf finishItemId:item.itemId success:NO error:error path:nil];
            return;
        }
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        request.timeoutInterval = 30.0;
        [request setValue:@"com.google.ios.youtube/19.29.1 (iPhone16,2; U; CPU iOS 17_5_1 like Mac OS X;)"
       forHTTPHeaderField:@"User-Agent"];
        NSURLSessionDataTask *task = [strongSelf.session dataTaskWithRequest:request];
        task.taskDescription = item.itemId;
        strongSelf.buffers[item.itemId] = [NSMutableData data];
        strongSelf.tasks[item.itemId] = task;
        [task resume];
    }];
}

- (void)cancelItem:(OTItem *)item
{
    NSURLSessionDataTask *task = self.tasks[item.itemId];
    if (task) {
        [task cancel];
    }
    [self cleanupItemId:item.itemId];
}

#pragma mark - NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler
{
    NSString *itemId = dataTask.taskDescription;
    if (itemId.length > 0 && [response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSInteger code = ((NSHTTPURLResponse *)response).statusCode;
        if (code >= 400) {
            completionHandler(NSURLSessionResponseCancel);
            NSError *error = [NSError errorWithDomain:@"OTDownloads" code:code
                                            userInfo:@{NSLocalizedDescriptionKey:
                                                           [NSString stringWithFormat:@"El servidor devolvió %ld", (long)code]}];
            [self finishItemId:itemId success:NO error:error path:nil];
            return;
        }
    }
    if (itemId.length > 0) {
        long long expected = response.expectedContentLength;
        if (expected > 0) {
            self.expectedSizes[itemId] = [NSValue valueWithBytes:&expected objCType:@encode(long long)];
        }
    }
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data
{
    NSString *itemId = dataTask.taskDescription;
    if (itemId.length == 0) {
        return;
    }
    NSMutableData *buffer = self.buffers[itemId];
    if (!buffer) {
        buffer = [NSMutableData data];
        self.buffers[itemId] = buffer;
    }
    [buffer appendData:data];

    long long expected = 0;
    NSValue *value = self.expectedSizes[itemId];
    if (value) {
        [value getValue:&expected];
    }
    if (expected > 0) {
        double progress = MIN(1.0, (double)buffer.length / (double)expected);
        NSNumber *last = self.lastReported[itemId];
        if (!last || progress - last.doubleValue > 0.01 || progress >= 1.0) {
            self.lastReported[itemId] = @(progress);
            OTDownloadProgress block = self.progressBlocks[itemId];
            if (block) {
                block(progress);
            }
        }
    }
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error
{
    NSString *itemId = task.taskDescription;
    if (itemId.length == 0) {
        return;
    }
    if (error) {
        if (error.code == NSURLErrorCancelled) {
            [self cleanupItemId:itemId];
            return;
        }
        [self finishItemId:itemId success:NO error:error path:nil];
        return;
    }
    NSData *data = self.buffers[itemId];
    if (data.length == 0) {
        NSError *emptyError = [NSError errorWithDomain:@"OTDownloads" code:-3
                                              userInfo:@{NSLocalizedDescriptionKey: @"Descarga vacía"}];
        [self finishItemId:itemId success:NO error:emptyError path:nil];
        return;
    }

    OTItem *stored = self.pendingItems[itemId];
    NSString *baseName = itemId;
    if (stored) {
        baseName = stored.artistsText.length > 0
            ? [NSString stringWithFormat:@"%@ - %@", stored.title, stored.artistsText]
            : (stored.title ?: itemId);
    }
    NSString *fileName = [NSString stringWithFormat:@"%@ [%@].m4a",
                          [self sanitizedName:baseName], itemId];
    NSString *directory = [[OTStore sharedStore] downloadsDirectory];
    NSString *path = [directory stringByAppendingPathComponent:fileName];
    NSError *writeError = nil;
    BOOL written = [data writeToFile:path options:NSDataWritingAtomic error:&writeError];
    if (!written) {
        [self finishItemId:itemId success:NO error:writeError path:nil];
        return;
    }

    if (stored) {
        [[OTStore sharedStore] registerDownload:stored path:path];
    }
    [self finishItemId:itemId success:YES error:nil path:path];
}

- (NSString *)sanitizedName:(NSString *)name
{
    NSCharacterSet *invalid = [NSCharacterSet characterSetWithCharactersInString:@"/\\:*?\"<>|"];
    NSString *clean = [[name componentsSeparatedByCharactersInSet:invalid] componentsJoinedByString:@"-"];
    if (clean.length > 70) {
        clean = [clean substringToIndex:70];
    }
    return clean.length > 0 ? clean : @"Cancion";
}

- (void)finishItemId:(NSString *)itemId success:(BOOL)success error:(NSError *)error path:(NSString *)path
{
    OTDownloadCompletion completion = self.completionBlocks[itemId];
    OTDownloadProgress progress = self.progressBlocks[itemId];
    if (success && progress) {
        progress(1.0);
    }
    [self cleanupItemId:itemId];
    if (completion) {
        completion(success, error, path);
    }
}

- (void)cleanupItemId:(NSString *)itemId
{
    [self.buffers removeObjectForKey:itemId];
    [self.progressBlocks removeObjectForKey:itemId];
    [self.completionBlocks removeObjectForKey:itemId];
    [self.tasks removeObjectForKey:itemId];
    [self.expectedSizes removeObjectForKey:itemId];
    [self.lastReported removeObjectForKey:itemId];
    [self.pendingItems removeObjectForKey:itemId];
}

@end

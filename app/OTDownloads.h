//
//  OTDownloads.h
//  OpenTune 9
//

#import <Foundation/Foundation.h>
#import "OTItem.h"

typedef void (^OTDownloadProgress)(double progress);
typedef void (^OTDownloadCompletion)(BOOL success, NSError *error, NSString *path);

@interface OTDownloads : NSObject

+ (instancetype)sharedDownloads;

- (BOOL)isDownloadingItem:(OTItem *)item;
- (void)downloadItem:(OTItem *)item
            progress:(OTDownloadProgress)progress
          completion:(OTDownloadCompletion)completion;
- (void)cancelItem:(OTItem *)item;

@end

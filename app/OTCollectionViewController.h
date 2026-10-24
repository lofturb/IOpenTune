//
//  OTCollectionViewController.h
//  OpenTune 9
//

#import "OTFeedViewController.h"

@interface OTCollectionViewController : OTFeedViewController

@property (nonatomic, copy) NSString *browseId;
@property (nonatomic, copy) NSString *params;
@property (nonatomic, copy) NSString *playlistId;
@property (nonatomic, copy) NSString *collectionTitle;
@property (nonatomic, assign) OTItemType collectionType;

@end

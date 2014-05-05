//
//  TCategoryStickersViewController.m
//  Tromke
//
//  Created by Satyanarayana SVV on 1/15/14.
//  Copyright (c) 2014 Tromkee. All rights reserved.
//

#import "TCategoryStickersViewController.h"
#import "TCategoryStickerCell.h"
#import "TPostViewController.h"

@interface TCategoryStickersViewController ()

@property (nonatomic, strong) NSArray* stickers;

@end

@implementation TCategoryStickersViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void)setCategory:(PFObject*)category {
    self.stickers = nil;
    [self.collectionView reloadData];
    
    _category = category;
    if ([Reachability isReachable]) {
        if (self.category) {
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
            PFRelation* stickers = [self.category relationforKey:@"Stickers"];
            PFQuery* stickersQuery = [stickers query];
            stickersQuery.cachePolicy = kPFCachePolicyCacheElseNetwork;
            stickersQuery.maxCacheAge = 3600;
            [stickersQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (error) {
                        NSLog(@"Error in getting stickers");
                    } else {
                        self.stickers = objects;
                        [self.collectionView reloadData];
                    }
                });
            }];
        }
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.view.backgroundColor = STICKERS_BG_COLOR;
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.stickers count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    static NSString* cellID = @"CategorySticker";
    TCategoryStickerCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellID forIndexPath:indexPath];
    
    PFObject* sticker = self.stickers[indexPath.item];
    
    PFFile *userImageFile = sticker[STICKER_IMAGE];
    [userImageFile getDataInBackgroundWithBlock:^(NSData *imageData, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!error) {
                TCategoryStickerCell* tempCell = (TCategoryStickerCell*)[collectionView cellForItemAtIndexPath:indexPath];
                tempCell.stickerImage.image = [UIImage imageWithData:imageData];
            }
        });
    }];

    return cell;
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"PostSticker"]) {
        [self.delegate userClickedSticker];
        NSIndexPath* indxPath = [[self.collectionView indexPathsForSelectedItems] firstObject];
        TPostViewController* postVC = segue.destinationViewController;
        postVC.postSticker = self.stickers[indxPath.item];
    }
}

@end

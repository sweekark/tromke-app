//
//  TCategoriesViewController.m
//  Tromke
//
//  Created by Satyanarayana SVV on 1/14/14.
//  Copyright (c) 2014 Tromkee. All rights reserved.
//

#import "TCategoriesViewController.h"
#import "TCategoryCell.h"
#import "TCategoryStickersViewController.h"


@interface TCategoriesViewController () <UICollectionViewDataSource, UICollectionViewDelegate, TStickersDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView *categoriesView;
@property (nonatomic, strong) NSArray* allCategories;
@property (nonatomic, strong) TCategoryStickersViewController* stickersVC;
@property (nonatomic) NSInteger currentSelectedItem;
@property (nonatomic, strong) UINavigationController* navController;

//@property (nonatomic) BOOL isStickersShowing;

- (IBAction)hideCategories:(id)sender;
@end

@implementation TCategoriesViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    self.currentSelectedItem = 0;
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hideCategories:) name:STICKER_POSTED object:nil];
    
    if ([Reachability isReachable]) {
        PFQuery* categoriesQuery = [PFQuery queryWithClassName:CATEGORY];
        categoriesQuery.cachePolicy = kPFCachePolicyCacheElseNetwork;
        categoriesQuery.maxCacheAge = 1209600;
        [categoriesQuery orderByAscending:CATEGORY_SORTBY];
        [categoriesQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            DLog(@"Categories received: %lu", (unsigned long)objects.count);
            if (error) {
                NSLog(@"Error in getting categories: %@", error.localizedDescription);
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.allCategories = objects;
                    [self.categoriesView reloadData];
                    self.stickersVC.category = self.allCategories[0];                        
                });
            }
        }];        
    }
}

-(void)viewWillAppear:(BOOL)animated {
//    self.isStickersShowing = NO;
    [super viewWillAppear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Collectionview Methods

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.allCategories count];
}

// The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    static NSString* cellID = @"Category";
    TCategoryCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellID forIndexPath:indexPath];
    
    PFObject* category = self.allCategories[indexPath.item];
    PFFile *userImageFile = category[CATEGORY_IMAGE];
    cell.categoryImage.image = [UIImage imageNamed:@"Placeholder"];
    if (userImageFile) {
        [cell.categoryImage setFile:userImageFile];
        [cell.categoryImage loadInBackground];
    }

    if (self.currentSelectedItem == indexPath.item) {
        cell.arrowImage.image = [UIImage imageNamed:@"NewCatArrow"];
        cell.categoryTitle.textColor = [UIColor blueColor];
    } else {
        cell.arrowImage.image = nil;
        cell.categoryTitle.textColor = [UIColor blackColor];
    }
    
//    [userImageFile getDataInBackgroundWithBlock:^(NSData *imageData, NSError *error) {
//        dispatch_async(dispatch_get_main_queue(), ^{
//            if (!error) {
//                TCategoryCell* tempCell = (TCategoryCell*)[collectionView cellForItemAtIndexPath:indexPath];
//                tempCell.categoryImage.image = [UIImage imageWithData:imageData];
//            } else {
//                NSLog(@"Error in getting ")
//            }
//        });
//    }];
    
    cell.categoryTitle.text = category[CATEGORY_NAME];
    
    return cell;
}


- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    self.currentSelectedItem = indexPath.item;
//    if (!self.isStickersShowing) {
//        self.stickersVC.category = self.allCategories[indexPath.item];
////        [self.delegate showCategoriesView];
//    } else {
//        [self.navController popToRootViewControllerAnimated:YES];
//        self.stickersVC.category = self.allCategories[indexPath.item];        
//    }
    
    
    [self.navController popToRootViewControllerAnimated:YES];
    self.stickersVC.category = self.allCategories[indexPath.item];
    
    [collectionView reloadData];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"CategoryStickers"]) {
        self.navController = segue.destinationViewController;
        self.stickersVC = [self.navController.viewControllers firstObject];
        self.stickersVC.delegate = self;
    }
}

-(void)userClickedSticker {
//    self.isStickersShowing = YES;
    self.categoriesView.userInteractionEnabled = NO;
    [self performSelector:@selector(enable) withObject:nil afterDelay:0.2];
}

-(void)enable {
    self.categoriesView.userInteractionEnabled = YES;
}

- (IBAction)hideCategories:(id)sender {
    [self.navController popToRootViewControllerAnimated:YES];
    [self.delegate hideCategoriesView];
//    self.isStickersShowing = NO;
}

@end

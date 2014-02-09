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

#define IMAGE @"Image"
#define NAME @"name"
#define SORTBY @"sort_no"

@interface TCategoriesViewController () <UICollectionViewDataSource, UICollectionViewDelegate, TStickersDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView *categoriesView;
@property (nonatomic, strong) NSArray* allCategories;
@property (nonatomic, strong) TCategoryStickersViewController* stickersVC;
@property (nonatomic) int currentSelectedItem;
@property (nonatomic, strong) UINavigationController* navController;

@property (nonatomic) BOOL isStickersShowing;

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
    self.currentSelectedItem = -1;
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    PFQuery* categoriesQuery = [PFQuery queryWithClassName:@"category"];
    [categoriesQuery orderByAscending:SORTBY];
    [categoriesQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (error) {
            NSLog(@"Error in getting categories: %@", error.localizedDescription);
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.allCategories = objects;
                [self.categoriesView reloadData];
            });
        }
    }];
}

-(void)viewWillAppear:(BOOL)animated {
    self.isStickersShowing = NO;
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
    
    PFFile *userImageFile = category[IMAGE];
    [userImageFile getDataInBackgroundWithBlock:^(NSData *imageData, NSError *error) {
        if (!error) {
            TCategoryCell* tempCell = (TCategoryCell*)[collectionView cellForItemAtIndexPath:indexPath];
            tempCell.categoryImage.image = [UIImage imageWithData:imageData];
        }
    }];
    
    cell.categoryTitle.text = category[NAME];
    
    return cell;
}


- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
//    if (self.currentSelectedItem == indexPath.item && self.isStickersShowing) {
//        return;
//    }

    self.currentSelectedItem = indexPath.item;
    if (!self.isStickersShowing) {
        self.stickersVC.category = self.allCategories[indexPath.item];
        [self.delegate showCategoriesView];
    } else {
        [self.navController popToRootViewControllerAnimated:YES];
        self.stickersVC.category = self.allCategories[indexPath.item];        
    }
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"CategoryStickers"]) {
        self.navController = segue.destinationViewController;
        self.stickersVC = [self.navController.viewControllers firstObject];
        self.stickersVC.delegate = self;
    }
}

-(void)userClickedSticker {
    self.isStickersShowing = YES;
}

- (IBAction)hideCategories:(id)sender {
    [self.delegate hideCategoriesView];
    self.isStickersShowing = NO;
}

@end

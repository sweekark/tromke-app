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
#define DISPLAY_NAME @"display_name"
#define SORTBY @"sort_no"

@interface TCategoriesViewController () <UICollectionViewDataSource, UICollectionViewDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView *categoriesView;
@property (nonatomic, strong) NSArray* allCategories;
@property (nonatomic, strong) TCategoryStickersViewController* stickersVC;

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
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    PFQuery* categoriesQuery = [PFQuery queryWithClassName:@"category"];
    [categoriesQuery orderByAscending:SORTBY];
    [categoriesQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (error) {
            NSLog(@"Error in getting categories: %@", error.localizedDescription);
        } else {
            for (PFObject* obj in objects) {
                NSLog(@"%@", obj);
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                self.allCategories = objects;
                [self.categoriesView reloadData];
            });
        }
    }];
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
    
    cell.categoryTitle.text = category[DISPLAY_NAME];
    
    return cell;
}


- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    self.stickersVC.category = self.allCategories[indexPath.item];
    [self.delegate showCategoriesView];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"CategoryStickers"]) {
        UINavigationController* navController = segue.destinationViewController;
        self.stickersVC = [navController.viewControllers firstObject];
    }
}

@end
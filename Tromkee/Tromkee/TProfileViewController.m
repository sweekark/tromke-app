//
//  TProfileViewController.m
//  Tromke
//
//  Created by Satyanarayana SVV on 3/1/14.
//  Copyright (c) 2014 Tromkee. All rights reserved.
//

#import "TProfileViewController.h"
#import "MBProgressHUD.h"
#import "TProfileCell.h"
#import "TFollowCell.h"
#import "MBProgressHUD.h"

#define SORT_KEY @"updatedAt"


NS_ENUM(int, ProfileDisplay) {
    ProfileDisplayActivity,
    ProfileDisplayFollowers,
    ProfileDisplayFollowing
};

@interface TProfileViewController () <UICollectionViewDataSource, UICollectionViewDelegate>

@property (weak, nonatomic) IBOutlet UILabel *noResultsLabel;
@property (weak, nonatomic) IBOutlet UILabel *userName;
@property (weak, nonatomic) IBOutlet PFImageView *userImage;
@property (weak, nonatomic) IBOutlet UILabel *userPoints;
@property (weak, nonatomic) IBOutlet UIButton *followButton;
@property (weak, nonatomic) IBOutlet UILabel *followersValue;
@property (weak, nonatomic) IBOutlet UILabel *followingValue;
@property (weak, nonatomic) IBOutlet UICollectionView* collectionView;

@property (strong, nonatomic) NSMutableArray* postsArray;
@property (strong, nonatomic) NSMutableArray* followersArray;
@property (strong, nonatomic) NSMutableArray* followingArray;

@property (nonatomic, strong) MBProgressHUD* progress;
@property (nonatomic) BOOL isFollowing;
@property (nonatomic) int currentDisplay;

@end

@implementation TProfileViewController

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
    self.currentDisplay = 0;
    if ([self.userProfile.objectId isEqualToString:[PFUser currentUser].objectId]) {
        self.followButton.hidden = YES;
    } else {
        [self updateFollowButton];
    }
    
    
	// Do any additional setup after loading the view.
    PFFile *imageFile = [self.userProfile objectForKey:FACEBOOK_SMALLPIC_KEY];
    if (imageFile) {
        [self.userImage setFile:imageFile];
        [self.userImage loadInBackground];
    } else {
        NSLog(@"No image found");
    }
    self.userName.text = self.userProfile[@"displayName"];
    self.postsArray = [[NSMutableArray alloc] init];
    [self updateActivity];
    [self updateFollowersAndFollowingValues];
}

- (IBAction)goBack:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}


-(void)updateActivity {
    self.progress = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.progress.labelText = @"Fetching ...";
    self.progress.dimBackground = YES;
    PFQuery* activityQuery = [PFQuery queryWithClassName:@"Activity" predicate:[NSPredicate predicateWithFormat:@"fromUser == %@", self.userProfile]];
    activityQuery.cachePolicy = kPFCachePolicyCacheThenNetwork;
    activityQuery.maxCacheAge = 300;
    [activityQuery includeKey:@"fromUser"];
    [activityQuery orderByDescending:SORT_KEY];
    __weak TProfileViewController* weakSelf = self;
    [activityQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        DLog(@"Received activities in profile: %lu", (unsigned long)objects.count);
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.progress hide:YES];
            if (error) {
                NSLog(@"Error in getting activities: %@", error.localizedDescription);
            } else {
                weakSelf.postsArray = [objects mutableCopy];
                if ([weakSelf.postsArray count]) {
                    weakSelf.noResultsLabel.hidden = YES;
                    weakSelf.collectionView.hidden = NO;
                    [weakSelf.collectionView reloadData];
                } else {
                    weakSelf.noResultsLabel.hidden = NO;
                    weakSelf.collectionView.hidden = YES;
                }
            }
        });
    }];
}

-(void)updateFollowerUsers {
    self.progress = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.progress.labelText = @"Fetching ...";
    self.progress.dimBackground = YES;

    PFQuery* followersQuery = [PFQuery queryWithClassName:@"Activity"];
//    [followersQuery whereKey:@"fromUser" equalTo:self.userProfile];
    [followersQuery whereKey:@"toUser" equalTo:[PFUser currentUser]];
    [followersQuery whereKey:@"type" equalTo:@"FOLLOW"];

    
    [followersQuery includeKey:@"fromUser"];
    followersQuery.cachePolicy = kPFCachePolicyCacheThenNetwork;
    followersQuery.maxCacheAge = 300;
    __weak TProfileViewController* weakSelf = self;
    [followersQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        DLog(@"Followers count is : %lu", (unsigned long)objects.count);
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.progress hide:YES];
            if (error) {
                NSLog(@"Error in getting activities: %@", error.localizedDescription);
            } else {
                weakSelf.postsArray = [objects mutableCopy];
                if ([weakSelf.postsArray count]) {
                    weakSelf.noResultsLabel.hidden = YES;
                    weakSelf.collectionView.hidden = NO;
                    [weakSelf.collectionView reloadData];
                } else {
                    weakSelf.noResultsLabel.hidden = NO;
                    weakSelf.collectionView.hidden = YES;
                }
            }
        });
    }];
}

-(void)updateFollowingUsers {
    self.progress = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.progress.labelText = @"Fetching ...";
    self.progress.dimBackground = YES;
    
    PFQuery* followersQuery = [PFQuery queryWithClassName:@"Activity"];
    [followersQuery whereKey:@"fromUser" equalTo:[PFUser currentUser]];
//    [followersQuery whereKey:@"toUser" equalTo:self.userProfile];
    [followersQuery whereKey:@"type" equalTo:@"FOLLOW"];

    [followersQuery includeKey:@"toUser"];
    followersQuery.cachePolicy = kPFCachePolicyCacheThenNetwork;
    followersQuery.maxCacheAge = 300;
    __weak TProfileViewController* weakSelf = self;
    [followersQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        DLog(@"Following count is : %lu", (unsigned long)objects.count);
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.progress hide:YES];
            if (error) {
                NSLog(@"Error in getting activities: %@", error.localizedDescription);
            } else {
                weakSelf.postsArray = [objects mutableCopy];
                if ([weakSelf.postsArray count]) {
                    weakSelf.noResultsLabel.hidden = YES;
                    weakSelf.collectionView.hidden = NO;
                    [weakSelf.collectionView reloadData];
                } else {
                    weakSelf.noResultsLabel.hidden = NO;
                    weakSelf.collectionView.hidden = YES;
                }
            }
        });
    }];
}

-(void)updateFollowersAndFollowingValues {
    
    PFQuery* followQuery = [PFUser query];
    __weak TProfileViewController* weakSelf = self;
    [followQuery getObjectInBackgroundWithId:self.userProfile.objectId block:^(PFObject *object, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            PFUser* usr = (PFUser*)object;
            DLog(@"Followers Value: %d, Following Value: %d", [usr[@"followers"] intValue],  [usr[@"following"] intValue]);
            weakSelf.followersValue.text = [NSString stringWithFormat:@"%d", [usr[@"followers"] intValue]];
            weakSelf.followingValue.text = [NSString stringWithFormat:@"%d", [usr[@"following"] intValue]];
        });
    }];
}

-(void)updateFollowButton {
    PFQuery* activityQuery = [PFQuery queryWithClassName:@"Activity" predicate:[NSPredicate predicateWithFormat:@"toUser == %@ AND fromUser == %@", self.userProfile, [PFUser currentUser]]];
    __weak TProfileViewController* weakself = self;
    [activityQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            weakself.followButton.hidden = NO;
            if (objects.count) {
                [weakself.followButton setTitle:@"Following" forState:UIControlStateNormal];
            } else {
                [weakself.followButton setTitle:@"Follow" forState:UIControlStateNormal];
            }
        });
    }];
}




- (IBAction)followTheUser:(id)sender {
    if (![[PFUser currentUser] isAuthenticated]) {
        [[[UIAlertView alloc] initWithTitle:@"Warning" message:@"You need to login inorder to follow other users" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
        return;
    }
    
    if (self.isFollowing) {
        PFQuery* activity = [PFQuery queryWithClassName:@"Actvity"];
        [activity whereKey:@"fromUser" equalTo:[PFUser currentUser]];
        [activity whereKey:@"toUser" equalTo:self.userProfile];
        [activity whereKey:@"type" equalTo:@"FOLLOW"];
        [activity findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            DLog(@"Deleted following");
            if (!error) {
                for (PFObject *activity in objects) {
                    [activity delete];
                }
            }
        }];
        self.isFollowing = NO;
        [self.followButton setTitle:@"Follow" forState:UIControlStateNormal];
    } else {
        PFObject* activiy = [PFObject objectWithClassName:@"Activity"];
        activiy[@"fromUser"] = [PFUser currentUser];
        activiy[@"toUser"] = self.userProfile;
        activiy[@"type"] = @"FOLLOW";
        
        __weak TProfileViewController* weakself = self;
        [activiy saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            [weakself.progress hide:YES];
                dispatch_async(dispatch_get_main_queue(), ^{
            if (succeeded) {
                    [self updateFollowButton];
            }
                });                    
        }];
        self.isFollowing = YES;
        [self.followButton setTitle:@"Following" forState:UIControlStateNormal];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    // Dispose of any resources that can be recreated.
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.postsArray.count;
}

// The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.currentDisplay == ProfileDisplayActivity) {
        static NSString* cellIdentifier = @"POSTCELL";
        
        TProfileCell* cell = (TProfileCell*)[collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
        
        PFObject* post = self.postsArray[indexPath.row];
        cell.postedTime.text = [TUtility computePostedTime:post.updatedAt];
        if ([post[@"type"] isEqualToString:COMMENT]) {
            cell.comment.text = [NSString stringWithFormat:@"posted %@", post[@"content"]];
        } else if ([post[@"type"] isEqualToString:THANKS]) {
            cell.comment.text = @"posted Thanks";
        } else if ([post[@"type"] isEqualToString:IMAGE_COMMENT]) {
            cell.comment.text = [NSString stringWithFormat:@"posted image with %@", post[@"content"]];
        } else if ([post[@"type"] isEqualToString:IMAGE_ONLY]) {
            cell.comment.text = @"posted Image";
        }
        //    [cell.comment sizeToFit];
        
        
        PFObject* fromUser = post[@"fromUser"];
        cell.personName.text = fromUser[@"displayName"];
        PFFile* imgFile = fromUser[FACEBOOK_SMALLPIC_KEY];
        if (imgFile) {
            [cell.personImage setFile:imgFile];
            [cell.personImage loadInBackground];
        }
        
        return cell;
    } else{
        static NSString* cellIdentifier = @"FOLLOWCELL";
        TFollowCell* cell = (TFollowCell*)[collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
        cell.personImage.image = [UIImage imageNamed:@"Personholder"];
        
        PFObject* act = self.postsArray[indexPath.row];
        PFUser* usr;
        if (self.currentDisplay == ProfileDisplayFollowers) {
            usr = act[@"fromUser"];
        } else if (self.currentDisplay == ProfileDisplayFollowing) {
            usr = act[@"toUser"];
        }

        PFFile *imageFile = [usr objectForKey:FACEBOOK_SMALLPIC_KEY];
        if (imageFile) {
            cell.personImage.image = [UIImage imageNamed:@"PersonHolder"];
            [cell.personImage setFile:imageFile];
            [cell.personImage loadInBackground];
        } else {
            NSLog(@"No image found");
        }

        return cell;
    }
    
    return nil;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGSize cellSize;
    switch (self.currentDisplay) {
        case ProfileDisplayActivity:
            cellSize = CGSizeMake(310, 100);
            break;
        case ProfileDisplayFollowers:
        case ProfileDisplayFollowing:            
            cellSize = CGSizeMake(90, 90);
            break;
    }
    
    return cellSize;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
}

#pragma mark - Actions

- (IBAction)showActivity:(id)sender {
    self.currentDisplay = ProfileDisplayActivity;
    [self updateActivity];
}

- (IBAction)showFollowers:(id)sender {
    self.currentDisplay = ProfileDisplayFollowers;
    [self updateFollowerUsers];
}

- (IBAction)showFollowing:(id)sender {
    self.currentDisplay = ProfileDisplayFollowing;
    [self updateFollowingUsers];
}


-(BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    if ([identifier isEqualToString:@"PROFILE"]) {
        if (self.currentDisplay == ProfileDisplayActivity) {
            return NO;
        }
    }
    
    return YES;
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"PROFILE"]) {
        NSIndexPath* indxPath = [[self.collectionView indexPathsForSelectedItems] firstObject];
        PFObject* act = self.postsArray[indxPath.row];
        PFUser* usr;
        if (self.currentDisplay == ProfileDisplayFollowers) {
            usr = act[@"fromUser"];
        } else if (self.currentDisplay == ProfileDisplayFollowing) {
            usr = act[@"toUser"];
        }
        
        TProfileViewController* profileVC = segue.destinationViewController;
        profileVC.userProfile = usr;
    }
}
@end

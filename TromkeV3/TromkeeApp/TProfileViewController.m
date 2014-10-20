//
//  TProfileViewController.m
//  Tromke
//
//  Created by Satyanarayana SVV on 3/1/14.
//  Copyright (c) 2014 Tromkee. All rights reserved.
//

#import "TProfileViewController.h"
#import "TProfileCell.h"
#import "TFollowCell.h"

#define SORT_KEY @"createdAt"


NS_ENUM(int, ProfileDisplay) {
    ProfileDisplayActivity = 0,
    ProfileDisplayFollowers,
    ProfileDisplayFollowing
};

@interface TProfileViewController () <UIActionSheetDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (weak, nonatomic) IBOutlet UIView *buttonsView;
@property (weak, nonatomic) IBOutlet UIButton *submitBtn;
@property (weak, nonatomic) IBOutlet UILabel *noResultsLabel;
@property (weak, nonatomic) IBOutlet UITextField *userName;
@property (weak, nonatomic) IBOutlet PFImageView *userImage;
@property (weak, nonatomic) IBOutlet UILabel *userPoints;
@property (weak, nonatomic) IBOutlet UIButton *followButton;
@property (weak, nonatomic) IBOutlet UILabel *followersValue;
@property (weak, nonatomic) IBOutlet UILabel *followingValue;
@property (weak, nonatomic) IBOutlet UICollectionView* collectionView;

@property (strong, nonatomic) NSMutableArray* postsArray;
@property (strong, nonatomic) NSMutableArray* followersArray;
@property (strong, nonatomic) NSMutableArray* followingArray;

@property (nonatomic) BOOL isFollowing;
@property (nonatomic) int currentDisplay;

@property (nonatomic) int totalFollowers;
@property (nonatomic) int totalFollowing;


@property (weak, nonatomic) IBOutlet UIButton *activityButton;
@property (weak, nonatomic) IBOutlet UIButton *followersButton;
@property (weak, nonatomic) IBOutlet UIButton *followingButton;


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
    self.submitBtn.hidden = YES;
    self.currentDisplay = ProfileDisplayActivity;
    if ([self.userProfile.objectId isEqualToString:[PFUser currentUser].objectId]) {
        self.followButton.hidden = YES;
        UITapGestureRecognizer* tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(selectPhoto)];
        [self.userImage addGestureRecognizer:tapGesture];
    } else {
        [self updateFollowButton];
    }
    
    
	// Do any additional setup after loading the view.
    PFFile *imageFile = [self.userProfile objectForKey:FACEBOOK_SMALLPIC_KEY];
    if (imageFile) {
        [self.userImage setFile:imageFile];
        [self.userImage loadInBackground];
    } else {
        DLog(@"No image found");
    }
    self.userName.text = [TUtility getDisplayNameForUser:self.userProfile]; //self.userProfile[USER_DISPLAY_NAME];
    self.postsArray = [[NSMutableArray alloc] init];

    [self updateFollowersAndFollowingValues];
}


-(void)viewWillAppear:(BOOL)animated {
    [self updateCurrentDisplay];
    [super viewWillAppear:animated];
}

-(void)updateCurrentDisplay {
    if (self.currentDisplay == ProfileDisplayActivity) {
        [self updateActivity];
    } else if (self.currentDisplay == ProfileDisplayFollowers) {
        [self updateFollowerUsers];
    } else if (self.currentDisplay == ProfileDisplayFollowing) {
        [self updateFollowingUsers];
    }
}

-(void)selectPhoto {
    UIActionSheet* actSheet = [[UIActionSheet alloc] initWithTitle:@"Select source for camera" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Camera", @"Album", nil];
    [actSheet showInView:self.view];
}

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 2) {
        return;
    }
    
    UIImagePickerController* imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.delegate = self;
    imagePicker.allowsEditing = YES;
    
    if (buttonIndex == 0) {
        imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
    } else if (buttonIndex == 1) {
        imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    }
    
    [self presentViewController:imagePicker animated:YES completion:nil];
}

//Tells the delegate that the user picked a still image or movie.
-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage *image = [info objectForKey:UIImagePickerControllerEditedImage];
    [TUtility uploadUserImage:image withCompletionHandler:^(BOOL success, UIImage *img) {
        if (success) {
            self.userImage.image = img;
            [self performSelector:@selector(updateCurrentDisplay) withObject:nil afterDelay:2.0];
        }
    }];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (IBAction)goBack:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}


-(void)updateActivity {
    if ([Reachability isReachable]) {
        self.activityButton.hidden = YES;
        [self.followersButton setImage:[UIImage imageNamed:@"NewBlueBuddy"] forState:UIControlStateNormal];
        [self.followingButton setImage:[UIImage imageNamed:@"NewBlueBuddy"] forState:UIControlStateNormal];
        
        self.buttonsView.userInteractionEnabled = NO;
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
        PFQuery* activityQuery = [PFQuery queryWithClassName:@"Activity" predicate:[NSPredicate predicateWithFormat:@"fromUser == %@", self.userProfile]];
        activityQuery.cachePolicy = kPFCachePolicyCacheThenNetwork;
        activityQuery.maxCacheAge = 300;
        [activityQuery includeKey:POST_FROMUSER];
        [activityQuery includeKey:@"toUser"];
        [activityQuery orderByDescending:SORT_KEY];
        __weak TProfileViewController* weakSelf = self;
        [activityQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            DLog(@"Received activities in profile: %lu", (unsigned long)objects.count);
            self.buttonsView.userInteractionEnabled = YES;
            dispatch_async(dispatch_get_main_queue(), ^{
                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
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
}

-(void)updateFollowerUsers {
    if ([Reachability isReachable]) {
        self.activityButton.hidden = NO;
        [self.followersButton setImage:[UIImage imageNamed:@"NewYelloBuddy"] forState:UIControlStateNormal];
        [self.followingButton setImage:[UIImage imageNamed:@"NewBlueBuddy"] forState:UIControlStateNormal];
        
        self.buttonsView.userInteractionEnabled = NO;
        self.noResultsLabel.hidden = self.collectionView.hidden = YES;
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
        
        PFQuery* followersQuery = [PFQuery queryWithClassName:@"Activity"];
//        [followersQuery whereKey:POST_FROMUSER equalTo:self.userProfile];
        [followersQuery whereKey:@"toUser" equalTo:self.userProfile];
        [followersQuery whereKey:POST_TYPE equalTo:ACTIVITY_TYPE_FOLLOW];
        [followersQuery includeKey:POST_FROMUSER];
        [followersQuery selectKeys:@[POST_FROMUSER]];
        followersQuery.cachePolicy = kPFCachePolicyCacheThenNetwork;
        followersQuery.maxCacheAge = 300;
        __weak TProfileViewController* weakSelf = self;
        [followersQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            self.buttonsView.userInteractionEnabled = YES;
            DLog(@"Followers count is : %lu", (unsigned long)objects.count);
            dispatch_async(dispatch_get_main_queue(), ^{
                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                if (error) {
                    NSLog(@"Error in getting followers: %@", error.localizedDescription);
                } else {
//                    weakSelf.postsArray = [objects mutableCopy];
                    if ([objects count]) {
                        weakSelf.noResultsLabel.hidden = YES;
                        weakSelf.collectionView.hidden = NO;
                        weakSelf.postsArray = [[objects valueForKeyPath:@"fromUser"] mutableCopy];
                        [weakSelf.collectionView reloadData];
                    } else {
                        [weakSelf.postsArray removeAllObjects];
                        [weakSelf.collectionView reloadData];
//                        weakSelf.noResultsLabel.hidden = NO;
//                        weakSelf.collectionView.hidden = YES;
                    }
                }
            });
        }];
    }
}

-(void)updateFollowingUsers {
    if ([Reachability isReachable]) {
        self.activityButton.hidden = NO;
        [self.followersButton setImage:[UIImage imageNamed:@"NewBlueBuddy"] forState:UIControlStateNormal];
        [self.followingButton setImage:[UIImage imageNamed:@"NewYelloBuddy"] forState:UIControlStateNormal];
        
        self.buttonsView.userInteractionEnabled = NO;
        self.noResultsLabel.hidden = self.collectionView.hidden = YES;
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
        PFQuery* followersQuery = [PFQuery queryWithClassName:@"Activity"];
        [followersQuery whereKey:POST_FROMUSER equalTo:self.userProfile];
//        [followersQuery whereKey:@"toUser" equalTo:self.userProfile];
        [followersQuery whereKey:POST_TYPE equalTo:ACTIVITY_TYPE_FOLLOW];
        [followersQuery includeKey:@"toUser"];
        [followersQuery selectKeys:@[@"toUser"]];
        followersQuery.cachePolicy = kPFCachePolicyCacheThenNetwork;
        followersQuery.maxCacheAge = 300;
        __weak TProfileViewController* weakSelf = self;
        [followersQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            self.buttonsView.userInteractionEnabled = YES;
            DLog(@"Following count is : %lu", (unsigned long)objects.count);
            dispatch_async(dispatch_get_main_queue(), ^{
                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                if (error) {
                    NSLog(@"Error in getting following users: %@", error.localizedDescription);
                } else {
//                    weakSelf.postsArray = [objects mutableCopy];
                    if ([objects count]) {
                        weakSelf.noResultsLabel.hidden = YES;
                        weakSelf.collectionView.hidden = NO;
                        weakSelf.postsArray = [[objects valueForKeyPath:@"toUser"] mutableCopy];
                        [weakSelf.collectionView reloadData];
                    } else {
                        [weakSelf.postsArray removeAllObjects];
                        [weakSelf.collectionView reloadData];
//                        weakSelf.noResultsLabel.hidden = NO;
//                        weakSelf.collectionView.hidden = YES;
                    }
                }
            });
        }];
    }
}

-(void)updateFollowersAndFollowingValues {
    if ([Reachability isReachable]) {
        PFQuery* followQuery = [PFUser query];
        __weak TProfileViewController* weakSelf = self;
        [followQuery getObjectInBackgroundWithId:self.userProfile.objectId block:^(PFObject *object, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                PFUser* usr = (PFUser*)object;
                DLog(@"Followers Value: %d, Following Value: %d", [usr[@"followers"] intValue],  [usr[@"following"] intValue]);
                weakSelf.totalFollowers = [usr[@"followers"] intValue];
                weakSelf.followersValue.text = [NSString stringWithFormat:@"%d", [usr[@"followers"] intValue]];
                weakSelf.totalFollowing = [usr[@"following"] intValue];
                weakSelf.followingValue.text = [NSString stringWithFormat:@"%d", [usr[@"following"] intValue]];
            });
        }];
    }
}

-(void)updateFollowButton {
    if ([Reachability isReachable]) {
        PFQuery* activityQuery = [PFQuery queryWithClassName:@"Activity" predicate:[NSPredicate predicateWithFormat:@"toUser == %@ AND fromUser == %@ AND type == %@", self.userProfile, [PFUser currentUser], @"FOLLOW"]];
        [activityQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            self.followButton.hidden = NO;
            if (objects.count) {
                self.isFollowing = YES;
                [self.followButton setTitle:@"Unfollow" forState:UIControlStateNormal];
            } else {
                self.isFollowing = NO;
                [self.followButton setTitle:@"Follow" forState:UIControlStateNormal];
            }
        }];
    }
}


- (IBAction)followTheUser:(id)sender {
    if (![[PFUser currentUser] isAuthenticated]) {
        [[[UIAlertView alloc] initWithTitle:@"Warning" message:@"You need to login inorder to follow other users" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
        return;
    }
    
    if (![Reachability isReachable]) {
        return;
    }
    
    self.followButton.userInteractionEnabled = NO;
    if (self.isFollowing) {
        if (self.currentDisplay == ProfileDisplayFollowers) {
            NSInteger indx = [self.postsArray indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
                return [[(PFUser*)obj objectId] isEqualToString:[[PFUser currentUser] objectId]];
            }];
            
            if (indx != NSNotFound) {
                [self.postsArray removeObjectAtIndex:indx];
                //            [self.postsArray removeObject:[PFUser currentUser]];
                [self.collectionView reloadData];
            }
        }

        if (self.totalFollowers > 0) {
            self.totalFollowers--;
            self.followersValue.text = [NSString stringWithFormat:@"%d", self.totalFollowers];
        }
        
        self.isFollowing = NO;
        [self.followButton setTitle:@"Follow" forState:UIControlStateNormal];
        
        PFQuery* activity = [PFQuery queryWithClassName:@"Activity"];
        [activity whereKey:POST_FROMUSER equalTo:[PFUser currentUser]];
        [activity whereKey:@"toUser" equalTo:self.userProfile];
        [activity whereKey:POST_TYPE equalTo:ACTIVITY_TYPE_FOLLOW];
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
        [activity getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
            DLog(@"Deleted following");
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            [object deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                self.followButton.userInteractionEnabled = YES;                
//                if (succeeded) {
//                    self.isFollowing = NO;
//                    [self.followButton setTitle:@"Follow" forState:UIControlStateNormal];
//                }
            }];
        }];
    } else {
        if (self.currentDisplay == ProfileDisplayFollowers) {
            [self.postsArray addObject:[PFUser currentUser]];
            [self.collectionView reloadData];
        }
        
        self.totalFollowers++;
        self.followersValue.text = [NSString stringWithFormat:@"%d", self.totalFollowers];
        
        self.isFollowing = YES;
        [self.followButton setTitle:@"Unfollow" forState:UIControlStateNormal];
        
        PFObject* activiy = [PFObject objectWithClassName:@"Activity"];
        activiy[POST_FROMUSER] = [PFUser currentUser];
        activiy[@"toUser"] = self.userProfile;
        activiy[POST_TYPE] = ACTIVITY_TYPE_FOLLOW;
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
        [activiy saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            self.followButton.userInteractionEnabled = YES;
//            if (succeeded) {
//                self.isFollowing = YES;
//                [self.followButton setTitle:@"Following" forState:UIControlStateNormal];
//            }
        }];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    // Dispose of any resources that can be recreated.
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    
    if (self.postsArray.count == 0) {
        self.noResultsLabel.hidden = NO;
        self.collectionView.hidden = YES;
    } else {
        self.noResultsLabel.hidden = YES;
        self.collectionView.hidden = NO;
    }
    
    return self.postsArray.count;
}

// The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {

    if (self.currentDisplay == ProfileDisplayActivity) {
        static NSString* cellIdentifier = @"POSTCELL";
        
        TProfileCell* cell = (TProfileCell*)[collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
        
        PFObject* post = self.postsArray[indexPath.row];
        cell.postedTime.text = [TUtility computePostedTime:post.createdAt];
        
        NSString* comment = @"";
        NSRange postedRange;
        if ([post[POST_TYPE] isEqualToString:ACTIVITY_TYPE_COMMENT]) {
            comment = [NSString stringWithFormat:@"Commented %@", post[@"content"]];
            postedRange = [comment rangeOfString:@"Commented"];
        } else if ([post[POST_TYPE] isEqualToString:ACTIVITY_TYPE_LIKE]) {
            comment = @"Liked";
            postedRange = [comment rangeOfString:@"Liked"];
        } else if ([post[POST_TYPE] isEqualToString:ACTIVITY_TYPE_IMAGE_COMMENT]) {
            comment = [NSString stringWithFormat:@"Posted image with %@", post[@"content"]];
            postedRange = [comment rangeOfString:@"Posted"];
        } else if ([post[POST_TYPE] isEqualToString:ACTIVITY_TYPE_IMAGE_ONLY]) {
            comment = @"Posted Image";
            postedRange = [comment rangeOfString:@"Posted"];
        } else if ([post[POST_TYPE] isEqualToString:ACTIVITY_TYPE_FOLLOW]) {
            PFUser* touser = post[@"toUser"];
            comment = [NSString stringWithFormat:@"Following %@", [TUtility getDisplayNameForUser:touser]];
            postedRange = [comment rangeOfString:@"Following"];
        } else if ([post[POST_TYPE] isEqualToString:ACTIVITY_TYPE_THANKS]) {
            PFUser* touser = post[@"toUser"];
            comment = [NSString stringWithFormat:@"Thanked %@", [TUtility getDisplayNameForUser:touser]];
            postedRange = [comment rangeOfString:@"Thanked"];
        }

        NSMutableAttributedString* msgStr = [[NSMutableAttributedString alloc] initWithString:comment];
        [msgStr addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:14] range:postedRange];
        cell.comment.attributedText = msgStr;
        
        
        PFUser* fromUser = post[POST_FROMUSER];
        cell.personName.text = [TUtility getDisplayNameForUser:fromUser];//fromUser[USER_DISPLAY_NAME];
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
        
//        PFObject* act = self.postsArray[indexPath.row];
        PFUser* usr = self.postsArray[indexPath.row];
//        if (self.currentDisplay == ProfileDisplayFollowers) {
//            usr = act[POST_FROMUSER];
//        } else if (self.currentDisplay == ProfileDisplayFollowing) {
//            usr = act[@"toUser"];
//        }

        cell.personName.text = [TUtility getDisplayNameForUser:usr];//usr[USER_DISPLAY_NAME];
        PFFile *imageFile = [usr objectForKey:FACEBOOK_SMALLPIC_KEY];
        cell.personImage.image = [UIImage imageNamed:@"Personholder"];
        if (imageFile) {
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
            cellSize = CGSizeMake(310, 60);
            break;
        case ProfileDisplayFollowers:
        case ProfileDisplayFollowing:            
            cellSize = CGSizeMake(90, 110);
            break;
    }
    
    return cellSize;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    if (self.currentDisplay == ProfileDisplayActivity) {
        return 0;
    } else {
        return 10;
    }
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section{
    if (self.currentDisplay == ProfileDisplayActivity) {
        return UIEdgeInsetsMake(0, 0, 0, 0);
    } else {
        return UIEdgeInsetsMake(5, 5, 5, 5);
    }
}

#pragma mark - Actions

- (IBAction)showActivity:(id)sender {
    [TFlurryManager tappedActivity];
    self.currentDisplay = ProfileDisplayActivity;
    [self updateActivity];
}

- (IBAction)showFollowers:(id)sender {
    [TFlurryManager tappedFollow];
    self.currentDisplay = ProfileDisplayFollowers;
    [self updateFollowerUsers];
}

- (IBAction)showFollowing:(id)sender {
    [TFlurryManager tappedFollowing];
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
        PFUser* usr = self.postsArray[indxPath.row];
//        if (self.currentDisplay == ProfileDisplayFollowers) {
//            usr = act[POST_FROMUSER];
//        } else if (self.currentDisplay == ProfileDisplayFollowing) {
//            usr = act[@"toUser"];
//        }
        
        TProfileViewController* profileVC = segue.destinationViewController;
        profileVC.userProfile = usr;
    }
}

- (IBAction)updateUserName:(id)sender {
    [self.userName resignFirstResponder];
    
    NSString* actualDispName = [TUtility getDisplayNameForUser:self.userProfile];//self.userProfile[USER_DISPLAY_NAME];
    NSString* latestDispName = self.userName.text;
    if (latestDispName && ![latestDispName isEqual:[NSNull null]] && latestDispName.length && ![latestDispName isEqualToString:actualDispName]) {
        [[PFUser currentUser] setObject:latestDispName forKey:USER_DISPLAY_NAME];
        [[PFUser currentUser] saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (succeeded) {
                [[PFUser currentUser] refresh];
                NSLog(@"Successfully name uploaded");
            }
        }];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    self.submitBtn.hidden = NO;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    self.submitBtn.hidden = YES;
}
@end

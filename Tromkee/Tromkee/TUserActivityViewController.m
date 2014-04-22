//
//  TUserActivityViewController.m
//  Tromke
//
//  Created by Satyanarayana SVV on 4/10/14.
//  Copyright (c) 2014 Tromkee. All rights reserved.
//

#import "TUserActivityViewController.h"
#import "TUserActivityCell.h"
#import "TProfileViewController.h"

#define SORTBY @"updatedAt"

@interface TUserActivityViewController ()

@property (strong, nonatomic) NSMutableArray* postsArray;
@property (weak, nonatomic) IBOutlet UILabel *noResultsLabel;
@property (weak, nonatomic) IBOutlet UITableView* userActivityTable;

@end

@implementation TUserActivityViewController

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
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    if (currentInstallation.badge != 0) {
        currentInstallation.badge = 0;
        [currentInstallation saveEventually:^(BOOL succeeded, NSError *error) {
            [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
        }];
    }
    
    if ([Reachability isReachable]) {
        self.postsArray = [[NSMutableArray alloc] init];
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
        PFQuery* activityQuery = [PFQuery queryWithClassName:@"NotifyActivity"];
        [activityQuery includeKey:@"activity"];
        [activityQuery includeKey:@"activity.fromUser"];
        [activityQuery includeKey:@"post"];
        [activityQuery includeKey:@"post.sticker"];
        [activityQuery includeKey:@"post.fromUser"];
        
        [activityQuery whereKey:@"notifyUser" equalTo:[PFUser currentUser]];
        [activityQuery whereKeyDoesNotExist:@"notifyUser"];
        [activityQuery orderByDescending:SORTBY];
        
        __weak TUserActivityViewController* weakSelf = self;
        [activityQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            DLog(@"Received activities in profile: %lu", (unsigned long)objects.count);
            dispatch_async(dispatch_get_main_queue(), ^{
                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                if (error) {
                    NSLog(@"Error in getting activities: %@", error.localizedDescription);
                } else {
                    weakSelf.postsArray = [objects mutableCopy];
                    if ([weakSelf.postsArray count]) {
                        weakSelf.noResultsLabel.hidden = YES;
                        weakSelf.userActivityTable.hidden = NO;
                        [weakSelf.userActivityTable reloadData];
                    } else {
                        weakSelf.noResultsLabel.hidden = NO;
                        weakSelf.userActivityTable.hidden = YES;
                    }
                }
            });
        }];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
- (IBAction)goBack:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

-(NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
    return self.postsArray.count;
}

-(UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    PFObject* notifyObj = self.postsArray[indexPath.row];
    if (notifyObj[@"activity"]) {
        static NSString* cellIdentifier = @"USERACTIVITY";
        TUserActivityCell* cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        cell.postedAt.text = [TUtility computePostedTime:notifyObj.updatedAt];
        
        PFObject* activityObj = notifyObj[@"activity"];
        if ([activityObj[@"type"] isEqualToString:COMMENT]) {
            cell.notificationMessage.text = [NSString stringWithFormat:@"Commented %@", activityObj[@"content"]];
        } else if ([activityObj[@"type"] isEqualToString:THANKS]) {
            cell.notificationMessage.text = @"Conveyed Thanks";
        } else if ([activityObj[@"type"] isEqualToString:IMAGE_COMMENT]) {
            cell.notificationMessage.text = [NSString stringWithFormat:@"Posted image with %@", activityObj[@"content"]];
        } else if ([activityObj[@"type"] isEqualToString:IMAGE_ONLY]) {
            cell.notificationMessage.text = @"Posted Image";
        }
        
        PFObject* fromUser = activityObj[@"fromUser"];
        cell.notificationMessage.text = fromUser[@"displayName"];
        PFFile* imgFile = fromUser[FACEBOOK_SMALLPIC_KEY];
        cell.userImage.image = [UIImage imageNamed:@"Personholder"];
        if (imgFile) {
            [cell.userImage setFile:imgFile];
            [cell.userImage loadInBackground];
        }
        
        return cell;
    } else {
        static NSString* cellIdentifier = @"USERPOST";
        TUserActivityCell* cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        cell.postedAt.text = [TUtility computePostedTime:notifyObj.updatedAt];
        PFObject* postObj = notifyObj[@"post"];
//        NSLog(@"%@", postObj);
        PFObject* stickerObj = postObj[@"sticker"];
//        NSLog(@"%@", stickerObj);
        
        
        
        PFObject* fromUser = postObj[@"fromUser"];
        
        NSString* str = [NSString stringWithFormat:@"%@ posted %@", fromUser[@"displayName"], postObj[@"data"]];
        NSMutableAttributedString* msgString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ posted %@", fromUser[@"displayName"], postObj[@"data"]]];
        NSRange postedRange = [str rangeOfString:@"posted"];
        
        [msgString addAttribute:NSFontAttributeName value:[UIFont italicSystemFontOfSize:14] range:postedRange];
        [msgString addAttribute:NSForegroundColorAttributeName value:[UIColor greenColor] range:postedRange];
        
        cell.notificationMessage.attributedText = msgString;
        PFFile* imgFile = fromUser[FACEBOOK_SMALLPIC_KEY];
        cell.userImage.image = [UIImage imageNamed:@"Personholder"];
        if (imgFile) {
            [cell.userImage setFile:imgFile];
            [cell.userImage loadInBackground];
        }

        return cell;
    }
}


-(void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"PROFILE"]) {
        NSIndexPath* indxPath = [self.userActivityTable indexPathForSelectedRow];
                                  
        PFObject* act = self.postsArray[indxPath.row];
        PFUser* usr = act[@"fromUser"];
        
        TProfileViewController* profileVC = segue.destinationViewController;
        profileVC.userProfile = usr;
    }
}

@end

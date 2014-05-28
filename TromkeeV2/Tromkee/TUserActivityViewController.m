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
#import "TActivityViewController.h"

#define SORTBY @"updatedAt"

@interface TUserActivityViewController () <TUserActivity>

@property (strong, nonatomic) NSMutableArray* postsArray;
@property (weak, nonatomic) IBOutlet UILabel *noResultsLabel;
@property (weak, nonatomic) IBOutlet UITableView* userActivityTable;

@property (nonatomic) NSInteger row;
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
        [currentInstallation saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
        }];
    }
    
    if ([Reachability isReachable]) {
        self.postsArray = [[NSMutableArray alloc] init];
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
        PFQuery* activityQuery = [PFQuery queryWithClassName:@"NotifyActivity"];
        [activityQuery includeKey:@"activity"];
        [activityQuery includeKey:@"activity.post"];
        [activityQuery includeKey:@"activity.post.sticker"];
        [activityQuery includeKey:@"activity.post.fromUser"];
        [activityQuery includeKey:@"activity.fromUser"];
        [activityQuery includeKey:@"post"];
        [activityQuery includeKey:@"post.fromUser"];
        [activityQuery includeKey:@"post.sticker"];
        activityQuery.limit = 30;
//        [activityQuery whereKeyDoesNotExist:@"notifyUser"];
        [activityQuery whereKey:@"notifyUser" equalTo:[PFUser currentUser]];
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
        static NSString* cellIdentifier = @"USERPOST";
        TUserActivityCell* cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        cell.delegate = self;
        cell.postedAt.text = [TUtility computePostedTime:notifyObj.updatedAt];
        
        PFObject* activityObj = notifyObj[@"activity"];
        
        NSString* comment;
        if ([activityObj[POST_TYPE] isEqualToString:ACTIVITY_TYPE_COMMENT]) {
            comment = [NSString stringWithFormat:@"commented %@", activityObj[@"content"]];
        } else if ([activityObj[POST_TYPE] isEqualToString:ACTIVITY_TYPE_THANKS]) {
            comment = @"conveyed Thanks";
        } else if ([activityObj[POST_TYPE] isEqualToString:ACTIVITY_TYPE_IMAGE_COMMENT]) {
            comment = [NSString stringWithFormat:@"posted image with %@", activityObj[@"content"]];
        } else if ([activityObj[POST_TYPE] isEqualToString:ACTIVITY_TYPE_IMAGE_ONLY]) {
            comment = @"posted image";
        } else if ([activityObj[POST_TYPE] isEqualToString:ACTIVITY_TYPE_FOLLOW]) {
            comment = @"is following you";
        }
        
        PFUser* fromUser = activityObj[POST_FROMUSER];
        
        NSString* str = [NSString stringWithFormat:@"%@ %@", /*fromUser[USER_DISPLAY_NAME]*/[TUtility getDisplayNameForUser:fromUser], comment];
        NSMutableAttributedString* msgStr = [[NSMutableAttributedString alloc] initWithString:str];
        
        NSRange postedRange;
        if ([activityObj[POST_TYPE] isEqualToString:ACTIVITY_TYPE_COMMENT]) {
            postedRange = [str rangeOfString:@"commented"];
        } else if ([activityObj[POST_TYPE] isEqualToString:ACTIVITY_TYPE_THANKS]) {
            postedRange = [str rangeOfString:@"conveyed"];
        } else if ([activityObj[POST_TYPE] isEqualToString:ACTIVITY_TYPE_IMAGE_COMMENT] || [activityObj[POST_TYPE] isEqualToString:ACTIVITY_TYPE_IMAGE_ONLY]) {
            postedRange = [str rangeOfString:@"posted"];
        } else if ([activityObj[POST_TYPE] isEqualToString:ACTIVITY_TYPE_FOLLOW]) {
            postedRange = [str rangeOfString:@"following"];
        }

        [msgStr addAttribute:NSFontAttributeName value:[UIFont italicSystemFontOfSize:14] range:postedRange];
        [msgStr addAttribute:NSForegroundColorAttributeName value:[UIColor greenColor] range:postedRange];

        cell.notificationMessage.attributedText = msgStr;
        
        PFFile* imgFile = fromUser[FACEBOOK_SMALLPIC_KEY];
        cell.userImage.image = [UIImage imageNamed:@"Personholder"];
        if (imgFile) {
            [cell.userImage setFile:imgFile];
            [cell.userImage loadInBackground];
        }
        
        cell.rowNumber = indexPath.row;
        return cell;
    } else {
        static NSString* cellIdentifier = @"USERPOST";
        TUserActivityCell* cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        cell.delegate = self;
        cell.postedAt.text = [TUtility computePostedTime:notifyObj.updatedAt];
        PFObject* postObj = notifyObj[@"post"];
        PFObject* stickerObj = postObj[STICKER];
        
        PFUser* fromUser = postObj[POST_FROMUSER];
        
        NSString* str;
        if ([postObj[POST_TYPE] isEqualToString:POST_TYPE_IMAGE]) {
            str = [NSString stringWithFormat:@"%@ posted an image @ %@", /*fromUser[USER_DISPLAY_NAME]*/ [TUtility getDisplayNameForUser:fromUser], postObj[POST_USERLOCATION]];
        } else if ([postObj[POST_TYPE] isEqualToString:POST_TYPE_ASK]) {
            str = [NSString stringWithFormat:@"%@ posted a question @ %@", /*fromUser[USER_DISPLAY_NAME]*/[TUtility getDisplayNameForUser:fromUser], postObj[POST_USERLOCATION]];
        } else if ([postObj[POST_TYPE] isEqualToString:POST_TYPE_STICKER]) {
            str = [NSString stringWithFormat:@"%@ posted sticker %@ @ %@", /*fromUser[USER_DISPLAY_NAME]*/[TUtility getDisplayNameForUser:fromUser], stickerObj[@"name"], postObj[POST_USERLOCATION]];
        }
        
        NSMutableAttributedString* msgString = [[NSMutableAttributedString alloc] initWithString:str];
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

        cell.rowNumber = indexPath.row;        
        return cell;
    }
}


-(void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"PROFILE"]) {
        PFObject* notifyObj = self.postsArray[self.row];
        PFObject* postObj = notifyObj[@"post"];
        PFUser* fromUser;
        if (!postObj) {
            postObj = notifyObj[@"activity"];
            fromUser = postObj[ACTIVITY_FROMUSER];
        } else {
             fromUser = postObj[POST_FROMUSER];
        }

        
        TProfileViewController* profileVC = segue.destinationViewController;
        profileVC.userProfile = fromUser;
    } else if ([segue.identifier isEqualToString:@"ACTIVITY"]) {
        NSIndexPath* indxPath = [self.userActivityTable indexPathForSelectedRow];
        PFObject* notifyObj = self.postsArray[indxPath.row];

        TActivityViewController* activityVC = segue.destinationViewController;
        
        PFObject* postObc = notifyObj[@"post"];
        if (!postObc) {
            PFObject* act = notifyObj[@"activity"];
//            activityVC.postedObjectID = [act[@"post"] objectId];
            activityVC.postedObject = act[@"post"];
        } else {
//            activityVC.postedObjectID = [notifyObj[@"post"] objectId];
            activityVC.postedObject = notifyObj[@"post"];
        }
        

    }
}

-(void)showProfile:(NSInteger)rowNumber {
    self.row = rowNumber;
    [self performSegueWithIdentifier:@"PROFILE" sender:nil];
}

@end

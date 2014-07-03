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

#define SORTBY @"createdAt"
#define TOTAL_ITEMS 50

@interface TUserActivityViewController () <TUserActivity>

@property (strong, nonatomic) NSMutableArray* postsArray;
@property (weak, nonatomic) IBOutlet UILabel *noResultsLabel;
@property (weak, nonatomic) IBOutlet UITableView* userActivityTable;

@property (nonatomic) NSInteger row;
@property (nonatomic) NSInteger fetchedRows;

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
    self.postsArray = [NSMutableArray array];
    self.fetchedRows = 0;
    [self fetchItems];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)goBack:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

-(NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
    return self.postsArray.count;
}

-(UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    PFObject* notifyObj = self.postsArray[indexPath.row];

    static NSString* cellIdentifier = @"USERPOST";
    TUserActivityCell* cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (notifyObj[@"activity"]) {
        
        cell.delegate = self;
        cell.postedAt.text = [TUtility computePostedTime:notifyObj.createdAt];
        
        PFObject* activityObj = notifyObj[@"activity"];
        
        NSString* comment;
        if ([activityObj[POST_TYPE] isEqualToString:ACTIVITY_TYPE_COMMENT]) {
            comment = [NSString stringWithFormat:@"Commented %@", activityObj[@"content"]];
        } else if ([activityObj[POST_TYPE] isEqualToString:ACTIVITY_TYPE_THANKS]) {
            comment = @"Conveyed Thanks";
        } else if ([activityObj[POST_TYPE] isEqualToString:ACTIVITY_TYPE_IMAGE_COMMENT]) {
            comment = [NSString stringWithFormat:@"Posted image with %@", activityObj[@"content"]];
        } else if ([activityObj[POST_TYPE] isEqualToString:ACTIVITY_TYPE_IMAGE_ONLY]) {
            comment = @"Posted image";
        } else if ([activityObj[POST_TYPE] isEqualToString:ACTIVITY_TYPE_FOLLOW]) {
            comment = @"is following you";
        }
        
        PFUser* fromUser = activityObj[POST_FROMUSER];
        cell.postedBy.text = [TUtility getDisplayNameForUser:fromUser];
        cell.postedBy.textColor = [TUtility colorFromHexString:USERNAME_COLOR];
        NSMutableAttributedString* msgStr = [[NSMutableAttributedString alloc] initWithString:comment];
        
        NSRange postedRange;
        if ([activityObj[POST_TYPE] isEqualToString:ACTIVITY_TYPE_COMMENT]) {
            postedRange = [comment rangeOfString:@"Commented"];
        } else if ([activityObj[POST_TYPE] isEqualToString:ACTIVITY_TYPE_THANKS]) {
            postedRange = [comment rangeOfString:@"Conveyed"];
        } else if ([activityObj[POST_TYPE] isEqualToString:ACTIVITY_TYPE_IMAGE_COMMENT] || [activityObj[POST_TYPE] isEqualToString:ACTIVITY_TYPE_IMAGE_ONLY]) {
            postedRange = [comment rangeOfString:@"Posted"];
        } else if ([activityObj[POST_TYPE] isEqualToString:ACTIVITY_TYPE_FOLLOW]) {
            postedRange = [comment rangeOfString:@"following"];
        }

        [msgStr addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:14] range:postedRange];

        cell.notificationMessage.attributedText = msgStr;
        
        PFFile* imgFile = fromUser[FACEBOOK_SMALLPIC_KEY];
        cell.userImage.image = [UIImage imageNamed:@"Personholder"];
        if (imgFile) {
            [cell.userImage setFile:imgFile];
            [cell.userImage loadInBackground];
        }
        
        cell.rowNumber = indexPath.row;
        return cell;
    } else if (notifyObj[@"post"]) {
        cell.delegate = self;
        cell.postedAt.text = [TUtility computePostedTime:notifyObj.createdAt];

        
        PFObject* postObj = notifyObj[@"post"];
        
        if (!postObj) {
            NSLog(@"%@", notifyObj);
        }
        PFObject* stickerObj = postObj[STICKER];
        
        PFUser* fromUser = postObj[POST_FROMUSER];
        cell.postedBy.text = [TUtility getDisplayNameForUser:fromUser];
        cell.postedBy.textColor = [TUtility colorFromHexString:USERNAME_COLOR];
        
        NSString* str;
        if ([postObj[POST_TYPE] isEqualToString:POST_TYPE_IMAGE]) {
            str = [NSString stringWithFormat:@"Posted an image @ %@", postObj[POST_USERLOCATION]];
        } else if ([postObj[POST_TYPE] isEqualToString:POST_TYPE_ASK]) {
            str = [NSString stringWithFormat:@"Posted a question @ %@", postObj[POST_USERLOCATION]];
        } else if ([postObj[POST_TYPE] isEqualToString:POST_TYPE_STICKER]) {
            str = [NSString stringWithFormat:@"Posted sticker %@ @ %@", stickerObj[@"name"], postObj[POST_USERLOCATION]];
        }
        
        NSLog(@"%@", postObj[POST_TYPE]);
        NSMutableAttributedString* msgString = [[NSMutableAttributedString alloc] initWithString:str];
        NSRange postedRange = [str rangeOfString:@"Posted"];
        
        [msgString addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:14] range:postedRange];
        
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
    
    cell.notificationMessage.attributedText = [[NSMutableAttributedString alloc] initWithString:@""];
    cell.postedAt.text = @"";
    cell.userImage.image = nil;
    cell.postedBy.text = @"";
    
    return cell;
}


-(void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    self.row = indexPath.row;
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self performSegueWithIdentifier:@"ACTIVITY" sender:nil];
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
        PFObject* notifyObj = self.postsArray[self.row];
        [TFlurryManager viewingNotification:notifyObj.objectId];
        
        TActivityViewController* activityVC = segue.destinationViewController;
        
        PFObject* postObc = notifyObj[@"post"];
        if (!postObc) {
            PFObject* act = notifyObj[@"activity"];
            activityVC.postedObject = act[@"post"];
        } else {
            activityVC.postedObject = notifyObj[@"post"];
        }
    }
}

-(void)showProfile:(NSInteger)rowNumber {
    self.row = rowNumber;
    [self performSegueWithIdentifier:@"PROFILE" sender:nil];
}


-(void)fetchItems {
    if ([Reachability isReachable]) {
        PFInstallation *currentInstallation = [PFInstallation currentInstallation];
        if (currentInstallation.badge != 0) {
            currentInstallation.badge = 0;
            [currentInstallation saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
            }];
        }
        
        self.postsArray = [[NSMutableArray alloc] init];
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
        PFQuery* activityQuery = [PFQuery queryWithClassName:NOTIFY];
        [activityQuery includeKey:NOTIFY_ACTIVITY];
        [activityQuery includeKey:NOTIFY_ACTIVITY_POST];
        [activityQuery includeKey:NOTIFY_POST_STICKER];
        [activityQuery includeKey:NOTIFY_POST_FROMUSER];
        [activityQuery includeKey:NOTIFY_ACTIVITY_FROMUSER];
        [activityQuery includeKey:NOTIFY_POST];
        [activityQuery includeKey:NOTIFY_FROMUSER];
        [activityQuery includeKey:NOTIFY_STICKER];
                
        activityQuery.limit = TOTAL_ITEMS;
        activityQuery.skip = self.fetchedRows;
        
        [activityQuery whereKey:NOTIFY_USER equalTo:[PFUser currentUser]];
        [activityQuery orderByDescending:SORTBY];
        
        __weak TUserActivityViewController* weakSelf = self;
        [activityQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            DLog(@"Received activities in profile: %lu", (unsigned long)objects.count);
            dispatch_async(dispatch_get_main_queue(), ^{
                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                if (error) {
                    NSLog(@"Error in getting activities: %@", error.localizedDescription);
                } else {
                    [weakSelf.postsArray addObjectsFromArray:[objects mutableCopy]];
                    if ([weakSelf.postsArray count]) {
                        weakSelf.fetchedRows = weakSelf.postsArray.count;
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

@end

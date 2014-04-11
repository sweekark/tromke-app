//
//  TUserActivityViewController.m
//  Tromke
//
//  Created by Satyanarayana SVV on 4/10/14.
//  Copyright (c) 2014 Tromkee. All rights reserved.
//

#import "TUserActivityViewController.h"
#import "MBProgressHUD.h"
#import "TUserActivityCell.h"
#import "TProfileViewController.h"

#define SORTBY @"updatedAt"

@interface TUserActivityViewController ()

@property (strong, nonatomic) NSMutableArray* postsArray;
@property (nonatomic, strong) MBProgressHUD* progress;
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
    PFQuery* query = [PFQuery queryWithClassName:@"Installation"];
    [query whereKey:@"user" equalTo:[PFUser currentUser]];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error && objects.count) {
            PFObject* obj = [objects firstObject];
            obj[@"badge"] = [NSNumber numberWithInt:0];
            [obj saveEventually];
            [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
        }
    }];
    
    self.postsArray = [[NSMutableArray alloc] init];
    self.progress = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.progress.labelText = @"Fetching ...";
    self.progress.dimBackground = YES;
    PFQuery* activityQuery = [PFQuery queryWithClassName:@"Activity" predicate:[NSPredicate predicateWithFormat:@"fromUser == %@ OR toUser == %@", [PFUser currentUser], [PFUser currentUser]]];
    activityQuery.cachePolicy = kPFCachePolicyCacheThenNetwork;
    activityQuery.maxCacheAge = 300;
    [activityQuery includeKey:@"fromUser"];
    [activityQuery orderByDescending:SORTBY];
    __weak TUserActivityViewController* weakSelf = self;
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
    static NSString* cellIdentifier = @"USERACTIVITY";
    TUserActivityCell* cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    PFObject* post = self.postsArray[indexPath.row];
    cell.postedAt.text = [TUtility computePostedTime:post.updatedAt];
    if ([post[@"type"] isEqualToString:COMMENT]) {
        cell.comment.text = [NSString stringWithFormat:@"Commented %@", post[@"content"]];
    } else if ([post[@"type"] isEqualToString:THANKS]) {
        cell.comment.text = @"Conveyed Thanks";
    } else if ([post[@"type"] isEqualToString:IMAGE_COMMENT]) {
        cell.comment.text = [NSString stringWithFormat:@"Posted image with %@", post[@"content"]];
    } else if ([post[@"type"] isEqualToString:IMAGE_ONLY]) {
        cell.comment.text = @"Posted Image";
    }
    //    [cell.comment sizeToFit];
    
    
    PFObject* fromUser = post[@"fromUser"];
    cell.userName.text = fromUser[@"displayName"];
    PFFile* imgFile = fromUser[FACEBOOK_SMALLPIC_KEY];
    cell.userImage.image = [UIImage imageNamed:@"Personholder"];
    if (imgFile) {
        [cell.userImage setFile:imgFile];
        [cell.userImage loadInBackground];
    }

    return cell;
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

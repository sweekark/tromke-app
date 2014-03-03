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

#define SORT_KEY @"updatedAt"

@interface TProfileViewController () <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UILabel *userName;
@property (weak, nonatomic) IBOutlet PFImageView *userImage;
@property (weak, nonatomic) IBOutlet UILabel *userPoints;

@property (strong, nonatomic) NSMutableArray* postsArray;
@property (weak, nonatomic) IBOutlet UITableView *postsTableView;
@property (nonatomic, strong) MBProgressHUD* progress;

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
	// Do any additional setup after loading the view.
    PFUser* user = [PFUser currentUser];
    PFFile *imageFile = [user objectForKey:FACEBOOK_SMALLPIC_KEY];
    if (imageFile) {
        NSLog(@"Loading person image:");
        [self.userImage setFile:imageFile];
        [self.userImage loadInBackground];
    } else {
        NSLog(@"No image found");
    }
    self.userName.text = user[@"displayName"];
    
    self.postsArray = [[NSMutableArray alloc] init];
    [self update];
}

- (IBAction)goBack:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}



-(void)update {
    self.progress = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.progress.labelText = @"Fetching ...";
    self.progress.dimBackground = YES;
    PFQuery* activityQuery = [PFQuery queryWithClassName:@"Activity" predicate:[NSPredicate predicateWithFormat:@"toUser == %@", [PFUser currentUser]]];
    [activityQuery includeKey:@"fromUser"];
    [activityQuery orderByDescending:SORT_KEY];
    __weak TProfileViewController* weakSelf = self;
    [activityQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.progress hide:YES];
            if (error) {
                NSLog(@"Error in getting activities: %@", error.localizedDescription);
            } else {
                weakSelf.postsArray = [objects mutableCopy];
                if ([weakSelf.postsArray count]) {
                    [weakSelf.postsTableView reloadData];
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

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.postsArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString* cellIdentifier = @"POSTCELL";
    TProfileCell* cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
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
    //[cell.comment sizeToFit];

    
    PFObject* fromUser = post[@"fromUser"];
    cell.personName.text = fromUser[@"displayName"];
    PFFile* imgFile = fromUser[FACEBOOK_SMALLPIC_KEY];
    if (imgFile) {
        [cell.personImage setFile:imgFile];
        [cell.personImage loadInBackground];
    }

    
    return cell;
}


@end

//
//  TActivityViewController.m
//  Tromke
//
//  Created by Satyanarayana SVV on 2/17/14.
//  Copyright (c) 2014 Tromkee. All rights reserved.
//

#import "TActivityViewController.h"
#import "TActivityCell.h"
#import "TAppDelegate.h"
#import "TCircleView.h"
#import "UIImage+ResizeAdditions.h"
#import "TProfileViewController.h"
#import "TPostCell.h"
#import "TCameraViewController.h"

#define SORT_ACTIVITIES_KEY @"updatedAt"

@interface TActivityViewController () <UITableViewDataSource, UITableViewDelegate, TPostCellDelegate>

@property (weak, nonatomic) IBOutlet UIView *topBar;
@property (weak, nonatomic) IBOutlet UILabel *activityTitle;

@property (nonatomic, strong) NSMutableArray* activities;
@property (nonatomic, weak) IBOutlet UITableView* activitiesTable;
@property (weak, nonatomic) IBOutlet UIView *bottomView;
@property (nonatomic) BOOL isCommentEditing;

@property (nonatomic, strong) TPostCell* postCell;


@property (weak, nonatomic) IBOutlet UIView *askQuestionView;
@property (weak, nonatomic) IBOutlet UILabel *textCount;
@property (weak, nonatomic) IBOutlet UITextView *askText;
    @property (weak, nonatomic) IBOutlet UIButton *onlyCameraButton;


- (IBAction)postActivityDescription:(id)sender;

@end

@implementation TActivityViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.postedObject = nil;
        self.postedObjectID = nil;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.postCell = nil;
	// Do any additional setup after loading the view.
//    UIBarButtonItem* forwardButton = [[UIBarButtonItem alloc] initWithTitle:@"Forward" style:UIBarButtonItemStyleBordered target:self action:@selector(share)];
//    self.navigationController.navigationItem.rightBarButtonItem = forwardButton;
    self.activities = [@[] mutableCopy];
    
    self.bottomView.backgroundColor = [TUtility colorFromHexString:YELLOW_COLOR];
    self.askQuestionView.backgroundColor = [TUtility colorFromHexString:YELLOW_COLOR];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(update) name:TROMKEE_UPDATE_COMMENTS object:nil];    
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    NSString* stickerType = self.postedObject[POST_TYPE];
    if ([stickerType isEqualToString:POST_TYPE_STICKER]) {
        self.activityTitle.text = ACTIVITY_STICKER;
        self.activityTitle.textColor = [UIColor darkGrayColor];
        self.topBar.backgroundColor = [TUtility colorFromHexString:ACTIVITY_STICKER_COLOR];
    } else if ([stickerType isEqualToString:POST_TYPE_ASK]) {
        self.activityTitle.text = ACTIVITY_ASK;
        self.topBar.backgroundColor = [TUtility colorFromHexString:ACTIVITY_PICTURE_COLOR];
    } else if ([stickerType isEqualToString:POST_TYPE_IMAGE]) {
        self.activityTitle.text = ACTIVITY_PICTURE;
        self.topBar.backgroundColor = [TUtility colorFromHexString:ACTIVITY_QUESTION_COLOR];
    }
}


-(void)setPostedObject:(PFObject *)stickerObject {
    _postedObject = stickerObject;
    [self update];
}


-(void)setPostedObjectID:(NSString *)postObjectID {
    _postedObjectID = postObjectID;
    if ([Reachability isReachable]) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
        PFQuery* postQuery = [PFQuery queryWithClassName:POST];
        [postQuery includeKey:STICKER];
        [postQuery includeKey:@"images"];
        [postQuery includeKey:POST_FROMUSER];
        [postQuery whereKey:@"objectId" equalTo:self.postedObjectID];
        [postQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            if (!error) {
                self.postedObject = [objects firstObject];
                [self update];
            }
        }];
    }
}

-(void)update {
    NSString* stickerType = self.postedObject[POST_TYPE];
    if ([stickerType isEqualToString:POST_TYPE_STICKER]) {
        self.activityTitle.text = ACTIVITY_STICKER;
        self.activityTitle.textColor = [UIColor darkGrayColor];
        self.topBar.backgroundColor = [TUtility colorFromHexString:ACTIVITY_STICKER_COLOR];
    } else if ([stickerType isEqualToString:POST_TYPE_ASK]) {
        self.activityTitle.text = ACTIVITY_ASK;
        self.topBar.backgroundColor = [TUtility colorFromHexString:ACTIVITY_PICTURE_COLOR];
    } else if ([stickerType isEqualToString:POST_TYPE_IMAGE]) {
        self.activityTitle.text = ACTIVITY_PICTURE;
        self.topBar.backgroundColor = [TUtility colorFromHexString:ACTIVITY_QUESTION_COLOR];
    }
    
    if ([Reachability isReachable]) {
        [self updateThanksButton];
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
        PFQuery* activityQuery = [PFQuery queryWithClassName:@"Activity"];
        [activityQuery whereKey:@"post" equalTo:self.postedObject];
        [activityQuery whereKey:POST_TYPE containedIn:@[@"IMAGE_COMMENT", @"COMMENT", @"THANKS"]];
        [activityQuery includeKey:POST_FROMUSER];
        [activityQuery orderByDescending:SORT_ACTIVITIES_KEY];
        
        __weak TActivityViewController* weakSelf = self;
        [activityQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            NSLog(@"Received objects for sticker : %lu", (unsigned long)objects.count);
            
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            
            NSIndexSet* indexes = [objects indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
                return [[(PFObject*)obj valueForKey:POST_TYPE] isEqualToString:THANKS];
            }];
            
            weakSelf.postCell.totalThanks.text = [NSString stringWithFormat:@"%lu", (unsigned long)(indexes ? indexes.count : 0)];
            
            if (error) {
                NSLog(@"Error in getting activities: %@", error.localizedDescription);
            } else {
                if (objects.count) {
                    weakSelf.activities = [NSMutableArray arrayWithArray:objects];
                    [weakSelf.activities removeObjectsAtIndexes:indexes];
                    [weakSelf.activitiesTable reloadData];
                }
            }
        }];
    }
}

-(void)updateThanksButton {
    PFQuery* thanksQuery = [PFQuery queryWithClassName:@"Activity"];
    [thanksQuery whereKey:@"post" equalTo:self.postedObject];
    [thanksQuery whereKey:POST_FROMUSER equalTo:[PFUser currentUser]];
    [thanksQuery whereKey:POST_TYPE equalTo:@"THANKS"];
    [thanksQuery getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        if (!error && object) {
            [self.postCell.thanksButton setTitle:@"Thanked" forState:UIControlStateNormal];
            self.postCell.thanksButton.userInteractionEnabled = NO;
        }
    }];
}

-(void)share {
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:[NSArray arrayWithObjects: self.postedObject[POST_DATA], nil] applicationActivities:nil];
    activityVC.excludedActivityTypes = @[ UIActivityTypeMessage ,UIActivityTypeAssignToContact,UIActivityTypeSaveToCameraRoll];
    [self presentViewController:activityVC animated:YES completion:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Tableview methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.activities && self.activities.count) {
        return self.activities.count + 1;
    }

    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.row == 0) {
        if (self.postCell == nil) {
            PFObject* images = self.postedObject[@"images"];
            if (images) {
                self.postCell = [tableView dequeueReusableCellWithIdentifier:@"POST_IMAGE"];
            } else {
                self.postCell = [tableView dequeueReusableCellWithIdentifier:@"ONLY_POST"];
            }
            self.postCell.delegate = self;
            [self.postCell update:self.postedObject];
        }
        
        return self.postCell;
    }
    
    PFObject* comment = self.activities[indexPath.row - 1];
    PFObject* fromUser = comment[POST_FROMUSER];
    
    TActivityCell* cell;
    if ([comment[POST_TYPE] isEqualToString:COMMENT]) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"ONLY_COMMENT"];
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:@"COMMENT_IMAGE"];
        PFFile* imgFile = comment[@"commentImage"];
        cell.commentImage.image = [UIImage imageNamed:@"Personholder"];
        if (imgFile) {
            [cell.commentImage setFile:imgFile];
            [cell.commentImage loadInBackground];
        }
    }

    cell.personName.text = fromUser[USER_DISPLAY_NAME];
    cell.comment.text = comment[@"content"];
    cell.updatedTime.text = [TUtility computePostedTime:comment.updatedAt];
    
    PFFile* perImg = fromUser[FACEBOOK_SMALLPIC_KEY];
    if (perImg) {
        cell.personImage.file = perImg;
        [cell.personImage loadInBackground];
    }
    
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat height = 100;
    if (indexPath.row == 0) {
        PFObject* images = self.postedObject[@"images"];
        if (images) {
            height = 325;
        } else {
            height = 150;
        }
    } else {
        if (self.activities && self.activities.count) {
            PFObject* comment = self.activities[indexPath.row - 1];
            if ([comment[POST_TYPE] isEqualToString:IMAGE_COMMENT]) {
                height = 300;
            }
        }
    }
    
    return height;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self performSegueWithIdentifier:@"PROFILE" sender:nil];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];    
}

#pragma mark - TextView methods

//- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
//{
//    if([text isEqualToString:@"\n"])
//    {
//        [textView resignFirstResponder];
//        return YES;
//    }
//    
//    return textView.text.length + (text.length - range.length) <= POSTDATA_LENGTH;
//}

//- (void)textViewDidBeginEditing:(UITextView *)textView {
//    self.isCommentEditing = YES;
//    [UIView animateWithDuration:0.35 animations:^{
//        CGRect r = self.bottomView.frame;
//        r.origin.y -= 216;
//        self.bottomView.frame = r;
//    }];
//}
//
//- (void)textViewDidEndEditing:(UITextView *)textView {
//    self.isCommentEditing = NO;
//    [UIView animateWithDuration:0.1 animations:^{
//        CGRect r = self.bottomView.frame;
//        r.origin.y += 216;
//        self.bottomView.frame = r;
//    }];
//}

- (IBAction)postActivityDescription:(id)sender {
//    if ([self.stickerImages count]) {
//        UIImage *resizedImage = [self.stickerImages[0] resizedImageWithContentMode:UIViewContentModeScaleAspectFit bounds:CGSizeMake(560.0f, 560.0f) interpolationQuality:kCGInterpolationHigh];
//        NSData *imageData = UIImageJPEGRepresentation(resizedImage, 0.8f);
//        
//        __block PFFile* imageFile = [PFFile fileWithData:imageData];
//        [imageFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
//            if (succeeded) {
//                NSLog(@"Saved image file");
//                PFObject* activiy = [PFObject objectWithClassName:@"Activity"];
//                activiy[POST_FROMUSER] = [PFUser currentUser];
//                activiy[@"commentImage"] = imageFile;
//                activiy[@"toUser"] = self.stickerObject[POST_FROMUSER];
//                activiy[POST_TYPE] = IMAGE_COMMENT;
//                activiy[@"content"] = self.activityDescription.text;
//                activiy[@"post"] = self.stickerObject;
//                
//                [activiy saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
//                    if (succeeded) {
//                        dispatch_async(dispatch_get_main_queue(), ^{
//                            [[[UIAlertView alloc] initWithTitle:@"Successful" message:@"Comment posted successfully" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
//                            [self update];
//                        });
//                    } else {
//                        NSLog(@"Failed to post comment");
//                    }
//                }];
//            } else {
//                NSLog(@"Failed to upload image");
//            }
//        }];
//    }
    

}

-(void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        [(TAppDelegate*)[[UIApplication sharedApplication] delegate] presentLoginViewControllerAnimated:NO];
    }
}

- (IBAction)goBack:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}


- (void)conveyThanks {
    [self.askText resignFirstResponder];

    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    PFObject* activiy = [PFObject objectWithClassName:@"Activity"];
    activiy[POST_FROMUSER] = [PFUser currentUser];
    activiy[@"toUser"] = self.postedObject[POST_FROMUSER];
    activiy[POST_TYPE] = @"THANKS";
    activiy[@"content"] = self.askText.text;
    activiy[@"post"] = self.postedObject;

    [activiy saveInBackground];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:PROFILE]) {
        NSIndexPath* indxPath = [self.activitiesTable indexPathForSelectedRow];
        if (indxPath.row == 0) {
            PFUser* fromUser = self.postedObject[POST_FROMUSER];
            TProfileViewController* profileVC = segue.destinationViewController;
            profileVC.userProfile = fromUser;
        } else {
            PFObject* comment = self.activities[indxPath.row - 1];
            PFUser* fromUser = comment[POST_FROMUSER];
            TProfileViewController* profileVC = segue.destinationViewController;
            profileVC.userProfile = fromUser;
        }
    } else if ([segue.identifier isEqualToString:STICKER_POSTED_PROFILE]) {
        PFUser* user = self.postedObject[POST_FROMUSER];
        TProfileViewController* profileVC = segue.destinationViewController;
        profileVC.userProfile = user;
    } else if ([segue.identifier isEqualToString:ASKCAMERA]) {
        TCameraViewController* cameraVC = segue.destinationViewController;
        [self.askText resignFirstResponder];
        cameraVC.activityName = YES;
        cameraVC.cameraMessage = self.askText.text;
        cameraVC.postedObject = self.postedObject;
    }
}

-(BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    if (![[PFUser currentUser] isAuthenticated]) {
        [[[UIAlertView alloc] initWithTitle:@"Warning" message:@"You need to login inorder to follow other users" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
        return NO;
    }
    
//    if ([identifier isEqualToString:PROFILE]) {
//    } else {
//        
//    }
    
    return YES;
}

- (IBAction)share:(id)sender {
    NSMutableArray* actItems = [[NSMutableArray alloc] init];
    NSString* comment = self.postedObject[POST_DATA];
    if (comment && comment.length) {
        [actItems addObject:comment];
    }
    
    PFObject* stickerObj = self.postedObject[STICKER];
    PFFile* stickerImage = stickerObj[STICKER_IMAGE];
    UIImage* img = [UIImage imageWithData:[stickerImage getData]];
    [actItems addObject:img];
    
    UIActivityViewController* actController = [[UIActivityViewController alloc] initWithActivityItems:actItems applicationActivities:nil];
    [self presentViewController:actController animated:YES completion:nil];
}


#pragma mark - Ask question delegate

- (void)textViewDidBeginEditing:(UITextView *)textView {
    if ([textView.text isEqualToString:@"Type your question here"]) {
        textView.text = @"";
    }
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if([text isEqualToString:@"\n"])
    {
        [self postAskQuestion:nil];
        [textView resignFirstResponder];
        return YES;
    }
    
    unsigned long charCount = textView.text.length + (text.length - range.length);
    
    if (charCount == 0) {
        self.onlyCameraButton.enabled = NO;
    } else {
        self.onlyCameraButton.enabled = YES;
    }
    
    if (charCount <= POSTDATA_LENGTH) {
        self.textCount.text = [NSString stringWithFormat:@"%ld", charCount];
    }
    
    return  charCount <= POSTDATA_LENGTH;
}

- (IBAction)postAskQuestion:(id)sender {
    [self.askText resignFirstResponder];
    
    if (![PFUser currentUser]) {
        [[[UIAlertView alloc] initWithTitle:@"Warning" message:@"You must login in order to post a sticker !!!" delegate:self cancelButtonTitle:@"Not Now" otherButtonTitles: @"Login", nil] show];
        return;
    }
    
    if (![Reachability isReachable]) {
        return;
    }
    
    PFObject* activiy = [PFObject objectWithClassName:@"Activity"];
    activiy[ACTIVITY_FROMUSER] = [PFUser currentUser];
    activiy[ACTIVITY_TOUSER] = self.postedObject[POST_FROMUSER];
    activiy[ACTIVITY_TYPE] = COMMENT;
    activiy[ACTIVITY_CONTENT] = self.askText.text;
    activiy[ACTIVITY_POST] = self.postedObject;
    
    [activiy saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self update];
            });
        }
    }];
}

- (IBAction)askAQuestion:(id)sender {
    if (![Reachability isReachable]) {
        return;
    }
    
    self.askText.text = @"Type your question here";
    self.onlyCameraButton.enabled = NO;
    self.textCount.text = @"0";
    
    [UIView animateWithDuration:0.5 animations:^{
        CGRect r = self.askQuestionView.frame;
        self.askQuestionView.frame = CGRectMake(0, 64, r.size.width, r.size.height);
    }];
}

- (IBAction)hideAskQuestionView:(id)sender {
    [UIView animateWithDuration:0.5 animations:^{
        [self.askText resignFirstResponder];
        CGRect r = self.askQuestionView.frame;
        self.askQuestionView.frame = CGRectMake(0, -130, r.size.width, r.size.height);
    }];
}


@end


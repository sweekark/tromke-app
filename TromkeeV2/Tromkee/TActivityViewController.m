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

@interface TActivityViewController () <UITableViewDataSource, UITableViewDelegate, TPostCellDelegate, TActivityDelegate>

@property (weak, nonatomic) IBOutlet UIView *topBar;
@property (weak, nonatomic) IBOutlet UILabel *activityTitle;

@property (nonatomic, strong) NSMutableArray* activities;
@property (nonatomic, weak) IBOutlet UITableView* activitiesTable;
@property (weak, nonatomic) IBOutlet UIView *bottomView;
@property (nonatomic) BOOL isCommentEditing;

@property (nonatomic, strong) TPostCell* postCell;


@property (weak, nonatomic) IBOutlet UIView *askQuestionView;
@property (weak, nonatomic) IBOutlet UIView *askBackground;
@property (weak, nonatomic) IBOutlet UILabel *textCount;
@property (weak, nonatomic) IBOutlet UITextView *askText;
@property (weak, nonatomic) IBOutlet UIButton *onlyCameraButton;
@property (weak, nonatomic) IBOutlet UIButton *commentButton;

@property (nonatomic) BOOL showProfileForPost;
@property (nonatomic) NSInteger showActivityItem;

//- (IBAction)postActivityDescription:(id)sender;

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
    self.activities = [@[] mutableCopy];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(update) name:TROMKEE_UPDATE_COMMENTS object:nil];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    self.bottomView.backgroundColor = [TUtility colorFromHexString:YELLOW_COLOR];
    self.askBackground.backgroundColor = [TUtility colorFromHexString:YELLOW_COLOR];
    

    NSString* stickerType = self.postedObject[POST_TYPE];
    if ([stickerType isEqualToString:POST_TYPE_STICKER]) {
        self.activityTitle.text = ACTIVITY_STICKER;
        self.activityTitle.textColor = [UIColor darkGrayColor];
        self.topBar.backgroundColor = [TUtility colorFromHexString:ACTIVITY_STICKER_COLOR];
//        self.askText.text = @"Type your comment here";
        [self.commentButton setTitle:@"Comment" forState:UIControlStateNormal];
    } else if ([stickerType isEqualToString:POST_TYPE_ASK]) {
        self.activityTitle.text = ACTIVITY_ASK;
        self.topBar.backgroundColor = [TUtility colorFromHexString:ACTIVITY_PICTURE_COLOR];
//        self.askText.text = @"Type your answer here";
        [self.commentButton setTitle:@"Answer" forState:UIControlStateNormal];
    } else if ([stickerType isEqualToString:POST_TYPE_IMAGE]) {
        self.activityTitle.text = ACTIVITY_PICTURE;
        self.topBar.backgroundColor = [TUtility colorFromHexString:ACTIVITY_QUESTION_COLOR];
//        self.askText.text = @"Type your comment here";
        [self.commentButton setTitle:@"Comment" forState:UIControlStateNormal];
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
                [self.activitiesTable reloadData];
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
        self.topBar.backgroundColor = [TUtility colorFromHexString:ACTIVITY_QUESTION_COLOR];
    } else if ([stickerType isEqualToString:POST_TYPE_IMAGE]) {
        self.activityTitle.text = ACTIVITY_PICTURE;
        self.topBar.backgroundColor = [TUtility colorFromHexString:ACTIVITY_PICTURE_COLOR];
    }
    
    if ([Reachability isReachable]) {
        [self updateThanksButton];
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
        PFQuery* activityQuery = [PFQuery queryWithClassName:ACTIVITY];
        [activityQuery whereKey:ACTIVITY_POST equalTo:self.postedObject];
        [activityQuery whereKey:ACTIVITY_TYPE containedIn:@[ACTIVITY_TYPE_IMAGE_COMMENT, ACTIVITY_TYPE_COMMENT, ACTIVITY_TYPE_THANKS]];
        [activityQuery includeKey:ACTIVITY_FROMUSER];
        [activityQuery orderByDescending:SORT_ACTIVITIES_KEY];
        
        __weak TActivityViewController* weakSelf = self;
        [activityQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            NSLog(@"Received objects for sticker : %lu", (unsigned long)objects.count);
            
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            
            NSIndexSet* indexes = [objects indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
                return [[(PFObject*)obj valueForKey:POST_TYPE] isEqualToString:ACTIVITY_TYPE_THANKS];
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
    PFQuery* thanksQuery = [PFQuery queryWithClassName:ACTIVITY];
    [thanksQuery whereKey:ACTIVITY_POST equalTo:self.postedObject];
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
    if (self.postedObject) {
        if (self.activities && self.activities.count) {
            return self.activities.count + 1;
        }
        
        return 1;
    }
    
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.row == 0) {
        if (self.postCell == nil) {
            NSString* stickerType = self.postedObject[POST_TYPE];
            if ([stickerType isEqualToString:POST_TYPE_STICKER]) {
                self.postCell = [tableView dequeueReusableCellWithIdentifier:VIEWSTICKER];
            } else if ([stickerType isEqualToString:POST_TYPE_ASK]) {
                self.postCell = [tableView dequeueReusableCellWithIdentifier:VIEWQUESTION];
                self.postCell.contentView.backgroundColor = [TUtility colorFromHexString:ACTIVITY_PICTURE_COLOR];
//                [self.postCell showLabelsForQuestion];
            } else if ([stickerType isEqualToString:POST_TYPE_IMAGE]) {
                self.postCell = [tableView dequeueReusableCellWithIdentifier:VIEWIMAGE];
                self.postCell.contentView.backgroundColor = [TUtility colorFromHexString:ACTIVITY_STICKER_COLOR];
            }

            self.postCell.delegate = self;
            [self.postCell update:self.postedObject];
        }
        
        return self.postCell;
    }
    
    PFObject* comment = self.activities[indexPath.row - 1];
    PFUser* fromUser = comment[ACTIVITY_FROMUSER];
    
    TActivityCell* cell;
    PFFile* imgFile = comment[ACTIVITY_ORIGINAL_IMAGE];
    
    if ([comment[POST_TYPE] isEqualToString:ACTIVITY_TYPE_COMMENT] && imgFile) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"COMMENT_IMAGE"];
//        PFFile* imgFile = comment[@"commentImage"];
        cell.commentImage.image = [UIImage imageNamed:@"PlaceHolder"];
        if (imgFile) {
            [cell.commentImage setFile:imgFile];
            [cell.commentImage loadInBackground];
        }
    }
    else { //if ([comment[POST_TYPE] isEqualToString:ACTIVITY_TYPE_COMMENT]) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"ONLY_COMMENT"];
    }

    cell.tag = indexPath.row - 1;
    cell.delegate = self;
    cell.personName.textColor = [TUtility colorFromHexString:USERNAME_COLOR];
    cell.personName.text = [TUtility getDisplayNameForUser:fromUser];//fromUser[USER_DISPLAY_NAME];
    cell.comment.text = comment[ACTIVITY_CONTENT];
    cell.updatedTime.text = [TUtility computePostedTime:comment.updatedAt];
    
    PFFile* perImg = fromUser[FACEBOOK_SMALLPIC_KEY];
    if (perImg) {
        cell.personImage.file = perImg;
        [cell.personImage loadInBackground];
    }
    
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    CGFloat height = 85;
    if (indexPath.row == 0) {
        NSString* stickerType = self.postedObject[POST_TYPE];
        if ([stickerType isEqualToString:POST_TYPE_STICKER]) {
            height = 150;
        } else if ([stickerType isEqualToString:POST_TYPE_ASK]) {
            height = 124;
        } else if ([stickerType isEqualToString:POST_TYPE_IMAGE]) {
            height = 450;
        }
    } else {
        if (self.activities && self.activities.count) {
            
            
            PFObject* comment = self.activities[indexPath.row - 1];
            PFFile* imgFile = comment[ACTIVITY_ORIGINAL_IMAGE];
            
            if ([comment[POST_TYPE] isEqualToString:ACTIVITY_TYPE_COMMENT] && imgFile) {
                height = 405;
            }
//            else { //if ([comment[POST_TYPE] isEqualToString:ACTIVITY_TYPE_COMMENT]) {
//                
//            }

            
//            PFObject* comment = self.activities[indexPath.row - 1];
//            if ([comment[POST_TYPE] isEqualToString:ACTIVITY_TYPE_IMAGE_COMMENT]) {
//                height = 300;
//            }
        }
    }
    
    return height;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
//    [self performSegueWithIdentifier:@"PROFILE" sender:nil];
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

//- (IBAction)postActivityDescription:(id)sender {
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
    

//}

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
    PFObject* activiy = [PFObject objectWithClassName:ACTIVITY];
    activiy[ACTIVITY_FROMUSER] = [PFUser currentUser];
    activiy[ACTIVITY_TOUSER] = self.postedObject[POST_FROMUSER];
    activiy[ACTIVITY_TYPE] = @"THANKS";
    activiy[ACTIVITY_CONTENT] = self.askText.text;
    activiy[ACTIVITY_POST] = self.postedObject;

    [activiy saveInBackground];
}

-(void)showProfileFromPost {
    self.showProfileForPost = YES;
    [self performSegueWithIdentifier:@"PROFILE" sender:nil];
}

-(void)showProfileFromActivity:(NSInteger)item {
    self.showProfileForPost = NO;
    self.showActivityItem = item;
    [self performSegueWithIdentifier:@"PROFILE" sender:nil];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:PROFILE]) {
        if (self.showProfileForPost) {
            PFUser* fromUser = self.postedObject[POST_FROMUSER];
            TProfileViewController* profileVC = segue.destinationViewController;
            profileVC.userProfile = fromUser;
        } else {
            PFObject* comment = self.activities[self.showActivityItem];
            PFUser* fromUser = comment[POST_FROMUSER];
            TProfileViewController* profileVC = segue.destinationViewController;
            profileVC.userProfile = fromUser;
        }
//        NSIndexPath* indxPath = [self.activitiesTable indexPathForSelectedRow];
//        if (indxPath.row == 0) {
//            PFUser* fromUser = self.postedObject[POST_FROMUSER];
//            TProfileViewController* profileVC = segue.destinationViewController;
//            profileVC.userProfile = fromUser;
//        } else {
//            PFObject* comment = self.activities[indxPath.row - 1];
//            PFUser* fromUser = comment[POST_FROMUSER];
//            TProfileViewController* profileVC = segue.destinationViewController;
//            profileVC.userProfile = fromUser;
//        }
    } /*else if ([segue.identifier isEqualToString:STICKER_POSTED_PROFILE]) {
        PFUser* user = self.postedObject[POST_FROMUSER];
        TProfileViewController* profileVC = segue.destinationViewController;
        profileVC.userProfile = user;
    }*/ else if ([segue.identifier isEqualToString:CAMERA]) {
        TCameraViewController* cameraVC = segue.destinationViewController;
        [self.askText resignFirstResponder];
        cameraVC.activityName = CameraForComment;
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
    
//    PFObject* stickerObj = self.postedObject[STICKER];
    PFFile* stickerImage = self.postedObject[POST_ORIGINAL_IMAGE];
    if (stickerImage) {
        UIImage* img = [UIImage imageWithData:[stickerImage getData]];
        [actItems addObject:img];
    }
    
    UIActivityViewController* actController = [[UIActivityViewController alloc] initWithActivityItems:actItems applicationActivities:nil];
    [self presentViewController:actController animated:YES completion:nil];
}


#pragma mark - Ask question delegate

//- (void)textViewDidBeginEditing:(UITextView *)textView {
//    if ([textView.text isEqualToString:@"Type your comment here"] || [textView.text isEqualToString:@"Type your answer here"]) {
//        textView.text = @"";
//    }
//}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if([text isEqualToString:@"\n"])
    {
        [textView resignFirstResponder];        
        [self postAskQuestion:nil];
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
//    [self.askText resignFirstResponder];
    [self hideAskQuestionView:nil];
    
    if (![PFUser currentUser]) {
        [[[UIAlertView alloc] initWithTitle:@"Warning" message:@"You must login in order to post a sticker !!!" delegate:self cancelButtonTitle:@"Not Now" otherButtonTitles: @"Login", nil] show];
        return;
    }
    
    if (![Reachability isReachable]) {
        return;
    }
    
    PFObject* activiy = [PFObject objectWithClassName:ACTIVITY];
    activiy[ACTIVITY_FROMUSER] = [PFUser currentUser];
    activiy[ACTIVITY_TOUSER] = self.postedObject[POST_FROMUSER];
    activiy[ACTIVITY_TYPE] = ACTIVITY_TYPE_COMMENT;
    activiy[ACTIVITY_CONTENT] = self.askText.text;
    activiy[ACTIVITY_POST] = self.postedObject;
    
    [activiy saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.askText.text = @"";
                [self update];
            });
        }
    }];
}

- (IBAction)askForComment:(id)sender {
    if (![Reachability isReachable]) {
        return;
    }
    
//    self.askText.text = @"Type your question here";
//    self.onlyCameraButton.enabled = NO;
//    self.textCount.text = @"0";
//    
//    NSString* stickerType = self.postedObject[POST_TYPE];
//    if ([stickerType isEqualToString:POST_TYPE_STICKER]) {
//        self.askText.text = @"Type your comment here";
//    } else if ([stickerType isEqualToString:POST_TYPE_ASK]) {
//        self.askText.text = @"Type your answer here";
//    } else if ([stickerType isEqualToString:POST_TYPE_IMAGE]) {
//        self.askText.text = @"Type your comment here";
//    }
    
    self.askText.text = @"";
    self.onlyCameraButton.enabled = NO;
    self.textCount.text = @"0";
    
    [UIView animateWithDuration:0.2 animations:^{
        CGRect r = self.askQuestionView.frame;
        self.askQuestionView.frame = CGRectMake(0, 0, r.size.width, r.size.height);
    }];
    
    [self.askText becomeFirstResponder];    
}

- (IBAction)hideAskQuestionView:(id)sender {
    [UIView animateWithDuration:0.5 animations:^{
        [self.askText resignFirstResponder];
        CGRect r = self.askQuestionView.frame;
        self.askQuestionView.frame = CGRectMake(0, -568, r.size.width, r.size.height);
    }];
}


@end


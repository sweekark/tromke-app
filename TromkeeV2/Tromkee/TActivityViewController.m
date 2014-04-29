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

#define SORT_ACTIVITIES_KEY @"updatedAt"

@interface TActivityViewController () <UITableViewDataSource, UITableViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIActionSheetDelegate, TPostCellDelegate>

@property (nonatomic, strong) NSMutableArray* activities;
@property (nonatomic, weak) IBOutlet UITableView* activitiesTable;
@property (nonatomic, weak) IBOutlet UITextView* activityDescription;
@property (weak, nonatomic) IBOutlet UIView *bottomView;
@property (nonatomic, strong) NSMutableArray* stickerImages;
@property (nonatomic, strong) UIImagePickerController* imagePickerController;
@property (nonatomic) BOOL isCommentEditing;

@property (nonatomic, assign) UIBackgroundTaskIdentifier photoPostBackgroundTaskId;

@property (nonatomic, strong) TPostCell* postCell;

- (IBAction)postActivityDescription:(id)sender;

@end

@implementation TActivityViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.stickerObject = nil;
        self.postObjectID = nil;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.postCell = nil;
	// Do any additional setup after loading the view.
    UIBarButtonItem* forwardButton = [[UIBarButtonItem alloc] initWithTitle:@"Forward" style:UIBarButtonItemStyleBordered target:self action:@selector(share)];
    self.navigationController.navigationItem.rightBarButtonItem = forwardButton;
    
    self.photoPostBackgroundTaskId = UIBackgroundTaskInvalid;
    self.activities = [@[] mutableCopy];
    self.stickerImages = [@[] mutableCopy];
}


-(void)setStickerObject:(PFObject *)stickerObject {
    _stickerObject = stickerObject;
    [self update];
}


-(void)setPostObjectID:(NSString *)postObjectID {
    _postObjectID = postObjectID;
    if ([Reachability isReachable]) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
        PFQuery* postQuery = [PFQuery queryWithClassName:@"Post"];
        [postQuery includeKey:@"sticker"];
        [postQuery includeKey:@"images"];
        [postQuery includeKey:@"fromUser"];
        [postQuery whereKey:@"objectId" equalTo:self.postObjectID];
        [postQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            if (!error) {
                self.stickerObject = [objects firstObject];
                [self update];
            }
        }];
    }
}

-(void)update {
    if ([Reachability isReachable]) {
        [self updateThanksButton];
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
        PFQuery* activityQuery = [PFQuery queryWithClassName:@"Activity"];
        [activityQuery whereKey:@"post" equalTo:self.stickerObject];
        [activityQuery whereKey:@"type" containedIn:@[@"IMAGE_COMMENT", @"COMMENT", @"THANKS"]];
        [activityQuery includeKey:@"fromUser"];
        [activityQuery orderByDescending:SORT_ACTIVITIES_KEY];
        
        __weak TActivityViewController* weakSelf = self;
        [activityQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            NSLog(@"Received objects for sticker : %lu", (unsigned long)objects.count);
            
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            
            NSIndexSet* indexes = [objects indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
                return [[(PFObject*)obj valueForKey:@"type"] isEqualToString:THANKS];
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
    [thanksQuery whereKey:@"post" equalTo:self.stickerObject];
    [thanksQuery whereKey:@"fromUser" equalTo:[PFUser currentUser]];
    [thanksQuery whereKey:@"type" equalTo:@"THANKS"];
    [thanksQuery getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        if (!error && object) {
            [self.postCell.thanksButton setTitle:@"Thanked" forState:UIControlStateNormal];
            self.postCell.thanksButton.userInteractionEnabled = NO;
        }
    }];
}

-(void)share {
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:[NSArray arrayWithObjects: self.stickerObject[@"data"], nil] applicationActivities:nil];
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
            PFObject* images = self.stickerObject[@"images"];
            if (images) {
                self.postCell = [tableView dequeueReusableCellWithIdentifier:@"POST_IMAGE"];
            } else {
                self.postCell = [tableView dequeueReusableCellWithIdentifier:@"ONLY_POST"];
            }
            self.postCell.delegate = self;
            [self.postCell update:self.stickerObject];
        }
        
        return self.postCell;
    }
    
    PFObject* comment = self.activities[indexPath.row - 1];
    PFObject* fromUser = comment[@"fromUser"];
    
    TActivityCell* cell;
    if ([comment[@"type"] isEqualToString:COMMENT]) {
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

    cell.personName.text = fromUser[@"displayName"];
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
        PFObject* images = self.stickerObject[@"images"];
        if (images) {
            height = 325;
        } else {
            height = 135;
        }
    } else {
        if (self.activities && self.activities.count) {
            PFObject* comment = self.activities[indexPath.row - 1];
            if ([comment[@"type"] isEqualToString:IMAGE_COMMENT]) {
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

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if([text isEqualToString:@"\n"])
    {
        [textView resignFirstResponder];
        return YES;
    }
    
    return textView.text.length + (text.length - range.length) <= POSTDATA_LENGTH;
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
    self.isCommentEditing = YES;
    [UIView animateWithDuration:0.35 animations:^{
        CGRect r = self.bottomView.frame;
        r.origin.y -= 216;
        self.bottomView.frame = r;
    }];
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    self.isCommentEditing = NO;
    [UIView animateWithDuration:0.1 animations:^{
        CGRect r = self.bottomView.frame;
        r.origin.y += 216;
        self.bottomView.frame = r;
    }];
}

- (IBAction)postActivityDescription:(id)sender {
    [self.activityDescription resignFirstResponder];
    
    if ([self.activityDescription.text length] == 0) {
        return;
    }
    
    if (![PFUser currentUser]) {
        [[[UIAlertView alloc] initWithTitle:@"Warning" message:@"You must login in order to post a sticker !!!" delegate:self cancelButtonTitle:@"Not Now" otherButtonTitles: @"Login", nil] show];
        return;
    }
    
    if ([self.stickerImages count]) {
        self.photoPostBackgroundTaskId = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
            [[UIApplication sharedApplication] endBackgroundTask:self.photoPostBackgroundTaskId];
        }];

        UIImage *resizedImage = [self.stickerImages[0] resizedImageWithContentMode:UIViewContentModeScaleAspectFit bounds:CGSizeMake(560.0f, 560.0f) interpolationQuality:kCGInterpolationHigh];
        NSData *imageData = UIImageJPEGRepresentation(resizedImage, 0.8f);
        
        __block PFFile* imageFile = [PFFile fileWithData:imageData];
        [imageFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (succeeded) {
                NSLog(@"Saved image file");
                PFObject* activiy = [PFObject objectWithClassName:@"Activity"];
                activiy[@"fromUser"] = [PFUser currentUser];
                activiy[@"commentImage"] = imageFile;
                activiy[@"toUser"] = self.stickerObject[@"fromUser"];
                activiy[@"type"] = IMAGE_COMMENT;
                activiy[@"content"] = self.activityDescription.text;
                activiy[@"post"] = self.stickerObject;
                
                [activiy saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                    if (succeeded) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [[[UIAlertView alloc] initWithTitle:@"Successful" message:@"Comment posted successfully" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
                            [self update];
                        });
                    } else {
                        NSLog(@"Failed to post comment");
                    }
                }];
            } else {
                NSLog(@"Failed to upload image");
            }
            
            [[UIApplication sharedApplication] endBackgroundTask:self.photoPostBackgroundTaskId];
        }];
    } else {

        self.photoPostBackgroundTaskId = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
            [[UIApplication sharedApplication] endBackgroundTask:self.photoPostBackgroundTaskId];
        }];
        
        PFObject* activiy = [PFObject objectWithClassName:@"Activity"];
        activiy[@"fromUser"] = [PFUser currentUser];
        activiy[@"toUser"] = self.stickerObject[@"fromUser"];
        activiy[@"type"] = COMMENT;
        activiy[@"content"] = self.activityDescription.text;
        activiy[@"post"] = self.stickerObject;

        [activiy saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (succeeded) {
                dispatch_async(dispatch_get_main_queue(), ^{
//                    [[[UIAlertView alloc] initWithTitle:@"Successful" message:@"Comment posted successfully" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
                    [self update];
                });
            }
            
            [[UIApplication sharedApplication] endBackgroundTask:self.photoPostBackgroundTaskId];
        }];
    }
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
    [self.activityDescription resignFirstResponder];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    PFObject* activiy = [PFObject objectWithClassName:@"Activity"];
    activiy[@"fromUser"] = [PFUser currentUser];
    activiy[@"toUser"] = self.stickerObject[@"fromUser"];
    activiy[@"type"] = @"THANKS";
    activiy[@"content"] = self.activityDescription.text;
    activiy[@"post"] = self.stickerObject;

    [activiy saveInBackground];
}

- (IBAction)takePicture:(id)sender {
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
    {
        [self showImagePickerForSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
    } else {
        UIActionSheet* sourceSelection = [[UIActionSheet alloc] initWithTitle:@"Select source type" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Camera", @"Photo Library", nil];
        [sourceSelection showInView:self.view];
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        [self showImagePickerForSourceType:UIImagePickerControllerSourceTypeCamera];
    } else if (buttonIndex == 1) {
        [self showImagePickerForSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
    }
}

- (void)showImagePickerForSourceType:(UIImagePickerControllerSourceType)sourceType
{
    if (self.isCommentEditing) {
        [self.activityDescription resignFirstResponder];
    }
    
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.modalPresentationStyle = UIModalPresentationCurrentContext;
    imagePickerController.sourceType = sourceType;
    imagePickerController.delegate = self;
    
    self.imagePickerController = imagePickerController;
    [self presentViewController:self.imagePickerController animated:YES completion:nil];
}

#pragma mark - UIImagePickerControllerDelegate

// This method is called when an image has been chosen from the library or taken from the camera.
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = [info valueForKey:UIImagePickerControllerOriginalImage];
//    [self.stickerImages addObject:image];
    [self.stickerImages insertObject:image atIndex:0];
    [self dismissViewControllerAnimated:YES completion:nil];
    self.imagePickerController = nil;
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:NULL];
    self.imagePickerController = nil;
}

- (void)updateLabelPreferredMaxLayoutWidthToCurrentWidth:(UILabel *)label
{
    label.preferredMaxLayoutWidth =
    [label alignmentRectForFrame:label.frame].size.width;
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:PROFILE]) {
        NSIndexPath* indxPath = [self.activitiesTable indexPathForSelectedRow];
        if (indxPath.row == 0) {
            PFUser* fromUser = self.stickerObject[@"fromUser"];
            TProfileViewController* profileVC = segue.destinationViewController;
            profileVC.userProfile = fromUser;
        } else {
            PFObject* comment = self.activities[indxPath.row - 1];
            PFUser* fromUser = comment[@"fromUser"];
            TProfileViewController* profileVC = segue.destinationViewController;
            profileVC.userProfile = fromUser;
        }
    } else if ([segue.identifier isEqualToString:STICKER_POSTED_PROFILE]) {
        PFUser* user = self.stickerObject[@"fromUser"];
        TProfileViewController* profileVC = segue.destinationViewController;
        profileVC.userProfile = user;
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
    NSString* comment = self.stickerObject[@"data"];
    if (comment && comment.length) {
        [actItems addObject:comment];
    }
    
    PFObject* stickerObj = self.stickerObject[@"sticker"];
    PFFile* stickerImage = stickerObj[@"image"];
    UIImage* img = [UIImage imageWithData:[stickerImage getData]];
    [actItems addObject:img];
    
    UIActivityViewController* actController = [[UIActivityViewController alloc] initWithActivityItems:actItems applicationActivities:nil];
    [self presentViewController:actController animated:YES completion:nil];
}



@end

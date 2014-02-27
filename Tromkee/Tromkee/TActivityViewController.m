//
//  TActivityViewController.m
//  Tromke
//
//  Created by Satyanarayana SVV on 2/17/14.
//  Copyright (c) 2014 Tromkee. All rights reserved.
//

#import "TActivityViewController.h"
#import "MBProgressHUD.h"
#import "TActivityCell.h"
#import "TAppDelegate.h"
#import "TCircleView.h"
#import "UIImage+ResizeAdditions.h"

#define SORT_ACTIVITIES_KEY @"updatedAt"

@interface TActivityViewController () <UITableViewDataSource, UITableViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIActionSheetDelegate>

@property (weak, nonatomic) IBOutlet PFImageView *fromImage;
@property (weak, nonatomic) IBOutlet UILabel *fromName;
@property (weak, nonatomic) IBOutlet UILabel *fromPostedTime;
@property (weak, nonatomic) IBOutlet UILabel *fromPostedMessage;
@property (weak, nonatomic) IBOutlet UILabel *totalThanks;
@property (weak, nonatomic) IBOutlet UIImageView *fromStickerImage;
@property (weak, nonatomic) IBOutlet TCircleView *fromStickerIntensity;


@property (nonatomic, strong) MBProgressHUD* progress;
@property (nonatomic, strong) NSMutableArray* activities;
@property (nonatomic, weak) IBOutlet UITableView* activitiesTable;
@property (nonatomic, weak) IBOutlet UITextView* activityDescription;
@property (weak, nonatomic) IBOutlet UIView *bottomView;

@property (nonatomic, strong) NSMutableArray* stickerImages;
@property (nonatomic, strong) UIImagePickerController* imagePickerController;
@property (nonatomic) BOOL isCommentEditing;

@property (nonatomic, assign) UIBackgroundTaskIdentifier photoPostBackgroundTaskId;

- (IBAction)postActivityDescription:(id)sender;

@end

@implementation TActivityViewController

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
    self.photoPostBackgroundTaskId = UIBackgroundTaskInvalid;
    self.activities = [@[] mutableCopy];
    self.stickerImages = [@[] mutableCopy];
    [self update];
}

-(void)update {
    self.progress = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.progress.labelText = @"Fetching ...";
    self.progress.dimBackground = YES;
    PFQuery* activityQuery = [PFQuery queryWithClassName:@"Activity" predicate:[NSPredicate predicateWithFormat:@"stickersInLocation == %@", self.stickerObject]];
    [activityQuery includeKey:@"fromUser"];
    [activityQuery orderByDescending:SORT_ACTIVITIES_KEY];
    
    __weak TActivityViewController* weakSelf = self;
    [activityQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        [weakSelf.progress hide:YES];
        if (error) {
            NSLog(@"Error in getting activities: %@", error.localizedDescription);
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                PFObject* user = weakSelf.stickerObject[@"user"];
                
                PFFile *imageFile = [user objectForKey:FACEBOOK_SMALLPIC_KEY];
                if (imageFile) {
                    NSLog(@"Loading person image:");
                    [weakSelf.fromImage setFile:imageFile];
                    [weakSelf.fromImage loadInBackground];
                } else {
                    NSLog(@"No image found");
                }
                
                
                weakSelf.fromName.text = user[@"username"];
                weakSelf.fromPostedTime.text = [weakSelf computePostedTime:self.stickerObject.updatedAt];
                weakSelf.fromPostedMessage.text = weakSelf.stickerObject[@"data"];
                [weakSelf.fromPostedMessage sizeToFit];
                //Compute Thanks objects posted
                NSIndexSet* indexes = [objects indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
                    return [[(PFObject*)obj valueForKey:@"type"] isEqualToString:THANKS];
                }];
                
                weakSelf.totalThanks.text = [NSString stringWithFormat:@"%lu", (unsigned long)(indexes ? indexes.count : 0)];
                
                PFObject* stickerObj = weakSelf.stickerObject[@"sticker"];
                PFFile* stickerImage = stickerObj[@"image"];
                [stickerImage getDataInBackgroundWithBlock:^(NSData *imageData, NSError *error) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (!error) {
                            weakSelf.fromStickerImage.image = [UIImage imageWithData:imageData];
                            weakSelf.fromStickerIntensity.green = [weakSelf.stickerObject[@"severity"] floatValue];
                            [weakSelf.fromStickerIntensity setNeedsDisplay];
                        }
                    });
                }];
                
                if (objects.count) {
                    weakSelf.activities = [NSMutableArray arrayWithArray:objects];
                    [weakSelf.activities removeObjectsAtIndexes:indexes];
                    [weakSelf.activitiesTable reloadData];
                }
            });
        }
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.activities.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    PFObject* comment = self.activities[indexPath.row];
    PFObject* fromUser = comment[@"fromUser"];
    
    TActivityCell* cell;
    if ([comment[@"type"] isEqualToString:COMMENT]) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"ONLY_COMMENT"];
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:@"COMMENT_IMAGE"];
        PFFile* imgFile = comment[@"commentImage"];
        if (imgFile) {
            [cell.commentImage setFile:imgFile];
            [cell.commentImage loadInBackground];
        }
    }

    cell.personName.text = fromUser[@"username"];
    cell.comment.text = comment[@"content"];
    [cell.comment sizeToFit];
    cell.updatedTime.text = [self computePostedTime:comment.updatedAt];
    
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat height = 100;
    PFObject* comment = self.activities[indexPath.row];
    if ([comment[@"type"] isEqualToString:IMAGE_COMMENT]) {
        height = 300;
    }
    
    return height;
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
                activiy[@"toUser"] = self.stickerObject[@"user"];
                activiy[@"type"] = IMAGE_COMMENT;
                activiy[@"content"] = self.activityDescription.text;
                activiy[@"stickersInLocation"] = self.stickerObject;
                
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
        activiy[@"toUser"] = self.stickerObject[@"user"];
        activiy[@"type"] = COMMENT;
        activiy[@"content"] = self.activityDescription.text;
        activiy[@"stickersInLocation"] = self.stickerObject;

        [activiy saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (succeeded) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[[UIAlertView alloc] initWithTitle:@"Successful" message:@"Comment posted successfully" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
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


-(NSString*)computePostedTime :(NSDate*)date {
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setAMSymbol:@"am"];
    [dateFormatter setPMSymbol:@"pm"];
    
    NSString* timestamp;
    int timeIntervalInHours = (int)[[NSDate date] timeIntervalSinceDate:date] /3600;
    
    int timeIntervalInMinutes = [[NSDate date] timeIntervalSinceDate:date] /60;
    
    if (timeIntervalInMinutes <= 2){//less than 2 minutes old
        
        timestamp = @"Just Now";
        
    }else if(timeIntervalInMinutes < 15){//less than 15 minutes old
        
        timestamp = @"A few minutes ago";
        
    }else if(timeIntervalInHours < 24){//less than 1 day
        
        [dateFormatter setDateFormat:@"h:mm a"];
        timestamp = [NSString stringWithFormat:@"Today at %@",[dateFormatter stringFromDate:date]];
        
    }else if (timeIntervalInHours < 48){//less than 2 days
        
        [dateFormatter setDateFormat:@"h:mm a"];
        timestamp = [NSString stringWithFormat:@"Yesterday at %@",[dateFormatter stringFromDate:date]];
        
    }else if (timeIntervalInHours < 168){//less than  a week
        
        [dateFormatter setDateFormat:@"EEEE"];
        timestamp = [NSString stringWithFormat:@"%@",[dateFormatter stringFromDate:date]];
        
    }else if (timeIntervalInHours < 8765){//less than a year
        
        [dateFormatter setDateFormat:@"d MMMM"];
        timestamp = [NSString stringWithFormat:@"%@",[dateFormatter stringFromDate:date]];
        
    }else{//older than a year
        
        [dateFormatter setDateFormat:@"d MMMM yyyy"];
        timestamp = [NSString stringWithFormat:@"%@",[dateFormatter stringFromDate:date]];
        
    }
    
    return timestamp;
}

- (IBAction)conveyThanks:(id)sender {
    [self.activityDescription resignFirstResponder];
    
    self.progress = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.progress.labelText = @"Sending Thanks ...";
    self.progress.dimBackground = YES;
    
    PFObject* activiy = [PFObject objectWithClassName:@"Activity"];
    activiy[@"fromUser"] = [PFUser currentUser];
    activiy[@"toUser"] = self.stickerObject[@"user"];
    activiy[@"type"] = @"THANKS";
    activiy[@"content"] = self.activityDescription.text;
    activiy[@"stickersInLocation"] = self.stickerObject;
    
    __weak TActivityViewController* weakself = self;
    [activiy saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        [weakself.progress hide:YES];
        if (succeeded) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[[UIAlertView alloc] initWithTitle:@"Successful" message:@"Comment posted successfully" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
                [self update];
            });
        }
    }];

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

@end

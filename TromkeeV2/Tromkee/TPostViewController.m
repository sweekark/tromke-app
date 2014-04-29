//
//  TPostViewController.m
//  Tromke
//
//  Created by Satyanarayana SVV on 1/17/14.
//  Copyright (c) 2014 Tromkee. All rights reserved.
//

#import "TPostViewController.h"
#import "TCircleView.h"
#import "TLogInViewController.h"
#import "TLocationUtility.h"
#import "TAppDelegate.h"
#import "UIImage+ResizeAdditions.h"
#import "UIImage+RoundedCornerAdditions.h"
#import "UIImage+AlphaAdditions.h"


#define IMAGE @"image"
#define STICKER_POINTS @"postPoints"
#define CAMERA_POINTS @"imagePoints"

@interface TPostViewController () <PFLogInViewControllerDelegate, UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (weak, nonatomic) IBOutlet TCircleView *circleView;
@property (weak, nonatomic) IBOutlet UIImageView *stickerImage;
@property (weak, nonatomic) IBOutlet UISlider *stickerSeverity;
@property (weak, nonatomic) IBOutlet UILabel *stickerPoints;
@property (weak, nonatomic) IBOutlet UILabel *cameraPoints;
@property (weak, nonatomic) IBOutlet UITextView *stickerDescription;
@property (weak, nonatomic) IBOutlet UIView* bottomView;

@property (nonatomic, strong) PFFile* photoFile;
@property (nonatomic, strong) PFFile* thumbnailFile;

@property (nonatomic, strong) UIImagePickerController* imagePickerController;
@property (nonatomic) BOOL isCommentEditing;

@property (nonatomic, assign) UIBackgroundTaskIdentifier fileUploadBackgroundTaskId;
@property (nonatomic, assign) UIBackgroundTaskIdentifier photoPostBackgroundTaskId;

- (IBAction)postSticker:(id)sender;
- (IBAction)takePicture:(id)sender;

@end

@implementation TPostViewController

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
    self.stickerDescription.contentInset = UIEdgeInsetsMake(-4, 0, 0, 0);
	// Do any additional setup after loading the view.
    self.view.backgroundColor = STICKERS_BG_COLOR;
    self.bottomView.backgroundColor = STICKER_POST_BOTTOM_COLOR;
    
    [self updateSeverityColor:0.5];
    self.fileUploadBackgroundTaskId = UIBackgroundTaskInvalid;
    self.photoPostBackgroundTaskId = UIBackgroundTaskInvalid;
}

-(void)viewWillAppear:(BOOL)animated {

    PFFile *userImageFile = self.postSticker[IMAGE];
    [userImageFile getDataInBackgroundWithBlock:^(NSData *imageData, NSError *error) {
        if (!error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.stickerImage.image = [UIImage imageWithData:imageData];
                self.stickerPoints.text = [NSString stringWithFormat:@"%@", self.postSticker[STICKER_POINTS]];
                self.cameraPoints.text = [NSString stringWithFormat:@"%@", self.postSticker[CAMERA_POINTS]];
            });
        }
    }];

    [super viewWillAppear:animated];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)updateStickerIntensity:(id)sender {
    CGFloat gValue = self.stickerSeverity.value;
    //CGFloat gHTMLValue = gValue / 255;
    [self updateSeverityColor:gValue];
}

-(void)updateSeverityColor : (CGFloat)greenValue {
    self.circleView.green = greenValue;
    [self.circleView setNeedsDisplay];

    self.stickerSeverity.minimumTrackTintColor = self.stickerSeverity.maximumTrackTintColor = self.stickerSeverity.thumbTintColor = [UIColor colorWithRed:1.0 - greenValue green:greenValue blue:0.0 alpha:1.0];
}

- (IBAction)postSticker:(id)sender {
    if (self.isCommentEditing) {
        [self.stickerDescription resignFirstResponder];
    }
    
    if (![PFUser currentUser]) {
        [[[UIAlertView alloc] initWithTitle:@"Warning" message:@"You must login in order to post a sticker !!!" delegate:self cancelButtonTitle:@"Not Now" otherButtonTitles: @"Login", nil] show];
        return;
    }
    
    if (![Reachability isReachable]) {
        return;
    }
    
//    if (![self.stickerDescription.text length]) {
//        [[[UIAlertView alloc] initWithTitle:@"Warning" message:@"Please enter comment to post !!!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
//        return;
//    }
    NSLog(@"User available");
    if (self.photoFile && self.thumbnailFile) {
        self.photoPostBackgroundTaskId = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
            [[UIApplication sharedApplication] endBackgroundTask:self.photoPostBackgroundTaskId];
        }];
        
        NSLog(@"Requested background expiration task with id %lu for Anypic photo upload", (unsigned long)self.photoPostBackgroundTaskId);
        
        __block PFObject *imagesObject = [PFObject objectWithClassName:@"Image"];
        imagesObject[@"image"] = self.photoFile;
        imagesObject[@"thumbnail"] = self.thumbnailFile;
        [imagesObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (succeeded) {
                CLLocationCoordinate2D usrLocation = [[TLocationUtility sharedInstance] getUserCoordinate];
                
                PFObject *stickerPost = [PFObject objectWithClassName:@"Post"];
                stickerPost[@"data"] = self.stickerDescription.text;
                stickerPost[@"location"] = [PFGeoPoint geoPointWithLatitude:usrLocation.latitude longitude:usrLocation.longitude];
                stickerPost[@"fromUser"] = [PFUser currentUser];
                stickerPost[@"sticker"] = self.postSticker;
                stickerPost[@"severity"] = [NSNumber numberWithFloat:self.stickerSeverity.value];
                stickerPost[@"points"] = @([self.postSticker[@"postPoints"] integerValue] + [self.postSticker[@"imagePoints"] integerValue]);
                stickerPost[@"images"] = imagesObject;
                stickerPost[@"usrlocation"] = [[NSUserDefaults standardUserDefaults] valueForKey:USER_LOCATION];
                stickerPost[@"type"] = @"STICKER";
                
                [stickerPost saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                    if (succeeded) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [[[UIAlertView alloc] initWithTitle:@"Successful" message:@"Sticker posted successfully" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
                            [self.navigationController popViewControllerAnimated:YES];
                            [[NSNotificationCenter defaultCenter] postNotificationName:TROMKEE_UPDATE_STICKERS object:nil];
                        });
                        
                    } else {
                        NSLog(@"Failed with Sticker Error: %@", error.localizedDescription);
                    }
                }];
            } else {
                NSLog(@"Failed with Image object Error: %@", error.localizedDescription);
            }
        }];
    }
    else {
        //Post only content
        CLLocationCoordinate2D usrLocation = [[TLocationUtility sharedInstance] getUserCoordinate];
        
        PFObject *stickerPost = [PFObject objectWithClassName:@"Post"];
        stickerPost[@"data"] = self.stickerDescription.text;
        stickerPost[@"location"] = [PFGeoPoint geoPointWithLatitude:usrLocation.latitude longitude:usrLocation.longitude];
        stickerPost[@"fromUser"] = [PFUser currentUser];
        stickerPost[@"sticker"] = self.postSticker;
        stickerPost[@"severity"] = [NSNumber numberWithFloat:self.stickerSeverity.value];
        stickerPost[@"points"] = self.postSticker[@"postPoints"];
        stickerPost[@"usrlocation"] = [[NSUserDefaults standardUserDefaults] valueForKey:USER_LOCATION];
        stickerPost[@"type"] = @"STICKER";
        
        [stickerPost saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (succeeded) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[[UIAlertView alloc] initWithTitle:@"Successful" message:@"Sticker posted successfully" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
                    [self.navigationController popViewControllerAnimated:YES];
                    [[NSNotificationCenter defaultCenter] postNotificationName:TROMKEE_UPDATE_STICKERS object:nil];
                });
            } else {
                NSLog(@"Failed with Sticker Error: %@", error.localizedDescription);
            }
        }];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:STICKER_POSTED object:nil];
}

-(void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        [(TAppDelegate*)[[UIApplication sharedApplication] delegate] presentLoginViewControllerAnimated:NO];
    }
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
    } else {
        [self showImagePickerForSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
    }
}

- (void)showImagePickerForSourceType:(UIImagePickerControllerSourceType)sourceType
{
    if (self.isCommentEditing) {
        [self.stickerDescription resignFirstResponder];
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
    [self shouldUploadImage:image];
    [self dismissViewControllerAnimated:YES completion:nil];
    self.imagePickerController = nil;
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:NULL];
    self.imagePickerController = nil;
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
        UIViewController* vc = [self topMostController];
        
        CGRect r = vc.view.frame;
        r.origin.y = -216;
        vc.view.frame = r;
    }];
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    self.isCommentEditing = NO;
    [UIView animateWithDuration:0.1 animations:^{
        UIViewController* vc = [self topMostController];
        
        CGRect r = vc.view.frame;
        r.origin.y = 0;
        vc.view.frame = r;
    }];
}

- (UIViewController*) topMostController
{
    UIViewController *topController = [UIApplication sharedApplication].keyWindow.rootViewController;
    
    while (topController.presentedViewController) {
        topController = topController.presentedViewController;
    }
    
    return topController;
}

- (void)shouldUploadImage:(UIImage *)anImage {
    UIImage *img = [anImage resizedImageWithContentMode:UIViewContentModeScaleAspectFit bounds:CGSizeMake(560.0f, 560.0f) interpolationQuality:kCGInterpolationHigh];
    UIImage *thumbnailImage = [img thumbnailImage:86.0f transparentBorder:0.0f cornerRadius:10.0f interpolationQuality:kCGInterpolationDefault];
    
    NSData *imageData = UIImageJPEGRepresentation(img, 0.8f);
    NSData* thumbnailData = UIImagePNGRepresentation(thumbnailImage);
    
    self.photoFile = [PFFile fileWithData:imageData];
    self.thumbnailFile = [PFFile fileWithData:thumbnailData];
    
    // Request a background execution task to allow us to finish uploading the photo even if the app is backgrounded
    self.fileUploadBackgroundTaskId = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        [[UIApplication sharedApplication] endBackgroundTask:self.fileUploadBackgroundTaskId];
    }];
    
    NSLog(@"Requested background expiration task with id %lu for Anypic photo upload", (unsigned long)self.fileUploadBackgroundTaskId);
    [self.photoFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            NSLog(@"Photo uploaded successfully");
            [self.thumbnailFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (succeeded) {
                    NSLog(@"Thumbnail uploaded successfully");
                }
                [[UIApplication sharedApplication] endBackgroundTask:self.fileUploadBackgroundTaskId];
            }];
        } else {
            [[UIApplication sharedApplication] endBackgroundTask:self.fileUploadBackgroundTaskId];
        }
    }];
}
@end

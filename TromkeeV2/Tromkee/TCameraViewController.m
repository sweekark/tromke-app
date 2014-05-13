//
//  TCameraViewController.m
//  Tromkee
//
//  Created by Satyanarayana SVV on 4/30/14.
//  Copyright (c) 2014 Tromkee. All rights reserved.
//

#import "TCameraViewController.h"
#import "UIImage+ResizeAdditions.h"
#import "TLocationUtility.h"

#define DEFAULT_TEXT @"Say Something"

@interface TCameraViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate, UITextViewDelegate>{
    
    //Today Implementation
    BOOL isSingleBuddy;
    BOOL FrontCamera;
    BOOL haveImage;
    BOOL initializeCamera, photoFromCam;
    AVCaptureSession *session;
    AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;
    AVCaptureStillImageOutput *stillImageOutput;
}

@property (nonatomic, weak) IBOutlet UIButton *photoCaptureButton;
@property (nonatomic, weak) IBOutlet UIButton *cancelButton;
@property (nonatomic, weak) IBOutlet UIButton *cameraToggleButton;
@property (nonatomic, weak) IBOutlet UIButton *flashToggleButton;
@property (nonatomic, weak) IBOutlet UIView *photoBar;
@property (nonatomic, weak) IBOutlet UIView *topBar;
@property (weak, nonatomic) IBOutlet UIView *imagePreview;
@property (weak, nonatomic) IBOutlet UIImageView *captureImage;
@property (weak, nonatomic) IBOutlet UIView *postBar;
@property (weak, nonatomic) IBOutlet UIButton *oneBuddy;
@property (weak, nonatomic) IBOutlet UIButton *groupBuddy;
@property (weak, nonatomic) IBOutlet UITextView *postMessage;
@property (weak, nonatomic) IBOutlet UIView* postMessageView;
@property (weak, nonatomic) IBOutlet UILabel* textCount;

@end

@implementation TCameraViewController

-(BOOL)prefersStatusBarHidden {
    return YES;
}

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
    
//    if ([self respondsToSelector:@selector(edgesForExtendedLayout)]){
//        self.edgesForExtendedLayout = UIRectEdgeNone;
//    }
    
    self.navigationController.navigationBarHidden = YES;
    [self.navigationController setNavigationBarHidden:YES];
    
    // Today Implementation
    isSingleBuddy = NO;
    FrontCamera = NO;
//    self.captureImage.hidden = YES;
    
    initializeCamera = YES;
    photoFromCam = YES;
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
    self.postBar.backgroundColor = [TUtility colorFromHexString:ACTIVITY_QUESTION_COLOR];
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    if (initializeCamera){
        initializeCamera = NO;
        
        // Initialize camera
        [self initializeCamera];
    }

    if (self.activityName != CameraForImage) {
        self.postMessage.text = self.cameraMessage;
        self.textCount.text = [NSString stringWithFormat:@"%lu", (unsigned long)self.cameraMessage.length];
    }
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    
//    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
//    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Camera Initialization

//AVCaptureSession to show live video feed in view
- (void) initializeCamera {
    if (session)
        session=nil;
    
    session = [[AVCaptureSession alloc] init];
	session.sessionPreset = AVCaptureSessionPresetMedium;
	
    if (captureVideoPreviewLayer)
        captureVideoPreviewLayer=nil;
    
	captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:session];
    [captureVideoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    
	captureVideoPreviewLayer.frame = self.imagePreview.bounds;
	[self.imagePreview.layer addSublayer:captureVideoPreviewLayer];
	
    UIView *view = [self imagePreview];
    CALayer *viewLayer = [view layer];
    [viewLayer setMasksToBounds:YES];
    
    CGRect bounds = [view bounds];
    [captureVideoPreviewLayer setFrame:bounds];
    
    NSArray *devices = [AVCaptureDevice devices];
    AVCaptureDevice *frontCamera=nil;
    AVCaptureDevice *backCamera=nil;
    
    // check if device available
    if (devices.count==0) {
        NSLog(@"No Camera Available");
        [self disableCameraDeviceControls];
        return;
    }
    
    for (AVCaptureDevice *device in devices) {
        
        NSLog(@"Device name: %@", [device localizedName]);
        
        if ([device hasMediaType:AVMediaTypeVideo]) {
            
            if ([device position] == AVCaptureDevicePositionBack) {
                NSLog(@"Device position : back");
                backCamera = device;
            }
            else {
                NSLog(@"Device position : front");
                frontCamera = device;
            }
        }
    }
    
    if (!FrontCamera) {
        
        if ([backCamera hasFlash]){
            [backCamera lockForConfiguration:nil];
            if (self.flashToggleButton.selected)
                [backCamera setFlashMode:AVCaptureFlashModeOn];
            else
                [backCamera setFlashMode:AVCaptureFlashModeOff];
            [backCamera unlockForConfiguration];
            
            [self.flashToggleButton setEnabled:YES];
        }
        else{
            if ([backCamera isFlashModeSupported:AVCaptureFlashModeOff]) {
                [backCamera lockForConfiguration:nil];
                [backCamera setFlashMode:AVCaptureFlashModeOff];
                [backCamera unlockForConfiguration];
            }
            [self.flashToggleButton setEnabled:NO];
        }
        
        NSError *error = nil;
        AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:backCamera error:&error];
        if (!input) {
            NSLog(@"ERROR: trying to open camera: %@", error);
        }
        [session addInput:input];
    }
    
    if (FrontCamera) {
        [self.flashToggleButton setEnabled:NO];
        NSError *error = nil;
        AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:frontCamera error:&error];
        if (!input) {
            NSLog(@"ERROR: trying to open camera: %@", error);
        }
        [session addInput:input];
    }
     
    if (stillImageOutput)
        stillImageOutput=nil;
    
    stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys: AVVideoCodecJPEG, AVVideoCodecKey, nil];
    [stillImageOutput setOutputSettings:outputSettings];
    
    [session addOutput:stillImageOutput];
    
	[session startRunning];
}

- (IBAction)snapImage:(id)sender {
    [self.photoCaptureButton setEnabled:NO];
    
    if (!haveImage) {
        self.captureImage.image = nil; //remove old image from view
//        self.captureImage.hidden = NO; //show the captured image view
//        self.imagePreview.hidden = YES; //hide the live video feed
        [self capImage];
    }
    else {
//        self.captureImage.hidden = YES;
//        self.imagePreview.hidden = NO;
        haveImage = NO;
    }
}

- (void) capImage { //method to capture image from AVCaptureSession video feed
    AVCaptureConnection *videoConnection = nil;
    for (AVCaptureConnection *connection in stillImageOutput.connections) {
        
        for (AVCaptureInputPort *port in [connection inputPorts]) {
            
            if ([[port mediaType] isEqual:AVMediaTypeVideo] ) {
                videoConnection = connection;
                break;
            }
        }
        
        if (videoConnection) {
            break;
        }
    }
    
    NSLog(@"about to request a capture from: %@", stillImageOutput);
    [stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler: ^(CMSampleBufferRef imageSampleBuffer, NSError *error) {
        
        if (imageSampleBuffer != NULL) {
            
            NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
            [self.captureImage setImage:[self cropImage:[UIImage imageWithData:imageData]]];
            [self setCapturedImage];
//            [self processImage:[UIImage imageWithData:imageData]];
        }
    }];
}

//- (UIImage*)imageWithImage:(UIImage *)sourceImage scaledToWidth:(float) i_width
//{
//    float oldWidth = sourceImage.size.width;
//    float scaleFactor = i_width / oldWidth;
//    
//    float newHeight = sourceImage.size.height * scaleFactor;
//    float newWidth = oldWidth * scaleFactor;
//    
//    UIGraphicsBeginImageContext(CGSizeMake(newWidth, newHeight));
//    [sourceImage drawInRect:CGRectMake(0, 0, newWidth, newHeight)];
//    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
//    UIGraphicsEndImageContext();
//    return newImage;
//}

- (UIImage *)cropImage:(UIImage *)imageToCrop {
    CGSize size = [imageToCrop size];
    int padding = 0;
    int pictureSize;
    int startCroppingPosition;
    if (size.height > size.width) {
        pictureSize = size.width - (2.0 * padding);
        startCroppingPosition = (size.height - pictureSize) / 2.0;
    } else {
        pictureSize = size.height - (2.0 * padding);
        startCroppingPosition = (size.width - pictureSize) / 2.0;
    }
    CGRect cropRect = CGRectMake(startCroppingPosition, padding, pictureSize, pictureSize);
    CGImageRef imageRef = CGImageCreateWithImageInRect([imageToCrop CGImage], cropRect);
    UIImage *newImage = [UIImage imageWithCGImage:imageRef scale:1.0 orientation:imageToCrop.imageOrientation];
    return newImage;
    
    
//    CGRect cropRect = CGRectMake(0, 105, 640, 640);
//    CGImageRef imageRef = CGImageCreateWithImageInRect([imageToCrop CGImage], cropRect);
//    UIImage *newImage = [UIImage imageWithCGImage:imageRef scale:1.0 orientation:imageToCrop.imageOrientation];
//    return newImage;
}

//- (void) processImage:(UIImage *)image { //process captured image, crop, resize and rotate
//    haveImage = YES;
//    photoFromCam = YES;
//    
//    // Resize image to 640x640
//    // Resize image
////    NSLog(@"Image size %@",NSStringFromCGSize(image.size));
//    
//    UIImage *smallImage = [self imageWithImage:image scaledToWidth:640.0f]; //UIGraphicsGetImageFromCurrentImageContext();
//    
//    CGRect cropRect = CGRectMake(0, 105, 640, 640);
//    CGImageRef imageRef = CGImageCreateWithImageInRect([smallImage CGImage], cropRect);
//    
////    UIImage *croppedImageWithoutOrientation = [[UIImage imageWithCGImage:imageRef] copy];
//    
//    UIImage *croppedImage = nil;
//    // adjust image orientation
//    switch ([[UIDevice currentDevice] orientation]) {
//        case UIDeviceOrientationLandscapeLeft:
//            croppedImage = [[UIImage alloc] initWithCGImage: imageRef
//                                                        scale: 1.0
//                                                  orientation: UIImageOrientationLeft];
//            break;
//        case UIDeviceOrientationLandscapeRight:
//            croppedImage = [[UIImage alloc] initWithCGImage: imageRef
//                                                        scale: 1.0
//                                                  orientation: UIImageOrientationRight];
//            break;
//            
//        case UIDeviceOrientationFaceUp:
//            croppedImage = [[UIImage alloc] initWithCGImage: imageRef
//                                                        scale: 1.0
//                                                  orientation: UIImageOrientationUp];
//            break;
//        
//        case UIDeviceOrientationPortraitUpsideDown:
//            croppedImage = [[UIImage alloc] initWithCGImage: imageRef
//                                                      scale: 1.0
//                                                orientation: UIImageOrientationDown];
//            break;
//            
//        default:
//            croppedImage = [UIImage imageWithCGImage:imageRef];
//            break;
//    }
//    CGImageRelease(imageRef);
//    
//    [self.captureImage setImage:croppedImage];
//    
//    [self setCapturedImage];
//}
//

- (void)setCapturedImage{
    // Stop capturing image
//    [session stopRunning];
    
    // Hide Top/Bottom controller after taking photo for editing
    [self hideControllers];
}

#pragma mark - Device Availability Controls
- (void)disableCameraDeviceControls{
    self.cameraToggleButton.enabled = NO;
    self.flashToggleButton.enabled = NO;
    self.photoCaptureButton.enabled = NO;
}

#pragma mark - Button clicks

-(void)goBack {
    [session stopRunning];
    [self.postMessage resignFirstResponder];
    [self.navigationController popViewControllerAnimated:YES];
}

-(IBAction) cancel:(id)sender {
    [self goBack];
}

- (IBAction)cancelPhotoCapture:(id)sender{
    [self goBack];
}

- (IBAction)retakePhoto:(id)sender{
    [self.photoCaptureButton setEnabled:YES];
    self.captureImage.image = nil;
//    self.imagePreview.hidden = NO;
    // Show Camera device controls
    [self showControllers];
    
    haveImage=NO;
    FrontCamera = NO;
//    [self performSelector:@selector(initializeCamera) withObject:nil afterDelay:0.001];
}

- (IBAction)switchCamera:(UIButton *)sender { //switch cameras front and rear cameras
    // Stop current recording process
    [session stopRunning];
    
    if (sender.selected) {  // Switch to Back camera
        sender.selected = NO;
        FrontCamera = NO;
        [self performSelector:@selector(initializeCamera) withObject:nil afterDelay:0.001];
    }
    else {                  // Switch to Front camera
        sender.selected = YES;
        FrontCamera = YES;
        [self performSelector:@selector(initializeCamera) withObject:nil afterDelay:0.001];
    }
}

- (IBAction)toogleFlash:(UIButton *)sender{
    if (!FrontCamera) {
        if (sender.selected) { // Set flash off
            [sender setSelected:NO];
            
            NSArray *devices = [AVCaptureDevice devices];
            for (AVCaptureDevice *device in devices) {
                
                NSLog(@"Device name: %@", [device localizedName]);
                
                if ([device hasMediaType:AVMediaTypeVideo]) {
                    
                    if ([device position] == AVCaptureDevicePositionBack) {
                        NSLog(@"Device position : back");
                        if ([device hasFlash]){
                            
                            [device lockForConfiguration:nil];
                            [device setFlashMode:AVCaptureFlashModeOff];
                            [device unlockForConfiguration];
                            
                            break;
                        }
                    }
                }
            }

        }
        else{                  // Set flash on
            [sender setSelected:YES];
            
            NSArray *devices = [AVCaptureDevice devices];
            for (AVCaptureDevice *device in devices) {
                
                NSLog(@"Device name: %@", [device localizedName]);
                
                if ([device hasMediaType:AVMediaTypeVideo]) {
                    
                    if ([device position] == AVCaptureDevicePositionBack) {
                        NSLog(@"Device position : back");
                        if ([device hasFlash]){
                            
                            [device lockForConfiguration:nil];
                            [device setFlashMode:AVCaptureFlashModeOn];
                            [device unlockForConfiguration];
                            
                            break;
                        }
                    }
                }
            }

        }
    }
}

#pragma mark - UI Control Helpers

- (void)hideControllers{
    [UIView animateWithDuration:0.2 animations:^{
        self.photoBar.center = CGPointMake(self.photoBar.center.x, self.photoBar.center.y+116.0);
        self.topBar.center = CGPointMake(self.topBar.center.x, self.topBar.center.y-44.0);
        self.postBar.hidden = NO;
        self.postMessageView.hidden = NO;
    } completion:nil];
}

- (void)showControllers{
    [UIView animateWithDuration:0.2 animations:^{
        self.photoBar.center = CGPointMake(self.photoBar.center.x, self.photoBar.center.y - 116.0);
        self.topBar.center = CGPointMake(self.topBar.center.x, self.topBar.center.y+44.0);
        self.postBar.hidden = YES;
        self.postMessageView.hidden = YES;
    } completion:nil];
}

- (IBAction)postImage:(id)sender {

    if (![PFUser currentUser]) {
        [[[UIAlertView alloc] initWithTitle:@"Warning" message:@"You must login in order to post a sticker !!!" delegate:self cancelButtonTitle:@"Not Now" otherButtonTitles: @"Login", nil] show];
        return;
    }

    if (![Reachability isReachable]) {
        return;
    }
    
    NSLog(@"Posting image");
    
    
    UIImage* imgToPost = self.captureImage.image;
    UIImage *thumbnailImage = [imgToPost thumbnailImage:60.0f transparentBorder:0.0f cornerRadius:10.0f interpolationQuality:kCGInterpolationLow];
    NSData *imageData = UIImageJPEGRepresentation(imgToPost, 0.8f);
    NSData* thumbnailData = UIImagePNGRepresentation(thumbnailImage);
    
    PFFile* photoFile = [PFFile fileWithData:imageData];
    PFFile* thumbnailFile = [PFFile fileWithData:thumbnailData];
    
    [photoFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            [thumbnailFile saveInBackground];
        }
    }];

    if ([self.postMessage.text isEqualToString:DEFAULT_TEXT]) {
        self.postMessage.text = @"";
    }
    
    
    CLLocationCoordinate2D usrLocation = [[TLocationUtility sharedInstance] getUserCoordinate];
    
    if (self.activityName == CameraForComment) {
        PFObject* activiy = [PFObject objectWithClassName:@"Activity"];
        activiy[ACTIVITY_FROMUSER] = [PFUser currentUser];
        activiy[ACTIVITY_TOUSER] = self.postedObject[POST_FROMUSER];
        activiy[ACTIVITY_TYPE] = COMMENT;
        activiy[ACTIVITY_CONTENT] = self.postMessage.text;
        activiy[ACTIVITY_POST] = self.postedObject;
        activiy[ACTIVITY_ORIGINAL_IMAGE] = photoFile;
        activiy[ACTIVITY_THUMBNAIL_IMAGE] = thumbnailFile;

        [activiy saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (succeeded) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                });
            }
        }];

    } else {
        PFObject *stickerPost = [PFObject objectWithClassName:POST];
        stickerPost[POST_DATA] = self.postMessage.text;
        stickerPost[POST_LOCATION] = [PFGeoPoint geoPointWithLatitude:usrLocation.latitude longitude:usrLocation.longitude];
        stickerPost[POST_FROMUSER] = [PFUser currentUser];
        stickerPost[POST_USERLOCATION] = [[NSUserDefaults standardUserDefaults] valueForKey:USER_LOCATION];
        stickerPost[POST_ORIGINAL_IMAGE] = photoFile;
        stickerPost[POST_THUMBNAIL_IMAGE] = thumbnailFile;
        if (self.activityName == CameraForAsk) {
            stickerPost[POST_TYPE] = POST_TYPE_ASK;
        } else if (self.activityName == CameraForImage){
            stickerPost[POST_TYPE] = POST_TYPE_IMAGE;
        } else if (self.activityName == CameraForComment) {
            
        }

        [stickerPost saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (succeeded) {
                NSString* msg;
                if (self.activityName == CameraForAsk) {
                    msg = @"Question is posted successfully. We will inform you if anyone on Tromke will respond to your question, thanks";
                } else {
                    msg = @"Image is posted successfully. We will inform you if anyoneon on Tromke will comment, thanks";
                }
                
                [[[UIAlertView alloc] initWithTitle:@"Successful" message:msg delegate:nil cancelButtonTitle:@"OK, Got it" otherButtonTitles: nil] show];
                [[NSNotificationCenter defaultCenter] postNotificationName:TROMKEE_UPDATE_STICKERS object:nil];
            } else {
                NSLog(@"Failed with Comment to post: %@", error.localizedDescription);
            }
        }];
    }
    
    [self goBack];
}

-(void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (self.activityName != CameraForComment) {
        [[NSNotificationCenter defaultCenter] postNotificationName:TROMKEE_UPDATE_STICKERS object:nil];
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:TROMKEE_UPDATE_COMMENTS object:nil];
    }

}

- (IBAction)handleOneBuddy:(id)sender {
    if (!isSingleBuddy) {
        [self.oneBuddy setImage:[UIImage imageNamed:@"NewOneBuddySelected"] forState:UIControlStateNormal];
        [self.groupBuddy setImage:[UIImage imageNamed:@"NewGrBuddyUnSelected"] forState:UIControlStateNormal];
        isSingleBuddy = NO;
    }
}

- (IBAction)handleGroupBuddy:(id)sender {
    if (isSingleBuddy) {
        [self.oneBuddy setImage:[UIImage imageNamed:@"NewOneBuddyUnSelected"] forState:UIControlStateNormal];
        [self.groupBuddy setImage:[UIImage imageNamed:@"NewGrBuddySelected"] forState:UIControlStateNormal];
        isSingleBuddy = YES;
    }
}


- (void)textViewDidBeginEditing:(UITextView *)textView {
    if ([textView.text isEqualToString:DEFAULT_TEXT]) {
        textView.text = @"";
    }
    
    CGRect r = self.postMessageView.frame;
    r.origin.y -= 125;
    self.postMessageView.frame = r;
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    CGRect r = self.postMessageView.frame;
    r.origin.y += 125;
    self.postMessageView.frame = r;
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if([text isEqualToString:@"\n"])
    {
        [textView resignFirstResponder];
        return YES;
    }
    
    unsigned long charCount = textView.text.length + (text.length - range.length);
    if (charCount <= POSTDATA_LENGTH) {
        self.textCount.text = [NSString stringWithFormat:@"%ld", charCount];
    }

    return  charCount <= POSTDATA_LENGTH;
}

@end

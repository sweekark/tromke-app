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

#define IMAGE @"image"
#define STICKER_POINTS @"postPoints"
#define CAMERA_POINTS @"imagePoints"

@interface TPostViewController () <PFLogInViewControllerDelegate>

@property (weak, nonatomic) IBOutlet TCircleView *circleView;
@property (weak, nonatomic) IBOutlet UIImageView *stickerImage;
@property (weak, nonatomic) IBOutlet UISlider *stickerSeverity;
@property (weak, nonatomic) IBOutlet UILabel *stickerPoints;
@property (weak, nonatomic) IBOutlet UILabel *cameraPoints;
@property (weak, nonatomic) IBOutlet UITextField *stickerDescription;

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
	// Do any additional setup after loading the view.
    [self updateSeverityColor:0.5];
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
    if ([PFUser currentUser]) {
        NSLog(@"User available");
    } else {
        [[[UIAlertView alloc] initWithTitle:@"Warning" message:@"You must login in order to post a sticker !!!" delegate:self cancelButtonTitle:@"Not Now" otherButtonTitles: @"Login", nil] show];
    }
}

-(void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        TLogInViewController *loginViewController = [[TLogInViewController alloc] init];
        [loginViewController setDelegate:self];
        loginViewController.fields = PFLogInFieldsPasswordForgotten | PFLogInFieldsFacebook | PFLogInFieldsSignUpButton | PFLogInFieldsUsernameAndPassword;
        loginViewController.facebookPermissions = @[ @"user_about_me" ];
        
        [self presentViewController:loginViewController animated:YES completion:nil];
    }
}

- (IBAction)takePicture:(id)sender {
    
}
@end

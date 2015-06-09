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

@interface TPostViewController () <PFLogInViewControllerDelegate> {
    BOOL isSingleBuddy;
}

@property (weak, nonatomic) IBOutlet UIButton *oneBuddy;
@property (weak, nonatomic) IBOutlet UIButton *groupBuddy;

@property (weak, nonatomic) IBOutlet TCircleView *circleView;
@property (weak, nonatomic) IBOutlet PFImageView *stickerImage;
@property (weak, nonatomic) IBOutlet UILabel *stickerName;
@property (weak, nonatomic) IBOutlet UISlider *stickerSeverity;
@property (weak, nonatomic) IBOutlet UITextView *stickerDescription;
@property (weak, nonatomic) IBOutlet UIView* commentView;
@property (weak, nonatomic) IBOutlet UIView* postView;

@property (nonatomic) BOOL isCommentEditing;
@property (nonatomic, assign) UIBackgroundTaskIdentifier photoPostBackgroundTaskId;
@property (weak, nonatomic) IBOutlet UILabel *whatLable;

- (IBAction)postSticker:(id)sender;

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
    isSingleBuddy = NO;
    self.stickerDescription.contentInset = UIEdgeInsetsMake(-4, 0, 0, 0);
	// Do any additional setup after loading the view.
    self.commentView.backgroundColor = STICKER_POST_BOTTOM_COLOR;
    
    [self updateSeverityColor:0.5];
    
    self.postView.backgroundColor = [TUtility colorFromHexString:ACTIVITY_QUESTION_COLOR];
    self.photoPostBackgroundTaskId = UIBackgroundTaskInvalid;
}

-(void)viewWillAppear:(BOOL)animated {

    PFFile *userImageFile = self.postSticker[STICKER_IMAGE];
    if (userImageFile) {
        self.stickerImage.file = userImageFile;
        [self.stickerImage loadInBackground];
    }
    self.stickerName.text = self.postSticker[STICKER_NAME];
    
    [super viewWillAppear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)updateStickerIntensity:(id)sender {
    CGFloat gValue = self.stickerSeverity.value;
    [self updateSeverityColor:gValue];
}

-(void)updateSeverityColor : (CGFloat)greenValue {
    self.circleView.green = greenValue;
    [self.circleView setNeedsDisplay];
//    self.stickerSeverity.minimumTrackTintColor = self.stickerSeverity.maximumTrackTintColor = self.stickerSeverity.thumbTintColor = [UIColor colorWithRed:1.0 - greenValue green:greenValue blue:0.0 alpha:1.0];
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
    
    [[NSNotificationCenter defaultCenter] postNotificationName:START_PROGRESS_ANIMATION object:nil];
    
    //Post only content
//    self.photoPostBackgroundTaskId = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
//        [[UIApplication sharedApplication] endBackgroundTask:self.photoPostBackgroundTaskId];
//    }];

    NSString* descText = self.stickerDescription.text;
    CLLocationCoordinate2D usrLocation = [[TLocationUtility sharedInstance] getUserCoordinate];
    
    PFObject *stickerPost = [PFObject objectWithClassName:POST];
    stickerPost[POST_DATA] = descText ? descText : @"";
    stickerPost[POST_LOCATION] = [PFGeoPoint geoPointWithLatitude:usrLocation.latitude longitude:usrLocation.longitude];
    stickerPost[POST_FROMUSER] = [PFUser currentUser];
    stickerPost[STICKER] = self.postSticker;
    stickerPost[STICKER_SEVERITY] = [NSNumber numberWithFloat:self.stickerSeverity.value];
//    stickerPost[@"points"] = self.postSticker[@"postPoints"];
    NSString* usrLoc = [[NSUserDefaults standardUserDefaults] valueForKey:USER_LOCATION];
    if (usrLoc && usrLoc.length) {
        stickerPost[POST_USERLOCATION] = usrLoc;
    }

    stickerPost[POST_TYPE] = @"STICKER";
    
    
    BOOL commentAvailable = descText ? YES : NO;
    NSMutableDictionary* dict = [@{@"CommentAvailable" : [NSNumber numberWithBool:commentAvailable],
                                   @"StickerID" : self.postSticker.objectId,
                                   @"Rating" : [NSNumber numberWithFloat:self.stickerSeverity.value]
                                   } mutableCopy];
    if (commentAvailable) {
        [dict setObject:descText forKey:@"Comment"];
    }
    
    [TFlurryManager tromSticker:dict];
    
    
    [stickerPost saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[[UIAlertView alloc] initWithTitle:@"Successful" message:@"Sticker posted successfully" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
                [self.navigationController popViewControllerAnimated:YES];
                [[NSNotificationCenter defaultCenter] postNotificationName:STOP_PROGRESS_ANIMATION object:nil];
                [[NSNotificationCenter defaultCenter] postNotificationName:TROMKEE_UPDATE_STICKERS object:nil];
            });
        } else {
            NSLog(@"Failed with Sticker Error: %@", error.localizedDescription);
        }
        
//        [[UIApplication sharedApplication] endBackgroundTask:self.photoPostBackgroundTaskId];
    }];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:STICKER_POSTED object:nil];
}

-(void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        [(TAppDelegate*)[[UIApplication sharedApplication] delegate] presentLoginViewControllerAnimated:NO];
    }
}

#pragma mark - TextView methods

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if([text isEqualToString:@"\n"])
    {
        [textView resignFirstResponder];
        return YES;
    }
    
    unsigned long charCount = textView.text.length + (text.length - range.length);
    
    if (charCount == 0) {
        self.whatLable.hidden = NO;
    } else {
        self.whatLable.hidden = YES;
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

- (IBAction)showCommentsView:(id)sender {
    self.commentView.hidden = NO;
    [UIView animateWithDuration:0.2 animations:^{
        CGRect r = self.commentView.frame;
        self.commentView.frame = CGRectMake(0, r.origin.y, r.size.width, r.size.height);
        
        CGRect r2 = self.postView.frame;
        self.postView.frame = CGRectMake(320, r2.origin.y, r2.size.width, r2.size.height);
    }];    
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

@end

//
//  TViewController.m
//  Tromkee
//
//  Created by Satyanarayana SVV on 1/3/14.
//  Copyright (c) 2014 Tromkee. All rights reserved.
//

#import <MapKit/MapKit.h>
#import <Crashlytics/Crashlytics.h>
#import "TViewController.h"
#import "TLogInViewController.h"
#import "TLocationUtility.h"
#import "TCategoriesViewController.h"
#import "TAppDelegate.h"
#import "TStickerAnnotation.h"
#import "TCircleView.h"
#import "TMenuViewController.h"
#import "TStickerAnnotationView.h"
#import "TActivityViewController.h"
#import "TProfileViewController.h"
#import "CustomViewMV.h"
#import "CustomPin.h"
#import "TCameraViewController.h"
#import "ITProgressBar.h"
#import "TCustomLoginViewController.h"
#import "TUserActivityViewController.h"

#define USER_LOCATION_TEXT @"User Location"

@interface TViewController () <TCameraDelegate, PFLogInViewControllerDelegate, MKMapViewDelegate, TCategoriesVCDelegate, TMenuDelegate/*, TActivityDelegate, */ /*TStickerAnnotationDelegate*/>

@property (nonatomic) BOOL allowMapUpdate;
@property (weak, nonatomic) IBOutlet UILabel *notificationsCount;
@property (weak, nonatomic) IBOutlet MKMapView *map;
@property (weak, nonatomic) IBOutlet UIView *categoryContainer;
@property (weak, nonatomic) IBOutlet UIView *menuContainer;

@property (strong, nonatomic) TCategoriesViewController* categoriesVC;

@property (nonatomic) BOOL firstTimeLogin;
@property (nonatomic) BOOL isCategoriesExpanded;
@property (nonatomic) BOOL isMenuExpanded;

@property (nonatomic) CLLocationCoordinate2D currentMapLocation;
@property (nonatomic) CLLocationCoordinate2D currentCenterLocation;

@property (nonatomic, strong) NSMutableArray* stickerLocations;

@property (weak, nonatomic) IBOutlet UIView *askQuestionView;
@property (weak, nonatomic) IBOutlet UIView *askBackgroundView;
@property (weak, nonatomic) IBOutlet UILabel *textCount;
@property (weak, nonatomic) IBOutlet UITextView *askText;
@property (weak, nonatomic) IBOutlet UIButton *onlyCameraButton;

//@property (nonatomic) BOOL isFirstTime;
@property (nonatomic) BOOL isAskViewVisible;
@property (weak, nonatomic) IBOutlet UIView *firstTimeHelpView;
@property (weak, nonatomic) IBOutlet ITProgressBar *progressBar;

@property (nonatomic, strong) IBOutlet UILabel* notificationCountValue;

@property (strong, nonatomic) UIView *alertPostsView;
@property (nonatomic) BOOL isAlertsPostsViewVisible;
@property (weak, nonatomic) IBOutlet UILabel *askAnythingLabel;


- (IBAction)menuClicked:(id)sender;
- (IBAction)searchClicked:(id)sender;
- (IBAction)hideFirstTimeHelpView:(id)sender;

@end

@implementation TViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateNotificationCount) name:UPDATE_NOTIFICATION_COUNT object:nil];

    if ([[NSUserDefaults standardUserDefaults] boolForKey:FIRST_TIME_HELP] == NO) {
//        [self.firstTimeHelpView removeFromSuperview];
        [self.firstTimeHelpView setHidden:YES];
    }
    
//    self.isFirstTime = YES;
    self.isAlertsPostsViewVisible = NO;
    self.allowMapUpdate = YES;
    self.isAskViewVisible = NO;
    self.firstTimeLogin = YES;
    self.isMenuExpanded = NO;
    self.stickerLocations = [[NSMutableArray alloc] initWithCapacity:10];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateUserLocation:) name:TROMKE_USER_LOCATION_UPDATED object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(uploadLatestStickers:) name:TROMKEE_UPDATE_STICKERS object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startShowingAnimation) name:START_PROGRESS_ANIMATION object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stopShowingAnimation) name:STOP_PROGRESS_ANIMATION object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showActivityLocation:) name:SHOW_STICKER_LOCATION object:nil];
    self.askBackgroundView.backgroundColor = [TUtility colorFromHexString:ACTIVITY_QUESTION_COLOR];
    
    CLLocationCoordinate2D temp = [[TLocationUtility sharedInstance] getUserCoordinate];
    if (temp.latitude != 0 && temp.longitude != 0) {
        [self updateUserLocation:nil];
    }
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [TFlurryManager startedMap];
    [self updateNotificationCount];
}

-(void)viewDidAppear:(BOOL)animated {
    if (self.isCategoriesExpanded) {
        [self showCategoriesView];
    }
    
//    if (!self.isFirstTime) {
    if (self.allowMapUpdate) {
        [self updatePostedStickersOnMapWithCenter:self.currentCenterLocation.latitude andLongitude:self.currentCenterLocation.longitude];
    }
//    }
//    self.isFirstTime = NO;
    [super viewDidAppear:animated];
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.progressBar.hidden = YES;
    if ([PFUser currentUser]) {
        [TFlurryManager stoppedMap];
    }
    self.allowMapUpdate = YES;
}

-(void)updateNotificationCount {
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    self.notificationCountValue.text = [NSString stringWithFormat:@"%ld", (long)currentInstallation.badge];
}

-(void)startShowingAnimation {
    self.progressBar.hidden = NO;
}

-(void)stopShowingAnimation {
    self.progressBar.hidden = YES;
}

-(void)uploadLatestStickers:(NSNotification*)notification {
    [self updatePostedStickers];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)updateUserLocation:(NSNotification*)notification {
    // Creates a marker in the center of the map.
    self.currentCenterLocation = self.currentMapLocation = [[TLocationUtility sharedInstance] getUserCoordinate];
    
    MKCoordinateRegion region;
    region.center = self.currentMapLocation;
    MKCoordinateSpan span;
    span.latitudeDelta = 0.0144927536 * STICKER_QUERY_RADIUS; //1 mile
    span.longitudeDelta = 0.0144927536 * STICKER_QUERY_RADIUS; //1 mile
    region.span = span;
    [self.map setRegion:region animated:NO];
    
    [self updatePostedStickers];
}

-(BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    if ([identifier isEqualToString:CAMERA]) {
        return [Reachability isReachable];
    }
    
    return YES;
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:CATEGORIES]) {
        self.categoriesVC = segue.destinationViewController;
        self.categoriesVC.delegate = self;
    } else if ([segue.identifier isEqualToString:MENU]) {
        TMenuViewController* menuVC = segue.destinationViewController;
        menuVC.delegate = self;
    } else if ([segue.identifier isEqualToString:ACTIVITY]) {
        TActivityViewController* activityVC = segue.destinationViewController;
//        activityVC.delegate = self;
        PFObject* postedObject = (PFObject*)sender;
        NSString* stickerType = postedObject[POST_TYPE];
        if ([stickerType isEqualToString:POST_TYPE_STICKER]) {
            [TFlurryManager tappedSticker:postedObject.objectId];
        } else if ([stickerType isEqualToString:POST_TYPE_ASK]) {
            [TFlurryManager tappedSticker:postedObject.objectId];
        } else if ([stickerType isEqualToString:POST_TYPE_IMAGE]) {
            [TFlurryManager tappedSticker:postedObject.objectId];
        }
        activityVC.postedObject = sender;
    } else if ([segue.identifier isEqualToString:PROFILE]) {
        TProfileViewController* profileVC = segue.destinationViewController;
        profileVC.userProfile = [PFUser currentUser];
    } else if ([segue.identifier isEqualToString:ASKCAMERA]) {
        TCameraViewController* cameraVC = segue.destinationViewController;
        [self.askText resignFirstResponder];
        cameraVC.activityName = CameraForAsk;
        cameraVC.cameraMessage = self.askText.text;
        cameraVC.delegate = self;
    } else if ([segue.identifier isEqualToString:CAMERA]) {
        TCameraViewController* cameraVC = segue.destinationViewController;
        cameraVC.activityName = CameraForImage;
        cameraVC.delegate = self;
    } else if ([segue.identifier isEqualToString:USER_ACTIVITY]) {
        TUserActivityViewController* notifications = segue.destinationViewController;
        notifications.showNotifications = YES;
    } else if ([segue.identifier isEqualToString:RECENT_POSTS]) {
        TUserActivityViewController* notifications = segue.destinationViewController;
        notifications.showNotifications = NO;
    }
}


#pragma mark - MKMapViewDelegate

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view {
    if ([view isKindOfClass:[MKPinAnnotationView class]]) {
        return;
    }

    DLog(@"Clicked Annotation");
    TStickerAnnotation* annotation = view.annotation;
    [self performSegueWithIdentifier:ACTIVITY sender:annotation.annotationObject];
    
    [mapView deselectAnnotation:view.annotation animated:NO];
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
//    if ([annotation isKindOfClass:[MKPointAnnotation class]]) {
//        return nil;
//    }
    
    static NSString *identifier = @"myAnnotation";
    CustomViewMV * annotationView = nil;//(CustomViewMV*)[mapView dequeueReusableAnnotationViewWithIdentifier:identifier];
    if (!annotationView)
    {
        annotationView = [[CustomViewMV alloc]initWithAnnotation:annotation reuseIdentifier:identifier];
        
        
        UIView* pinView = [annotationView viewWithTag:100];
        if (pinView) {
            [pinView removeFromSuperview];
        }
        
        CustomPin *annotationPin = (CustomPin *)[[[NSBundle mainBundle] loadNibNamed:@"CustomPin" owner:self options:nil] objectAtIndex:0];
        annotationPin.coOrdinate2D = ((TStickerAnnotation*)annotation).coordinate;
        annotationPin.tag = 100;
        
        annotationPin.stickerImage.image = [UIImage imageNamed:@"NewStickerPlaceHolder"];;
        PFObject* postObj = [(TStickerAnnotation*)annotation annotationObject];
        if ([postObj[POST_TYPE] isEqualToString:POST_TYPE_STICKER]) {
            PFObject* stickerObj = postObj[STICKER];
            annotationPin.stickerImage.file = stickerObj[STICKER_IMAGE];
            [annotationPin.stickerImage loadInBackground];
            
            CGFloat severity = [postObj[STICKER_SEVERITY] floatValue];
            annotationPin.bottomBar.backgroundColor = [UIColor colorWithRed:1.0 - severity green:severity blue:0 alpha:1.0];
            
            annotationPin.stickerColor = severity;
        } else if ([postObj[POST_TYPE] isEqualToString:POST_TYPE_IMAGE]) {
            annotationPin.stickerImage.file = postObj[POST_THUMBNAIL_IMAGE];
            [annotationPin.stickerImage loadInBackground];
            annotationPin.circleView.hidden = YES;
        } else if ([postObj[POST_TYPE] isEqualToString:POST_TYPE_ASK]) {
            annotationPin.bottomBar.backgroundColor = [UIColor darkGrayColor];
            annotationPin.stickerImage.image = [UIImage imageNamed:@"NewMapAsk"];
            annotationPin.circleView.hidden = YES;
        }
        
        NSNumber* commentsCount = postObj[POST_COMMENTS_COUNT];
        if (commentsCount) {
            annotationPin.commentsCount.text = [NSString stringWithFormat:@"%@",commentsCount];
        } else {
            annotationPin.commentsCount.text = @"0";
        }
        
        annotationView.frame = annotationPin.frame;
        [annotationView addSubview:annotationPin];
        
        annotationView.canShowCallout = NO;
    }
    
    return annotationView;
}

//- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated{
- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
    if (animated) {
        return;
    }
    
    CLLocationCoordinate2D mapCenter2D = mapView.centerCoordinate;
    CLLocation* mapCenter = [[CLLocation alloc] initWithLatitude:mapCenter2D.latitude longitude:mapCenter2D.longitude];
    
    CLLocation* oldCenter = [[CLLocation alloc] initWithLatitude:self.currentCenterLocation.latitude longitude:self.currentCenterLocation.longitude];
    DLog(@"Distance is: %f", [mapCenter distanceFromLocation:oldCenter]);
    if ([mapCenter distanceFromLocation:oldCenter] > 1000) {
        
        
        
        CLLocationCoordinate2D center = mapView.centerCoordinate;
        self.currentCenterLocation = center;
        [self updatePostedStickersOnMapWithCenter:center.latitude andLongitude:center.longitude];
    }
}

#pragma mark - Actions

-(void)showCategoriesView {
    [UIView animateWithDuration:0.5 animations:^{
        CGRect r = self.categoryContainer.frame;
        r.origin.y = self.view.frame.size.height - r.size.height;
        self.categoryContainer.frame = r;
    } completion:^(BOOL finished) {
        self.categoriesVC.hideButton.hidden = NO;
        self.isCategoriesExpanded = YES;
    }];
}

-(void)hideCategoriesView {
    [UIView animateWithDuration:0.5 animations:^{
        CGRect r = self.categoryContainer.frame;
        r.origin.y = self.view.frame.size.height;
        self.categoryContainer.frame = r;
    } completion:^(BOOL finished) {
        self.categoriesVC.hideButton.hidden = YES;
        self.isCategoriesExpanded = NO;
    }];
}

-(void)updatePostedStickersOnMapWithCenter:(CGFloat)latitude andLongitude:(CGFloat)longitude {
    if (latitude == 0.0 && longitude == 0.0) {
        return;
    }
    
    if ([Reachability isReachable]) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
        PFQuery* stickersQuery = [PFQuery queryWithClassName:POST];
        [stickersQuery includeKey:STICKER];
        [stickersQuery includeKey:POST_FROMUSER];
        [stickersQuery whereKey:POST_LOCATION nearGeoPoint:[PFGeoPoint geoPointWithLatitude:latitude longitude:longitude] withinMiles:STICKER_QUERY_RADIUS];
        stickersQuery.limit = 15;
        
        if ([self.stickerLocations count] == 0) {
            stickersQuery.cachePolicy = kPFCachePolicyCacheThenNetwork;
        }

        [stickersQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (!error && objects.count) {
                    [self updateMapWithStickers:objects];
                } else {
                    if (self.isAlertsPostsViewVisible == NO && [[NSUserDefaults standardUserDefaults] boolForKey:FIRST_TIME_ALERT]) {
//                        [self showNoPostsView];
                    }
                    DLog(@"Stickers received: %lu", (unsigned long)objects.count);
                    NSLog(@"No stickers Found");
                }
            });
        }];
    }
}

-(void)updatePostedStickers {
    [self updatePostedStickersOnMapWithCenter:self.currentMapLocation.latitude andLongitude:self.currentMapLocation.longitude];
}

-(void)updateMapWithStickers:(NSArray*)stickers {
    NSMutableArray* newPosts = [[NSMutableArray alloc] initWithCapacity:10];
    NSMutableArray* allNewPosts = [[NSMutableArray alloc] initWithCapacity:10];
    for (PFObject* obj in stickers) {
        TStickerAnnotation* newObj = [[TStickerAnnotation alloc] initWithObject:obj];
        [allNewPosts addObject:newObj];
        BOOL found = NO;
        for (TStickerAnnotation* currentObj in self.stickerLocations) {
            if ([newObj equalToPost:currentObj]) {
                found = YES;
                break;
            }
        }
        
        if (!found) {
            [newPosts addObject:newObj];
            newObj.animatesDrop = YES;
            [self.map addAnnotation:newObj];
        }
    }
    
    NSMutableArray *postsToRemove = [[NSMutableArray alloc] initWithCapacity:10];
    for (TStickerAnnotation* currentObj in self.stickerLocations) {
        BOOL found = NO;
        for (TStickerAnnotation* allNewPost in allNewPosts) {
            if ([currentObj equalToPost:allNewPost]) {
                found = YES;
                break;
            }
        }
        
        if (!found) {
            [postsToRemove addObject:currentObj];
            [self.map removeAnnotation:currentObj];
        }
    }

    [self.stickerLocations addObjectsFromArray:newPosts];
    [self.stickerLocations removeObjectsInArray:postsToRemove];
    DLog(@"Total stickers in memory are: %lu", (unsigned long)self.stickerLocations.count);
}

- (IBAction)menuClicked:(id)sender {
    if (self.isMenuExpanded) {
        //hide
        [UIView animateWithDuration:0.5 animations:^{
            CGRect r = self.menuContainer.frame;
            r.origin.y = -568;
            self.menuContainer.frame = r;
        }];
    } else {
        
        if (self.isAskViewVisible) {
            [self hideAskQuestionView:nil];
        }
        
        //show
        [UIView animateWithDuration:0.5 animations:^{
            CGRect r = self.menuContainer.frame;
            r.origin.y = 64;
            self.menuContainer.frame = r;
        }];
    }
    self.isMenuExpanded = !self.isMenuExpanded;
}

- (IBAction)searchClicked:(id)sender {
    [[[UIAlertView alloc] initWithTitle:@"" message:@"This feature is in development" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
}

- (IBAction)hideFirstTimeHelpView:(id)sender {
//    [UIView animateWithDuration:0.2 animations:^{
//        self.firstTimeHelpView.alpha = 0.0;
//    } completion:^(BOOL finished) {
//        [self.firstTimeHelpView removeFromSuperview];
//    }];

    [self.firstTimeHelpView setHidden:YES];
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:FIRST_TIME_HELP];
}


-(IBAction)takeToUserLocation:(id)sender {
    [self updateUserLocation:nil];
}


-(void)userClickedMenu:(NSInteger)rowNumber {
    [self menuClicked:nil];
    switch (rowNumber) {
        case MenuItemMyProfile:
            [TFlurryManager viewingProfile];
            if ([[PFUser currentUser] isAuthenticated]) {
                [self performSegueWithIdentifier:PROFILE sender:nil];
            } else {
                [[[UIAlertView alloc] initWithTitle:@"Warning" message:@"You need to login first" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
            }

            break;
        case MenuInviteFriends:{
//            UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:[NSArray arrayWithObjects: @"I recommend you to use Tromke which stays us connected with the events happening around us. Get the app from the URL: http://tinyurl.com/tinyapp", [UIImage imageNamed:@"Logo"], nil] applicationActivities:nil];
//            [activityVC setValue:@"Join Tromke!!!" forKey:@"subject"];
//            activityVC.excludedActivityTypes = @[ UIActivityTypeMessage ,UIActivityTypeAssignToContact,UIActivityTypeSaveToCameraRoll];
//            [self presentViewController:activityVC animated:YES completion:nil];
            [TFlurryManager inviteFriends];
            if ([[PFUser currentUser] isAuthenticated]) {
                [self performSegueWithIdentifier:INVITE_FRIENDS sender:nil];
            } else {
                [[[UIAlertView alloc] initWithTitle:@"Warning" message:@"You need to login first" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
            }
        }
            break;
        case MenuItemHelp:
            [self.firstTimeHelpView setHidden:NO];
            break;
        case MenuItemLogout:
        {
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Confirm" message:@"Please confirm if you want to logout of the application" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
            alert.tag = 1000;
            [alert show];
        }
            break;
        default:
            break;
    }
}

-(void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == 1000) {
        if (buttonIndex == 1) {
            [TFlurryManager userLoggedOut];
            [TFlurryManager stoppedMap];
            [PFQuery clearAllCachedResults];            
            [PFUser logOut];
            NSArray* allViewControllers = [self.navigationController viewControllers];
            for (UIViewController* vc in allViewControllers) {
                if ([vc isKindOfClass:[TCustomLoginViewController class]]) {
                    [self.navigationController popToViewController:vc animated:YES];
                    break;
                }
            }
//            [self.navigationController popViewControllerAnimated:YES];
//            [self.navigationController popToRootViewControllerAnimated:YES];
        }
    } else if (alertView.tag == 2000) {
        [self updatePostedStickers];
    }
}

- (IBAction)postStickerOnly:(id)sender {

    if (![Reachability isReachable]) {
        return;
    }

    [UIView animateWithDuration:0.2 animations:^{
        CGRect r = self.categoryContainer.frame;
        r.origin.y = self.view.frame.size.height - r.size.height;
        self.categoryContainer.frame = r;
    } completion:^(BOOL finished) {
        self.categoriesVC.hideButton.hidden = NO;
        self.isCategoriesExpanded = YES;
    }];
}

- (IBAction)askAQuestion:(id)sender {
    if (![Reachability isReachable]) {
        return;
    }

    self.askText.text = @"";
    self.askAnythingLabel.hidden = NO;
    self.onlyCameraButton.enabled = NO;
    self.textCount.text = @"0";
    [self.askText becomeFirstResponder];
    
    [UIView animateWithDuration:0.2 animations:^{
        CGRect r = self.askQuestionView.frame;
        self.askQuestionView.frame = CGRectMake(0, 64, r.size.width, r.size.height);
    }];
    
    self.isAskViewVisible = YES;
}

- (IBAction)hideAskQuestionView:(id)sender {
    
    [TFlurryManager cancelledQuestion];
    
    [UIView animateWithDuration:0.2 animations:^{
        [self.askText resignFirstResponder];
        CGRect r = self.askQuestionView.frame;
        self.askQuestionView.frame = CGRectMake(0, -568, r.size.width, r.size.height);
    }];
    
    self.isAskViewVisible = NO;
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
    
    [self startShowingAnimation];
    CLLocationCoordinate2D usrLocation = [[TLocationUtility sharedInstance] getUserCoordinate];
    
    PFObject *stickerPost = [PFObject objectWithClassName:POST];
    stickerPost[POST_DATA] = self.askText.text;
    stickerPost[POST_LOCATION] = [PFGeoPoint geoPointWithLatitude:usrLocation.latitude longitude:usrLocation.longitude];
    stickerPost[POST_FROMUSER] = [PFUser currentUser];
    stickerPost[POST_USERLOCATION] = [[NSUserDefaults standardUserDefaults] valueForKey:USER_LOCATION];
    stickerPost[POST_TYPE] = POST_TYPE_ASK;
    
    NSDictionary* dict = @{@"QuestionWithPhoto" : @NO, @"Question" : self.askText.text};
    [TFlurryManager tromQuestion:dict];

    
    [stickerPost saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            dispatch_async(dispatch_get_main_queue(), ^{
                UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Successful" message:@"Question is posted successfully. We will inform you if anyone on Tromke will respond to your question, thanks" delegate:self cancelButtonTitle:@"OK, Got it" otherButtonTitles: nil];
                alert.tag = 2000;
                [alert show];
                [self stopShowingAnimation];
            });
        } else {
            NSLog(@"Failed with Sticker Error: %@", error.localizedDescription);
        }
    }];

    [self hideAskQuestionView:nil];
}


#pragma mark - Ask question delegate

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
        self.askAnythingLabel.hidden = NO;
    } else {
        self.onlyCameraButton.enabled = YES;
        self.askAnythingLabel.hidden = YES;
    }
    
    if (charCount <= POSTDATA_LENGTH) {
        self.textCount.text = [NSString stringWithFormat:@"%ld", charCount];
    }
    
    return  charCount <= POSTDATA_LENGTH;
}


-(void)hideMenu {
    
}

-(void)startedPosting {
    self.progressBar.hidden = NO;
}

-(void)completedPosting:(BOOL)status andMessage:(NSString*)msg {
    self.progressBar.hidden = YES;
    NSString* statusTitle;
    if (status) {
        statusTitle = @"Successful";
        [self updatePostedStickers];
    } else {
        statusTitle = @"Warning";
    }

    [[[UIAlertView alloc] initWithTitle:statusTitle message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
}

-(void)showActivityLocation:(NSNotification*)tempLocation {
    PFGeoPoint* location = tempLocation.object;
    self.allowMapUpdate = NO;

    MKCoordinateRegion region;
    region.center = CLLocationCoordinate2DMake(location.latitude, location.longitude);
    MKCoordinateSpan span;
    span.latitudeDelta = 0.0144927536 * STICKER_QUERY_RADIUS; //1 mile
    span.longitudeDelta = 0.0144927536 * STICKER_QUERY_RADIUS; //1 mile
    region.span = span;
    [self.map setRegion:region animated:NO];

    [self updatePostedStickersOnMapWithCenter:location.latitude andLongitude:location.longitude];
}

- (IBAction)closeAlertPostsView {
    self.alertPostsView.hidden = YES;
    self.isAlertsPostsViewVisible = NO;
}


-(void)showNoPostsView {
    self.alertPostsView = [[UIView alloc] initWithFrame:self.view.frame];
    self.alertPostsView.backgroundColor = [UIColor clearColor];
    
    UIImageView* imgView = [[UIImageView alloc] initWithFrame:CGRectMake(5, (self.view.frame.size.height - 150) / 2.0, self.view.frame.size.width - 10.0, 150)];
    imgView.image = [UIImage imageNamed:@"BlackTransparent"];
    imgView.userInteractionEnabled = YES;
    [self.alertPostsView addSubview:imgView];

    UILabel* lbl = [[UILabel alloc] initWithFrame:CGRectMake(20, 25, imgView.frame.size.width - 40, 50)];
    lbl.text = @"There are no posts in this region. Start posting now!!!";
    lbl.numberOfLines = 2;
    lbl.textColor = [UIColor whiteColor];
    lbl.textAlignment = NSTextAlignmentCenter;
    [imgView addSubview:lbl];
    
    UIButton* closeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [closeBtn setTitle:@"Close" forState:UIControlStateNormal];
    [closeBtn addTarget:self action:@selector(closeAlertPostsView) forControlEvents:UIControlEventTouchUpInside];
    [closeBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    closeBtn.frame = CGRectMake(70, lbl.frame.origin.y + 50, 180, 50);
    closeBtn.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    [imgView addSubview:closeBtn];
    
    [self.view addSubview:self.alertPostsView];
    [self.view bringSubviewToFront:self.alertPostsView];
    
    self.isAlertsPostsViewVisible = YES;
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:FIRST_TIME_ALERT];
}

@end

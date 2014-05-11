//
//  TViewController.m
//  Tromkee
//
//  Created by Satyanarayana SVV on 1/3/14.
//  Copyright (c) 2014 Tromkee. All rights reserved.
//

#import "TViewController.h"
#import "TLogInViewController.h"
#import "TLocationUtility.h"
#import <MapKit/MapKit.h>
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
#import <Crashlytics/Crashlytics.h>
#import "TCameraViewController.h"

#define USER_LOCATION_TEXT @"User Location"

@interface TViewController () <PFLogInViewControllerDelegate, MKMapViewDelegate, TCategoriesVCDelegate, TMenuDelegate, TStickerAnnotationDelegate>

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

@property (nonatomic) BOOL isFirstTime;

- (IBAction)menuClicked:(id)sender;
- (IBAction)searchClicked:(id)sender;


@end

@implementation TViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.isFirstTime = YES;
    self.firstTimeLogin = YES;
    self.isMenuExpanded = NO;
    self.stickerLocations = [[NSMutableArray alloc] initWithCapacity:10];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateUserLocation:) name:TROMKE_USER_LOCATION_UPDATED object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatePostedStickers) name:TROMKEE_UPDATE_STICKERS object:nil];
    
    self.askBackgroundView.backgroundColor = [TUtility colorFromHexString:ACTIVITY_PICTURE_COLOR];
    //[UIColor colorWithPatternImage:[UIImage imageNamed:@"RedBox"]];
}

-(void)viewWillAppear:(BOOL)animated {
    if (![PFUser currentUser]) {
        [(TAppDelegate*)[[UIApplication sharedApplication] delegate] presentLoginViewControllerAnimated:NO];
        return;
    }
    
    [super viewWillAppear:animated];
}

-(void)viewDidAppear:(BOOL)animated {
    if (self.isCategoriesExpanded) {
        [self showCategoriesView];
    }
    
    if (!self.isFirstTime) {
        [self updatePostedStickersOnMapWithCenter:self.currentCenterLocation.latitude andLongitude:self.currentCenterLocation.longitude];
    }
    self.isFirstTime = NO;
    [super viewDidAppear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Login Delegates

- (void)logInViewController:(PFLogInViewController *)logInController didLogInUser:(PFUser *)user {
    [logInController dismissViewControllerAnimated:YES completion:nil];
}

- (void)logInViewController:(PFLogInViewController *)logInController didFailToLogInWithError:(NSError *)error {
    [logInController dismissViewControllerAnimated:YES completion:nil];
}


-(void)updateUserLocation:(NSNotification*)notification {
    [self.map removeAnnotations:self.map.annotations];
    // Creates a marker in the center of the map.
    self.currentCenterLocation = self.currentMapLocation = [[TLocationUtility sharedInstance] getUserCoordinate];
    
    MKPointAnnotation* point = [[MKPointAnnotation alloc] init];
    point.coordinate = self.currentMapLocation;
    point.title = USER_LOCATION_TEXT;
    [self.map addAnnotation:point];
    
    MKCoordinateRegion region;
    region.center = self.currentMapLocation;
    MKCoordinateSpan span;
    span.latitudeDelta = 0.0144927536 * 20;// * STICKER_QUERY_RADIUS; //1 mile
    span.longitudeDelta = 0.0144927536 * 20;//  * STICKER_QUERY_RADIUS; //1 mile
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
        activityVC.postedObject = sender;
    } else if ([segue.identifier isEqualToString:PROFILE]) {
        TProfileViewController* profileVC = segue.destinationViewController;
        profileVC.userProfile = [PFUser currentUser];
    } else if ([segue.identifier isEqualToString:ASKCAMERA]) {
        TCameraViewController* cameraVC = segue.destinationViewController;
        [self.askText resignFirstResponder];
        cameraVC.activityName = CameraForAsk;
        cameraVC.cameraMessage = self.askText.text;
    } else if ([segue.identifier isEqualToString:CAMERA]) {
        TCameraViewController* cameraVC = segue.destinationViewController;
        cameraVC.activityName = CameraForImage;
    }
}


#pragma mark - MKMapViewDelegate

-(void)userTappedSticker:(id<MKAnnotation>)annotation {
    TStickerAnnotation* ann = (TStickerAnnotation*)annotation;
    [self performSegueWithIdentifier:ACTIVITY sender:ann.annotationObject];
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view {
    if ([view isKindOfClass:[MKPinAnnotationView class]]) {
        return;
    }

    DLog(@"Clicked Annotation");
    TStickerAnnotation* annotation = view.annotation;
    [self performSegueWithIdentifier:ACTIVITY sender:annotation.annotationObject];
    
//    if ([view isKindOfClass:[TStickerAnnotationView class]]) {
//        TStickerAnnotation* annotation = [(TStickerAnnotationView*)view annotation];
//        [self performSegueWithIdentifier:ACTIVITY sender:annotation.annotationObject];
//    }

}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    if ([annotation isKindOfClass:[MKPointAnnotation class]]) {
        return nil;
    }
    
//    static NSString *annotationIdentifier = @"StickerPin";
//    
//    MKAnnotationView* annotationView = (MKAnnotationView*)[mapView dequeueReusableAnnotationViewWithIdentifier:annotationIdentifier];
//    
//    if (!annotationView) {
//        annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:annotationIdentifier];
//        annotationView.canShowCallout = NO;
//        annotationView.image = [UIImage imageNamed:@"Sticker"];
//    }
//    
//    return annotationView;

    
    static NSString *identifier = @"myAnnotation";
    CustomViewMV * annotationView = (CustomViewMV*)[mapView dequeueReusableAnnotationViewWithIdentifier:identifier];
    if (!annotationView)
    {
        annotationView = [[CustomViewMV alloc]initWithAnnotation:annotation reuseIdentifier:identifier];
        CustomPin *annotationPin = (CustomPin *)[[[NSBundle mainBundle] loadNibNamed:@"CustomPin" owner:self options:nil] objectAtIndex:0];
        annotationPin.coOrdinate2D = ((TStickerAnnotation*)annotation).coordinate;
        annotationPin.tag = 100;
        
        
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
        
//    [stickerImage getDataInBackgroundWithBlock:^(NSData *imageData, NSError *error) {
//        dispatch_async(dispatch_get_main_queue(), ^{
//            if (!error) {
//                annotationView.image = [UIImage imageWithData:imageData];
//                annotationView.stickerColor = [postObj[STICKER_SEVERITY] floatValue];
//            }
//        });
//    }];
        
        annotationView.frame = annotationPin.frame;
        [annotationView addSubview:annotationPin];
        
        annotationView.canShowCallout = NO;
    } else {
        annotationView.annotation = annotation;
    }
    return annotationView;

    
    
//    if ([annotation isKindOfClass:[MKPointAnnotation class]]) {
//        return nil;
//    }
//    
//    static NSString *annotationIdentifier = @"StickerPin";
//    
//    TStickerAnnotationView *annotationView = (TStickerAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:annotationIdentifier];
//    
//    if (!annotationView) {
//        annotationView = [[TStickerAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:annotationIdentifier];
//        annotationView.canShowCallout = NO;
//        annotationView.delegate = self;
//    }
//    
//    PFObject* postObj = [(TStickerAnnotation*)annotation annotationObject];
//    PFObject* stickerObj = postObj[STICKER];
//    PFFile* stickerImage = stickerObj[STICKER_IMAGE];
//    [stickerImage getDataInBackgroundWithBlock:^(NSData *imageData, NSError *error) {
//        dispatch_async(dispatch_get_main_queue(), ^{
//            if (!error) {
//                annotationView.image = [UIImage imageWithData:imageData];
//                annotationView.stickerColor = [postObj[STICKER_SEVERITY] floatValue];
//            }
//        });
//    }];
//    
//    return annotationView;
}

//- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated{
- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
    if (!animated) {
        return;
    }
    CLLocationCoordinate2D mapCenter2D = mapView.centerCoordinate;
    CLLocation* mapCenter = [[CLLocation alloc] initWithLatitude:mapCenter2D.latitude longitude:mapCenter2D.longitude];
    
    CLLocation* oldCenter = [[CLLocation alloc] initWithLatitude:self.currentCenterLocation.latitude longitude:self.currentCenterLocation.longitude];
    DLog(@"Distance is: %f", [mapCenter distanceFromLocation:oldCenter]);
    if ([mapCenter distanceFromLocation:oldCenter] > 2000) {
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
    if ([Reachability isReachable]) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
        PFQuery* stickersQuery = [PFQuery queryWithClassName:POST];
        [stickersQuery includeKey:STICKER];
//        [stickersQuery includeKey:@"images"];
        [stickersQuery includeKey:POST_FROMUSER];
        [stickersQuery whereKey:POST_LOCATION nearGeoPoint:[PFGeoPoint geoPointWithLatitude:latitude longitude:longitude] withinMiles:STICKER_QUERY_RADIUS];
        stickersQuery.limit = 15;
        
        if ([self.stickerLocations count] == 0) {
            stickersQuery.cachePolicy = kPFCachePolicyCacheThenNetwork;
        }
//        __weak TViewController* weakSelf = self;
        [stickersQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            DLog(@"Stickers received: %lu", (unsigned long)objects.count);
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (!error) {
//                    [self.map removeAnnotations:self.map.annotations];                    
//                    self.stickerLocations = [objects mutableCopy];
                    [self updateMapWithStickers:objects];
                } else {
                    NSLog(@"No stickers Found");
//                    [[[UIAlertView alloc] initWithTitle:@"Warning" message:@"Error in retrieving stickers" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
                }
            });
        }];
    }
}

-(void)updatePostedStickers {
    [self updatePostedStickersOnMapWithCenter:self.currentMapLocation.latitude andLongitude:self.currentMapLocation.longitude];
}

-(void)updateMapWithStickers:(NSArray*)stickers {
    for (PFObject* sticker in stickers) {
//        if ([sticker[POST_TYPE] isEqualToString:POST_TYPE_STICKER]) {
            TStickerAnnotation *annotation = [[TStickerAnnotation alloc] initWithObject:sticker];
            [self.map addAnnotation:annotation];
//        }
    }
    
    /*
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
        }
    }
    
    NSMutableArray *postsToRemove = [[NSMutableArray alloc] initWithCapacity:10];
    for (TStickerAnnotation* currentObj in self.stickerLocations) {
        BOOL found = NO;
        for (TStickerAnnotation* allNewPost in allNewPosts) {
            if ([currentObj equalToPost:allNewPost]) {
                found = YES;
            }
        }
        
        if (!found) {
            [postsToRemove addObject:currentObj];
        }
    }
    
    [self.map removeAnnotations:postsToRemove];
    [self.map addAnnotations:newPosts];
    [self.stickerLocations addObjectsFromArray:newPosts];
    [self.stickerLocations removeObjectsInArray:postsToRemove];
    */
}

- (IBAction)menuClicked:(id)sender {
    if (self.isMenuExpanded) {
        //hide
        [UIView animateWithDuration:0.5 animations:^{
            CGRect r = self.menuContainer.frame;
            r.origin.y = -568;
            self.menuContainer.frame = r;
            
//            CGRect vr = self.view.frame;
//            vr.origin.x = 0;
//            self.view.frame = vr;
        }];
    } else {
        //show
        [UIView animateWithDuration:0.5 animations:^{
            CGRect r = self.menuContainer.frame;
            r.origin.y = 64;
            self.menuContainer.frame = r;
            
//            CGRect vr = self.view.frame;
//            vr.origin.x = 280;
//            self.view.frame = vr;
        }];
    }
    self.isMenuExpanded = !self.isMenuExpanded;
}

- (IBAction)searchClicked:(id)sender {
}


-(IBAction)takeToUserLocation:(id)sender {
    [self updateUserLocation:nil];
}


-(void)userClickedMenu:(NSInteger)rowNumber {
    [self menuClicked:nil];
    switch (rowNumber) {
        case MenuItemNearMe:
            [self updateUserLocation:nil];
            break;
        case MenuItemMyProfile:
            if ([[PFUser currentUser] isAuthenticated]) {
                [self performSegueWithIdentifier:PROFILE sender:nil];
            } else {
                [[[UIAlertView alloc] initWithTitle:@"Warning" message:@"You need to login first" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
            }

            break;
        case MenuItemMyActivity:
            break;
        case MenuItemSettings:
            break;
        case MenuItemLogout:
            [PFUser logOut];
            break;
        default:
            break;
    }
}


- (IBAction)postStickerOnly:(id)sender {

    if (![Reachability isReachable]) {
        return;
    }

    [UIView animateWithDuration:0.5 animations:^{
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
    
    self.askText.text = @"Type your question here";
    self.onlyCameraButton.enabled = NO;
    self.textCount.text = @"0";
    
    [UIView animateWithDuration:0.5 animations:^{
        CGRect r = self.askQuestionView.frame;
        self.askQuestionView.frame = CGRectMake(0, 0, r.size.width, r.size.height);
    }];
}

- (IBAction)hideAskQuestionView:(id)sender {
    [UIView animateWithDuration:0.5 animations:^{
        [self.askText resignFirstResponder];
        CGRect r = self.askQuestionView.frame;
        self.askQuestionView.frame = CGRectMake(0, -568, r.size.width, r.size.height);
    }];
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
    
    CLLocationCoordinate2D usrLocation = [[TLocationUtility sharedInstance] getUserCoordinate];
    
    PFObject *stickerPost = [PFObject objectWithClassName:POST];
    stickerPost[POST_DATA] = self.askText.text;
    stickerPost[POST_LOCATION] = [PFGeoPoint geoPointWithLatitude:usrLocation.latitude longitude:usrLocation.longitude];
    stickerPost[POST_FROMUSER] = [PFUser currentUser];
    stickerPost[POST_USERLOCATION] = [[NSUserDefaults standardUserDefaults] valueForKey:USER_LOCATION];
    stickerPost[POST_TYPE] = POST_TYPE_ASK;
    
    [stickerPost saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[[UIAlertView alloc] initWithTitle:@"Successful" message:@"Question is posted successfully. We will inform you if anyone on Tromke will respond to your question, thanks" delegate:self cancelButtonTitle:@"OK, Got it" otherButtonTitles: nil] show];
            });
        } else {
            NSLog(@"Failed with Sticker Error: %@", error.localizedDescription);
        }
    }];

    [self hideAskQuestionView:nil];
}

-(void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    [self updatePostedStickers];
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


-(void)hideMenu {
    
}

@end

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

//@property (nonatomic, strong) NSArray* stickerLocations;

@property (weak, nonatomic) IBOutlet UIView *askQuestionView;
@property (weak, nonatomic) IBOutlet UILabel *textCount;
@property (weak, nonatomic) IBOutlet UITextView *askText;
@property (weak, nonatomic) IBOutlet UIButton *sendButton;
@property (weak, nonatomic) IBOutlet UIButton *onlyCameraButton;


- (IBAction)menuClicked:(id)sender;
- (IBAction)searchClicked:(id)sender;


@end

@implementation TViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.firstTimeLogin = YES;
    self.isMenuExpanded = NO;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateUserLocation:) name:TROMKE_USER_LOCATION_UPDATED object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatePostedStickers) name:TROMKEE_UPDATE_STICKERS object:nil];
    
    self.askQuestionView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"RedBox"]];
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
    
    [self updatePostedStickersOnMapWithCenter:self.currentCenterLocation.latitude andLongitude:self.currentCenterLocation.longitude];
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
    span.latitudeDelta = 0.0144927536 * STICKER_QUERY_RADIUS; //1 mile
    span.longitudeDelta = 0.0144927536  * STICKER_QUERY_RADIUS; //1 mile
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
        activityVC.stickerObject = sender;
    } else if ([segue.identifier isEqualToString:PROFILE]) {
        TProfileViewController* profileVC = segue.destinationViewController;
        profileVC.userProfile = [PFUser currentUser];
    } else if ([segue.identifier isEqualToString:ASKCAMERA]) {
        TCameraViewController* cameraVC = segue.destinationViewController;
        [self.askText resignFirstResponder];
        cameraVC.isAsking = YES;
        cameraVC.askMessage = self.askText.text;
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
            PFObject* stickerObj = postObj[@"sticker"];
            annotationPin.stickerImage.file = stickerObj[STICKER_IMAGE];
            [annotationPin.stickerImage loadInBackground];
            annotationPin.stickerColor = [postObj[STICKER_SEVERITY] floatValue];
        } else if ([postObj[POST_TYPE] isEqualToString:POST_TYPE_IMAGE]) {
            annotationPin.stickerImage.file = postObj[POST_THUMBNAIL_IMAGE];
            [annotationPin.stickerImage loadInBackground];
        } else if ([postObj[POST_TYPE] isEqualToString:POST_TYPE_ASK]) {
            annotationPin.stickerImage.image = [UIImage imageNamed:@"NewMapAsk"];
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
//    PFObject* stickerObj = postObj[@"sticker"];
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

- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated{

    CLLocationCoordinate2D mapCenter2D = mapView.centerCoordinate;
    CLLocation* mapCenter = [[CLLocation alloc] initWithLatitude:mapCenter2D.latitude longitude:mapCenter2D.longitude];
    
    CLLocation* oldCenter = [[CLLocation alloc] initWithLatitude:self.currentCenterLocation.latitude longitude:self.currentCenterLocation.longitude];
    NSLog(@"Distance is: %f", [mapCenter distanceFromLocation:oldCenter]);
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
    if ([Reachability isReachable]) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
        PFQuery* stickersQuery = [PFQuery queryWithClassName:POST];
        [stickersQuery includeKey:@"sticker"];
//        [stickersQuery includeKey:@"images"];
        [stickersQuery includeKey:POST_FROMUSER];
        [stickersQuery whereKey:POST_LOCATION nearGeoPoint:[PFGeoPoint geoPointWithLatitude:latitude longitude:longitude] withinMiles:STICKER_QUERY_RADIUS];
        stickersQuery.limit = 15;
        
//        __weak TViewController* weakSelf = self;
        [stickersQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            DLog(@"Stickers received: %lu", (unsigned long)objects.count);
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (!error) {
//                    weakSelf.stickerLocations = objects;
                    [self updateMapWithStickers:objects];
                } else {
                    [[[UIAlertView alloc] initWithTitle:@"Warning" message:@"Error in retrieving stickers" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
                }
            });
        }];
    }
}

-(void)updatePostedStickers {
    [self updatePostedStickersOnMapWithCenter:self.currentMapLocation.latitude andLongitude:self.currentMapLocation.longitude];
}

-(void)updateMapWithStickers:(NSArray*)stickerLocations {
    for (PFObject* sticker in stickerLocations) {
        TStickerAnnotation *annotation = [[TStickerAnnotation alloc] initWithObject:sticker];
        [self.map addAnnotation:annotation];
    }
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
//        case MenuItemNearMe:
//            [self updateUserLocation:nil];
//            break;
//        case MenuItemChooseMyRoute:
//            break;
//        case MenuItemChats:
//            break;
//        case MenuItemProfile:
//            if ([[PFUser currentUser] isAuthenticated]) {
//                [self performSegueWithIdentifier:PROFILE sender:nil];
//            } else {
//                [[[UIAlertView alloc] initWithTitle:@"Warning" message:@"You need to login first" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
//            }
//
//            break;
//        case MenuItemTopTromers:
//            break;
//        case MenuItemSettings:
//            break;
//        case MenuItemLogout:
//            [PFUser logOut];
//            break;
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
    self.sendButton.enabled = NO;
    self.onlyCameraButton.enabled = NO;
    self.textCount.text = @"0";
    
    [UIView animateWithDuration:0.5 animations:^{
        CGRect r = self.askQuestionView.frame;
        self.askQuestionView.frame = CGRectMake(0, 64, r.size.width, r.size.height);
    }];
}

- (IBAction)hideAskQuestionView:(id)sender {
    [UIView animateWithDuration:0.5 animations:^{
        CGRect r = self.askQuestionView.frame;
        self.askQuestionView.frame = CGRectMake(0, -130, r.size.width, r.size.height);
        [self.askText resignFirstResponder];
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
                [[[UIAlertView alloc] initWithTitle:@"Successful" message:@"Question is posted successfully. We will inform you if anyone on Tromke will respond to your question, thanks" delegate:nil cancelButtonTitle:@"OK, Got it" otherButtonTitles: nil] show];
            });
        } else {
            NSLog(@"Failed with Sticker Error: %@", error.localizedDescription);
        }
    }];

    [self hideAskQuestionView:nil];
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
        self.sendButton.enabled = NO;
    } else {
        self.onlyCameraButton.enabled = YES;
        self.sendButton.enabled = YES;
    }
    
    if (charCount <= POSTDATA_LENGTH) {
        self.textCount.text = [NSString stringWithFormat:@"%ld", charCount];
    }
    
    return  charCount <= POSTDATA_LENGTH;
}


-(void)hideMenu {
    
}

@end

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

@interface TViewController () <PFLogInViewControllerDelegate, MKMapViewDelegate, TCategoriesVCDelegate, TMenuDelegate>

@property (weak, nonatomic) IBOutlet MKMapView *map;
@property (weak, nonatomic) IBOutlet UIView *categoryContainer;
@property (weak, nonatomic) IBOutlet UIView *menuContainer;

@property (strong, nonatomic) TCategoriesViewController* categoriesVC;

@property (nonatomic) BOOL firstTimeLogin;
@property (nonatomic) BOOL isCategoriesExpanded;
@property (nonatomic) BOOL isMenuExpanded;

@property (nonatomic) CLLocationCoordinate2D currentMapLocation;

@property (nonatomic, strong) NSArray* stickerLocations;

- (IBAction)eyeClicked:(id)sender;
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
    self.currentMapLocation = [[TLocationUtility sharedInstance] getUserCoordinate];
    
    MKPointAnnotation* point = [[MKPointAnnotation alloc] init];
    point.coordinate = self.currentMapLocation;
    point.title = @"User Location";
    [self.map addAnnotation:point];
    
    MKCoordinateRegion region;
    region.center = self.currentMapLocation;
    MKCoordinateSpan span;
    span.latitudeDelta = 0.0144927536; //1 mile
    span.longitudeDelta = 0.0144927536; //1 mile
    region.span = span;
    [self.map setRegion:region animated:YES];
    
    [self updatePostedStickers];
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
    }
}


#pragma mark - MKMapViewDelegate

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view {
    NSLog(@"Clicked Annotation");
    if ([view isKindOfClass:[TStickerAnnotationView class]]) {
        TStickerAnnotation* annotation = [(TStickerAnnotationView*)view annotation];
        [self performSegueWithIdentifier:@"Activity" sender:annotation.annotationObject];
    }
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    if ([annotation isKindOfClass:[MKPointAnnotation class]]) {
        return nil;
    }
    
    static NSString *annotationIdentifier = @"StickerPin";
    
    TStickerAnnotationView *annotationView = (TStickerAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:annotationIdentifier];
    
    if (!annotationView) {
        annotationView = [[TStickerAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:annotationIdentifier];
        annotationView.canShowCallout = NO;
    }
    
    PFObject* postObj = [(TStickerAnnotation*)annotation annotationObject];
    PFObject* stickerObj = postObj[@"sticker"];
    PFFile* stickerImage = stickerObj[@"image"];
    [stickerImage getDataInBackgroundWithBlock:^(NSData *imageData, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!error) {
                annotationView.image = [UIImage imageWithData:imageData];
                annotationView.stickerColor = [postObj[@"severity"] floatValue];
            }
        });
    }];
    
    return annotationView;
}

- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated{
    if(!animated){
        //Instantaneous change, which means you probably did something code-wise, so you should have handled anything there, but you can do it here as well.
        
    } else {
        //User is most likely scrolling, so the best way to do things here is check if the new region is significantly (by whatever standard) away from the starting region
//        CLLocationDistance *distance = [mapView.centerCoordinate distanceFromLocation:originalCoordinate];
//        if( distance > 200 ) {
//            //The map region was shifted by 200 meters
//            //Remove annotations outsides the view, or whatever
//            //Most likely, instead of checking for a distance change, you might want to check for a change relative to the view size
//        }
        
    }
    
}

#pragma mark - Actions

-(void)showCategoriesView {
    [UIView animateWithDuration:1.0 animations:^{
        CGRect r = self.categoryContainer.frame;
        r.origin.y = self.view.frame.size.height - r.size.height;
        self.categoryContainer.frame = r;
    } completion:^(BOOL finished) {
        self.categoriesVC.hideButton.hidden = NO;
        self.isCategoriesExpanded = YES;
    }];
}

-(void)hideCategoriesView {
    [UIView animateWithDuration:1.0 animations:^{
        CGRect r = self.categoryContainer.frame;
        r.origin.y = self.view.frame.size.height - 92;
        self.categoryContainer.frame = r;
    } completion:^(BOOL finished) {
        self.categoriesVC.hideButton.hidden = YES;
        self.isCategoriesExpanded = NO;
    }];
}


-(void)updatePostedStickers {
//    CLLocationCoordinate2D userCoordinate = [[TLocationUtility sharedInstance] getUserCoordinate];
    PFQuery* stickersQuery = [PFQuery queryWithClassName:@"Post"];
    [stickersQuery includeKey:@"sticker"];
    [stickersQuery includeKey:@"images"];
    [stickersQuery includeKey:@"fromUser"];
    [stickersQuery whereKey:@"location" nearGeoPoint:[PFGeoPoint geoPointWithLatitude:self.currentMapLocation.latitude longitude:self.currentMapLocation.longitude] withinMiles:STICKER_QUERY_RADIUS];
    stickersQuery.limit = 15;
    
    __weak TViewController* weakSelf = self;
    [stickersQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            weakSelf.stickerLocations = objects;
            [self updateMapWithStickers];
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[[UIAlertView alloc] initWithTitle:@"Warning" message:@"Error in retrieving stickers" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
            });
        }
        
    }];
}

-(void)updateMapWithStickers {
    for (PFObject* sticker in self.stickerLocations) {
        TStickerAnnotation *annotation = [[TStickerAnnotation alloc] initWithObject:sticker];
        [self.map addAnnotation:annotation];
    }
}

- (IBAction)eyeClicked:(id)sender {
    if (self.isMenuExpanded) {
        //hide
        [UIView animateWithDuration:0.5 animations:^{
            CGRect r = self.menuContainer.frame;
            r.origin.y = -568;
            self.menuContainer.frame = r;
        }];
    } else {
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
}


-(void)userClickedMenu:(NSInteger)rowNumber {
    [self eyeClicked:nil];
    switch (rowNumber) {
        case MenuItemNearMe:
            break;
        case MenuItemChooseMyRoute:
            break;
        case MenuItemChats:
            break;
        case MenuItemProfile:
            if ([[PFUser currentUser] isAuthenticated]) {
                [self performSegueWithIdentifier:PROFILE sender:nil];
            } else {
                [[[UIAlertView alloc] initWithTitle:@"Warning" message:@"You need to login first" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
            }

            break;
        case MenuItemTopTromers:
            break;
        case MenuItemSettings:
            break;
        case MenuItemLogout:
            [PFUser logOut];
            break;
    }
}

@end

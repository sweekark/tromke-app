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

@interface TViewController () <PFLogInViewControllerDelegate, MKMapViewDelegate, TCategoriesVCDelegate>

@property (weak, nonatomic) IBOutlet MKMapView *map;
@property (weak, nonatomic) IBOutlet UIView *container;
@property (nonatomic) BOOL firstTimeLogin;
@property (strong, nonatomic) TCategoriesViewController* categoriesVC;
@property (nonatomic) BOOL isCategoriesExpanded;
@end

@implementation TViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.firstTimeLogin = YES;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateUserLocation:) name:TROMKE_USER_LOCATION_UPDATED object:nil];
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
    CLLocationCoordinate2D userCoordinate = [[TLocationUtility sharedInstance] getUserCoordinate];
    
    MKPointAnnotation* point = [[MKPointAnnotation alloc] init];
    point.coordinate = userCoordinate;
    point.title = @"User Location";
    [self.map addAnnotation:point];
    
    MKCoordinateRegion region;
    region.center = userCoordinate;
    MKCoordinateSpan span;
    span.latitudeDelta = 0.0144927536; //1 mile
    span.longitudeDelta = 0.0144927536; //1 mile
    region.span = span;
    [self.map setRegion:region animated:YES];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"Categories"]) {
        self.categoriesVC = segue.destinationViewController;
        self.categoriesVC.delegate = self;
    }
}

-(void)showCategoriesView {
    [UIView animateWithDuration:1.0 animations:^{
        CGRect r = self.container.frame;
        r.origin.y = self.view.frame.size.height - r.size.height;
        self.container.frame = r;
    } completion:^(BOOL finished) {
        self.categoriesVC.hideButton.hidden = NO;
        self.isCategoriesExpanded = YES;
    }];
}

-(void)hideCategoriesView {
    [UIView animateWithDuration:1.0 animations:^{
        CGRect r = self.container.frame;
        r.origin.y = self.view.frame.size.height - 92;
        self.container.frame = r;
    } completion:^(BOOL finished) {
        self.categoriesVC.hideButton.hidden = YES;
        self.isCategoriesExpanded = NO;
    }];
}

@end

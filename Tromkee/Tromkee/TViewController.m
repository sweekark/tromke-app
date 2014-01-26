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

@interface TViewController () <PFLogInViewControllerDelegate, MKMapViewDelegate, TCategoriesVCDelegate>

@property (weak, nonatomic) IBOutlet MKMapView *map;
@property (weak, nonatomic) IBOutlet UIView *container;

@end

@implementation TViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateUserLocation:) name:TROMKE_USER_LOCATION_UPDATED object:nil];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (![PFUser currentUser]) {
        TLogInViewController *loginViewController = [[TLogInViewController alloc] init];
        [loginViewController setDelegate:self];
        loginViewController.fields = PFLogInFieldsPasswordForgotten | PFLogInFieldsFacebook | PFLogInFieldsSignUpButton | PFLogInFieldsUsernameAndPassword;
        loginViewController.facebookPermissions = @[ @"user_about_me" ];
        
        [self presentViewController:loginViewController animated:YES completion:nil];
        return;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
//
//- (IBAction)registerUser:(id)sender {
//    TSignUpViewController* signVC = [[TSignUpViewController alloc] init];
//    signVC.fields = PFSignUpFieldsUsernameAndPassword | PFSignUpFieldsEmail | PFSignUpFieldsSignUpButton | PFSignUpFieldsDismissButton;
//    signVC.delegate = self;
//    [self presentViewController:signVC animated:YES completion:nil];
//}
//
//- (IBAction)authenticateUser:(id)sender {
//    TLoginViewController* loginVC = [[TLoginViewController alloc] init];
//    loginVC.fields = PFLogInFieldsUsernameAndPassword | PFLogInFieldsLogInButton | PFLogInFieldsFacebook | PFLogInFieldsDismissButton;
//    loginVC.facebookPermissions = @[ @"user_about_me" ];
//    loginVC.delegate = self;
//    [self presentViewController:loginVC animated:YES completion:nil];
//    
//}
//
//#pragma mark - Signup Delegates
//
//- (void)signUpViewController:(PFSignUpViewController *)signUpController didSignUpUser:(PFUser *)user {
//    NSLog(@"Signup Success");
//    [signUpController dismissViewControllerAnimated:YES completion:nil];
//}
//
//- (void)signUpViewController:(PFSignUpViewController *)signUpController didFailToSignUpWithError:(NSError *)error {
//    NSLog(@"Signup Failed");
//    [signUpController dismissViewControllerAnimated:YES completion:nil];
//}

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
        TCategoriesViewController* categoriesVC = segue.destinationViewController;
        categoriesVC.delegate = self;
    }
}

-(void)showCategoriesView {
    [UIView animateWithDuration:1.0 animations:^{
        CGRect r = self.container.frame;
        r.origin.y = self.view.frame.size.height - r.size.height;
        self.container.frame = r;
    }];
}

-(void)hideCategoriesView {
    
}

@end

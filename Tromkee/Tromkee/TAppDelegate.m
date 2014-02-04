//
//  TAppDelegate.m
//  Tromkee
//
//  Created by Satyanarayana SVV on 1/3/14.
//  Copyright (c) 2014 Tromkee. All rights reserved.
//

#import "TAppDelegate.h"
#import <CoreLocation/CoreLocation.h>
#import "TLocationUtility.h"
#import "TLogInViewController.h"
#import "MBProgressHUD.h"

@interface TAppDelegate() <PFLogInViewControllerDelegate>

@property (nonatomic, strong) Reachability *hostReach;
@property (nonatomic, strong) Reachability *internetReach;
@property (nonatomic, strong) Reachability *wifiReach;

@property (nonatomic) int networkStatus;
@property (nonatomic, strong) MBProgressHUD *hud;

@end

@implementation TAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [[UINavigationBar appearance] setBarTintColor:[UIColor colorWithRed:160/255.0f green:234/255.0f blue:242/255.0f alpha:1.0f]];

    //Following are Tromkee's credentials
    [Parse setApplicationId:kParseApplicationID clientKey:kParseClientKey];
    [PFFacebookUtils initializeFacebook];

    // Track app open.
    [PFAnalytics trackAppOpenedWithLaunchOptions:launchOptions];
    
    //[PFUser enableAutomaticUser];
    
    // Use Reachability to monitor connectivity
    [self monitorReachability];
    
    PFACL *defaultACL = [PFACL ACL];
    // If you would like all objects to be private by default, remove this line.
    [defaultACL setPublicReadAccess:YES];
    [PFACL setDefaultACL:defaultACL withAccessForCurrentUser:YES];

    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
//    if ([CLLocationManager authorizationStatus] != kCLAuthorizationStatusAuthorized) {
//        [[[UIAlertView alloc] initWithTitle:@"Warning" message:@"Tromkee can't find your location. Please visit settings on your iOS device and allow the app to detect your settings" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
//    }
    [TLocationUtility sharedInstance];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    return [PFFacebookUtils handleOpenURL:url];
}


- (void)monitorReachability {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
    
    self.hostReach = [Reachability reachabilityWithHostName:@"api.parse.com"];
    [self.hostReach startNotifier];
    
    self.internetReach = [Reachability reachabilityForInternetConnection];
    [self.internetReach startNotifier];
    
    self.wifiReach = [Reachability reachabilityForLocalWiFi];
    [self.wifiReach startNotifier];
}

- (void)reachabilityChanged:(NSNotification* )note {
    Reachability *curReach = (Reachability *)[note object];
    NSParameterAssert([curReach isKindOfClass: [Reachability class]]);
    
    self.networkStatus = [curReach currentReachabilityStatus];
    
    if (self.networkStatus == NotReachable) {
        NSLog(@"Network not reachable.");
    }    
}

- (BOOL)isParseReachable {
    return self.networkStatus != NotReachable;
}

#pragma mark - PFLoginViewController

- (void)presentLoginViewControllerAnimated:(BOOL)animated {

    TLogInViewController *loginViewController = [[TLogInViewController alloc] init];
    [loginViewController setDelegate:self];
    loginViewController.fields = PFLogInFieldsPasswordForgotten | PFLogInFieldsFacebook | PFLogInFieldsSignUpButton | PFLogInFieldsUsernameAndPassword;
    loginViewController.facebookPermissions = @[ @"user_about_me" ];

    [(UINavigationController *)self.window.rootViewController presentViewController:loginViewController animated:NO completion:nil];
}

- (void)presentLoginViewController {
    [self presentLoginViewControllerAnimated:YES];
}


- (void)logInViewController:(PFLogInViewController *)logInController didLogInUser:(PFUser *)user {

    [logInController dismissViewControllerAnimated:YES completion:nil];
    
//    if (![self shouldProceedToMainInterface:user]) {
//        UINavigationController* navControler = (UINavigationController *)self.window.rootViewController;
//        self.hud = [MBProgressHUD showHUDAddedTo:navControler.presentedViewController.view animated:YES];
//        self.hud.labelText = NSLocalizedString(@"Loading", nil);
//        self.hud.dimBackground = YES;
//    }
//    
//    [FBRequestConnection startForMeWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
//        if (!error) {
//            [self facebookRequestDidLoad:result];
//        } else {
//            [self facebookRequestDidFailWithError:error];
//        }
//    }];
}

- (BOOL)shouldProceedToMainInterface:(PFUser *)user {
    if ([TUtility userHasValidFacebookData:[PFUser currentUser]]) {
        UINavigationController* navControler = (UINavigationController *)self.window.rootViewController;
        [MBProgressHUD hideHUDForView:navControler.presentedViewController.view animated:YES];
//        [self presentTabBarController];

        [(UINavigationController *)self.window.rootViewController dismissViewControllerAnimated:YES completion:nil];
        return YES;
    }
    
    return NO;
}

#pragma mark - Facebook Methods

- (void)facebookRequestDidLoad:(id)result {
    // This method is called twice - once for the user's /me profile, and a second time when obtaining their friends. We will try and handle both scenarios in a single method.
    PFUser *user = [PFUser currentUser];
    
    self.hud.labelText = NSLocalizedString(@"Creating Profile", nil);
        
    if (user) {
        NSString *facebookName = result[@"name"];
        if (facebookName && [facebookName length] != 0) {
            [user setObject:facebookName forKey:kPAPUserDisplayNameKey];
        } else {
            [user setObject:@"TromkeeUser" forKey:kPAPUserDisplayNameKey];
        }
        
        NSString *facebookId = result[@"id"];
        if (facebookId && [facebookId length] != 0) {
            [user setObject:facebookId forKey:kPAPUserFacebookIDKey];
        }
        
        [user saveEventually];
    }
}

- (void)facebookRequestDidFailWithError:(NSError *)error {
    NSLog(@"Facebook error: %@", error);
    
    if ([PFUser currentUser]) {
        if ([[error userInfo][@"error"][@"type"] isEqualToString:@"OAuthException"]) {
            NSLog(@"The Facebook token was invalidated. Logging out.");
            [self logOut];
        }
    }
}

- (void)logOut {
    // Clear all caches
    [PFQuery clearAllCachedResults];
    
    // Log out
    [PFUser logOut];
    
    // clear out cached data, view controllers, etc
    [(UINavigationController *)self.window.rootViewController popToRootViewControllerAnimated:NO];
}

@end

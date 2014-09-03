//
//  TAppDelegate.m
//  Tromke
//
//  Created by Satyam on 7/21/14.
//  Copyright (c) 2014 tromke. All rights reserved.
//

#import "TAppDelegate.h"

#import <CoreLocation/CoreLocation.h>
#import "TLocationUtility.h"
#import "TLogInViewController.h"
#import "TActivityViewController.h"
#import <Crashlytics/Crashlytics.h>
#import "TWelcomeViewController.h"

@interface TAppDelegate() <PFLogInViewControllerDelegate> {
    NSMutableData *_data;
}

@property (nonatomic, strong) Reachability *hostReach;
@property (nonatomic, strong) Reachability *internetReach;
@property (nonatomic, strong) Reachability *wifiReach;

@property (nonatomic) int networkStatus;
@property (nonatomic) BOOL applicationIsActive;
@property (nonatomic, strong) TWelcomeViewController* welcomeVC;

@property (nonatomic, strong) UIViewController* loginVC;
@property (nonatomic, strong) UIViewController* mainVC;
@end


@implementation TAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    self.loginVC = (UIViewController*)[storyboard instantiateViewControllerWithIdentifier:@"Login"];
    self.mainVC =  (UIViewController*)[storyboard instantiateViewControllerWithIdentifier:@"MainVC"];

    [PFImageView class];
    [TFlurryManager initializeFlurry];
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{FIRST_TIME : @YES,
                                                              FIRST_TIME_HELP : @YES}];
    
    [Crashlytics startWithAPIKey:CRASHLYTICS_ID];

    // Register for push notifications
    [application registerForRemoteNotificationTypes: UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound];
    
    
    //Following are Tromkee's credentials
    [Parse setApplicationId:kParseApplicationID clientKey:kParseClientKey];
    [PFFacebookUtils initializeFacebook];

    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    
    self.welcomeVC = [[TWelcomeViewController alloc] init];
    self.navController = [[UINavigationController alloc] initWithRootViewController:self.welcomeVC];
    self.navController.navigationBarHidden = YES;
    
    self.window.rootViewController = self.navController;
    [self.window makeKeyAndVisible];


    //Sticker posted
    //    {
    //	    aps =     {
    //	        alert = "sat posted a sticker";
    //	        badge = 36;
    //	    };
    //	    fu = eS1z0ZKRZz;
    //	    p = p;
    //	    pid = OX6rWD0ftJ;
    //	    t = s;
    //	}
    
    //Comment for sticker
    //    {
    //	    aid = waJGIoXCts;
    //	    aps =     {
    //	        alert = "sat: PPP";
    //	        badge = 37;
    //	    };
    //	    fu = eS1z0ZKRZz;
    //	    p = a;
    //	    pid = OX6rWD0ftJ;
    //	    t = c;
    //	    tu = eS1z0ZKRZz;
    //	}
    
    
    NSLog(@"Launch options is %@", launchOptions);
    if (launchOptions != nil) {
        NSLog(@"Received remote notification");
        NSDictionary *userInfo = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
        [self performSelector:@selector(showActivityForPushNotification:) withObject:userInfo afterDelay:3.0];
    }

    // Track app open.
    //    [PFAnalytics trackAppOpenedWithLaunchOptions:launchOptions];
    
    //[PFUser enableAutomaticUser];
    
    //    PFACL *defaultACL = [PFACL ACL];
    //    // If you would like all objects to be private by default, remove this line.
    //    [defaultACL setPublicReadAccess:YES];
    //    [PFACL setDefaultACL:defaultACL withAccessForCurrentUser:YES];
    

    return YES;
}

-(void)showActivityForPushNotification:(NSDictionary*)userInfo {
    //    if ([userInfo[@"p"] isEqualToString:@"p"]) {
    UIStoryboard *mainstoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    TActivityViewController* pvc = [mainstoryboard instantiateViewControllerWithIdentifier:@"Activity"];
    pvc.postedObjectID = userInfo[@"pid"];
    UINavigationController* navController = (UINavigationController*)self.window.rootViewController;
    [navController pushViewController:pvc animated:YES];
    //    }
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    self.applicationIsActive = NO;
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    [[TLocationUtility sharedInstance] initiateLocationCapture];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    //    if ([CLLocationManager authorizationStatus] != kCLAuthorizationStatusAuthorized) {
    //        [[[UIAlertView alloc] initWithTitle:@"Warning" message:@"Tromkee can't find your location. Please visit settings on your iOS device and allow the app to detect your settings" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
    //    }
    self.applicationIsActive = YES;
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)newDeviceToken {
    
    // Store the deviceToken in the current installation and save it to Parse.
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation setDeviceTokenFromData:newDeviceToken];
    [currentInstallation saveInBackground];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    if (!self.applicationIsActive) {
        NSLog(@"Inside didReceiveRemoteNotification");
        [self showActivityForPushNotification:userInfo];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:UPDATE_NOTIFICATION_COUNT object:nil];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    return [FBAppCall handleOpenURL:url sourceApplication:sourceApplication withSession:[PFFacebookUtils session]];
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
    if ([PFFacebookUtils isLinkedWithUser:[PFUser currentUser]]) {
        [FBRequestConnection startWithGraphPath:@"me" parameters:[NSDictionary dictionaryWithObject:@"picture,id,birthday,email,name,gender,username" forKey:@"fields"] HTTPMethod:@"GET" completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
            if (!error) {
                [self facebookRequestDidLoad:result];
            } else {
                [self facebookRequestDidFailWithError:error];
            }
        }];
    }
}

#pragma mark - Facebook Methods

- (void)facebookRequestDidLoad:(id)result {
    // This method is called twice - once for the user's /me profile, and a second time when obtaining their friends. We will try and handle both scenarios in a single method.
    PFUser *user = [PFUser currentUser];
    
    if (user) {
        //        picture,id,birthday,email,name,gender,username
        
        NSString *facebookName = result[@"name"];
        if (facebookName && [facebookName length] != 0) {
            [user setObject:facebookName forKey:FACEBOOK_DISPLAYNAME];
            NSLog(@"FB Name: %@", facebookName);
        } else {
            [user setObject:@"TromkeeUser" forKey:FACEBOOK_DISPLAYNAME];
        }
        
        NSString *facebookId = result[@"id"];
        if (facebookId && [facebookId length] != 0) {
            NSLog(@"FB ID: %@", facebookId);
            [user setObject:facebookId forKey:FACEBOOK_ID_KEY];
        }
        
        NSMutableDictionary* dict = [@{} mutableCopy];
        NSDictionary* pictureURL = result[@"picture"];
        if (pictureURL) {
            dict[@"picture"] = [pictureURL valueForKeyPath:@"data.url"];
        }
        
        NSString* birthday = result[@"birthday"];
        if (birthday) {
            dict[@"birthday"] = birthday;
        }
        
        NSString* email = result [@"email"];
        if (email) {
            dict[@"email"] = email;
        }
        
        NSString* username = result[@"username"];
        if (username) {
            dict[@"username"] = username;
        }
        
        NSString* gender = result[@"gender"];
        if (gender) {
            dict[@"gender"] = gender;
        }
        
        user[@"profile"] = dict;
        
        [user saveEventually];
    }
    
    NSURL *profilePictureURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large", [[PFUser currentUser] objectForKey:FACEBOOK_ID_KEY]]];
    NSURLRequest *profilePictureURLRequest = [NSURLRequest requestWithURL:profilePictureURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10.0f]; // Facebook profile picture cache policy: Expires in 2 weeks
    [NSURLConnection connectionWithRequest:profilePictureURLRequest delegate:self];
}

- (void)facebookRequestDidFailWithError:(NSError *)error {
    NSLog(@"Facebook error: %@", error);
    
    if ([PFUser currentUser]) {
        if ([[error userInfo][@"error"][POST_TYPE] isEqualToString:@"OAuthException"]) {
            NSLog(@"The Facebook token was invalidated. Logging out.");
            [self logOut];
        }
    }
}

#pragma mark - NSURLConnectionDataDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    _data = [[NSMutableData alloc] init];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [_data appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [TUtility processFacebookProfilePictureData:_data];
}


- (void)logOut {
    // Clear all caches
    [PFQuery clearAllCachedResults];
    
    // Log out
    [PFUser logOut];
    
    // clear out cached data, view controllers, etc
    [(UINavigationController *)self.window.rootViewController popToRootViewControllerAnimated:NO];
}

#pragma mark - View controllers

- (void)showHelpViewController {
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController* vc = (UIViewController*)[storyboard instantiateViewControllerWithIdentifier:@"Help"];
//    [self.welcomeVC presentViewController:vc animated:YES completion:nil];
    [self.navController setViewControllers:@[self.welcomeVC, self.loginVC, vc]];
}

- (void)showLoginViewController {
    [self.navController setViewControllers:@[self.welcomeVC, self.loginVC]];
}

- (void)showMainViewController {
    [self.navController setViewControllers:@[self.welcomeVC, self.loginVC, self.mainVC]];
}
@end

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

@interface TAppDelegate()

@property (nonatomic, strong) Reachability *hostReach;
@property (nonatomic, strong) Reachability *internetReach;
@property (nonatomic, strong) Reachability *wifiReach;

@property (nonatomic) int networkStatus;

@end

@implementation TAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    //Using Satyam's credentials.
    //[Parse setApplicationId:@"N0FkYQfbbqKDUVt2qykOno04N81LbctgqhyHAan8" clientKey:@"OlKJmRgLr9dLh2eWrtrXEKK3U0e3YLQokaEQLl2U"];

    
    // ****************************************************************************
    //Following are Tromkee's credentials
    [Parse setApplicationId:kParseApplicationID clientKey:kParseClientKey];
    [PFFacebookUtils initializeFacebook];
    //****************************************************************************
    // Track app open.
    [PFAnalytics trackAppOpenedWithLaunchOptions:launchOptions];
    
    [PFUser enableAutomaticUser];
    
    // Use Reachability to monitor connectivity
    [self monitorReachability];
    
    PFACL *defaultACL = [PFACL ACL];
    // If you would like all objects to be private by default, remove this line.
    [defaultACL setPublicReadAccess:YES];
    
    [PFACL setDefaultACL:defaultACL withAccessForCurrentUser:YES];

    // Override point for customization after application launch.
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


@end

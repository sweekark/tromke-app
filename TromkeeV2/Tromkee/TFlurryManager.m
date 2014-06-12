//
//  TFlurryManager.m
//  Tromke
//
//  Created by Satyam on 6/11/14.
//  Copyright (c) 2014 Tromkee. All rights reserved.
//

#import "TFlurryManager.h"
#import "Flurry.h"

#define TROM_STICKER @"TromSticker"
#define TROM_PHOTO @"TromPhoto"
#define TROM_QUESTION @"TromQuestion"

#define CANCELLED_STICKER @"CancelledSticker"
#define CANCELLED_QUESTION @"CancelledQuestion"
#define CANCELLED_PHOTO @"CancelledPhoto"

//Map
#define MAP_VIEWING_DURATION @"MapViewingDuration"
#define MAP_TRAVERSED @"MapTraversed"

#define MAP_TAPPED_STICKER @"MapTappedSticker"
#define MAP_TAPPED_PHOTO @"MapTappedPhoto"
#define MAP_TAPPED_QUESTION @"MapTappedQuestion"

//Profile
#define PROFILE_ACTIVITY @"ProfileActivityTapped"
#define PROFILE_FOLLOW @"ProfileFollowTapped"
#define PROFILE_FOLLOWING @"ProfileFollowingTapped"


//Notification
#define VIEWING_NOTIFICATOIN @"ViewingNotificaton"

//Menu
#define MENU_SELECTED_PROFILE @"MenuProfile"
#define MENU_SELECTED_LOGOUT @"MenuLogout"


static NSDate* mapviewStarttime;

@implementation TFlurryManager

+(void)initializeFlurry {
    [Flurry setCrashReportingEnabled:YES];
    [Flurry startSession:FLURRY_ID];   
}


+(void)tromSticker:(NSDictionary*)params {
    [Flurry logEvent:TROM_STICKER withParameters:params];
}

+(void)tromPhoto:(NSDictionary*)params {
    [Flurry logEvent:TROM_PHOTO withParameters:params];
}

+(void)tromQuestion:(NSDictionary*)params {
    [Flurry logEvent:TROM_QUESTION withParameters:params];
}

+(void)cancelledQuestion {
    [Flurry logEvent:CANCELLED_QUESTION];
}

+(void)cancelledPhoto {
    [Flurry logEvent:CANCELLED_PHOTO];
}

+(void)cancelledSticker {
    [Flurry logEvent:CANCELLED_STICKER];
}

//Map

+(void)startedMap {
    mapviewStarttime = [NSDate date];
}

+(void)stoppedMap {
    NSDate* dt = [NSDate date];
    NSTimeInterval duration = [dt timeIntervalSinceDate:mapviewStarttime];
    [Flurry logEvent:MAP_VIEWING_DURATION withParameters:@{@"MapViewingDuration" : [NSNumber numberWithDouble:duration], @"UserID" : [PFUser currentUser]}];
    mapviewStarttime = nil;
}

+(void)userTraversedInMap {
    [Flurry logEvent:MAP_TRAVERSED withParameters:@{@"UserID" : [PFUser currentUser]}];
}

+(void)tappedSticker:(NSString*)postID {
    [Flurry logEvent:MAP_TAPPED_STICKER withParameters:@{@"PostID" : postID}];
}

+(void)tappedPhoto:(NSString*)postID {
    [Flurry logEvent:MAP_TAPPED_PHOTO withParameters:@{@"PostID" : postID}];
}

+(void)tappedQustion:(NSString*)postID {
    [Flurry logEvent:MAP_TAPPED_QUESTION withParameters:@{@"PostID" : postID}];
}

//Profile
+(void)tappedActivity {
    [Flurry logEvent:PROFILE_ACTIVITY];
}

+(void)tappedFollow {
    [Flurry logEvent:PROFILE_FOLLOW];
}

+(void)tappedFollowing {
    [Flurry logEvent:PROFILE_FOLLOWING];
}


//Notification
+(void)viewingNotification:(NSString*)notificationID {
    [Flurry logEvent:VIEWING_NOTIFICATOIN withParameters:@{@"NotificatonID" : notificationID}];
}


//Menu
+(void)viewingProfile {
    [Flurry logEvent:MENU_SELECTED_PROFILE];
}

+(void)userLoggedOut {
    [Flurry logEvent:MENU_SELECTED_LOGOUT];
}


@end

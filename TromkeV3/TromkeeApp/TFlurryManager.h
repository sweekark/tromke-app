//
//  TFlurryManager.h
//  Tromke
//
//  Created by Satyam on 6/11/14.
//  Copyright (c) 2014 Tromkee. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TFlurryManager : NSObject

+(void)initializeFlurry;

+(void)tromSticker:(NSDictionary*)params;
+(void)tromPhoto:(NSDictionary*)params;
+(void)tromQuestion:(NSDictionary*)params;

+(void)cancelledQuestion;
+(void)cancelledPhoto;

//Map

+(void)startedMap;
+(void)stoppedMap;
+(void)userTraversedInMap;
+(void)tappedSticker:(NSString*)postID;
+(void)tappedPhoto:(NSString*)postID;
+(void)tappedQustion:(NSString*)postID;


//Profile
+(void)tappedActivity;
+(void)tappedFollow;
+(void)tappedFollowing;

//Notification
+(void)viewingNotification:(NSString*)notificationID;


//Menu
+(void)viewingProfile;
+(void)userLoggedOut;
+(void)inviteFriends;

@end

//
//  TConstants.h
//  Tromkee
//
//  Created by Satyanarayana SVV on 1/9/14.
//  Copyright (c) 2014 Tromkee. All rights reserved.
//

#import <Foundation/Foundation.h>

static NSString* const kParseApplicationID = @"IgOuPSL7tE4lSUYDUoqeovRPalXs7PWV61xfsIKb";
static NSString* const kParseClientKey = @"QPokBBeDc8I1uMHDuOIgRHBq52kzB5sup2zVNi1T";

#ifdef DEBUG
#    define DLog(...) NSLog(@"TROMKE :: "__VA_ARGS__)
#else
#    define DLog(...) /* */
#endif

//User defaults
#define USER_LOCATION @"USER_LOCATION"

//Notifications
#define TROMKE_USER_LOCATION_UPDATED @"TROMKE_USER_LOCATION_UPDATED"
#define TROMKEE_UPDATE_STICKERS @"TROMEE_UPDATE_STICKERS"

#define STICKERS_BG_COLOR [UIColor colorWithRed:240/255.0f green:242/255.0f blue:242/255.0f alpha:1.0f]
#define STICKER_POST_BOTTOM_COLOR [UIColor colorWithRed:226/255.0f green:226/255.0f blue:226/255.0f alpha:1.0f]


#define POSTDATA_LENGTH 140
#define STICKER_QUERY_RADIUS 40.0 //In miles

//FACEBOOK
#define FACEBOOK_ID_KEY @"facebookId"
#define FACEBOOK_DISPLAYNAME @"username"
#define FACEBOOK_SMALLPIC_KEY @"profilePictureSmall"
#define FACEBOOK_MEDIUMPIC_KEY @"profilePictureMedium"


//ACTIVITY
#define THANKS @"THANKS"
#define FOLLOWS @"FOLLOWS"
#define COMMENT @"COMMENT"
#define IMAGE_COMMENT @"IMAGE_COMMENT"
#define IMAGE_ONLY @"IMAGE"


//MENU IDENTIFIERS
typedef NS_ENUM(NSInteger, MenuItem) {
    MenuItemNearMe = 0,
    MenuItemChooseMyRoute,
    MenuItemChats,
    MenuItemProfile,
    MenuItemTopTromers,
    MenuItemSettings,
    MenuItemLogout
};

#define STICKER_POSTED_PROFILE @"StickerPostedProfile"
#define PROFILE @"PROFILE"
#define ACTIVITY @"Activity"
#define MENU @"Menu"
#define CATEGORIES @"Categories"
#define PROFILEVIEW @"Profile"

#define UPDATE_NOTIFICATION_COUNT @"UPDATE_NOTIFICATION_COUNT"
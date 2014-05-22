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
#define TROMKEE_UPDATE_COMMENTS @"TROMKEE_UPDATE_COMMENTS"
#define STICKER_POSTED @"STICKER_POSTED"
#define UPDATE_NOTIFICATION_COUNT @"UPDATE_NOTIFICATION_COUNT"

//Colors
#define STICKERS_BG_COLOR [UIColor colorWithRed:240/255.0f green:242/255.0f blue:242/255.0f alpha:1.0f]
#define STICKER_POST_BOTTOM_COLOR [UIColor colorWithRed:226/255.0f green:226/255.0f blue:226/255.0f alpha:1.0f]

#define ACTIVITY_PICTURE_COLOR @"#D393BC"
#define ACTIVITY_QUESTION_COLOR @"#F88190"
#define ACTIVITY_STICKER_COLOR @"#FFFFFF"

#define YELLOW_COLOR @"#FDD17D"


//GENERAL
#define POSTDATA_LENGTH 100
#define STICKER_QUERY_RADIUS 2 //In miles

//STRINGS
#define ACTIVITY_STICKER @"Sticker"
#define ACTIVITY_ASK @"Question"
#define ACTIVITY_PICTURE @"Picture"

//FACEBOOK
#define FACEBOOK_ID_KEY @"facebookId"
#define FACEBOOK_DISPLAYNAME @"username"
#define FACEBOOK_SMALLPIC_KEY @"profilePictureSmall"
#define FACEBOOK_MEDIUMPIC_KEY @"profilePictureMedium"



//MENU IDENTIFIERS
typedef NS_ENUM(NSInteger, MenuItem) {
    MenuItemNearMe = 0,
    MenuItemMyProfile,
    MenuItemMyActivity,
    MenuItemSettings,
    MenuItemLogout
};

typedef NS_ENUM(NSInteger, Camera) {
    CameraForAsk = 0,
    CameraForImage,
    CameraForSticker,
    CameraForComment
};

#define STICKER_POSTED_PROFILE @"StickerPostedProfile"
#define PROFILE @"PROFILE"
#define ACTIVITY @"Activity"
#define MENU @"Menu"
#define CATEGORIES @"Categories"
#define PROFILEVIEW @"Profile"
#define ASKCAMERA @"ASKCAMERA"

//VIEW or Segue Identifiers
#define CAMERA @"CAMERA"
#define ASKCAMERA @"ASKCAMERA"
#define VIEWSTICKER @"VIEWSTICKER"
#define VIEWQUESTION @"VIEWQUESTION"
#define VIEWIMAGE @"VIEWIMAGE"

//Posting Sticker, Image, Ask
#define POST @"Post"
#define POST_DATA @"data"
#define POST_LOCATION @"location"
#define POST_FROMUSER @"fromUser"
#define POST_USERLOCATION @"usrlocation"
#define POST_ORIGINAL_IMAGE @"originalImage"
#define POST_THUMBNAIL_IMAGE @"thumbnailImage"
#define POST_TYPE @"type"
#define POST_COMMENTS_COUNT @"comments_count"
#define POST_THANKS_COUNT @"thanks_count"

#define POST_TYPE_STICKER @"STICKER"
#define POST_TYPE_ASK @"ASK"
#define POST_TYPE_IMAGE @"IMAGE"

//Sticker Object
#define STICKER @"sticker"
#define STICKER_NAME @"name"
#define STICKER_IMAGE @"image"
#define STICKER_SEVERITY @"severity"


//Activity Object
#define ACTIVITY_TYPE_THANKS @"THANKS"
#define ACTIVITY_TYPE_FOLLOW @"FOLLOW"
#define ACTIVITY_TYPE_COMMENT @"COMMENT"
#define ACTIVITY_TYPE_IMAGE_COMMENT @"IMAGE_COMMENT"
#define ACTIVITY_TYPE_IMAGE_ONLY @"IMAGE"

#define ACTIVITY @"Activity"
#define ACTIVITY_FROMUSER @"fromUser"
#define ACTIVITY_TOUSER @"toUser"
#define ACTIVITY_TYPE @"type"
#define ACTIVITY_CONTENT @"content"
#define ACTIVITY_POST @"post"
#define ACTIVITY_ORIGINAL_IMAGE @"originalImage"
#define ACTIVITY_THUMBNAIL_IMAGE @"thumbnailImage"


//Category Object
#define CATEGORY @"category"
#define CATEGORY_IMAGE @"Image"
#define CATEGORY_NAME @"name"
#define CATEGORY_SORTBY @"sort_no"

//User Object
#define USER_DISPLAY_NAME @"displayName"
#define USER_USER_NAME @"username"




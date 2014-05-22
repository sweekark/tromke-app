//
//  TUtility.h
//  Tromke
//
//  Created by Satyanarayana SVV on 2/1/14.
//  Copyright (c) 2014 Tromkee. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TUtility : NSObject

+ (void)processFacebookProfilePictureData:(NSData *)data;
+ (void)uploadUserImage:(UIImage*)image withCompletionHandler:(void (^)(BOOL,UIImage*))handler;
+ (NSString*)computePostedTime :(NSDate*)date;
+ (UIColor *)colorFromHexString:(NSString *)hexString;
+ (NSString*)getDisplayNameForUser:(PFUser*)user;
@end

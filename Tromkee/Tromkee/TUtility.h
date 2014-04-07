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
+ (UIImage*)uploadUserImage:(UIImage*)image;
+ (NSString*)computePostedTime :(NSDate*)date;

@end

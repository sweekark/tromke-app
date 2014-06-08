//
//  TUtility.m
//  Tromke
//
//  Created by Satyanarayana SVV on 2/1/14.
//  Copyright (c) 2014 Tromkee. All rights reserved.
//

#import "TUtility.h"
#import "UIImage+ResizeAdditions.h"

@implementation TUtility

#pragma mark Facebook

+ (void)processFacebookProfilePictureData:(NSData *)newProfilePictureData {
    if (newProfilePictureData.length == 0) {
        return;
    }
    
    // The user's Facebook profile picture is cached to disk. Check if the cached profile picture data matches the incoming profile picture. If it does, avoid uploading this data to Parse.
    
    NSURL *cachesDirectoryURL = [[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] lastObject]; // iOS Caches directory
    
    NSURL *profilePictureCacheURL = [cachesDirectoryURL URLByAppendingPathComponent:@"FacebookProfilePicture.jpg"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:[profilePictureCacheURL path]]) {
        // We have a cached Facebook profile picture
        
        NSData *oldProfilePictureData = [NSData dataWithContentsOfFile:[profilePictureCacheURL path]];
        
        if ([oldProfilePictureData isEqualToData:newProfilePictureData]) {
            return;
        }
    }
    
    UIImage *image = [UIImage imageWithData:newProfilePictureData];
    [self uploadUserImage:image withCompletionHandler:^(BOOL success, UIImage *img) {
        
    }];
}


+ (void)uploadUserImage:(UIImage*)image withCompletionHandler:(void (^)(BOOL,UIImage*))handler {
    UIImage *mediumImage = [image thumbnailImage:280 transparentBorder:0 cornerRadius:0 interpolationQuality:kCGInterpolationHigh];
    UIImage *smallRoundedImage = [image thumbnailImage:64 transparentBorder:0 cornerRadius:9 interpolationQuality:kCGInterpolationLow];
    
    NSData *mediumImageData = UIImageJPEGRepresentation(mediumImage, 0.5); // using JPEG for larger pictures
    NSData *smallRoundedImageData = UIImagePNGRepresentation(smallRoundedImage);

    PFFile *fileSmallRoundedImage = [PFFile fileWithData:smallRoundedImageData];
    if (smallRoundedImageData.length > 0) {
        [fileSmallRoundedImage saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (error) {
                //Handle error
            }
        }];
    }

    
    PFFile *fileMediumImage = [PFFile fileWithData:mediumImageData];
    if (mediumImageData.length > 0) {
    
        [fileMediumImage saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (error) {
                //Handle error
            }
        }];
    }
    
    [[PFUser currentUser] setObject:fileMediumImage forKey:FACEBOOK_MEDIUMPIC_KEY];
    [[PFUser currentUser] setObject:fileSmallRoundedImage forKey:FACEBOOK_SMALLPIC_KEY];
    
    [[PFUser currentUser] saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            [[PFUser currentUser] refresh];
            NSLog(@"User photo uploaded successfully");
            handler(YES, smallRoundedImage);
        } else {
            handler(NO, nil);
        }
    }];
}

+(NSString*)computePostedTime :(NSDate*)date {
    
//    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
//    [dateFormatter setAMSymbol:@"am"];
//    [dateFormatter setPMSymbol:@"pm"];
//    
//    NSString* timestamp;
//    int timeIntervalInHours = (int)[[NSDate date] timeIntervalSinceDate:date] /3600;
//    
//    int timeIntervalInMinutes = [[NSDate date] timeIntervalSinceDate:date] /60;
//    
//    if (timeIntervalInMinutes <= 2){//less than 2 minutes old
//        
//        timestamp = @"Just Now";
//        
//    }else if(timeIntervalInMinutes < 15){//less than 15 minutes old
//        
//        timestamp = @"A few minutes ago";
//        
//    }else if(timeIntervalInHours < 24){//less than 1 day
//        
//        [dateFormatter setDateFormat:@"h:mm a"];
//        timestamp = [NSString stringWithFormat:@"Today at %@",[dateFormatter stringFromDate:date]];
//        
//    }else if (timeIntervalInHours < 48){//less than 2 days
//        
//        [dateFormatter setDateFormat:@"h:mm a"];
//        timestamp = [NSString stringWithFormat:@"Yesterday at %@",[dateFormatter stringFromDate:date]];
//        
//    }else if (timeIntervalInHours < 168){//less than  a week
//        
//        [dateFormatter setDateFormat:@"EEEE"];
//        timestamp = [NSString stringWithFormat:@"%@",[dateFormatter stringFromDate:date]];
//        
//    }else if (timeIntervalInHours < 8765){//less than a year
//        
//        [dateFormatter setDateFormat:@"d MMMM"];
//        timestamp = [NSString stringWithFormat:@"%@",[dateFormatter stringFromDate:date]];
//        
//    }else{//older than a year
//        
//        [dateFormatter setDateFormat:@"d MMMM yyyy"];
//        timestamp = [NSString stringWithFormat:@"%@",[dateFormatter stringFromDate:date]];
//        
//    }
//    
//    return timestamp;
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setAMSymbol:@"am"];
    [dateFormatter setPMSymbol:@"pm"];
    
    NSString* timestamp;
    int timeInterValInSeconds = [[NSDate date] timeIntervalSinceDate:date];
    
    if (timeInterValInSeconds <= 59) { //seconds
        timestamp = @"Now"; //[NSString stringWithFormat:@"%ds", timeInterValInSeconds];
    }else { //minutes
        int timeIntervalInMinutes = timeInterValInSeconds / 60;
        
        if (timeIntervalInMinutes <= 59) {
            timestamp = [NSString stringWithFormat:@"%dm", timeIntervalInMinutes];
        } else { //hours
            int timeIntervalInHours = (int)timeIntervalInMinutes / 60;
            if (timeIntervalInHours <= 23) {
                timestamp = [NSString stringWithFormat:@"%dh", timeIntervalInHours];
            } else { //days
                int timeIntervalInDays = timeIntervalInHours / 24;
                if (timeIntervalInDays <= 6) { //day
                    timestamp = [NSString stringWithFormat:@"%dd", timeIntervalInDays];
                } else { //weeks
                    int timeIntervalInWeek = (int)timeIntervalInDays / 7;
                    if (timeIntervalInWeek <= 3) {
                        timestamp = [NSString stringWithFormat:@"%dw", timeIntervalInWeek];
                    } else { //months
                        int timeIntervalInMonths = (int)timeIntervalInWeek / 4;
                        if (timeIntervalInMonths <= 11) {
                            timestamp = [NSString stringWithFormat:@"%dM", timeIntervalInMonths];
                        } else { //years
                            int timeIntervalInYears = (int)timeIntervalInMonths / 12;
                            timestamp = [NSString stringWithFormat:@"%dy", timeIntervalInYears];
                        }
                    }
                }
            }
        }

    }
    
    return timestamp;

}

+ (UIColor *)colorFromHexString:(NSString *)hexString {
    unsigned rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:hexString];
    [scanner setScanLocation:1]; // bypass '#' character
    [scanner scanHexInt:&rgbValue];
    return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:1.0];
}

+ (NSString*)getDisplayNameForUser:(PFUser*)user {
    NSString* str = user[USER_DISPLAY_NAME];
    if (!str || str.length == 0) {
        str = user[USER_USER_NAME];
    }
    
    return str;
}
@end

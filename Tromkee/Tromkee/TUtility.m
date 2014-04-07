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
    [self uploadUserImage:image];
}


+ (UIImage*)uploadUserImage:(UIImage*)image {
    UIImage *mediumImage = [image thumbnailImage:280 transparentBorder:0 cornerRadius:0 interpolationQuality:kCGInterpolationHigh];
    UIImage *smallRoundedImage = [image thumbnailImage:64 transparentBorder:0 cornerRadius:9 interpolationQuality:kCGInterpolationLow];
    
    NSData *mediumImageData = UIImageJPEGRepresentation(mediumImage, 0.5); // using JPEG for larger pictures
    NSData *smallRoundedImageData = UIImagePNGRepresentation(smallRoundedImage);
    
    if (mediumImageData.length > 0) {
        PFFile *fileMediumImage = [PFFile fileWithData:mediumImageData];
        [fileMediumImage saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (!error) {
                [[PFUser currentUser] setObject:fileMediumImage forKey:FACEBOOK_MEDIUMPIC_KEY];
                [[PFUser currentUser] saveEventually];
            }
        }];
    }
    
    if (smallRoundedImageData.length > 0) {
        PFFile *fileSmallRoundedImage = [PFFile fileWithData:smallRoundedImageData];
        [fileSmallRoundedImage saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (!error) {
                [[PFUser currentUser] setObject:fileSmallRoundedImage forKey:FACEBOOK_SMALLPIC_KEY];
                [[PFUser currentUser] saveEventually];
            }
        }];
    }
    
    return smallRoundedImage;
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
    int timeIntervalInHours = (int)[[NSDate date] timeIntervalSinceDate:date] /3600;
    
    int timeIntervalInMinutes = [[NSDate date] timeIntervalSinceDate:date] /60;
    
    if (timeIntervalInMinutes <= 2){//less than 2 minutes old
        
        timestamp = @"Just Now";
        
    }else if(timeIntervalInMinutes < 15){//less than 15 minutes old
        
        timestamp = @"A few minutes ago";
        
    } else if (timeIntervalInHours < 2) {
        
        timestamp = @"One hour back";
        
    } else if (timeIntervalInHours < 3) {
        
        timestamp = @"2 hours back";
        
    }
    else if(timeIntervalInHours < 24){//less than 1 day

        [dateFormatter setDateFormat:@"EEEE h:mm a"];
        timestamp = [NSString stringWithFormat:@"%@",[dateFormatter stringFromDate:date]];
        
    }else if (timeIntervalInHours < 8765){//less than a year
        
        [dateFormatter setDateFormat:@"d MMMM"];
        timestamp = [NSString stringWithFormat:@"%@",[dateFormatter stringFromDate:date]];
        
    }else{//older than a year
        
        [dateFormatter setDateFormat:@"d MMMM yyyy"];
        timestamp = [NSString stringWithFormat:@"%@",[dateFormatter stringFromDate:date]];
        
    }
    
    return timestamp;

}


@end

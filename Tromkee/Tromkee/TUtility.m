//
//  TUtility.m
//  Tromke
//
//  Created by Satyanarayana SVV on 2/1/14.
//  Copyright (c) 2014 Tromkee. All rights reserved.
//

#import "TUtility.h"

@implementation TUtility

+ (BOOL)userHasValidFacebookData:(PFUser *)user {
    NSString *facebookId = [user objectForKey:kPAPUserFacebookIDKey];
    return (facebookId && facebookId.length > 0);
}

+(NSString*)getCacheLocation {
    NSArray *writablePaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    return [writablePaths firstObject];
}

+(NSString*)prepareFilePathWithObjectID:(NSString*)objID {
    NSString* fNameToSave = [NSString stringWithFormat:@"%@.png", objID];
    return [[self getCacheLocation] stringByAppendingPathComponent:fNameToSave];
}

+ (void)getImage:(PFFile*)file withObjectID:(NSString*)objID andHandler:(FileHandler)handler {
    NSData* fileData = [self getImageWithObjectID:objID];
    if (fileData) {
        handler(fileData, nil);
    } else {
        [file getDataInBackgroundWithBlock:^(NSData *imageData, NSError *error) {
            [self saveImage:imageData withObjectID:objID];
            handler(imageData, error);
        }];
    }
}

+ (NSData*)getImageWithObjectID:(NSString*)objID {
    NSString* fNameToSave = [self prepareFilePathWithObjectID:objID];
    if ([[NSFileManager defaultManager]  fileExistsAtPath:fNameToSave]) {
        return [NSData dataWithContentsOfFile:fNameToSave];
    }
    
    return nil;
}

+ (void)saveImage:(NSData*)fileData withObjectID:(NSString*)objID {
    NSString* fNameToSave = [self prepareFilePathWithObjectID:objID];
    if (![[NSFileManager defaultManager] fileExistsAtPath:fNameToSave]) {
        [fileData writeToFile:fNameToSave atomically:YES];
    }
}

@end

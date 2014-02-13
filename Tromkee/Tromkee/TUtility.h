//
//  TUtility.h
//  Tromke
//
//  Created by Satyanarayana SVV on 2/1/14.
//  Copyright (c) 2014 Tromkee. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^FileHandler)(NSData *imageData, NSError *error);


@interface TUtility : NSObject

+ (void)getImage:(PFFile*)file withObjectID:(NSString*)objID andHandler:(FileHandler)handler;

@end

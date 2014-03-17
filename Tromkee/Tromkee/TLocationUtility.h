//
//  TLocationUtility.h
//  Tromkee
//
//  Created by Satyanarayana SVV on 1/13/14.
//  Copyright (c) 2014 Tromkee. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TLocationUtility : NSObject

+(id)sharedInstance;
-(CLLocationCoordinate2D)getUserCoordinate;
-(void)initiateLocationCapture;

@end

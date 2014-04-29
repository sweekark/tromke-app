//
//  TAppDelegate.h
//  Tromkee
//
//  Created by Satyanarayana SVV on 1/3/14.
//  Copyright (c) 2014 Tromkee. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Reachability.h"

@interface TAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

- (void)presentLoginViewControllerAnimated:(BOOL)animated;

@end

//
//  TAppDelegate.h
//  Tromke
//
//  Created by Satyam on 7/21/14.
//  Copyright (c) 2014 tromke. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) UINavigationController* navController;

- (void)presentLoginViewControllerAnimated:(BOOL)animated;
- (void)showHelpViewController;
- (void)showLoginViewController;
- (void)showMainViewController;

@end

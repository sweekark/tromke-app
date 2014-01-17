//
//  TCategoriesViewController.h
//  Tromke
//
//  Created by Satyanarayana SVV on 1/14/14.
//  Copyright (c) 2014 Tromkee. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol TCategoriesVCDelegate <NSObject>

-(void)showCategoriesView;
-(void)hideCategoriesView;

@end

@interface TCategoriesViewController : UIViewController

@property(nonatomic, weak) id<TCategoriesVCDelegate> delegate;

@end

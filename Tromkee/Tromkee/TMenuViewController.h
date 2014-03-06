//
//  TMenuViewController.h
//  Tromke
//
//  Created by Satyanarayana SVV on 2/13/14.
//  Copyright (c) 2014 Tromkee. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol TMenuDelegate <NSObject>

-(void)userClickedMenu:(NSInteger)rowNumber;

@end

@interface TMenuViewController : UITableViewController

@property(nonatomic, weak) id<TMenuDelegate> delegate;

@end

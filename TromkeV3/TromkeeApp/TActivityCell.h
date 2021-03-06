//
//  TActivityCell.h
//  Tromke
//
//  Created by Satyanarayana SVV on 2/17/14.
//  Copyright (c) 2014 Tromkee. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol TActivityDelegate <NSObject>

-(void)showProfileFromActivity:(NSInteger)item;

@end

@interface TActivityCell : UITableViewCell

@property (nonatomic, weak) IBOutlet PFImageView* personImage;
@property (nonatomic, weak) IBOutlet UILabel* personName;
@property (nonatomic, weak) IBOutlet UILabel* comment;
@property (nonatomic, weak) IBOutlet PFImageView* commentImage;
@property (nonatomic, weak) IBOutlet UILabel* updatedTime;

@property (nonatomic, weak) id<TActivityDelegate> delegate;

@end

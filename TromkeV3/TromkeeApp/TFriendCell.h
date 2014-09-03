//
//  TFriendCell.h
//  Tromke
//
//  Created by Satyam on 8/11/14.
//  Copyright (c) 2014 tromke. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol TFriendDelegate <NSObject>

-(void)selectedFriend:(NSInteger)friendID;

@end

@interface TFriendCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UIButton* selection;
@property (nonatomic, weak) IBOutlet UILabel* friendName;
@property (nonatomic, weak) IBOutlet UILabel* friendPhone;
@property (nonatomic, weak) IBOutlet PFImageView* friendImage;
@property (nonatomic) NSInteger friendID;

@property (nonatomic, weak) id<TFriendDelegate> delegate;

@end

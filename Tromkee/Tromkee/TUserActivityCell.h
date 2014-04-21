//
//  TUserActivityCell.h
//  Tromke
//
//  Created by Satyanarayana SVV on 4/11/14.
//  Copyright (c) 2014 Tromkee. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TUserActivityCell : UITableViewCell

@property (nonatomic, weak) IBOutlet PFImageView* userImage;
@property (nonatomic, weak) IBOutlet UILabel* notificationMessage;
@property (nonatomic, weak) IBOutlet UILabel* postedAt;

@end

//
//  TProfileCell.h
//  Tromke
//
//  Created by Satyanarayana SVV on 3/1/14.
//  Copyright (c) 2014 Tromkee. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TProfileCell : UITableViewCell

@property (nonatomic, weak) IBOutlet PFImageView* personImage;
@property (nonatomic, weak) IBOutlet UILabel* personName;
@property (nonatomic, weak) IBOutlet UILabel* comment;
@property (nonatomic, weak) IBOutlet UILabel* postedTime;

@end

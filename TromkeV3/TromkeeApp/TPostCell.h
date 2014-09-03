//
//  TPostCell.h
//  Tromke
//
//  Created by Satyanarayana SVV on 4/17/14.
//  Copyright (c) 2014 Tromkee. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol TPostCellDelegate <NSObject>

-(void)showProfileFromPost;
-(void)conveyThanks;
-(void)showLocationOfActivity:(PFGeoPoint*)location;;

@end

@interface TPostCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIButton *thanksButton;
@property (weak, nonatomic) IBOutlet UILabel *totalThanks;

@property (weak, nonatomic) id<TPostCellDelegate> delegate;


-(void)update:(PFObject*)postObj;
-(void)showLabelsForQuestion;
@end

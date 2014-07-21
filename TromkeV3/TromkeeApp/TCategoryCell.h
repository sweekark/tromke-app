//
//  TCategoryCell.h
//  Tromke
//
//  Created by Satyanarayana SVV on 1/14/14.
//  Copyright (c) 2014 Tromkee. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TCategoryCell : UICollectionViewCell

@property (nonatomic, weak) IBOutlet PFImageView* categoryImage;
@property (nonatomic, weak) IBOutlet UILabel* categoryTitle;
@property (nonatomic, weak) IBOutlet UIImageView* arrowImage;

@end

//
//  TCategoryStickersViewController.h
//  Tromke
//
//  Created by Satyanarayana SVV on 1/15/14.
//  Copyright (c) 2014 Tromkee. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol TStickersDelegate <NSObject>
-(void)userClickedSticker;
@end

@interface TCategoryStickersViewController : UICollectionViewController

@property (nonatomic, strong) PFObject* category;
@property (nonatomic, weak) id<TStickersDelegate> delegate;

@end

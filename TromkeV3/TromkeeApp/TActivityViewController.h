//
//  TActivityViewController.h
//  Tromke
//
//  Created by Satyanarayana SVV on 2/17/14.
//  Copyright (c) 2014 Tromkee. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol TActivityDelegate <NSObject>
-(void)showActivityLocation:(PFGeoPoint*)location;
@end

@interface TActivityViewController : UIViewController

@property (nonatomic, strong) PFObject* postedObject;
@property (nonatomic, strong) NSString* postedObjectID;
@property (nonatomic, weak) id<TActivityDelegate> delegate;

@end

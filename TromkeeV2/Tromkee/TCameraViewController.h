//
//  TCameraViewController.h
//  Tromkee
//
//  Created by Satyanarayana SVV on 4/30/14.
//  Copyright (c) 2014 Tromkee. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@protocol TCameraDelegate <NSObject>

-(void)startedPosting;
-(void)completedPosting:(BOOL)status andMessage:(NSString*)msg;

@end

@interface TCameraViewController : UIViewController

@property (nonatomic) int activityName;
@property (nonatomic, strong) NSString* cameraMessage;
@property(nonatomic, strong) PFObject* postedObject;

@property (nonatomic, weak) id<TCameraDelegate> delegate;

@end


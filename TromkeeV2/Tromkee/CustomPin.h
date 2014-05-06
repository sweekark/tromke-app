//
//  CustomPin.h
//  MapView
//
//  Created by admin on 10/06/14.
//  Copyright (c) 2014 codigator. All rights reserved.
//

#import <MapKit/MapKit.h>
#import "TCircleView.h"

@interface CustomPin : UIView//MKAnnotationView

@property (nonatomic, assign) CLLocationCoordinate2D coOrdinate2D;
@property (nonatomic, weak) IBOutlet PFImageView* stickerImage;
@property (nonatomic, weak) IBOutlet UILabel* commentsCount;
@property (nonatomic) float stickerColor;
@property (weak, nonatomic) UIView *bottomBar;

@end

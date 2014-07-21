//
//  TStickerAnnotationView.h
//  Tromke
//
//  Created by Satyanarayana SVV on 2/16/14.
//  Copyright (c) 2014 Tromkee. All rights reserved.
//

#import <MapKit/MapKit.h>

//@protocol TStickerAnnotationDelegate <NSObject>
//
//-(void)userTappedSticker:(id<MKAnnotation>)annotation;
//
//@end

@interface TStickerAnnotationView : MKAnnotationView

@property (nonatomic) float stickerColor;
//@property (nonatomic, weak) id<TStickerAnnotationDelegate> delegate;

@end

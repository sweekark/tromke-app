//
//  TStickerAnnotation.h
//  Tromke
//
//  Created by Satyanarayana SVV on 2/7/14.
//  Copyright (c) 2014 Tromkee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import "TStickerAnnotationView.h"

@interface TStickerAnnotation : NSObject <MKAnnotation>

- (id)initWithObject:(PFObject *)aObject;

@property (nonatomic, strong) PFObject* annotationObject;
@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;
@property (nonatomic, strong) TStickerAnnotationView* calloutAnnotation;

@end

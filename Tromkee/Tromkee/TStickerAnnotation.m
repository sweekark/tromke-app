//
//  TStickerAnnotation.m
//  Tromke
//
//  Created by Satyanarayana SVV on 2/7/14.
//  Copyright (c) 2014 Tromkee. All rights reserved.
//

#import "TStickerAnnotation.h"

@implementation TStickerAnnotation

- (id)initWithObject:(PFObject *)aObject {
    self = [super init];
    if (self) {
        
        PFGeoPoint *geoPoint = aObject[@"location"];
        [self setGeoPoint:geoPoint];
    }
    return self;
}


#pragma mark - MKAnnotation

// Called when the annotation is dragged and dropped. We update the geoPoint with the new coordinates.
- (void)setCoordinate:(CLLocationCoordinate2D)newCoordinate {
    _coordinate = newCoordinate;
}


#pragma mark - ()

- (void)setGeoPoint:(PFGeoPoint *)geoPoint {
    _coordinate = CLLocationCoordinate2DMake(geoPoint.latitude, geoPoint.longitude);
    
    _title = @"";
    _subtitle = @"";
}

@end

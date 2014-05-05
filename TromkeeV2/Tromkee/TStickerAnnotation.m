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
        PFGeoPoint *geoPoint = aObject[POST_LOCATION];
        [self setGeoPoint:geoPoint];
        self.annotationObject = aObject;
        if (aObject[POST_DATA]) {
            self.title = aObject[POST_DATA];
        } else {
            PFUser* postedUser = aObject[POST_FROMUSER];
            if ([aObject[POST_TYPE] isEqualToString:POST_TYPE_ASK]) {
                self.title = [NSString stringWithFormat:@"%@ asking question", postedUser[@"displayName"]];
            } else if ([aObject[POST_TYPE] isEqualToString:POST_TYPE_IMAGE]) {
                self.title = [NSString stringWithFormat:@"%@ posted image", postedUser[@"displayName"]];
            } else if ([aObject[POST_TYPE] isEqualToString:POST_TYPE_STICKER]) {
                self.title = [NSString stringWithFormat:@"%@ posted sticker", postedUser[@"displayName"]];
            }
        }
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
}

@end

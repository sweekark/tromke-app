//
//  TStickerAnnotation.m
//  Tromke
//
//  Created by Satyanarayana SVV on 2/7/14.
//  Copyright (c) 2014 Tromkee. All rights reserved.
//

#import "TStickerAnnotation.h"

@interface TStickerAnnotation()
@property (nonatomic, strong) PFObject *object;
@end

@implementation TStickerAnnotation

- (id)initWithObject:(PFObject *)aObject {
    self = [super init];
    if (self) {
        _object = aObject;
        
        PFGeoPoint *geoPoint = self.object[@"location"];
        [self setGeoPoint:geoPoint];
    }
    return self;
}


#pragma mark - MKAnnotation

// Called when the annotation is dragged and dropped. We update the geoPoint with the new coordinates.
- (void)setCoordinate:(CLLocationCoordinate2D)newCoordinate {
    _coordinate = newCoordinate;
//    PFGeoPoint *geoPoint = [PFGeoPoint geoPointWithLatitude:newCoordinate.latitude longitude:newCoordinate.longitude];
//    [self setGeoPoint:geoPoint];
//    [self.object setObject:geoPoint forKey:@"location"];
//    [self.object saveEventually:^(BOOL succeeded, NSError *error) {
//        if (succeeded) {
//            // Send a notification when this geopoint has been updated. MasterViewController will be listening for this notification, and will reload its data when this notification is received.
//            [[NSNotificationCenter defaultCenter] postNotificationName:@"geoPointAnnotiationUpdated" object:self.object];
//        }
//    }];
}


#pragma mark - ()

- (void)setGeoPoint:(PFGeoPoint *)geoPoint {
    _coordinate = CLLocationCoordinate2DMake(geoPoint.latitude, geoPoint.longitude);
    
    _title = @"";
    _subtitle = @"";
}

@end

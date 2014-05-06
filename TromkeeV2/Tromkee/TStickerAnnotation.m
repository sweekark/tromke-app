//
//  TStickerAnnotation.m
//  Tromke
//
//  Created by Satyanarayana SVV on 2/7/14.
//  Copyright (c) 2014 Tromkee. All rights reserved.
//

#import "TStickerAnnotation.h"

@interface TStickerAnnotation ()

@property (nonatomic, assign) MKPinAnnotationColor pinColor;

@end

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

static NSString * const kPAWWallCantViewPost = @"Can’t view post! Get closer.";

- (void)setTitleAndSubtitleOutsideDistance:(BOOL)outside {
	if (outside) {
		self.title = kPAWWallCantViewPost;
		self.pinColor = MKPinAnnotationColorRed;
	} else {
        PFUser* postedUser = self.annotationObject[POST_FROMUSER];
        if ([self.annotationObject[POST_TYPE] isEqualToString:POST_TYPE_ASK]) {
            self.title = [NSString stringWithFormat:@"%@ asking question", postedUser[@"displayName"]];
        } else if ([self.annotationObject[POST_TYPE] isEqualToString:POST_TYPE_IMAGE]) {
            self.title = [NSString stringWithFormat:@"%@ posted image", postedUser[@"displayName"]];
        } else if ([self.annotationObject[POST_TYPE] isEqualToString:POST_TYPE_STICKER]) {
            self.title = [NSString stringWithFormat:@"%@ posted sticker", postedUser[@"displayName"]];
        }
        
		self.pinColor = MKPinAnnotationColorGreen;
	}
}

- (BOOL)equalToPost:(TStickerAnnotation *)aPost {
	if (aPost == nil) {
		return NO;
	}
    
	if (aPost.annotationObject && self.annotationObject) {
		// We have a PFObject inside the PAWPost, use that instead.
		if ([aPost.annotationObject.objectId compare:self.annotationObject.objectId] != NSOrderedSame) {
			return NO;
		}
        
		return YES;
	}
    
    return YES;
}

@end

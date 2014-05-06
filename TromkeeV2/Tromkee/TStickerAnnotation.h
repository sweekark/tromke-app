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


@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;
@property (nonatomic, copy) NSString* title;



@property (nonatomic, strong) PFObject* annotationObject;
@property (nonatomic, strong) TStickerAnnotationView* calloutAnnotation;
@property (nonatomic, assign) BOOL animatesDrop;
@property (nonatomic, readonly) MKPinAnnotationColor pinColor;

- (id)initWithObject:(PFObject *)aObject;
- (void)setTitleAndSubtitleOutsideDistance:(BOOL)outside;
- (BOOL)equalToPost:(TStickerAnnotation *)aPost;

@end

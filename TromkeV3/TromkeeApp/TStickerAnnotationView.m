//
//  TStickerAnnotationView.m
//  Tromke
//
//  Created by Satyanarayana SVV on 2/16/14.
//  Copyright (c) 2014 Tromkee. All rights reserved.
//

#import "TStickerAnnotationView.h"
#import "TCircleView.h"

@interface TStickerAnnotationView () {
    UIImageView *_imageView;
    TCircleView *_circleView;
}


@end

@implementation TStickerAnnotationView

-(id)initWithAnnotation:(id<MKAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];

    if (self) {
        // make sure the x and y of the CGRect are half it's
        // width and height, so the callout shows when user clicks
        // in the middle of the image
        CGRect  viewRect = CGRectMake(-20, -20, 40, 40);
        
        TCircleView* circleView = [[TCircleView alloc] initWithFrame:viewRect];
        _circleView = circleView;
        [self addSubview:circleView];
        
        UIImageView* imageView = [[UIImageView alloc] initWithFrame:viewRect];
        
        // keeps the image dimensions correct
        // so if you have a rectangle image, it will show up as a rectangle,
        // instead of being resized into a square
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        
        _imageView = imageView;
        
        [self addSubview:imageView];
    }

    return self;
}


- (void)setImage:(UIImage *)image
{
    // when an image is set for the annotation view,
    // it actually adds the image to the image view
    _imageView.image = image;
}

- (void)setStickerColor:(float)color {
    _circleView.green = color;
    [_circleView setNeedsDisplay];
}


@end

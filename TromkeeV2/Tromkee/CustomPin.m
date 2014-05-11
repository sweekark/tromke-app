//
//  CustomPin.m
//  MapView
//
//  Created by admin on 10/06/14.
//  Copyright (c) 2014 codigator. All rights reserved.
//

#import "CustomPin.h"

@interface CustomPin ()

@property (weak, nonatomic) IBOutlet TCircleView *labelBackground;

@end

@implementation CustomPin

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        self.backgroundColor = [UIColor redColor];
        
        // Initialization code
    }
    return self;
}


- (void)setStickerColor:(float)color {
    _circleView.green = _labelBackground.green = color;
    [_circleView setNeedsDisplay];
    [_labelBackground setNeedsDisplay];
}


//-(id)initWithAnnotation:(id<MKAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier{
//
//
//    return self;
//}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end

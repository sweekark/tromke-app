//
//  TCircleView.m
//  Tromke
//
//  Created by Satyanarayana SVV on 1/25/14.
//  Copyright (c) 2014 Tromkee. All rights reserved.
//

#import "TCircleView.h"

@implementation TCircleView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.backgroundColor = [UIColor clearColor];
        self.green = 0.0;
        self.opacity = 1.0;        
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Initialization code
        self.backgroundColor = [UIColor clearColor];
        self.green = 0.0;
        self.opacity = 1.0;
    }
    
    return self;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
//    CGRect borderRect = CGRectMake(0.0, 0.0, 60.0, 60.0);
    CGRect borderRect = CGRectMake(0.0, 0.0, self.frame.size.width, self.frame.size.height);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetRGBStrokeColor(context, 1.0, 1.0, 1.0, 1.0);
    CGContextSetRGBFillColor(context, 1.0 - self.green, self.green, 0.0, self.opacity);
    CGContextSetLineWidth(context, 2.0);
    CGContextFillEllipseInRect (context, borderRect);
    CGContextStrokeEllipseInRect(context, borderRect);
    CGContextFillPath(context);
}

@end

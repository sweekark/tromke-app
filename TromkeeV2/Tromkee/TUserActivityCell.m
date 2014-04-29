//
//  TUserActivityCell.m
//  Tromke
//
//  Created by Satyanarayana SVV on 4/11/14.
//  Copyright (c) 2014 Tromkee. All rights reserved.
//

#import "TUserActivityCell.h"

@implementation TUserActivityCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (IBAction)showProfile:(id)sender {
    [self.delegate showProfile:self.rowNumber];
}


@end

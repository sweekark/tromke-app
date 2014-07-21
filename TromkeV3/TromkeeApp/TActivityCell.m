//
//  TActivityCell.m
//  Tromke
//
//  Created by Satyanarayana SVV on 2/17/14.
//  Copyright (c) 2014 Tromkee. All rights reserved.
//

#import "TActivityCell.h"

@implementation TActivityCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (IBAction)showProfileOfUser:(id)sender {
    [self.delegate showProfileFromActivity:self.tag];
}

@end

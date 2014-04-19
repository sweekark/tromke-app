//
//  TPostCell.m
//  Tromke
//
//  Created by Satyanarayana SVV on 4/17/14.
//  Copyright (c) 2014 Tromkee. All rights reserved.
//

#import "TPostCell.h"
#import "TCircleView.h"

@interface TPostCell ()

@property (weak, nonatomic) IBOutlet PFImageView *fromImage;
@property (weak, nonatomic) IBOutlet UILabel *fromName;
@property (weak, nonatomic) IBOutlet UILabel *fromPostedTime;
@property (weak, nonatomic) IBOutlet UILabel *fromPostedMessage;
@property (weak, nonatomic) IBOutlet PFImageView *fromStickerImage;
@property (weak, nonatomic) IBOutlet TCircleView *fromStickerIntensity;
@property (weak, nonatomic) IBOutlet UILabel* postedLocation;
@property (weak, nonatomic) IBOutlet PFImageView* postImage;

@end

@implementation TPostCell

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

-(void)update:(PFObject*)stickerObject {
    PFUser* user = stickerObject[@"fromUser"];
    PFFile *imageFile = [user objectForKey:FACEBOOK_SMALLPIC_KEY];
    self.fromImage.image = [UIImage imageNamed:@"Personholder"];
    if (imageFile) {
        NSLog(@"Showing sticker user image");
        [self.fromImage setFile:imageFile];
        [self.fromImage loadInBackground];
    } else {
        NSLog(@"No image found");
    }
    
    self.fromName.text = user[@"displayName"];
    self.fromPostedTime.text = [TUtility computePostedTime:stickerObject.updatedAt];
    self.fromPostedMessage.text = stickerObject[@"data"];
    //                [weakSelf.fromPostedMessage sizeToFit];
    //Compute Thanks objects posted
    
    PFObject* stickerObj = stickerObject[@"sticker"];
    
    PFFile* stickerImage = stickerObj[@"image"];
    if (stickerImage) {
        self.fromStickerImage.file = stickerImage;
        [self.fromStickerImage loadInBackground];
    }
    
    self.fromStickerIntensity.green = [stickerObject[@"severity"] floatValue];
    [self.fromStickerIntensity setNeedsDisplay];
    
    PFObject* images = stickerObject[@"images"];
    if (images) {
        PFFile* imgFile = images[@"image"];
        if (imgFile) {
            self.postImage.file = imgFile;
            [self.postImage loadInBackground];
        }
    }
}

- (IBAction)tellThanks:(id)sender {
    self.thanksButton.userInteractionEnabled = NO;
    [self.thanksButton setTitle:@"Thanked" forState:UIControlStateNormal];
    int totalThanks = [self.totalThanks.text intValue];
    self.totalThanks.text = [NSString stringWithFormat:@"%d", ++totalThanks];
    [self.delegate conveyThanks];
}

@end

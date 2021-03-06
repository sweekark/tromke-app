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
@property (weak, nonatomic) IBOutlet PFImageView *fromStickerImage;
@property (weak, nonatomic) IBOutlet TCircleView *fromStickerIntensity;
@property (weak, nonatomic) IBOutlet PFImageView* postImage;
@property (nonatomic, strong) PFGeoPoint* postLocation;

@property (weak, nonatomic) IBOutlet UILabel *stickerName;
@property (weak, nonatomic) IBOutlet UILabel *fromName;
@property (weak, nonatomic) IBOutlet UILabel *fromPostedTime;
@property (weak, nonatomic) IBOutlet UILabel *fromPostedMessage;
@property (weak, nonatomic) IBOutlet UILabel* postedLocation;
@property (weak, nonatomic) IBOutlet UILabel* postedByLabel;

@property (weak, nonatomic) IBOutlet UIButton* flagButton;
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

-(void)update:(PFObject*)postObj {
    
    BOOL flag = [postObj[ACTIVITY_INAPPROPRIATE] boolValue];
    if (flag) {
        self.flagButton.userInteractionEnabled = NO;
        [self.flagButton setImage:[UIImage imageNamed:@"RedFlag"] forState:UIControlStateNormal];
    } else {
        self.flagButton.userInteractionEnabled = YES;
        [self.flagButton setImage:[UIImage imageNamed:@"WhiteFlag"] forState:UIControlStateNormal];
    }

    
    PFUser* user = postObj[POST_FROMUSER];
    PFFile *imageFile = [user objectForKey:FACEBOOK_SMALLPIC_KEY];
    self.fromImage.image = [UIImage imageNamed:@"Personholder"];
    if (imageFile) {
        [self.fromImage setFile:imageFile];
        [self.fromImage loadInBackground];
    }
    self.fromName.text = [TUtility getDisplayNameForUser:user];
    self.fromName.textColor = [TUtility colorFromHexString:USERNAME_COLOR];
    
    self.fromPostedTime.text = [TUtility computePostedTime:postObj.createdAt];
    self.fromPostedMessage.text = postObj[POST_DATA];
    self.postedLocation.text = [NSString stringWithFormat:@"@ %@", postObj[POST_USERLOCATION]];
    
    self.postLocation = postObj[POST_LOCATION];
    
    NSString* stickerType = postObj[POST_TYPE];
    if ([stickerType isEqualToString:POST_TYPE_STICKER]) {
        PFObject* stickerObj = postObj[STICKER];
        PFFile* stickerImage = stickerObj[STICKER_IMAGE];
        if (stickerImage) {
            self.fromStickerImage.file = stickerImage;
            [self.fromStickerImage loadInBackground];
        }
        
        self.fromStickerIntensity.green = [postObj[STICKER_SEVERITY] floatValue];
        [self.fromStickerIntensity setNeedsDisplay];
        
        self.stickerName.text = stickerObj[STICKER_NAME];
    } else if ([stickerType isEqualToString:POST_TYPE_ASK]) {

    } else if ([stickerType isEqualToString:POST_TYPE_IMAGE]) {
        PFFile* imgFile = postObj[POST_ORIGINAL_IMAGE];
        if (imgFile) {
            self.postImage.file = imgFile;
            [self.postImage loadInBackground];
        }
    }
}

- (IBAction)tellThanks:(id)sender {
    self.thanksButton.userInteractionEnabled = NO;
    [self.thanksButton setTitle:@"Liked" forState:UIControlStateNormal];
    int totalThanks = [self.totalThanks.text intValue];
    self.totalThanks.text = [NSString stringWithFormat:@"%d", ++totalThanks];
    [self.delegate conveyThanks];
}

- (IBAction)showLocation:(id)sender {
    [self.delegate showLocationOfActivity:self.postLocation];
}

-(void)showLabelsForQuestion {
    self.fromPostedTime.textColor = self.fromPostedMessage.textColor = self.postedLocation.textColor = self.postedByLabel.textColor = [UIColor whiteColor];
    
}

- (IBAction)showProfileOfUser:(id)sender {
    [self.delegate showProfileFromPost];
}

@end

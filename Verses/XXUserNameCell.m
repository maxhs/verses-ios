//
//  XXUserNameCell.m
//  Verses
//
//  Created by Max Haines-Stiles on 11/4/13.
//  Copyright (c) 2013 Verses. All rights reserved.
//

#import "XXUserNameCell.h"
#import <SDWebImage/UIButton+WebCache.h>
#import "Constants.h"

@implementation XXUserNameCell

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

- (void)configureCell:(User*)user {
    [self.nameLabel setText:user.penName];
    [self.nameLabel setFont:[UIFont fontWithName:kSourceSansProSemibold size:18]];
    [self.nameLabel setTextColor:[UIColor whiteColor]];
    [self.storyLabel setText:[NSString stringWithFormat:@"%@ stories  |  %lu contacts",user.storyCount,(unsigned long)user.contacts.count]];
    [self.storyLabel setFont:[UIFont fontWithName:kSourceSansProRegular size:14]];
    

    self.userPhotoButton.imageView.layer.shouldRasterize = YES;
    self.userPhotoButton.imageView.layer.rasterizationScale = [UIScreen mainScreen].scale;
    [self.userPhotoButton sd_setImageWithURL:[NSURL URLWithString:user.picSmall] forState:UIControlStateNormal completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        [self.userPhotoButton setImage:image forState:UIControlStateNormal];
        [UIView animateWithDuration:.25 animations:^{
            [self.userPhotoButton setAlpha:1.0];
        }];
    }];
}
@end

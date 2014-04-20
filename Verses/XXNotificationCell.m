//
//  XXNotificationCell.m
//  Verses
//
//  Created by Max Haines-Stiles on 11/4/13.
//  Copyright (c) 2013 Verses. All rights reserved.
//

#import "XXNotificationCell.h"
#import <SDWebImage/UIButton+WebCache.h>

@implementation XXNotificationCell

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

- (void)configureCell:(XXNotification*)notification {
    self.userPhotoButton.imageView.layer.cornerRadius = self.userPhotoButton.frame.size.width/2;
    [self.userPhotoButton.imageView setBackgroundColor:[UIColor clearColor]];
    self.userPhotoButton.layer.shouldRasterize = YES;
    self.userPhotoButton.layer.rasterizationScale = [UIScreen mainScreen].scale;
    [self.messageLabel setText:notification.message];
    [self.messageLabel setFont:[UIFont fontWithName:kSourceSansProRegular size:14]];
    XXPhoto *firstPhoto = [notification.photos firstObject];
    if (firstPhoto){
        CGRect rect = self.messageLabel.frame;
        CGFloat initialX = self.messageLabel.frame.origin.x;
        rect.origin.x = 43;
        rect.size.width -= initialX - 43;
        [self.messageLabel setFrame:rect];
        [self.userPhotoButton setImageWithURL:firstPhoto.imageSmallUrl forState:UIControlStateNormal completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
            [self.userPhotoButton setImage:image forState:UIControlStateNormal];
            [UIView animateWithDuration:.25 animations:^{
                [self.userPhotoButton setAlpha:1.0];
            }];
        }];
    }
    [self.monthLabel setText:notification.createdMonth];
    [self.monthLabel setFont:[UIFont fontWithName:kSourceSansProRegular size:12]];
    
    [self.timeLabel setText:notification.createdTime];
    [self.timeLabel setFont:[UIFont fontWithName:kSourceSansProRegular size:12]];
    [UIView animateWithDuration:.25 animations:^{
        [self.messageLabel setAlpha:1.0];
        [self.timeLabel setAlpha:1.0];
        [self.monthLabel setAlpha:1.0];
    }];
}

@end

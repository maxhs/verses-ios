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

- (void)configureCell:(Notification*)notification {
    [_messageLabel setText:notification.message];
    if (IDIOM == IPAD){
        [_messageLabel setFont:[UIFont fontWithName:kSourceSansProRegular size:16]];
    } else {
        [_messageLabel setFont:[UIFont fontWithName:kSourceSansProRegular size:14]];
    }
    
    /*Photo *firstPhoto = [notification.photos firstObject];
    if (firstPhoto){
        CGRect rect = _messageLabel.frame;
        CGFloat initialX = _messageLabel.frame.origin.x;
        rect.origin.x = 43;
        rect.size.width -= initialX - 43;
        [_messageLabel setFrame:rect];
        [_userPhotoButton setImageWithURL:firstPhoto.imageSmallUrl forState:UIControlStateNormal completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
            [_userPhotoButton setImage:image forState:UIControlStateNormal];
            [UIView animateWithDuration:.25 animations:^{
                [_userPhotoButton setAlpha:1.0];
            }];
        }];
    }*/
    
    [_monthLabel setFont:[UIFont fontWithName:kSourceSansProRegular size:12]];
    
    [_timeLabel setFont:[UIFont fontWithName:kSourceSansProRegular size:12]];
    [UIView animateWithDuration:.25 animations:^{
        [_messageLabel setAlpha:1.0];
        [_timeLabel setAlpha:1.0];
        [_monthLabel setAlpha:1.0];
    }];
    _messageLabel.layer.rasterizationScale = [UIScreen mainScreen].scale;
    _messageLabel.layer.shouldRasterize = YES;
    _timeLabel.layer.rasterizationScale = [UIScreen mainScreen].scale;
    _timeLabel.layer.shouldRasterize = YES;
    _monthLabel.layer.rasterizationScale = [UIScreen mainScreen].scale;
    _monthLabel.layer.shouldRasterize = YES;
}

@end

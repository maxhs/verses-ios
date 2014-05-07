//
//  XXCircleCell.m
//  Verses
//
//  Created by Max Haines-Stiles on 3/16/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import "XXCircleCell.h"

@implementation XXCircleCell

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
- (void)configureCell:(XXCircle*)circle withTextColor:(UIColor *)textColor {
    [_circleName setText:circle.name];
    [_circleName setFont:[UIFont fontWithName:kCrimsonRoman size:24]];
    [_circleName setTextColor:textColor];
    if (circle.titles.length){
        [_infoLabel setText:circle.titles];
        [_infoLabel setFont:[UIFont fontWithName:kSourceSansProRegular size:15]];
        [_infoLabel setTextColor:textColor];
    } else {
        [_infoLabel setText:@"No stories..."];
        [_infoLabel setFont:[UIFont fontWithName:kSourceSansProItalic size:15]];
        if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
            [_infoLabel setTextColor:textColor];
        } else {
            [_infoLabel setTextColor:[UIColor lightGrayColor]];
        }
    }
    
    if (circle.unreadCommentCount == 0){
        [_unreadLabel setText:@""];
        [_unreadLabel setHidden:YES];
    } else {
        [_unreadLabel setText:[NSString stringWithFormat:@"%d",circle.unreadCommentCount]];
        [_unreadLabel setHidden:NO];
        CGRect unreadFrame = _unreadLabel.frame;
        if (unreadFrame.origin.x <= 5.f){
            CGRect expectedSize = [_circleName.text boundingRectWithSize:_circleName.frame.size options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:_circleName.font} context:nil];
            unreadFrame.origin.x += expectedSize.size.width;
            [_unreadLabel setFrame:unreadFrame];
            [_unreadLabel setBackgroundColor:[UIColor redColor]];
            [_unreadLabel setTextColor:[UIColor whiteColor]];
            [_unreadLabel setFont:[UIFont fontWithName:kSourceSansProRegular size:14]];
            [_unreadLabel.layer setBackgroundColor:[UIColor clearColor].CGColor];
            _unreadLabel.layer.cornerRadius = _unreadLabel.frame.size.height/2;
            [_unreadLabel setTextAlignment:NSTextAlignmentCenter];
        }
        _unreadLabel.layer.rasterizationScale = [UIScreen mainScreen].scale;
        _unreadLabel.layer.shouldRasterize = YES;
    }
}

@end

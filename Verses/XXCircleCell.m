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
    
    int count = circle.unreadCommentCount;
    if (circle.fresh) count ++;
    
    if (count == 0){
        [_alertLabel setText:@""];
        [_alertLabel setHidden:YES];
    } else {
        [_alertLabel setText:[NSString stringWithFormat:@"%d",count]];
        [_alertLabel setHidden:NO];
        CGRect unreadFrame = _alertLabel.frame;
        CGRect expectedSize = [_circleName.text boundingRectWithSize:_circleName.frame.size options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:_circleName.font} context:nil];
        unreadFrame.origin.x = expectedSize.size.width;
        [_alertLabel setFrame:unreadFrame];
        [_alertLabel setBackgroundColor:[UIColor redColor]];
        [_alertLabel setTextColor:[UIColor whiteColor]];
        [_alertLabel setFont:[UIFont fontWithName:kSourceSansProRegular size:14]];
        [_alertLabel.layer setBackgroundColor:[UIColor clearColor].CGColor];
        _alertLabel.layer.cornerRadius = _alertLabel.frame.size.height/2;
        [_alertLabel setTextAlignment:NSTextAlignmentCenter];
        _alertLabel.layer.rasterizationScale = [UIScreen mainScreen].scale;
        _alertLabel.layer.shouldRasterize = YES;
    }
}

@end

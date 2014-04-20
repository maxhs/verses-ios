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
    [self.circleName setText:circle.name];
    [self.circleName setFont:[UIFont fontWithName:kCrimsonRoman size:23]];
    [self.circleName setTextColor:textColor];
    [self.infoLabel setText:circle.titles];
    [self.infoLabel setFont:[UIFont fontWithName:kSourceSansProRegular size:15]];
    [self.infoLabel setTextColor:textColor];
    
    if (circle.circleDescription.length) {
        [self.descriptionTextView setText:circle.circleDescription];
        [self.descriptionTextView setFont:[UIFont fontWithName:kCrimsonRoman size:15]];
        [self.descriptionTextView setTextColor:textColor];
    } else {
        [self.descriptionTextView setText:@""];
    }
    
    if (circle.unreadCommentCount == 0){
        [self.unreadLabel setText:@""];
        [self.unreadLabel setHidden:YES];
    } else {
        [self.unreadLabel setText:[NSString stringWithFormat:@"%d",circle.unreadCommentCount]];
        [self.unreadLabel setHidden:NO];
        CGRect unreadFrame = self.unreadLabel.frame;
        if (unreadFrame.origin.x <= 5.f){
            CGRect expectedSize = [self.circleName.text boundingRectWithSize:self.circleName.frame.size options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:self.circleName.font} context:nil];
            unreadFrame.origin.x += expectedSize.size.width;
            [self.unreadLabel setFrame:unreadFrame];
            [self.unreadLabel setBackgroundColor:[UIColor redColor]];
            [self.unreadLabel setTextColor:[UIColor whiteColor]];
            [self.unreadLabel setFont:[UIFont fontWithName:kSourceSansProRegular size:14]];
            [self.unreadLabel.layer setBackgroundColor:[UIColor clearColor].CGColor];
            self.unreadLabel.layer.cornerRadius = self.unreadLabel.frame.size.height/2;
            self.unreadLabel.layer.rasterizationScale = [UIScreen mainScreen].scale;
            self.unreadLabel.layer.shouldRasterize = YES;
            [self.unreadLabel setTextAlignment:NSTextAlignmentCenter];
        }
        
       
    }
}

@end

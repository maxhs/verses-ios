//
//  XXProfileStoryCell.m
//  Verses
//
//  Created by Max Haines-Stiles on 4/14/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import "XXProfileStoryCell.h"

@implementation XXProfileStoryCell

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

- (void)configureStory:(XXStory *)story withTextColor:(UIColor*)textColor {
    [self.titleLabel setText:story.title];
    [self.titleLabel setTextColor:textColor];
    [self.titleLabel setFont:[UIFont fontWithName:kCrimsonRoman size:23]];
}

@end
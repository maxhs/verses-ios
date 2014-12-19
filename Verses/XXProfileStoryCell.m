//
//  XXProfileStoryCell.m
//  Verses
//
//  Created by Max Haines-Stiles on 4/14/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import "XXProfileStoryCell.h"
#import "Story+helper.h"
#import "Constants.h"

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

- (void)configureStory:(Story *)story withTextColor:(UIColor*)textColor {
    [self.titleLabel setText:story.title];
    [self.titleLabel setTextColor:textColor];
    [self.titleLabel setFont:[UIFont fontWithName:kSourceSansProSemibold size:27]];
    [self.subtitleLabel setTextColor:textColor];
    [self.subtitleLabel setFont:[UIFont fontWithName:kCrimsonRoman size:18]];
}

@end

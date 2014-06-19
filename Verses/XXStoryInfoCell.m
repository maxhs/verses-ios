//
//  XXStoryInfoCell.m
//  Verses
//
//  Created by Max Haines-Stiles on 2/25/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import "XXStoryInfoCell.h"

@implementation XXStoryInfoCell

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

- (void)configureForStory:(Story*)story {
    [self.storyTitle setText:story.title];
    [self.storyTitle setFont:[UIFont fontWithName:kSourceSansProSemibold size:27]];
    [self.lastUpdatedAt setFont:[UIFont fontWithName:kCrimsonRoman size:15]];
    
    if (story.views){
        [self.viewsLabel setText:[NSString stringWithFormat:@"%@ views",story.views]];
        [self.viewsLabel setFont:[UIFont fontWithName:kCrimsonRoman size:15]];
    }
}

@end

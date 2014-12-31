//
//  XXSearchCell.m
//  Verses
//
//  Created by Max Haines-Stiles on 3/24/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import "XXSearchCell.h"
#import "Constants.h"

@implementation XXSearchCell

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

- (void)configure:(Story *)story {
    [_storyTitle setFont:[UIFont fontWithName:kSourceSansPro size:19]];
    [_storyTitle setText:story.title];
    [_authorLabel setFont:[UIFont fontWithName:kSourceSansPro size:15]];
    [_authorLabel setText:story.authorNames];
}
@end

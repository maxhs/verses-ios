//
//  XXWritingTitleCell.m
//  Verses
//
//  Created by Max Haines-Stiles on 4/24/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import "XXWritingTitleCell.h"

@implementation XXWritingTitleCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)configure:(XXStory*)story withOrientation:(UIInterfaceOrientation)orientation {
    [_titleTextField setFont:[UIFont fontWithName:kSourceSansProSemibold size:31]];
    [_titleTextField setPlaceholder:kTitlePlaceholder];
    if (story.title.length) {
        [_titleTextField setText:story.title];
    } else {
        [_titleTextField setText:@""];
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end

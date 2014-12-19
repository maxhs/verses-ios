//
//  XXDraftCell.m
//  Verses
//
//  Created by Max Haines-Stiles on 3/16/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import "XXDraftCell.h"
#import "Constants.h"

@implementation XXDraftCell

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

- (void)configure:(Story*)story {
    if (story.title.length){
        [self.titleLabel setText:story.title];
        [self.titleLabel setTextColor:[UIColor blackColor]];
    } else {
        [self.titleLabel setText:@""];
        [self.titleLabel setTextColor:[UIColor lightGrayColor]];
    }
    [self.titleLabel setFont:[UIFont fontWithName:kCrimsonRoman size:27]];
    [self.lastUpdatedLabel setFont:[UIFont fontWithName:kSourceSansProLight size:15]];
    [self.wordCountLabel setFont:[UIFont fontWithName:kSourceSansProLight size:15]];
}

@end

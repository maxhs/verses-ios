//
//  XXCircleDetailsCell.m
//  Verses
//
//  Created by Max Haines-Stiles on 4/18/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import "XXCircleDetailsCell.h"
#import "Constants.h"

@implementation XXCircleDetailsCell

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
- (void)configureWithTextColor:(UIColor *)textColor {
    [self.headingLabel setTextColor:textColor];
    [self.headingLabel setFont:[UIFont fontWithName:kSourceSansPro size:13]];
    [self.contentLabel setTextColor:textColor];
    [self.contentLabel setFont:[UIFont fontWithName:kSourceSansPro size:16]];
}
@end

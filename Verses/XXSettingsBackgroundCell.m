//
//  XXSettingsBackgroundCell.m
//  Verses
//
//  Created by Max Haines-Stiles on 7/1/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import "XXSettingsBackgroundCell.h"

@implementation XXSettingsBackgroundCell

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
    [super awakeFromNib];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end

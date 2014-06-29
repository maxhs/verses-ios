//
//  XXNothingCell.m
//  Verses
//
//  Created by Max Haines-Stiles on 6/27/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import "XXNothingCell.h"

@implementation XXNothingCell

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

@end

//
//  XXBookmarkCell.m
//  Verses
//
//  Created by Max Haines-Stiles on 3/26/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import "XXBookmarkCell.h"

@implementation XXBookmarkCell

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
}

- (void)configureBookmark:(XXBookmark*)bookmark {
    [self.bookmarkLabel setText:bookmark.story.title];
    [self.bookmarkLabel setFont:[UIFont fontWithName:kSourceSansProSemibold size:21]];
    [self.createdLabel setFont:[UIFont fontWithName:kCrimsonRoman size:18]];
}
@end

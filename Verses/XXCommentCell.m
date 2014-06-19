//
//  XXCommentCell.m
//  Verses
//
//  Created by Max Haines-Stiles on 3/28/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import "XXCommentCell.h"

@implementation XXCommentCell

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
-(void)configureComment:(Comment*)comment{
    [_commentLabel setFont:[UIFont fontWithName:kCrimsonRoman size:17]];
    NSString *commentText = [NSString stringWithFormat:@"\"%@\"",comment.body];
    [_commentLabel setText:commentText];
    [_timestampLabel setFont:[UIFont fontWithName:kSourceSansProLight size:15]];
    [_separatorView setBackgroundColor:kSeparatorColor];
}

@end

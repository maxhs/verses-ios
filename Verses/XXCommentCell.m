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
-(void)configureComment:(XXComment*)comment{
     [self.commentLabel setFont:[UIFont fontWithName:kCrimsonRoman size:19]];
    NSString *commentText = [NSString stringWithFormat:@"\"%@\"\n   - %@",comment.body,comment.user.penName];
    [self.commentLabel setText:commentText];
    [self.timestampLabel setFont:[UIFont fontWithName:kSourceSansProRegular size:15]];
}

@end

//
//  XXFeedbackCell.m
//  Verses
//
//  Created by Max Haines-Stiles on 3/16/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import "XXFeedbackCell.h"

@implementation XXFeedbackCell

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

- (void)configure:(XXFeedback*)feedback textColor:(UIColor*)color{
    [self.titleLabel setTextColor:color];
    [self.titleLabel setFont:[UIFont fontWithName:kCrimsonRoman size:27]];
    [self.messageLabel setText:[feedback.comments.firstObject body]];
    [self.messageLabel setTextColor:color];
    [self.messageLabel setFont:[UIFont fontWithName:kSourceSansProLight size:16]];
    if (feedback.snippet.length){
        [self.snippetTextView setHidden:NO];
        [self.snippetTextView setText:[NSString stringWithFormat:@"\"%@\"",feedback.snippet]];
        [self.snippetTextView setFont:[UIFont fontWithName:kCrimsonRoman size:18]];
    } else {
        [self.snippetTextView setHidden:YES];
    }
    [self.snippetTextView setTextColor:color];
}

@end

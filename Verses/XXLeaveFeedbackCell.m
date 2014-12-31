//
//  XXLeaveFeedbackCell.m
//  Verses
//
//  Created by Max Haines-Stiles on 3/23/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import "XXLeaveFeedbackCell.h"
#import "Constants.h"

@implementation XXLeaveFeedbackCell

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

- (void)configure {
    [self.feedbackTextView setText:kFeedbackPlaceholder];
    //self.feedbackTextView.layer.borderColor = [UIColor colorWithWhite:1 alpha:1].CGColor;
    //self.feedbackTextView.layer.borderWidth = 1.f;
    self.feedbackTextView.layer.cornerRadius = 2.f;
    self.feedbackTextView.clipsToBounds = YES;
    [self.feedbackTextView setFont:[UIFont fontWithName:kSourceSansProLight size:16]];
    [self.cancelButton.titleLabel setFont:[UIFont fontWithName:kSourceSansPro size:15]];
    [_cancelButton addTarget:self action:@selector(cancelEditing) forControlEvents:UIControlEventTouchUpInside];
    [self.sendButton.titleLabel setFont:[UIFont fontWithName:kSourceSansPro size:15]];
}

- (void)cancelEditing {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CancelEditing" object:nil userInfo:nil];
}

@end

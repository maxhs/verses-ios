//
//  XXFeedbackResponseCell.m
//  Verses
//
//  Created by Max Haines-Stiles on 7/19/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import "XXAppDelegate.h"
#import "XXFeedbackResponseCell.h"

@implementation XXFeedbackResponseCell

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
    [self.feedbackTextView setText:kFeedbackResponsePlaceholder];
    //self.feedbackTextView.layer.borderColor = [UIColor colorWithWhite:1 alpha:1].CGColor;
    //self.feedbackTextView.layer.borderWidth = 1.f;
    self.feedbackTextView.layer.cornerRadius = 2.f;
    self.feedbackTextView.clipsToBounds = YES;
    [self.feedbackTextView setFont:[UIFont fontWithName:kSourceSansProLight size:16]];
    [self.cancelButton.titleLabel setFont:[UIFont fontWithName:kSourceSansProRegular size:15]];
    [self.sendButton.titleLabel setFont:[UIFont fontWithName:kSourceSansProRegular size:15]];
    
    [_cancelButton setHidden:YES];
    [_sendButton setHidden:YES];
}

@end

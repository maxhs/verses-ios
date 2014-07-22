//
//  XXFeedbackResponseCell.h
//  Verses
//
//  Created by Max Haines-Stiles on 7/19/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XXFeedbackResponseTextView.h"

@interface XXFeedbackResponseCell : UITableViewCell
@property (weak, nonatomic) IBOutlet XXFeedbackResponseTextView *feedbackTextView;
@property (weak, nonatomic) IBOutlet UIButton *sendButton;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
- (void)configure;
@end

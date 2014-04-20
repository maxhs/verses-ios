//
//  XXLeaveFeedbackCell.h
//  Verses
//
//  Created by Max Haines-Stiles on 3/23/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface XXLeaveFeedbackCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UITextView *feedbackTextView;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIButton *sendButton;
-(void)configure;
@end

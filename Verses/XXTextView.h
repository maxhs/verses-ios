//
//  XXTextView.h
//  Verses
//
//  Created by Max Haines-Stiles on 3/16/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XXContribution.h"

@protocol TextViewDelegate <UITextViewDelegate>

- (void)textViewDidBeginEditing:(UITextView *)textView;

@end

@interface XXTextView : UITextView <UITextInputDelegate, UITextViewDelegate>
@property id <TextViewDelegate> customDelegate;
@property (strong, nonatomic) UIInputView *keyboardView;
@property (strong, nonatomic) UIButton *feedbackButton;
@property (strong, nonatomic) UIButton *footnoteButton;
@property (strong, nonatomic) UIButton *headerButton;
@property (strong, nonatomic) UIButton *boldButton;
@property (strong, nonatomic) UIButton *italicsButton;
@property (strong, nonatomic) UIButton *underlineButton;
@property (strong, nonatomic) XXContribution *contribution;
@property BOOL keyboardEnabled;
@property BOOL feedbackEnabled;
- (void)setupButtons;

@end

//
//  XXWriteViewController.h
//  Verses
//
//  Created by Max Haines-Stiles on 10/11/13.
//  Copyright (c) 2013 Verses. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XXStoriesViewController.h"
#import "XXTextView.h"
#import "Story+helper.h"

@interface XXWriteViewController : UIViewController <UIScrollViewDelegate, UITextFieldDelegate, UITextViewDelegate>

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UITextField *titleTextField;
@property (strong, nonatomic) Story *story;
@property (strong, nonatomic) Contribution *contribution;
@property (weak, nonatomic) IBOutlet UIView *optionsContainerView;
@property (weak, nonatomic) IBOutlet UISwitch *inviteOnlySwitch;
@property (weak, nonatomic) IBOutlet UILabel *inviteOnlyLabel;
@property (weak, nonatomic) IBOutlet UISwitch *feedbackSwitch;
@property (weak, nonatomic) IBOutlet UILabel *feedbackLabel;
@property (weak, nonatomic) IBOutlet UISwitch *joinableSwitch;
@property (weak, nonatomic) IBOutlet UILabel *joinableLabel;
@property (weak, nonatomic) IBOutlet UISwitch *slowRevealSwitch;
@property (weak, nonatomic) IBOutlet UILabel *slowRevealLabel;
@property (weak, nonatomic) IBOutlet UISwitch *draftSwitch;
@property (weak, nonatomic) IBOutlet UILabel *draftLabel;
@property (weak, nonatomic) IBOutlet UIButton *doneOptionsButton;
@property (weak, nonatomic) IBOutlet UIButton *deleteButton;
@property (weak, nonatomic) IBOutlet UIButton *collaborateButton;
@property (strong, nonatomic) XXStoriesViewController *welcomeViewController;
@property BOOL mystery;
@property BOOL editMode;
- (IBAction)doneOptions;
- (IBAction)deleteStory;
- (IBAction)collaborate;
- (void)prepareStory;
@end

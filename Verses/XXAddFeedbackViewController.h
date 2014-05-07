//
//  XXAddFeedbackViewController.h
//  Verses
//
//  Created by Max Haines-Stiles on 5/2/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XXContribution.h"
#import "XXStoryViewController.h"

@interface XXAddFeedbackViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *sendButton;
@property (strong, nonatomic) NSString *snippet;
@property (strong, nonatomic) XXStory *story;
@property (strong, nonatomic) XXContribution *contribution;
@property (strong, nonatomic) XXStoryViewController *storyViewController;
@property (strong, nonatomic) UIColor *textColor;
@property (strong, nonatomic) NSNumber *stringLocation;

@end

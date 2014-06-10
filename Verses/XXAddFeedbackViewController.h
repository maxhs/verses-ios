//
//  XXAddFeedbackViewController.h
//  Verses
//
//  Created by Max Haines-Stiles on 5/2/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Contribution+helper.h"
#import "XXStoryViewController.h"

@interface XXAddFeedbackViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSString *snippet;
@property (strong, nonatomic) Story *story;
@property (strong, nonatomic) Contribution *contribution;
@property (strong, nonatomic) XXStoryViewController *storyViewController;
@property (strong, nonatomic) UIColor *textColor;
@property (strong, nonatomic) NSNumber *stringLocation;

@end

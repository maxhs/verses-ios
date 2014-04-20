//
//  XXStoryInfoViewController.h
//  Verses
//
//  Created by Max Haines-Stiles on 2/25/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XXStory.h"
#import "XXFeedbackCell.h"
#import "MSDynamicsDrawerViewController/MSDynamicsDrawerViewController.h"

@interface XXStoryInfoViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSMutableArray *feedbacks;
@property (strong, nonatomic) XXFeedback *feedback;
@property (strong, nonatomic) XXStory *story;
@property (nonatomic, weak) MSDynamicsDrawerViewController *dynamicsDrawerViewController;
@property (nonatomic, assign) MSPaneViewControllerType paneViewControllerType;
@property (strong, nonatomic) UIPopoverController *popover;
@end

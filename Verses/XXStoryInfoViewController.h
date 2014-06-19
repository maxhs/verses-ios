//
//  XXStoryInfoViewController.h
//  Verses
//
//  Created by Max Haines-Stiles on 2/25/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Story+helper.h"
#import "XXFeedbackCell.h"
#import "XXStoryViewController.h"
#import "MSDynamicsDrawerViewController/MSDynamicsDrawerViewController.h"

@interface XXStoryInfoViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) Story *story;
@property (nonatomic, weak) MSDynamicsDrawerViewController *dynamicsDrawerViewController;
@property (strong, nonatomic) UIPopoverController *popover;
@end

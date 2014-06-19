//
//  XXProfileViewController.h
//  Verses
//
//  Created by Max Haines-Stiles on 4/14/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Story+helper.h"
#import "User+helper.h"
#import "XXStoryInfoViewController.h"

@interface XXProfileViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) User *user;
@property (strong, nonatomic) NSNumber *userId;
@property (strong, nonatomic) XXStoryInfoViewController *storyInfoVc;
@end

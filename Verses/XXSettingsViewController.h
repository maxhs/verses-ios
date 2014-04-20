//
//  XXSettingsViewController.h
//  Verses
//
//  Created by Max Haines-Stiles on 11/4/13.
//  Copyright (c) 2013 Verses. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MSDynamicsDrawerViewController/MSDynamicsDrawerViewController.h"
#import "XXUser.h"

@interface XXSettingsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *logoutButton;
@property (nonatomic, weak) MSDynamicsDrawerViewController *dynamicsDrawerViewController;
- (IBAction)logout;
@end

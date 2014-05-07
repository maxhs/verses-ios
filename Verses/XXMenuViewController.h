//
//  XXMenuViewController.h
//  Verses
//
//  Created by Max Haines-Stiles on 11/3/13.
//  Copyright (c) 2013 Verses. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MSDynamicsDrawerViewController/MSDynamicsDrawerViewController.h"

@interface XXMenuViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (nonatomic, weak) MSDynamicsDrawerViewController *dynamicsDrawerViewController;
@property (nonatomic, assign) MSPaneViewControllerType paneViewControllerType;
@property (strong, nonatomic) NSMutableArray *stories;
@property (strong, nonatomic) UIPopoverController *popover;
- (void)transitionToViewController:(MSPaneViewControllerType)paneViewControllerType;
@end

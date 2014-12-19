//
//  XXFlagContentViewController.h
//  Verses
//
//  Created by Max Haines-Stiles on 5/30/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Story+helper.h"

@interface XXFlagContentViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) Story *story;
@end

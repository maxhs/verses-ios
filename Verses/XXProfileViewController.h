//
//  XXProfileViewController.h
//  Verses
//
//  Created by Max Haines-Stiles on 4/14/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XXStory.h"
#import "XXUser.h"

@interface XXProfileViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) XXUser *user;
@end

//
//  XXFlagContentViewController.h
//  Verses
//
//  Created by Max Haines-Stiles on 5/30/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface XXFlagContentViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) XXStory *story;
@end

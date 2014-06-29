//
//  XXManageCircleViwController.h
//  Verses
//
//  Created by Max Haines-Stiles on 6/28/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface XXManageCircleViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) Circle *circle;

@end

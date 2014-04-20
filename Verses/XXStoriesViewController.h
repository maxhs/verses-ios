//
//  XXStoriesViewController.h
//  Verses
//
//  Created by Max Haines-Stiles on 10/6/13.
//  Copyright (c) 2013 Verses. All rights reserved.
//

#import <UIKit/UIKit.h>

@class XXDetailViewController;

@interface XXStoriesViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) NSMutableArray *contributions;
@property (strong, nonatomic) NSMutableArray *stories;
@property BOOL featured;
@property BOOL trending;
@end

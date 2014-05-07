//
//  XXBookmarksViewController.h
//  Verses
//
//  Created by Max Haines-Stiles on 3/26/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface XXBookmarksViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property BOOL reloadTheme;
@end

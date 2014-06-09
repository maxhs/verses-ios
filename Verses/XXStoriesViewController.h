//
//  XXStoriesViewController.h
//  Verses
//
//  Created by Max Haines-Stiles on 10/11/13.
//  Copyright (c) 2013 Verses. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface XXStoriesViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSMutableArray *stories;
@property BOOL reloadTheme;
@property BOOL featured;
@property BOOL trending;
@property BOOL shared;
@property BOOL ether;
- (void)loadEtherStories;
@end

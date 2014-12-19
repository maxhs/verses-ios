//
//  XXAddCollaboratorsViewController.h
//  Verses
//
//  Created by Max Haines-Stiles on 6/28/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "User+helper.h"

@interface XXAddCollaboratorsViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) User *currentUser;

@end

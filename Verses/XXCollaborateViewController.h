//
//  XXCollaborateViewController.h
//  Verses
//
//  Created by Max Haines-Stiles on 3/31/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "User.h"
#import "Story+helper.h"

@interface XXCollaborateViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) Story *story;
@property BOOL manageContacts;
-(void)addContact;

@end

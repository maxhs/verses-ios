//
//  XXCollaborateViewController.h
//  Verses
//
//  Created by Max Haines-Stiles on 3/31/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XXUser.h"

@interface XXCollaborateViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSMutableArray *collaborators;
@property (strong, nonatomic) NSMutableArray *circleCollaborators;
@property BOOL manageContacts;
-(void)addContact;

@end

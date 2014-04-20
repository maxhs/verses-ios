//
//  XXFeedbackDetailViewController.h
//  Verses
//
//  Created by Max Haines-Stiles on 3/26/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XXFeedbackViewController.h"
#import "XXFeedback.h"

@interface XXFeedbackDetailViewController : UIViewController <UITableViewDelegate,UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) XXFeedback *feedback;
@end

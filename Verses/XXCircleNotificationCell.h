//
//  XXCircleNotificationCell.h
//  Verses
//
//  Created by Max Haines-Stiles on 4/22/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XXNotification.h"

@interface XXCircleNotificationCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *notificationLabel;
@property (weak, nonatomic) IBOutlet UILabel *timestamp;

- (void)configureNotification:(XXNotification*)notification;
@end

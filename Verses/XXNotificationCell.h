//
//  XXNotificationCell.h
//  Verses
//
//  Created by Max Haines-Stiles on 11/4/13.
//  Copyright (c) 2013 Verses. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XXNotification.h"

@interface XXNotificationCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIButton *userPhotoButton;
@property (weak, nonatomic) IBOutlet UILabel *messageLabel;
@property (weak, nonatomic) IBOutlet UILabel *monthLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;

- (void)configureCell:(XXNotification*)notification;

@end

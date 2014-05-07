//
//  XXCircleNotificationCell.m
//  Verses
//
//  Created by Max Haines-Stiles on 4/22/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import "XXCircleNotificationCell.h"

@implementation XXCircleNotificationCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib {
    [self.notificationLabel setFont:[UIFont fontWithName:kSourceSansProRegular size:15]];
    [self.timestamp setFont:[UIFont fontWithName:kSourceSansProLight size:13]];
}

- (void)configureNotification:(XXNotification *)notification {
    if ([notification.type isEqualToString:kCircleComment]){
        [self.notificationLabel setText:[NSString stringWithFormat:@"%@ added a comment.",notification.targetUser.penName]];
    } else if ([notification.type isEqualToString:kCircle]){
        [self.notificationLabel setText:[NSString stringWithFormat:@"%@ added you to the circle.",notification.targetUser.penName]];
    } else {
        [self.notificationLabel setText:notification.message];
    }
    
}

@end

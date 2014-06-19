//
//  Notification.h
//  Verses
//
//  Created by Max Haines-Stiles on 6/15/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Circle, Contribution, Story, User;

@interface Notification : NSManagedObject

@property (nonatomic, retain) NSDate * createdDate;
@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSString * message;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) Circle *circle;
@property (nonatomic, retain) Contribution *contribution;
@property (nonatomic, retain) Story *story;
@property (nonatomic, retain) User *targetUser;
@property (nonatomic, retain) User *user;

@end

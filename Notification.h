//
//  Notification.h
//  Verses
//
//  Created by Max Haines-Stiles on 6/10/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Story, User, Circle;

@interface Notification : NSManagedObject

@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSString * message;
@property (nonatomic, retain) NSDate * createdDate;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) User *targetUser;
@property (nonatomic, retain) User *user;
@property (nonatomic, retain) Story *story;
@property (nonatomic, retain) Circle *circle;

@end

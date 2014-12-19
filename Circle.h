//
//  Circle.h
//  Verses
//
//  Created by Max Haines-Stiles on 6/15/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Comment, User;

@interface Circle : NSManagedObject

@property (nonatomic, retain) NSString * blurb;
@property (nonatomic, retain) NSDate * createdDate;
@property (nonatomic, retain) NSNumber * fresh;
@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSString * members;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * publicCircle;
@property (nonatomic, retain) NSString * titles;
@property (nonatomic, retain) NSNumber * unreadCommentCount;
@property (nonatomic, retain) NSOrderedSet *comments;
@property (nonatomic, retain) NSOrderedSet *notifications;
@property (nonatomic, retain) NSOrderedSet *stories;
@property (nonatomic, retain) NSOrderedSet *users;
@property (nonatomic, retain) User *owner;

@end
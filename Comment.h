//
//  Comment.h
//  Verses
//
//  Created by Max Haines-Stiles on 6/15/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Circle, Feedback, User;

@interface Comment : NSManagedObject

@property (nonatomic, retain) NSString * body;
@property (nonatomic, retain) NSDate * createdDate;
@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSNumber * read;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) Circle *circle;
@property (nonatomic, retain) Feedback *feedback;
@property (nonatomic, retain) User *targetUser;
@property (nonatomic, retain) User *user;
@property CGSize rectSize;
@end

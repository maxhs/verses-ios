//
//  Circle.h
//  Verses
//
//  Created by Max Haines-Stiles on 6/10/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Comment, Notification, Story, User;

@interface Circle : NSManagedObject

@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSNumber * unreadCommentCount;
@property (nonatomic, retain) NSNumber * fresh;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * titles;
@property (nonatomic, retain) NSString * blurb;
@property (nonatomic, retain) NSDate * createdDate;
@property (nonatomic, retain) NSSet *members;
@property (nonatomic, retain) NSOrderedSet *notifications;
@property (nonatomic, retain) NSOrderedSet *stories;
@property (nonatomic, retain) NSOrderedSet *comments;
@end

@interface Circle (CoreDataGeneratedAccessors)

- (void)addUsersObject:(User *)value;
- (void)removeUsersObject:(User *)value;
- (void)addUsers:(NSSet *)values;
- (void)removeUsers:(NSSet *)values;

- (void)insertObject:(Notification *)value inNotificationsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromNotificationsAtIndex:(NSUInteger)idx;
- (void)insertNotifications:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeNotificationsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInNotificationsAtIndex:(NSUInteger)idx withObject:(Notification *)value;
- (void)replaceNotificationsAtIndexes:(NSIndexSet *)indexes withNotifications:(NSArray *)values;
- (void)addNotificationsObject:(Notification *)value;
- (void)removeNotificationsObject:(Notification *)value;
- (void)addNotifications:(NSOrderedSet *)values;
- (void)removeNotifications:(NSOrderedSet *)values;
- (void)insertObject:(Story *)value inStoriesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromStoriesAtIndex:(NSUInteger)idx;
- (void)insertStories:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeStoriesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInStoriesAtIndex:(NSUInteger)idx withObject:(Story *)value;
- (void)replaceStoriesAtIndexes:(NSIndexSet *)indexes withStories:(NSArray *)values;
- (void)addStoriesObject:(Story *)value;
- (void)removeStoriesObject:(Story *)value;
- (void)addStories:(NSOrderedSet *)values;
- (void)removeStories:(NSOrderedSet *)values;
- (void)insertObject:(Comment *)value inCommentsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromCommentsAtIndex:(NSUInteger)idx;
- (void)insertComments:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeCommentsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInCommentsAtIndex:(NSUInteger)idx withObject:(Comment *)value;
- (void)replaceCommentsAtIndexes:(NSIndexSet *)indexes withComments:(NSArray *)values;
- (void)addCommentsObject:(Comment *)value;
- (void)removeCommentsObject:(Comment *)value;
- (void)addComments:(NSOrderedSet *)values;
- (void)removeComments:(NSOrderedSet *)values;
@end

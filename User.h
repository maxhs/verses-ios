//
//  User.h
//  Verses
//
//  Created by Max Haines-Stiles on 5/2/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface User : NSManagedObject

@property (nonatomic, retain) NSNumber * contactCount;
@property (nonatomic, retain) NSString * email;
@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSString * location;
@property (nonatomic, retain) NSString * bio;
@property (nonatomic, retain) NSString * dayJob;
@property (nonatomic, retain) NSString * nightJob;
@property (nonatomic, retain) NSString * penName;
@property (nonatomic, retain) NSString * picSmall;
@property (nonatomic, retain) NSString * picThumb;
@property (nonatomic, retain) NSNumber * storyCount;
@property (nonatomic, retain) NSNumber * pushBookmarks;
@property (nonatomic, retain) NSNumber * pushCirclePublish;
@property (nonatomic, retain) NSNumber * pushCircleComments;
@property (nonatomic, retain) NSNumber * pushDaily;
@property (nonatomic, retain) NSNumber * pushPermissions;
@property (nonatomic, retain) NSNumber * pushInvitations;
@property (nonatomic, retain) NSNumber * pushSubscribe;
@property (nonatomic, retain) NSNumber * pushWeekly;
@property (nonatomic, retain) NSNumber * pushFeedbacks;
@property (nonatomic, retain) NSNumber * subscribed;
@property (nonatomic, retain) id thumbImage;
@property (nonatomic, retain) NSString * picLarge;
@property (nonatomic, retain) NSString * picMedium;
@property (nonatomic, retain) NSString * firstName;
@property (nonatomic, retain) NSString * lastName;
@property (nonatomic, retain) NSManagedObject *ownedStory;
@property (nonatomic, retain) NSOrderedSet *stories;
@property (nonatomic, retain) NSOrderedSet *contributions;
@property (nonatomic, retain) NSOrderedSet *photos;
@end

@interface User (CoreDataGeneratedAccessors)

- (void)insertObject:(NSManagedObject *)value inStoriesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromStoriesAtIndex:(NSUInteger)idx;
- (void)insertStories:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeStoriesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInStoriesAtIndex:(NSUInteger)idx withObject:(NSManagedObject *)value;
- (void)replaceStoriesAtIndexes:(NSIndexSet *)indexes withStories:(NSArray *)values;
- (void)addStoriesObject:(NSManagedObject *)value;
- (void)removeStoriesObject:(NSManagedObject *)value;
- (void)addStories:(NSOrderedSet *)values;
- (void)removeStories:(NSOrderedSet *)values;
@end

//
//  Story.h
//  Verses
//
//  Created by Max Haines-Stiles on 6/7/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "User+helper.h"
@class Footnote;

@interface Story : NSManagedObject

@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSDate * createdDate;
@property (nonatomic, retain) NSDate * updatedDate;
@property (nonatomic, retain) NSNumber * wordCount;
@property (nonatomic, retain) NSNumber * views;
@property (nonatomic, retain) NSNumber * trendingCount;
@property (nonatomic, retain) NSDate * publishedDate;
@property (nonatomic, retain) NSString * authorNames;
@property (nonatomic, retain) NSString * storyUrl;
@property (nonatomic, retain) NSNumber * minutesToRead;
@property (nonatomic, retain) NSNumber * joinable;
@property (nonatomic, retain) NSNumber * draft;
@property (nonatomic, retain) NSNumber * inviteOnly;
@property (nonatomic, retain) NSNumber * bookmarked;
@property (nonatomic, retain) NSNumber * mystery;
@property (nonatomic, retain) NSNumber * featured;
@property (nonatomic, retain) NSOrderedSet *footnotes;
@property (nonatomic, retain) User *owner;
@property (nonatomic, retain) NSNumber *ownerId;
@property (nonatomic, retain) NSOrderedSet *users;
@property (nonatomic, retain) NSOrderedSet *circles;
@property (nonatomic, retain) NSOrderedSet *contributions;
@property (nonatomic, retain) NSOrderedSet *photos;
@property (nonatomic, retain) NSOrderedSet *feedbacks;
@property (nonatomic, retain) NSManagedObject *tags;
@property (nonatomic, retain) id attributedSnippet;
@end

@interface Story (CoreDataGeneratedAccessors)

- (void)insertObject:(Footnote *)value inFootnotesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromFootnotesAtIndex:(NSUInteger)idx;
- (void)insertFootnotes:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeFootnotesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInFootnotesAtIndex:(NSUInteger)idx withObject:(Footnote *)value;
- (void)replaceFootnotesAtIndexes:(NSIndexSet *)indexes withFootnotes:(NSArray *)values;
- (void)addFootnotesObject:(Footnote *)value;
- (void)removeFootnotesObject:(Footnote *)value;
- (void)addFootnotes:(NSOrderedSet *)values;
- (void)removeFootnotes:(NSOrderedSet *)values;
- (void)addUsersObject:(User *)value;
- (void)removeUsersObject:(User *)value;
- (void)addUsers:(NSSet *)values;
- (void)removeUsers:(NSSet *)values;

- (void)insertObject:(NSManagedObject *)value inContributionsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromContributionsAtIndex:(NSUInteger)idx;
- (void)insertContributions:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeContributionsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInContributionsAtIndex:(NSUInteger)idx withObject:(NSManagedObject *)value;
- (void)replaceContributionsAtIndexes:(NSIndexSet *)indexes withContributions:(NSArray *)values;
- (void)addContributionsObject:(NSManagedObject *)value;
- (void)removeContributionsObject:(NSManagedObject *)value;
- (void)addContributions:(NSOrderedSet *)values;
- (void)removeContributions:(NSOrderedSet *)values;
- (void)insertObject:(NSManagedObject *)value inPhotosAtIndex:(NSUInteger)idx;
- (void)removeObjectFromPhotosAtIndex:(NSUInteger)idx;
- (void)insertPhotos:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removePhotosAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInPhotosAtIndex:(NSUInteger)idx withObject:(NSManagedObject *)value;
- (void)replacePhotosAtIndexes:(NSIndexSet *)indexes withPhotos:(NSArray *)values;
- (void)addPhotosObject:(NSManagedObject *)value;
- (void)removePhotosObject:(NSManagedObject *)value;
- (void)addPhotos:(NSOrderedSet *)values;
- (void)removePhotos:(NSOrderedSet *)values;
@end

//
//  User.h
//  Verses
//
//  Created by Max Haines-Stiles on 6/16/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "Photo+helper.h"
#import "Notification+helper.h"
#import "Bookmark+helper.h"
#import "Story+helper.h"
#import "Circle+helper.h"
#import "Contribution+helper.h"
#import "Comment+helper.h"
#import "Feedback+helper.h"

@interface User : NSManagedObject

@property (nonatomic, retain) NSString * authToken;
@property (nonatomic, retain) id backgroundImageView;
@property (nonatomic, retain) NSString * bio;
@property (nonatomic, retain) NSString * dayJob;
@property (nonatomic, retain) NSString * email;
@property (nonatomic, retain) NSString * phone;
@property (nonatomic, retain) NSString * firstName;
@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSString * lastName;
@property (nonatomic, retain) NSString * location;
@property (nonatomic, retain) NSString * nightJob;
@property (nonatomic, retain) NSNumber * ownerId;
@property (nonatomic, retain) NSString * penName;
@property (nonatomic, retain) NSString * picLarge;
@property (nonatomic, retain) NSString * picMedium;
@property (nonatomic, retain) NSString * picSmall;
@property (nonatomic, retain) NSString * picThumb;
@property (nonatomic, retain) NSString * backgroundUrl;
@property (nonatomic, retain) NSNumber * pushBookmarks;
@property (nonatomic, retain) NSNumber * pushCircleComments;
@property (nonatomic, retain) NSNumber * pushCirclePublish;
@property (nonatomic, retain) NSNumber * pushDaily;
@property (nonatomic, retain) NSNumber * pushFeedbacks;
@property (nonatomic, retain) NSNumber * pushInvitations;
@property (nonatomic, retain) NSNumber * pushPermissions;
@property (nonatomic, retain) NSNumber * pushSubscribe;
@property (nonatomic, retain) NSNumber * pushWeekly;
@property (nonatomic, retain) NSNumber * storyCount;
@property (nonatomic, retain) NSNumber * subscribed;
@property (nonatomic, retain) id thumbImage;
@property (nonatomic, retain) NSOrderedSet *bookmarks;
@property (nonatomic, retain) NSOrderedSet *circles;
@property (nonatomic, retain) NSOrderedSet *comments;
@property (nonatomic, retain) NSOrderedSet *contacts;
@property (nonatomic, retain) NSOrderedSet *contributions;
@property (nonatomic, retain) NSOrderedSet *drafts;
@property (nonatomic, retain) NSOrderedSet *feedbacks;
@property (nonatomic, retain) NSOrderedSet *notifications;
@property (nonatomic, retain) NSOrderedSet *ownedCircles;
@property (nonatomic, retain) NSOrderedSet *ownedStories;
@property (nonatomic, retain) NSOrderedSet *photos;
@property (nonatomic, retain) Feedback *receivedFeedbacks;
@property (nonatomic, retain) NSOrderedSet *stories;
@property (nonatomic, retain) NSOrderedSet *targetComments;
@property (nonatomic, retain) NSOrderedSet *targetNotifications;
@end

@interface User (CoreDataGeneratedAccessors)

- (void)insertObject:(Bookmark *)value inBookmarksAtIndex:(NSUInteger)idx;
- (void)removeObjectFromBookmarksAtIndex:(NSUInteger)idx;
- (void)insertBookmarks:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeBookmarksAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInBookmarksAtIndex:(NSUInteger)idx withObject:(Bookmark *)value;
- (void)replaceBookmarksAtIndexes:(NSIndexSet *)indexes withBookmarks:(NSArray *)values;
- (void)addBookmarksObject:(Bookmark *)value;
- (void)removeBookmarksObject:(Bookmark *)value;
- (void)addBookmarks:(NSOrderedSet *)values;
- (void)removeBookmarks:(NSOrderedSet *)values;
- (void)insertObject:(Circle *)value inCirclesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromCirclesAtIndex:(NSUInteger)idx;
- (void)insertCircles:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeCirclesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInCirclesAtIndex:(NSUInteger)idx withObject:(Circle *)value;
- (void)replaceCirclesAtIndexes:(NSIndexSet *)indexes withCircles:(NSArray *)values;
- (void)addCirclesObject:(Circle *)value;
- (void)removeCirclesObject:(Circle *)value;
- (void)addCircles:(NSOrderedSet *)values;
- (void)removeCircles:(NSOrderedSet *)values;
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
- (void)insertObject:(User *)value inContactsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromContactsAtIndex:(NSUInteger)idx;
- (void)insertContacts:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeContactsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInContactsAtIndex:(NSUInteger)idx withObject:(User *)value;
- (void)replaceContactsAtIndexes:(NSIndexSet *)indexes withContacts:(NSArray *)values;
- (void)addContactsObject:(User *)value;
- (void)removeContactsObject:(User *)value;
- (void)addContacts:(NSOrderedSet *)values;
- (void)removeContacts:(NSOrderedSet *)values;
- (void)insertObject:(Contribution *)value inContributionsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromContributionsAtIndex:(NSUInteger)idx;
- (void)insertContributions:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeContributionsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInContributionsAtIndex:(NSUInteger)idx withObject:(Contribution *)value;
- (void)replaceContributionsAtIndexes:(NSIndexSet *)indexes withContributions:(NSArray *)values;
- (void)addContributionsObject:(Contribution *)value;
- (void)removeContributionsObject:(Contribution *)value;
- (void)addContributions:(NSOrderedSet *)values;
- (void)removeContributions:(NSOrderedSet *)values;
- (void)insertObject:(Story *)value inDraftsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromDraftsAtIndex:(NSUInteger)idx;
- (void)insertDrafts:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeDraftsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInDraftsAtIndex:(NSUInteger)idx withObject:(Story *)value;
- (void)replaceDraftsAtIndexes:(NSIndexSet *)indexes withDrafts:(NSArray *)values;
- (void)addDraftsObject:(Story *)value;
- (void)removeDraftsObject:(Story *)value;
- (void)addDrafts:(NSOrderedSet *)values;
- (void)removeDrafts:(NSOrderedSet *)values;
- (void)insertObject:(Feedback *)value inFeedbacksAtIndex:(NSUInteger)idx;
- (void)removeObjectFromFeedbacksAtIndex:(NSUInteger)idx;
- (void)insertFeedbacks:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeFeedbacksAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInFeedbacksAtIndex:(NSUInteger)idx withObject:(Feedback *)value;
- (void)replaceFeedbacksAtIndexes:(NSIndexSet *)indexes withFeedbacks:(NSArray *)values;
- (void)addFeedbacksObject:(Feedback *)value;
- (void)removeFeedbacksObject:(Feedback *)value;
- (void)addFeedbacks:(NSOrderedSet *)values;
- (void)removeFeedbacks:(NSOrderedSet *)values;
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
- (void)insertObject:(Circle *)value inOwnedCirclesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromOwnedCirclesAtIndex:(NSUInteger)idx;
- (void)insertOwnedCircles:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeOwnedCirclesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInOwnedCirclesAtIndex:(NSUInteger)idx withObject:(Circle *)value;
- (void)replaceOwnedCirclesAtIndexes:(NSIndexSet *)indexes withOwnedCircles:(NSArray *)values;
- (void)addOwnedCirclesObject:(Circle *)value;
- (void)removeOwnedCirclesObject:(Circle *)value;
- (void)addOwnedCircles:(NSOrderedSet *)values;
- (void)removeOwnedCircles:(NSOrderedSet *)values;
- (void)insertObject:(Story *)value inOwnedStoriesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromOwnedStoriesAtIndex:(NSUInteger)idx;
- (void)insertOwnedStories:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeOwnedStoriesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInOwnedStoriesAtIndex:(NSUInteger)idx withObject:(Story *)value;
- (void)replaceOwnedStoriesAtIndexes:(NSIndexSet *)indexes withOwnedStories:(NSArray *)values;
- (void)addOwnedStoriesObject:(Story *)value;
- (void)removeOwnedStoriesObject:(Story *)value;
- (void)addOwnedStories:(NSOrderedSet *)values;
- (void)removeOwnedStories:(NSOrderedSet *)values;
- (void)insertObject:(Photo *)value inPhotosAtIndex:(NSUInteger)idx;
- (void)removeObjectFromPhotosAtIndex:(NSUInteger)idx;
- (void)insertPhotos:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removePhotosAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInPhotosAtIndex:(NSUInteger)idx withObject:(Photo *)value;
- (void)replacePhotosAtIndexes:(NSIndexSet *)indexes withPhotos:(NSArray *)values;
- (void)addPhotosObject:(Photo *)value;
- (void)removePhotosObject:(Photo *)value;
- (void)addPhotos:(NSOrderedSet *)values;
- (void)removePhotos:(NSOrderedSet *)values;
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
- (void)insertObject:(Comment *)value inTargetCommentsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromTargetCommentsAtIndex:(NSUInteger)idx;
- (void)insertTargetComments:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeTargetCommentsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInTargetCommentsAtIndex:(NSUInteger)idx withObject:(Comment *)value;
- (void)replaceTargetCommentsAtIndexes:(NSIndexSet *)indexes withTargetComments:(NSArray *)values;
- (void)addTargetCommentsObject:(Comment *)value;
- (void)removeTargetCommentsObject:(Comment *)value;
- (void)addTargetComments:(NSOrderedSet *)values;
- (void)removeTargetComments:(NSOrderedSet *)values;
- (void)insertObject:(Notification *)value inTargetNotificationsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromTargetNotificationsAtIndex:(NSUInteger)idx;
- (void)insertTargetNotifications:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeTargetNotificationsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInTargetNotificationsAtIndex:(NSUInteger)idx withObject:(Notification *)value;
- (void)replaceTargetNotificationsAtIndexes:(NSIndexSet *)indexes withTargetNotifications:(NSArray *)values;
- (void)addTargetNotificationsObject:(Notification *)value;
- (void)removeTargetNotificationsObject:(Notification *)value;
- (void)addTargetNotifications:(NSOrderedSet *)values;
- (void)removeTargetNotifications:(NSOrderedSet *)values;
@end

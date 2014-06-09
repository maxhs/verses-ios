//
//  Utilities.m
//  Verses
//
//  Created by Max Haines-Stiles on 10/11/13.
//  Copyright (c) 2013 Verses. All rights reserved.
//

#import "Utilities.h"
#import "XXContribution.h"
#import "XXUser.h"
#import "XXTag.h"
#import "XXStory.h"
#import "XXNotification.h"
#import "XXPhoto.h"
#import "XXCircle.h"
#import "XXFeedback.h"
#import "XXBookmark.h"
#import "XXComment.h"
#import "Story+helper.h"

@implementation Utilities

+ (UIImageView *)findNavShadow:(UIView *)view {
    if ([view isKindOfClass:UIImageView.class] && view.bounds.size.height <= 1.0) {
        return (UIImageView *)view;
    }
    for (UIView *subview in view.subviews) {
        UIImageView *imageView = [self findNavShadow:subview];
        if (imageView) {
            return imageView;
        }
    }
    return nil;
}

+ (NSArray *)storiesFromJSONArray:(NSMutableArray *) array {
    NSMutableArray *stories = [NSMutableArray arrayWithCapacity:array.count];
    for (NSDictionary *dict in array){
        if ([dict objectForKey:@"id"] && [dict objectForKey:@"id"] != [NSNull null]){
            Story *story = [Story MR_findFirstByAttribute:@"identifier" withValue:[dict objectForKey:@"id"]];
            if (!story){
                story = [Story MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [story populateFromDict:dict];
        }
    }
    return stories;
}

+ (NSArray *)contributionsFromJSONArray:(NSMutableArray *) array {
    NSMutableArray *contributions = [NSMutableArray arrayWithCapacity:array.count];
    for (NSDictionary *contributionDictionary in array) {
        XXContribution *contribution = [[XXContribution alloc] initWithDictionary:contributionDictionary];
        [contributions addObject:contribution];
    }
    return contributions;
}

+ (NSArray *)tagsFromJSONArray:(NSMutableArray *) array {
    NSMutableArray *tags = [NSMutableArray arrayWithCapacity:array.count];
    for (NSDictionary *tagDictionary in array) {
        XXTag *tag = [[XXTag alloc] initWithDictionary:tagDictionary];
        [tags addObject:tag];
    }
    return tags;
}

+ (NSArray *)photosFromJSONArray:(NSMutableArray *) array {
    NSMutableArray *photos = [NSMutableArray arrayWithCapacity:array.count];
    for (id photoDict in array) {
        if ([photoDict isKindOfClass:[NSDictionary class]]){
            XXPhoto *photo = [[XXPhoto alloc] initWithDictionary:(NSDictionary*)photoDict];
            [photos addObject:photo];
        } else if ([photoDict isKindOfClass:[NSArray class]]) {
            for (id miniDict in photoDict){
                XXPhoto *photo = [[XXPhoto alloc] initWithDictionary:(NSDictionary*)miniDict];
                [photos addObject:photo];
            }
        }
        
    }
    return photos;
}

+ (NSArray *)notificationsFromJSONArray:(NSMutableArray *) array {
    NSMutableArray *notifications = [NSMutableArray arrayWithCapacity:array.count];
    for (NSDictionary *notificationDictionary in array) {
        XXNotification *notification = [[XXNotification alloc] initWithDictionary:notificationDictionary];
        [notifications addObject:notification];
    }
    return notifications;
}

+ (NSArray *)circlesFromJSONArray:(NSMutableArray *) array {
    NSMutableArray *circles = [NSMutableArray arrayWithCapacity:array.count];
    for (NSDictionary *circleDictionary in array) {
        XXCircle *circle = [[XXCircle alloc] initWithDictionary:circleDictionary];
        [circles addObject:circle];
    }
    return circles;
}

+ (NSArray *)usersFromJSONArray:(NSMutableArray *) array {
    NSMutableArray *users = [NSMutableArray arrayWithCapacity:array.count];
    for (NSDictionary *userDictionary in array) {
        XXUser *user = [[XXUser alloc] initWithDictionary:userDictionary];
        [users addObject:user];
    }
    return users;
}

+ (NSArray *)feedbacksFromJSONArray:(NSMutableArray *) array {
    NSMutableArray *feedbacks = [NSMutableArray arrayWithCapacity:array.count];
    for (NSDictionary *feedbackDictionary in array) {
        XXFeedback *feedback = [[XXFeedback alloc] initWithDictionary:feedbackDictionary];
        [feedbacks addObject:feedback];
    }
    return feedbacks;
}

+ (NSArray *)commentsFromJSONArray:(NSMutableArray *) array {
    NSMutableArray *comments = [NSMutableArray arrayWithCapacity:array.count];
    for (NSDictionary *commentDictionary in array) {
        XXComment *comment = [[XXComment alloc] initWithDictionary:commentDictionary];
        [comments addObject:comment];
    }
    return comments;
}
+ (NSArray *)bookmarksFromJSONArray:(NSMutableArray *) array {
    NSMutableArray *bookmarks = [NSMutableArray arrayWithCapacity:array.count];
    for (NSDictionary *bookmarkDictionary in array) {
        XXBookmark *bookmark = [[XXBookmark alloc] initWithDictionary:bookmarkDictionary];
        [bookmarks addObject:bookmark];
    }
    return bookmarks;
}

@end

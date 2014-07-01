//
//  User+helper.m
//  Verses
//
//  Created by Max Haines-Stiles on 6/7/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import "User+helper.h"

@implementation User (helper)
- (void)populateFromDict:(NSDictionary*)dictionary {
    //NSLog(@"user dictionary: %@",dictionary);
    if ([dictionary objectForKey:@"id"] && [dictionary objectForKey:@"id"] != [NSNull null]) {
        self.identifier = [dictionary objectForKey:@"id"];
    }
    if ([dictionary objectForKey:@"pen_name"] && [dictionary objectForKey:@"pen_name"] != [NSNull null]) {
        self.penName = [dictionary objectForKey:@"pen_name"];
    }
    if ([dictionary objectForKey:@"first_name"] && [dictionary objectForKey:@"first_name"] != [NSNull null]) {
        self.firstName = [dictionary objectForKey:@"first_name"];
    }
    if ([dictionary objectForKey:@"last_name"] && [dictionary objectForKey:@"last_name"] != [NSNull null]) {
        self.lastName = [dictionary objectForKey:@"last_name"];
    }
    if ([dictionary objectForKey:@"bio"] && [dictionary objectForKey:@"bio"] != [NSNull null]) {
        self.bio = [dictionary objectForKey:@"bio"];
    }
    if ([dictionary objectForKey:@"day_job"] && [dictionary objectForKey:@"day_job"] != [NSNull null]) {
        self.dayJob = [dictionary objectForKey:@"day_job"];
    }
    if ([dictionary objectForKey:@"night_job"] && [dictionary objectForKey:@"night_job"] != [NSNull null]) {
        self.nightJob = [dictionary objectForKey:@"night_job"];
    }
    if ([dictionary objectForKey:@"email"] && [dictionary objectForKey:@"email"] != [NSNull null]) {
        self.email = [dictionary objectForKey:@"email"];
    }
    if ([dictionary objectForKey:@"location"] && [dictionary objectForKey:@"location"] != [NSNull null]) {
        self.location = [dictionary objectForKey:@"location"];
    }
    if ([dictionary objectForKey:@"pic_small_url"] && [dictionary objectForKey:@"pic_small_url"] != [NSNull null]) {
        self.picSmall = [dictionary objectForKey:@"pic_small_url"];
    }
    if ([dictionary objectForKey:@"pic_medium_url"] && [dictionary objectForKey:@"pic_medium_url"] != [NSNull null]) {
        self.picMedium = [dictionary objectForKey:@"pic_medium_url"];
    }
    if ([dictionary objectForKey:@"pic_large_url"] && [dictionary objectForKey:@"pic_large_url"] != [NSNull null]) {
        self.picLarge = [dictionary objectForKey:@"pic_large_url"];
    }
    if ([dictionary objectForKey:@"push_permissions"] && [dictionary objectForKey:@"push_permissions"] != [NSNull null]) {
        self.pushPermissions = [dictionary objectForKey:@"push_permissions"];
    }
    if ([dictionary objectForKey:@"push_circle_comments"] && [dictionary objectForKey:@"push_circle_comments"] != [NSNull null]) {
        self.pushCircleComments = [dictionary objectForKey:@"push_circle_comments"];
    }
    if ([dictionary objectForKey:@"push_feedbacks"] && [dictionary objectForKey:@"push_feedbacks"] != [NSNull null]) {
        self.pushFeedbacks = [dictionary objectForKey:@"push_feedbacks"];
    }
    if ([dictionary objectForKey:@"push_circle_publish"] && [dictionary objectForKey:@"push_circle_publish"] != [NSNull null]) {
        self.pushCirclePublish = [dictionary objectForKey:@"push_circle_publish"];
    }
    if ([dictionary objectForKey:@"push_subscribe"] && [dictionary objectForKey:@"push_subscribe"] != [NSNull null]) {
        self.pushSubscribe = [dictionary objectForKey:@"push_subscribe"];
    }
    if ([dictionary objectForKey:@"push_invitations"] && [dictionary objectForKey:@"push_invitations"] != [NSNull null]) {
        self.pushInvitations = [dictionary objectForKey:@"push_invitations"];
    }
    if ([dictionary objectForKey:@"push_bookmarks"] && [dictionary objectForKey:@"push_bookmarks"] != [NSNull null]) {
        self.pushBookmarks = [dictionary objectForKey:@"push_bookmarks"];
    }
    if ([dictionary objectForKey:@"subscribed"] && [dictionary objectForKey:@"subscribed"] != [NSNull null]) {
        self.subscribed = [dictionary objectForKey:@"subscribed"];
    }
}

- (void)update:(NSDictionary*)dictionary {
    if ([dictionary objectForKey:@"pen_name"] && [dictionary objectForKey:@"pen_name"] != [NSNull null]) {
        self.penName = [dictionary objectForKey:@"pen_name"];
    }
    if ([dictionary objectForKey:@"first_name"] && [dictionary objectForKey:@"first_name"] != [NSNull null]) {
        self.firstName = [dictionary objectForKey:@"first_name"];
    }
    if ([dictionary objectForKey:@"last_name"] && [dictionary objectForKey:@"last_name"] != [NSNull null]) {
        self.lastName = [dictionary objectForKey:@"last_name"];
    }
    if ([dictionary objectForKey:@"bio"] && [dictionary objectForKey:@"bio"] != [NSNull null]) {
        self.bio = [dictionary objectForKey:@"bio"];
    }
    if ([dictionary objectForKey:@"day_job"] && [dictionary objectForKey:@"day_job"] != [NSNull null]) {
        self.dayJob = [dictionary objectForKey:@"day_job"];
    }
    if ([dictionary objectForKey:@"night_job"] && [dictionary objectForKey:@"night_job"] != [NSNull null]) {
        self.nightJob = [dictionary objectForKey:@"night_job"];
    }
    if ([dictionary objectForKey:@"email"] && [dictionary objectForKey:@"email"] != [NSNull null]) {
        self.email = [dictionary objectForKey:@"email"];
    }
    if ([dictionary objectForKey:@"location"] && [dictionary objectForKey:@"location"] != [NSNull null]) {
        self.location = [dictionary objectForKey:@"location"];
    }
    if ([dictionary objectForKey:@"pic_small_url"] && [dictionary objectForKey:@"pic_small_url"] != [NSNull null]) {
        self.picSmall = [dictionary objectForKey:@"pic_small_url"];
    }
    if ([dictionary objectForKey:@"pic_medium_url"] && [dictionary objectForKey:@"pic_medium_url"] != [NSNull null]) {
        self.picMedium = [dictionary objectForKey:@"pic_medium_url"];
    }
    if ([dictionary objectForKey:@"pic_large_url"] && [dictionary objectForKey:@"pic_large_url"] != [NSNull null]) {
        self.picLarge = [dictionary objectForKey:@"pic_large_url"];
    }

    if ([dictionary objectForKey:@"subscribed"] && [dictionary objectForKey:@"subscribed"] != [NSNull null]) {
        self.subscribed = [dictionary objectForKey:@"subscribed"];
    }
}

- (void)addNotification:(Notification*)notification{
    NSMutableOrderedSet *set = [[NSMutableOrderedSet alloc] initWithOrderedSet:self.notifications];
    [set addObject:notification];
    self.notifications = set;
}

- (void)removeNotification:(Notification*)notification{
    NSMutableOrderedSet *set = [[NSMutableOrderedSet alloc] initWithOrderedSet:self.notifications];
    [set removeObject:notification];
    self.notifications = set;
}

- (void)addBookmark:(Bookmark*)bookmark{
    NSMutableOrderedSet *set = [[NSMutableOrderedSet alloc] initWithOrderedSet:self.bookmarks];
    [set addObject:bookmark];
    self.bookmarks = set;
}

- (void)removeBookmark:(Bookmark*)bookmark{
    NSMutableOrderedSet *set = [[NSMutableOrderedSet alloc] initWithOrderedSet:self.bookmarks];
    [set removeObject:bookmark];
    self.bookmarks = set;
}

- (void)addDraft:(Story*)story{
    NSMutableOrderedSet *set = [[NSMutableOrderedSet alloc] initWithOrderedSet:self.drafts];
    [set addObject:story];
    self.drafts = set;
}

- (void)removeDraft:(Story*)story{
    if (story){
        NSMutableOrderedSet *set = [[NSMutableOrderedSet alloc] initWithOrderedSet:self.drafts];
        [set removeObject:story];
        self.drafts = set;
    }
}

- (void)addOwnedStory:(Story*)story{
    NSMutableOrderedSet *set = [[NSMutableOrderedSet alloc] initWithOrderedSet:self.ownedStories];
    [set addObject:story];
    self.ownedStories = set;
}
- (void)removeOwnedStory:(Story*)story{
    NSMutableOrderedSet *set = [[NSMutableOrderedSet alloc] initWithOrderedSet:self.ownedStories];
    [set removeObject:story];
    self.ownedStories = set;
}

- (void)addStory:(Story*)story{
    NSMutableOrderedSet *set = [[NSMutableOrderedSet alloc] initWithOrderedSet:self.stories];
    [set addObject:story];
    self.ownedStories = set;
}
- (void)removeStory:(Story*)story{
    NSMutableOrderedSet *set = [[NSMutableOrderedSet alloc] initWithOrderedSet:self.stories];
    [set removeObject:story];
    self.stories = set;
}

- (void)addCircle:(Circle*)circle{
    NSMutableOrderedSet *set = [[NSMutableOrderedSet alloc] initWithOrderedSet:self.circles];
    [set addObject:circle];
    self.circles = set;
}
- (void)removeCircle:(Circle*)circle{
    NSMutableOrderedSet *set = [[NSMutableOrderedSet alloc] initWithOrderedSet:self.circles];
    [set removeObject:circle];
    self.circles = set;
}

- (void)addContact:(User*)user{
    NSMutableOrderedSet *set = [[NSMutableOrderedSet alloc] initWithOrderedSet:self.contacts];
    [set addObject:user];
    self.contacts = set;
}
- (void)removeContact:(User*)user{
    NSMutableOrderedSet *set = [[NSMutableOrderedSet alloc] initWithOrderedSet:self.contacts];
    [set removeObject:user];
    self.contacts = set;
}

@end

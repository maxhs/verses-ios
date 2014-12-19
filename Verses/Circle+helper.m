//
//  Circle+helper.m
//  Verses
//
//  Created by Max Haines-Stiles on 6/10/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import "Circle+helper.h"
#import <MagicalRecord/CoreData+MagicalRecord.h>
#import "Constants.h"

@implementation Circle (helper)
- (void)update:(NSDictionary*)dictionary {
    if ([dictionary objectForKey:@"description"] && [dictionary objectForKey:@"description"] != [NSNull null]) {
        self.blurb = [dictionary objectForKey:@"description"];
    }
    if ([dictionary objectForKey:@"name"] && [dictionary objectForKey:@"name"] != [NSNull null]) {
        self.name = [dictionary objectForKey:@"name"];
    }
    if ([dictionary objectForKey:@"story_titles"] && [dictionary objectForKey:@"story_titles"] != [NSNull null]) {
        self.titles = [dictionary objectForKey:@"story_titles"];
    }
    if ([dictionary objectForKey:@"unread_comments"] && [dictionary objectForKey:@"unread_comments"] != [NSNull null]) {
        self.unreadCommentCount = [NSNumber numberWithInteger:[self unreadComments:[dictionary objectForKey:@"unread_comments"]]];
    }
}

- (void)populateFromDict:(NSDictionary*)dictionary {
    if ([dictionary objectForKey:@"id"] && [dictionary objectForKey:@"id"] != [NSNull null]) {
        self.identifier = [dictionary objectForKey:@"id"];
    }
    if ([dictionary objectForKey:@"name"] && [dictionary objectForKey:@"name"] != [NSNull null]) {
        self.name = [dictionary objectForKey:@"name"];
    }
    if ([dictionary objectForKey:@"description"] && [dictionary objectForKey:@"description"] != [NSNull null]) {
        self.blurb = [dictionary objectForKey:@"description"];
    }
    if ([dictionary objectForKey:@"story_titles"] && [dictionary objectForKey:@"story_titles"] != [NSNull null]) {
        self.titles = [dictionary objectForKey:@"story_titles"];
    }
    if ([dictionary objectForKey:@"fresh"] && [dictionary objectForKey:@"fresh"] != [NSNull null]) {
        self.fresh = [dictionary objectForKey:@"fresh"];
    }
    if ([dictionary objectForKey:@"public_circle"] && [dictionary objectForKey:@"public_circle"] != [NSNull null]) {
        self.publicCircle = [dictionary objectForKey:@"public_circle"];
    }
    if ([dictionary objectForKey:@"members"] && [dictionary objectForKey:@"members"] != [NSNull null]) {
        self.members = [dictionary objectForKey:@"members"];
    }
    if ([dictionary objectForKey:@"created_date"] && [dictionary objectForKey:@"created_date"] != [NSNull null]) {
        NSTimeInterval _interval = [[dictionary objectForKey:@"created_date"] doubleValue];
        self.createdDate = [NSDate dateWithTimeIntervalSince1970:_interval];
    }
    if ([dictionary objectForKey:@"unread_comments"] && [dictionary objectForKey:@"unread_comments"] != [NSNull null]) {
        self.unreadCommentCount = [NSNumber numberWithInteger:[self unreadComments:[dictionary objectForKey:@"unread_comments"]]];
    }
    if ([dictionary objectForKey:@"comments"] && [dictionary objectForKey:@"comments"] != [NSNull null]) {
        NSMutableOrderedSet *orderedComments = [NSMutableOrderedSet orderedSet];
        for (NSDictionary *commentDict in [dictionary objectForKey:@"comments"]){
            if ([commentDict objectForKey:@"id"] != [NSNull null]){
                Comment *comment = [Comment MR_findFirstByAttribute:@"identifier" withValue:[commentDict objectForKey:@"id"] inContext:[NSManagedObjectContext MR_defaultContext]];
                if (!comment){
                    comment = [Comment MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                }
                [comment populateFromDict:commentDict];
                [orderedComments addObject:comment];
            }
        }
        for (Comment *comment in self.comments){
            if (![orderedComments containsObject:comment]){
                NSLog(@"Deleting a circle comment that no longer exist.");
                [comment MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
            }
        }
        self.comments = orderedComments;
    }
    if ([dictionary objectForKey:@"stories"] && [dictionary objectForKey:@"stories"] != [NSNull null]) {
        //NSLog(@"stories dict: %@",[dictionary objectForKey:@"stories"]);
        NSMutableOrderedSet *orderedStories = [NSMutableOrderedSet orderedSet];
        for (NSDictionary *storyDict in [dictionary objectForKey:@"stories"]){
            if ([storyDict objectForKey:@"id"] != [NSNull null]){
                Story *story = [Story MR_findFirstByAttribute:@"identifier" withValue:[storyDict objectForKey:@"id"] inContext:[NSManagedObjectContext MR_defaultContext]];
                if (!story){
                    story = [Story MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                }
                [story populateFromDict:storyDict];
                [orderedStories addObject:story];
            }
        }
        for (Story *story in self.stories){
            if (![orderedStories containsObject:story]){
                [self removeStory:story];
            }
        }
        self.stories = orderedStories;
    }
    if ([dictionary objectForKey:@"user"] && [dictionary objectForKey:@"user"] != [NSNull null]) {
        User *user = [User MR_findFirstByAttribute:@"identifier" withValue:[[dictionary objectForKey:@"user"] objectForKey:@"id"] inContext:[NSManagedObjectContext MR_defaultContext]];
        if (!user){
            user = [User MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
        }
        [user populateFromDict:[dictionary objectForKey:@"user"]];
        self.owner = user;
    }
    if ([dictionary objectForKey:@"users"] && [dictionary objectForKey:@"users"] != [NSNull null]) {
        NSMutableOrderedSet *orderedUsers = [NSMutableOrderedSet orderedSet];
        for (NSDictionary *userDict in [dictionary objectForKey:@"users"]){
            if ([userDict objectForKey:@"id"] != [NSNull null]){
                User *user = [User MR_findFirstByAttribute:@"identifier" withValue:[userDict objectForKey:@"id"] inContext:[NSManagedObjectContext MR_defaultContext]];
                if (!user){
                    user = [User MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                }
                [user populateFromDict:userDict];
                [orderedUsers addObject:user];
            }
        }
        for (User *user in self.users){
            if (![orderedUsers containsObject:user]){
                [self removeUser:user];
            }
        }
        self.users = orderedUsers;
    }
}

- (NSInteger)unreadComments:(NSArray*)unreadComments {
    __block NSInteger unreadCount = 0;
    [unreadComments enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([[obj objectForKey:@"user_id"] isEqualToNumber:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]]) unreadCount ++;
    }];
    return unreadCount;
}

- (void)addComment:(Comment*)comment{
    NSMutableOrderedSet *set = [[NSMutableOrderedSet alloc] initWithOrderedSet:self.comments];
    [set addObject:comment];
    self.comments = set;
}

- (void)removeComment:(Comment*)comment{
    NSMutableOrderedSet *set = [[NSMutableOrderedSet alloc] initWithOrderedSet:self.comments];
    [set removeObject:comment];
    self.comments = set;
}

- (void)removeStory:(Story*)story{
    NSMutableOrderedSet *set = [[NSMutableOrderedSet alloc] initWithOrderedSet:self.stories];
    [set removeObject:story];
    self.stories = set;
}

- (void)addUser:(User*)user{
    NSMutableOrderedSet *set = [[NSMutableOrderedSet alloc] initWithOrderedSet:self.users];
    [set addObject:user];
    self.users = set;
}

- (void)removeUser:(User*)user{
    NSMutableOrderedSet *set = [[NSMutableOrderedSet alloc] initWithOrderedSet:self.users];
    [set removeObject:user];
    self.users = set;
}

@end

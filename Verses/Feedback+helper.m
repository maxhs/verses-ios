//
//  Feedback+helper.m
//  Verses
//
//  Created by Max Haines-Stiles on 6/10/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import "Feedback+helper.h"
#import "User+helper.h"
#import "Comment+helper.h"

@implementation Feedback (helper)
- (void)populateFromDict:(NSDictionary*)dictionary {
    if ([dictionary objectForKey:@"id"] && [dictionary objectForKey:@"id"] != [NSNull null]) {
        self.identifier = [dictionary objectForKey:@"id"];
    }

    if ([dictionary objectForKey:@"comments"] && [dictionary objectForKey:@"comments"] != [NSNull null]) {
        //NSLog(@"comments dict: %@",[dictionary objectForKey:@"comments"]);
        NSMutableOrderedSet *orderedComments = [NSMutableOrderedSet orderedSet];
        for (NSDictionary *commentDict in [dictionary objectForKey:@"comments"]){
            if ([commentDict objectForKey:@"id"] != [NSNull null]){
                Comment *comment = [Comment MR_findFirstByAttribute:@"identifier" withValue:[commentDict objectForKey:@"id"]];
                if (!comment){
                    comment = [Comment MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                }
                [comment populateFromDict:commentDict];
                [orderedComments addObject:comment];
            }
        }
        for (Comment *comment in self.comments){
            if (![orderedComments containsObject:comment]){
                [comment MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
            }
        }
        self.comments = orderedComments;
    }
    if ([dictionary objectForKey:@"user"] && [dictionary objectForKey:@"user"] != [NSNull null]) {
        User *user = [User MR_findFirstByAttribute:@"identifier" withValue:[[dictionary objectForKey:@"user"] objectForKey:@"id"]];
        if (!user){
            user = [User MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
        }
        [user populateFromDict:[dictionary objectForKey:@"user"]];
        self.user = user;
    }
    if ([dictionary objectForKey:@"recipient"] && [dictionary objectForKey:@"recipient"] != [NSNull null]) {
        User *recipient = [User MR_findFirstByAttribute:@"identifier" withValue:[[dictionary objectForKey:@"recipient"] objectForKey:@"id"]];
        if (!recipient){
            recipient = [User MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
        }
        [recipient populateFromDict:[dictionary objectForKey:@"recipient"]];
        self.recipient = recipient;
    }
    if ([dictionary objectForKey:@"story"] && [dictionary objectForKey:@"story"] != [NSNull null]) {
        NSDictionary *dict = [dictionary objectForKey:@"story"];
        Story *story = [Story MR_findFirstByAttribute:@"identifier" withValue:[dict objectForKey:@"id"]];
        if (!story){
            story = [Story MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
        }
        [story populateFromDict:dict];
        self.story = story;
    }
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

@end

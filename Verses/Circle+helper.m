//
//  Circle+helper.m
//  Verses
//
//  Created by Max Haines-Stiles on 6/10/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import "Circle+helper.h"

@implementation Circle (helper)
- (void)populateFromDict:(NSDictionary*)dictionary {
    if ([dictionary objectForKey:@"id"] != [NSNull null]) {
        self.identifier = [dictionary objectForKey:@"id"];
    }
    if ([dictionary objectForKey:@"description"] != [NSNull null]) {
        self.blurb = [dictionary objectForKey:@"description"];
    }
    if ([dictionary objectForKey:@"story_title"] != [NSNull null]) {
        self.titles = [dictionary objectForKey:@"story_title"];
    }
    if ([dictionary objectForKey:@"fresh"] != [NSNull null]) {
        self.fresh = [dictionary objectForKey:@"fresh"];
    }
    if ([dictionary objectForKey:@"created_date"] != [NSNull null]) {
        NSTimeInterval _interval = [[dictionary objectForKey:@"created_date"] doubleValue];
        self.createdDate = [NSDate dateWithTimeIntervalSince1970:_interval];
    }
    if ([dictionary objectForKey:@"unread_comments"] != [NSNull null]) {
        self.unreadCommentCount = [NSNumber numberWithInteger:[self unreadComments:[dictionary objectForKey:@"unread_comments"]]];
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

@end

//
//  Notification+helper.m
//  Verses
//
//  Created by Max Haines-Stiles on 6/10/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import "Notification+helper.h"
#import "Circle+helper.h"

@implementation Notification (helper)
- (void)populateFromDict:(NSDictionary*)dictionary {
    if ([dictionary objectForKey:@"id"] && [dictionary objectForKey:@"id"] != [NSNull null]) {
        self.identifier = [dictionary objectForKey:@"id"];
    }
    if ([dictionary objectForKey:@"message"] && [dictionary objectForKey:@"message"] != [NSNull null]) {
        self.message = [dictionary objectForKey:@"message"];
    }
    if ([dictionary objectForKey:@"read"] && [dictionary objectForKey:@"read"] != [NSNull null]) {
        self.read = [dictionary objectForKey:@"read"];
    }
    if ([dictionary objectForKey:@"notification_type"] && [dictionary objectForKey:@"notification_type"] != [NSNull null]) {
        self.type = [dictionary objectForKey:@"notification_type"];
    }
    if ([dictionary objectForKey:@"the_story_id"] && [dictionary objectForKey:@"the_story_id"] != [NSNull null]) {
        Story *story = [Story MR_findFirstByAttribute:@"identifier" withValue:[dictionary objectForKey:@"the_story_id"]];
        if (!story){
            story = [Story MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            story.identifier = [dictionary objectForKey:@"the_story_id"];
        }
        self.story = story;
    }
    if ([dictionary objectForKey:@"circle"] && [dictionary objectForKey:@"circle"] != [NSNull null]) {
        Circle *circle = [Circle MR_findFirstByAttribute:@"identifier" withValue:[[dictionary objectForKey:@"circle"] objectForKey:@"id"]];
        if (!circle){
            circle = [Circle MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
        }
        [circle populateFromDict:[dictionary objectForKey:@"circle"]];
        self.circle = circle;
    }
    if ([dictionary objectForKey:@"user"] && [dictionary objectForKey:@"user"] != [NSNull null]) {
        User *user = [User MR_findFirstByAttribute:@"identifier" withValue:[[dictionary objectForKey:@"user"] objectForKey:@"id"]];
        if (!user){
            user = [User MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
        }
        [user populateFromDict:[dictionary objectForKey:@"user"]];
        self.user = user;
    }
    if ([dictionary objectForKey:@"target_user"] && [dictionary objectForKey:@"target_user"] != [NSNull null]) {
        User *user = [User MR_findFirstByAttribute:@"identifier" withValue:[[dictionary objectForKey:@"target_user"] objectForKey:@"id"]];
        if (!user){
            user = [User MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
        }
        [user populateFromDict:[dictionary objectForKey:@"target_user"]];
        self.targetUser = user;
    }
    if ([dictionary objectForKey:@"created_date"] && [dictionary objectForKey:@"created_date"] != [NSNull null]) {
        NSTimeInterval _interval = [[dictionary objectForKey:@"created_date"] doubleValue];
        self.createdDate = [NSDate dateWithTimeIntervalSince1970:_interval];
    }
}
@end

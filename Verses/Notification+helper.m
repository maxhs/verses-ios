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
    if ([dictionary objectForKey:@"id"] != [NSNull null]) {
        self.identifier = [dictionary objectForKey:@"id"];
    }
    if ([dictionary objectForKey:@"message"] != [NSNull null]) {
        self.message = [dictionary objectForKey:@"message"];
    }
    if ([dictionary objectForKey:@"the_story_id"] != [NSNull null]) {
        Story *story = [Story MR_findFirstByAttribute:@"identifer" withValue:[dictionary objectForKey:@"the_story_id"]];
        if (!story){
            story = [Story MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            story.identifier = [dictionary objectForKey:@"the_story_id"];
        }
        self.story = story;
    }
    if ([dictionary objectForKey:@"circle"] != [NSNull null]) {
        Circle *circle = [Circle MR_findFirstByAttribute:@"identifer" withValue:[[dictionary objectForKey:@"circle"] objectForKey:@"id"]];
        if (!circle){
            circle = [Circle MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
        }
        [circle populateFromDict:[dictionary objectForKey:@"circle"]];
        self.circle = circle;
    }
    if ([dictionary objectForKey:@"created_date"] && [dictionary objectForKey:@"created_date"] != [NSNull null]) {
        NSTimeInterval _interval = [[dictionary objectForKey:@"created_date"] doubleValue];
        self.createdDate = [NSDate dateWithTimeIntervalSince1970:_interval];
    }
}
@end

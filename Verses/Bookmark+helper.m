//
//  Bookmark+helper.m
//  Verses
//
//  Created by Max Haines-Stiles on 6/10/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import "Bookmark+helper.h"
#import "User+helper.h"

@implementation Bookmark (helper)
- (void)populateFromDict:(NSDictionary*)dictionary {
    if ([dictionary objectForKey:@"id"] && [dictionary objectForKey:@"id"] != [NSNull null]) {
        self.identifier = [dictionary objectForKey:@"id"];
    }
    if ([dictionary objectForKey:@"story"] && [dictionary objectForKey:@"story"] != [NSNull null]) {
        NSDictionary *dict = [dictionary objectForKey:@"story"];
        Story *story = [Story MR_findFirstByAttribute:@"identifier" withValue:[dict objectForKey:@"id"]];
        if (story){
            self.story = story;
        }
        
    } else if ([dictionary objectForKey:@"contribution_story"] && [dictionary objectForKey:@"contribution_story"] != [NSNull null]) {
        NSDictionary *dict = [dictionary objectForKey:@"contribution_story"];
        Story *story = [Story MR_findFirstByAttribute:@"identifier" withValue:[dict objectForKey:@"id"]];
        if (story){
            //already have it
        } else {
            story = [Story MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            [story populateFromDict:dict];
        }
        
        self.story = story;
    }
    if ([dictionary objectForKey:@"contribution"] && [dictionary objectForKey:@"contribution"] != [NSNull null]) {
        NSDictionary *dict = [dictionary objectForKey:@"contribution"];
        Contribution *contribution = [Contribution MR_findFirstByAttribute:@"identifier" withValue:[dict objectForKey:@"id"]];
        if (contribution){
            [contribution update:dict];
        } else {
            contribution = [Contribution MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            [contribution populateFromDict:dict];
        }
        
        self.contribution = contribution;
    }
    if ([dictionary objectForKey:@"created_date"] && [dictionary objectForKey:@"created_date"] != [NSNull null]) {
        NSTimeInterval _interval = [[dictionary objectForKey:@"created_date"] doubleValue];
        self.createdDate = [NSDate dateWithTimeIntervalSince1970:_interval];
    }
}
@end

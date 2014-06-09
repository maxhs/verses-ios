//
//  Contribution+helper.m
//  Verses
//
//  Created by Max Haines-Stiles on 6/7/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import "Contribution+helper.h"
#import "User+helper.h"

@implementation Contribution (helper)
- (void)populateFromDict:(NSDictionary*)dictionary {
    if ([dictionary objectForKey:@"id"] && [dictionary objectForKey:@"id"] != [NSNull null]) {
        self.identifier = [dictionary objectForKey:@"id"];
    }
    if ([dictionary objectForKey:@"body"] && [dictionary objectForKey:@"body"] != [NSNull null]) {
        self.body = [dictionary objectForKey:@"body"];
    }
    if ([dictionary objectForKey:@"word_count"] && [dictionary objectForKey:@"word_count"] != [NSNull null]) {
        self.wordCount = [dictionary objectForKey:@"word_count"];
    }
    if ([dictionary objectForKey:@"user"] && [dictionary objectForKey:@"user"] != [NSNull null]) {
        User *user = [User MR_findFirstByAttribute:@"identifier" withValue:[[dictionary objectForKey:@"user"] objectForKey:@"id"]];
        if (!user){
            user = [User MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
        }
        [user populateFromDict:[dictionary objectForKey:@"user"]];
        self.user = user;
    }
    if ([dictionary objectForKey:@"created_date"] && [dictionary objectForKey:@"created_date"] != [NSNull null]) {
        NSTimeInterval _interval = [[dictionary objectForKey:@"created_date"] doubleValue];
        self.createdDate = [NSDate dateWithTimeIntervalSince1970:_interval];
    }
    if ([dictionary objectForKey:@"updated_date"] && [dictionary objectForKey:@"updated_date"] != [NSNull null]) {
        NSTimeInterval _interval = [[dictionary objectForKey:@"updated_date"] doubleValue];
        self.updatedDate = [NSDate dateWithTimeIntervalSince1970:_interval];
    }
    if ([dictionary objectForKey:@"published_date"] && [dictionary objectForKey:@"published_date"] != [NSNull null]) {
        NSTimeInterval _interval = [[dictionary objectForKey:@"published_date"] doubleValue];
        self.publishedDate = [NSDate dateWithTimeIntervalSince1970:_interval];
    }
}
@end

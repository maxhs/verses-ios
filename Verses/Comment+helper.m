//
//  Comment+helper.m
//  Verses
//
//  Created by Max Haines-Stiles on 6/10/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import "Comment+helper.h"
#import "User+helper.h"

@implementation Comment (helper)
- (void)populateFromDict:(NSDictionary*)dictionary {
    if ([dictionary objectForKey:@"id"] && [dictionary objectForKey:@"id"] != [NSNull null]) {
        self.identifier = [dictionary objectForKey:@"id"];
    }
    if ([dictionary objectForKey:@"body"] && [dictionary objectForKey:@"body"] != [NSNull null]) {
        self.body = [dictionary objectForKey:@"body"];
    }
    if ([dictionary objectForKey:@"comment_type"] && [dictionary objectForKey:@"comment_type"] != [NSNull null]) {
        self.type = [dictionary objectForKey:@"comment_type"];
    }
    if ([dictionary objectForKey:@"read"] && [dictionary objectForKey:@"read"] != [NSNull null]) {
        self.read = [dictionary objectForKey:@"read"];
    }
    if ([dictionary objectForKey:@"created_date"] && [dictionary objectForKey:@"created_date"] != [NSNull null]) {
        NSTimeInterval _interval = [[dictionary objectForKey:@"created_date"] doubleValue];
        self.createdDate = [NSDate dateWithTimeIntervalSince1970:_interval];
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
        User *targetUser = [User MR_findFirstByAttribute:@"identifier" withValue:[[dictionary objectForKey:@"target_user"] objectForKey:@"id"]];
        if (!targetUser){
            targetUser = [User MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
        }
        [targetUser populateFromDict:[dictionary objectForKey:@"target_user"]];
        self.targetUser = targetUser;
    }
}
@end

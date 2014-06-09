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
    if ([dictionary objectForKey:@"id"] && [dictionary objectForKey:@"id"] != [NSNull null]) {
        self.identifier = [dictionary objectForKey:@"id"];
    }
    if ([dictionary objectForKey:@"pen_name"] && [dictionary objectForKey:@"pen_name"] != [NSNull null]) {
        self.penName = [dictionary objectForKey:@"pen_name"];
    }
    if ([dictionary objectForKey:@"email"] && [dictionary objectForKey:@"email"] != [NSNull null]) {
        self.email = [dictionary objectForKey:@"email"];
    }
    if ([dictionary objectForKey:@"pic_small_url"] && [dictionary objectForKey:@"pic_small_url"] != [NSNull null]) {
        self.picSmall = [dictionary objectForKey:@"pic_small_url"];
    }
}
@end

//
//  Photo+helper.m
//  Verses
//
//  Created by Max Haines-Stiles on 6/8/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import "Photo+helper.h"
#import <MagicalRecord/CoreData+MagicalRecord.h>
#import "Contribution+helper.h"

@implementation Photo (helper)
- (void)populateFromDict:(NSDictionary*)dictionary {
    if ([dictionary objectForKey:@"id"] && [dictionary objectForKey:@"id"] != [NSNull null]) {
        self.identifier = [dictionary objectForKey:@"id"];
    }
    if ([dictionary objectForKey:@"image_medium_url"] && [dictionary objectForKey:@"image_medium_url"] != [NSNull null]) {
        self.mediumUrl = [dictionary objectForKey:@"image_medium_url"];
        self.image = nil;
    }
    if ([dictionary objectForKey:@"image_small_url"] && [dictionary objectForKey:@"image_small_url"] != [NSNull null]) {
        self.smallUrl = [dictionary objectForKey:@"image_small_url"];
        self.image = nil;
    }
    if ([dictionary objectForKey:@"image_large_url"] && [dictionary objectForKey:@"image_large_url"] != [NSNull null]) {
        self.largeUrl = [dictionary objectForKey:@"image_large_url"];
        self.image = nil;
    }
    if ([dictionary objectForKey:@"image_thumb_url"] && [dictionary objectForKey:@"image_thumb_url"] != [NSNull null]) {
        self.thumbUrl = [dictionary objectForKey:@"image_thumb_url"];
        self.image = nil;
    }
    if ([dictionary objectForKey:@"created_date"] && [dictionary objectForKey:@"created_date"] != [NSNull null]) {
        NSTimeInterval _interval = [[dictionary objectForKey:@"created_date"] doubleValue];
        self.createdDate = [NSDate dateWithTimeIntervalSince1970:_interval];
    }
    if ([dictionary objectForKey:@"updated_date"] && [dictionary objectForKey:@"updated_date"] != [NSNull null]) {
        NSTimeInterval _interval = [[dictionary objectForKey:@"updated_date"] doubleValue];
        self.updatedDate = [NSDate dateWithTimeIntervalSince1970:_interval];
    }
    if ([dictionary objectForKey:@"contribution_id"] && [dictionary objectForKey:@"contribution_id"] != [NSNull null]) {
        Contribution *contribution = [Contribution MR_findFirstByAttribute:@"identifier" withValue:[dictionary objectForKey:@"contribution_id"] inContext:[NSManagedObjectContext MR_defaultContext]];
        if (contribution){
            self.contribution = contribution;
        }
    }
    if ([dictionary objectForKey:@"visible"] && [dictionary objectForKey:@"visible"] != [NSNull null]) {
        self.visible = [dictionary objectForKey:@"visible"];
    }
}

- (void)update:(NSDictionary*)dictionary {
    if ([dictionary objectForKey:@"image_medium_url"] && [dictionary objectForKey:@"image_medium_url"] != [NSNull null]) {
        self.mediumUrl = [dictionary objectForKey:@"image_medium_url"];
        self.image = nil;
    }
    if ([dictionary objectForKey:@"image_small_url"] && [dictionary objectForKey:@"image_small_url"] != [NSNull null]) {
        self.smallUrl = [dictionary objectForKey:@"image_small_url"];
        self.image = nil;
    }
    if ([dictionary objectForKey:@"image_large_url"] && [dictionary objectForKey:@"image_large_url"] != [NSNull null]) {
        self.largeUrl = [dictionary objectForKey:@"image_large_url"];
        self.image = nil;
    }
    if ([dictionary objectForKey:@"image_thumb_url"] && [dictionary objectForKey:@"image_thumb_url"] != [NSNull null]) {
        self.thumbUrl = [dictionary objectForKey:@"image_thumb_url"];
        self.image = nil;
    }
    if ([dictionary objectForKey:@"updated_date"] && [dictionary objectForKey:@"updated_date"] != [NSNull null]) {
        NSTimeInterval _interval = [[dictionary objectForKey:@"updated_date"] doubleValue];
        self.updatedDate = [NSDate dateWithTimeIntervalSince1970:_interval];
    }
    if ([dictionary objectForKey:@"visible"] && [dictionary objectForKey:@"visible"] != [NSNull null]) {
        self.visible = [dictionary objectForKey:@"visible"];
    }
}
@end

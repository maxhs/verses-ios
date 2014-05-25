//
//  XXNotification.m
//  Verses
//
//  Created by Max Haines-Stiles on 11/4/13.
//  Copyright (c) 2013 Verses. All rights reserved.
//

#import "XXNotification.h"

@implementation XXNotification

- (void)setValue:(id)value forKey:(NSString *)key {
    if ([key isEqualToString:@"id"]) {
        self.identifier = [value stringValue];
    } else if ([key isEqualToString:@"message"]) {
        self.message = value;
    } else if ([key isEqualToString:@"contribution"]) {
        self.contribution = [[XXContribution alloc] initWithDictionary:value];
    } else if ([key isEqualToString:@"photos"]) {
        self.photos = value;
    } else if ([key isEqualToString:@"epoch_time"]) {
        self.epochTime = value;
        NSTimeInterval _interval = [value doubleValue];
        self.createdAt = [NSDate dateWithTimeIntervalSince1970:_interval];
    } else if ([key isEqualToString:@"created_month"]) {
        self.createdMonth = value;
    } else if ([key isEqualToString:@"created_time"]) {
        self.createdTime = value;
    } else if ([key isEqualToString:@"the_story_id"]) {
        self.storyId = value;
    } else if ([key isEqualToString:@"story_title"]) {
        self.storyTitle = value;
    } else if ([key isEqualToString:@"circle"]) {
        self.circle = [[XXCircle alloc] initWithDictionary:value];
    } else if ([key isEqualToString:@"target_user"]) {
        self.targetUser = [[XXUser alloc] initWithDictionary:value];
    } else if ([key isEqualToString:@"notification_type"]) {
        self.type = value;
    } else if ([key isEqualToString:@"read"]) {
        self.read = [value boolValue];
    }
}

- (id)initWithDictionary:(NSDictionary *)dictionary {
    if (self = [super init]) {
        [self setValuesForKeysWithDictionary:dictionary];
    }
    
    return self;
}

- (void)setValuesForKeysWithDictionary:(NSDictionary *)keyedValues {
    [super setValuesForKeysWithDictionary:keyedValues];
}

@end

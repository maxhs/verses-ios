//
//  XXFeedback.m
//  Verses
//
//  Created by Max Haines-Stiles on 3/16/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import "XXFeedback.h"

@implementation XXFeedback

- (void)setValue:(id)value forKey:(NSString *)key {
    if ([key isEqualToString:@"id"]) {
        self.identifier = [value stringValue];
    } else if ([key isEqualToString:@"snippet"]) {
        self.snippet = value;
    } else if ([key isEqualToString:@"user"]) {
        self.user = [[XXUser alloc] initWithDictionary:value];
    } else if ([key isEqualToString:@"recipient"]) {
        self.recipient = [[XXUser alloc] initWithDictionary:value];
    } else if ([key isEqualToString:@"story"]) {
        self.story = [[XXStory alloc] initWithDictionary:value];
    } else if ([key isEqualToString:@"comments"]) {
        self.comments = [[Utilities commentsFromJSONArray:value] mutableCopy];
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

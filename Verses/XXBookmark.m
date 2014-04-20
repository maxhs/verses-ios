//
//  XXBookmark.m
//  Verses
//
//  Created by Max Haines-Stiles on 3/26/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import "XXBookmark.h"

@implementation XXBookmark
- (void)setValue:(id)value forKey:(NSString *)key {
    if ([key isEqualToString:@"id"]) {
        self.identifier = value;
    } else if ([key isEqualToString:@"created_date"]) {
        NSTimeInterval _interval = [value doubleValue];
        self.createdDate = [NSDate dateWithTimeIntervalSince1970:_interval];
    } else if ([key isEqualToString:@"story"] || [key isEqualToString:@"contribution_story"]) {
        self.story = [[XXStory alloc] initWithDictionary:value];
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

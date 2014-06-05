//
//  XXContribution.m
//  Verses
//
//  Created by Max Haines-Stiles on 10/7/13.
//  Copyright (c) 2013 Verses. All rights reserved.
//

#import "XXContribution.h"
#import "XXUser.h"

@implementation XXContribution

- (void)setValue:(id)value forKey:(NSString *)key {
    if ([key isEqualToString:@"id"]) {
        self.identifier = value;
    } else if ([key isEqualToString:@"user"]) {
        self.user = [[XXUser alloc] initWithDictionary:value];
    } else if ([key isEqualToString:@"body"]) {
        self.body = value;
    } else if ([key isEqualToString:@"photos"]) {
        self.photos = [Utilities photosFromJSONArray:value];
    } else if ([key isEqualToString:@"allow_feedback"]) {
        self.allowFeedback = [value boolValue];
    } else if ([key isEqualToString:@"word_count"]) {
        self.wordCount = value;
    } else if ([key isEqualToString:@"created_date"]){
        self.epochTime = value;
        NSTimeInterval _interval = [value doubleValue];
        self.createdDate = [NSDate dateWithTimeIntervalSince1970:_interval];
    } else if ([key isEqualToString:@"updated_date"]){
        NSTimeInterval _interval = [value doubleValue];
        self.updatedDate = [NSDate dateWithTimeIntervalSince1970:_interval];
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

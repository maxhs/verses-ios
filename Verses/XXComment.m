//
//  XXComment.m
//  Verses
//
//  Created by Max Haines-Stiles on 3/17/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import "XXComment.h"

@implementation XXComment

- (void)setValue:(id)value forKey:(NSString *)key {
    if ([key isEqualToString:@"id"]) {
        self.identifier = [value stringValue];
    } else if ([key isEqualToString:@"body"]) {
        self.body = value;
    } else if ([key isEqualToString:@"comment_type"]) {
        self.type = value;
    } else if ([key isEqualToString:@"user"]) {
        self.user = [[XXUser alloc] initWithDictionary:value];
    } else if ([key isEqualToString:@"target_user"]) {
        self.targetUser = [[XXUser alloc] initWithDictionary:value];
    } else if ([key isEqualToString:@"created"]) {
        double unixTimeStamp = [value doubleValue];
        NSTimeInterval _interval=unixTimeStamp;
        self.createdDate = [NSDate dateWithTimeIntervalSince1970:_interval];
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

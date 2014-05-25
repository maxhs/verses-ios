//
//  XXCircle.m
//  Verses
//
//  Created by Max Haines-Stiles on 3/16/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import "XXCircle.h"

@implementation XXCircle

- (void)setValue:(id)value forKey:(NSString *)key {
    if ([key isEqualToString:@"id"]) {
        self.identifier = value;
    } else if ([key isEqualToString:@"name"]) {
        self.name = value;
    } else if ([key isEqualToString:@"description"]) {
        self.circleDescription = value;
    } else if ([key isEqualToString:@"story_titles"]) {
        self.titles = value;
    } else if ([key isEqualToString:@"user"]) {
        self.owner = [[XXUser alloc] initWithDictionary:value];
    } else if ([key isEqualToString:@"users"]) {
        self.users = [[Utilities usersFromJSONArray:value] mutableCopy];
    } else if ([key isEqualToString:@"comments"]) {
        self.comments = [[Utilities commentsFromJSONArray:value] mutableCopy];
    } else if ([key isEqualToString:@"stories"]) {
        self.stories = [[Utilities storiesFromJSONArray:value] mutableCopy];
    } else if ([key isEqualToString:@"public_circle"]) {
        self.publicCircle = [value boolValue];
    } else if ([key isEqualToString:@"created"]) {
        self.epochTime = value;
        NSTimeInterval _interval = [value doubleValue];
        self.createdDate = [NSDate dateWithTimeIntervalSince1970:_interval];
    } else if ([key isEqualToString:@"members"]) {
        self.members = value;
    } else if ([key isEqualToString:@"unread_comments"]) {
        self.unreadCommentCount = [self unreadComments:value];
    } else if ([key isEqualToString:@"fresh"]) {
        self.fresh = [value boolValue];
    }
}

- (NSUInteger)unreadComments:(NSArray*)unreadComments {
    __block NSUInteger unreadCount = 0;
    [unreadComments enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([[obj objectForKey:@"user_id"] isEqualToNumber:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]]) unreadCount ++;
    }];
    return unreadCount;
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

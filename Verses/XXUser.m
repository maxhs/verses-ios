//
//  XXUser.m
//  Verses
//
//  Created by Max Haines-Stiles on 10/7/13.
//  Copyright (c) 2013 Verses. All rights reserved.
//

#import "XXUser.h"

@implementation XXUser

- (void)setValue:(id)value forKey:(NSString *)key {
    if ([key isEqualToString:@"id"]) {
        self.identifier = [value stringValue];
    } else if ([key isEqualToString:@"email"]) {
        self.email = value;
    } else if ([key isEqualToString:@"pen_name"]) {
        self.penName = value;
    } else if ([key isEqualToString:@"location"]) {
        self.location = value;
    } else if([key isEqualToString:@"authentication_token"]) {
        self.authToken = value;
    }
}

//////////////////

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

//
//  XXPhoto.m
//  Verses
//
//  Created by Max Haines-Stiles on 10/30/13.
//  Copyright (c) 2013 Verses. All rights reserved.
//

#import "XXPhoto.h"

@implementation XXPhoto

- (void)setValue:(id)value forKey:(NSString *)key {
    if ([key isEqualToString:@"id"]) {
        self.identifier = [value stringValue];
    } else if ([key isEqualToString:@"image_large_url"]) {
        self.imageLargeUrl = [NSURL URLWithString:value];
    } else if ([key isEqualToString:@"image_medium_url"]) {
        self.imageMediumUrl = [NSURL URLWithString:value];
    } else if ([key isEqualToString:@"image_small_url"]) {
        self.imageSmallUrl = [NSURL URLWithString:value];
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

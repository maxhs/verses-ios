//
//  XXStory.m
//  Verses
//
//  Created by Max Haines-Stiles on 10/7/13.
//  Copyright (c) 2013 Verses. All rights reserved.
//

#import "XXStory.h"
#import "XXTag.h"
#import <DTCoreText/DTCoreText.h>
#import "XXTextStorage.h"

@implementation XXStory
@synthesize collaborators, contributions;
- (void)setValue:(id)value forKey:(NSString *)key {
    if ([key isEqualToString:@"id"]) {
        self.identifier = value;
    } else if ([key isEqualToString:@"title"]) {
        self.title = value;
    } else if ([key isEqualToString:@"owner"]) {
        self.owner = [[XXUser alloc] initWithDictionary:value];
    } else if ([key isEqualToString:@"author"]) {
        self.author = value;
    } else if ([key isEqualToString:@"authors"]) {
        self.authors = value;
    } else if ([key isEqualToString:@"users"]) {
        self.collaborators = [[Utilities usersFromJSONArray:value] mutableCopy];
    } else if ([key isEqualToString:@"circles"]) {
        self.circles = [[Utilities circlesFromJSONArray:value] mutableCopy];
    } else if ([key isEqualToString:@"mystery"]){
        self.mystery = [value boolValue];
    } else if ([key isEqualToString:@"contributions"]) {
        self.contributions = [[Utilities contributionsFromJSONArray:value] mutableCopy];
        int rangeAmount;
        if (self.mystery){
            rangeAmount = 250;
        } else if (IDIOM == IPAD) {
            rangeAmount = 1000;
        } else {
            rangeAmount = 700;
        }
        NSRange range;
        if ([[self.contributions.firstObject body] length] > rangeAmount){
            range = NSMakeRange(0, rangeAmount);
        } else {
            range = NSMakeRange(0, [[self.contributions.firstObject body] length]);
        }
        
        NSDictionary *options = @{DTUseiOS6Attributes: [NSNumber numberWithBool:YES],
                                  DTDefaultFontSize: @21,
                                  DTDefaultFontFamily: @"Crimson Text",
                                  NSTextEncodingNameDocumentOption: @"UTF-8"};
        DTHTMLAttributedStringBuilder *stringBuilder = [[DTHTMLAttributedStringBuilder alloc] initWithHTML:[[[self.contributions.firstObject body] substringWithRange:range] dataUsingEncoding:NSUTF8StringEncoding] options:options documentAttributes:nil];
        
        self.attributedSnippet = [stringBuilder generatedAttributedString];
    
    } else if ([key isEqualToString:@"photos"]) {
        self.photos = [Utilities photosFromJSONArray:value];
    } else if ([key isEqualToString:@"user_photos"]) {
        self.userPhotos = [Utilities photosFromJSONArray:value];
    } else if ([key isEqualToString:@"views"]){
        self.views = value;
    } else if ([key isEqualToString:@"word_count"]){
        self.wordCount = value;
    } else if ([key isEqualToString:@"trending_count"]){
        self.trendingCount = value;
    } else if ([key isEqualToString:@"minutes_to_read"]){
        self.minutesToRead = value;
    } else if ([key isEqualToString:@"created_date"]){
        self.epochTime = value;
        NSTimeInterval _interval = [value doubleValue];
        self.createdDate = [NSDate dateWithTimeIntervalSince1970:_interval];
    } else if ([key isEqualToString:@"updated_date"]){
        NSTimeInterval _interval = [value doubleValue];
        self.updatedDate = [NSDate dateWithTimeIntervalSince1970:_interval];
    } else if ([key isEqualToString:@"published_date"]){
        NSTimeInterval _interval = [value doubleValue];
        self.published = [NSDate dateWithTimeIntervalSince1970:_interval];
    } else if ([key isEqualToString:@"saved"]){
        self.saved = [value boolValue];
    } else if ([key isEqualToString:@"joinable"]){
        self.joinable = [value boolValue];
    } else if ([key isEqualToString:@"is_private"]){
        self.privateStory = [value boolValue];
    } else if ([key isEqualToString:@"bookmarked"]){
        self.bookmarked = [value boolValue];
    } else if ([key isEqualToString:@"to_param"]){
        self.storyUrl = [NSString stringWithFormat:@"%@/stories/%@",kBaseUrl,value];
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

- (XXContribution*)lastContribution {
    if (self.contributions.count){
        return self.contributions.lastObject;
    } else {
        return nil;
    }
}

- (XXContribution*)firstContribution {
    if (self.contributions.count){
        return self.contributions.firstObject;
    } else {
        return nil;
    }
}

- (id)initWithCoder:(NSCoder *)decoder {
    if (self = [super init]) {
        self.identifier = [decoder decodeObjectForKey:@"identifier"];
        self.title = [decoder decodeObjectForKey:@"title"];
        self.owner = [decoder decodeObjectForKey:@"owner"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.identifier forKey:@"identifier"];
    [coder encodeObject:self.title forKey:@"title"];
    [coder encodeObject:self.owner forKey:@"owner"];
}

@end

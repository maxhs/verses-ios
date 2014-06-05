//
//  XXUser.m
//  Verses
//
//  Created by Max Haines-Stiles on 10/7/13.
//  Copyright (c) 2013 Verses. All rights reserved.
//

#import "XXUser.h"
#import <SDWebImage/UIButton+WebCache.h>

@implementation XXUser

@synthesize userImage;

- (void)setValue:(id)value forKey:(NSString *)key {
    if ([key isEqualToString:@"id"]) {
        self.identifier = value;
    } else if ([key isEqualToString:@"email"]) {
        self.email = value;
    } else if ([key isEqualToString:@"first_name"]) {
        self.firstName = value;
    } else if ([key isEqualToString:@"last_name"]) {
        self.lastName = value;
    } else if ([key isEqualToString:@"pen_name"]) {
        self.penName = value;
    } else if ([key isEqualToString:@"location"]) {
        self.location = value;
    } else if ([key isEqualToString:@"bio"]) {
        self.bio = value;
    } else if ([key isEqualToString:@"day_job"]) {
        self.dayJob = value;
    } else if ([key isEqualToString:@"night_job"]) {
        self.nightJob = value;
    } else if([key isEqualToString:@"authentication_token"]) {
        self.authToken = value;
    } else if ([key isEqualToString:@"subscribed"]) {
        self.subscribed = [value boolValue];
    } else if([key isEqualToString:@"pic_medium_url"]) {
        self.picMediumUrl = value;
    } else if([key isEqualToString:@"pic_small_url"]) {
        self.picSmallUrl = value;
    } else if([key isEqualToString:@"pic_large_url"]) {
        self.picLargeUrl = value;
        [self downloadImageWithURL:[NSURL URLWithString:value] completionBlock:^(BOOL succeeded, UIImage *image) {
            self.largeImage = image;
        }];
    } else if ([key isEqualToString:@"story_count"]) {
        self.storyCount = value;
    } else if ([key isEqualToString:@"contact_count"]) {
        self.contactCount = value;
    } else if ([key isEqualToString:@"push_subscribe"]) {
        self.pushSubscribe = [value boolValue];
    } else if ([key isEqualToString:@"push_invitations"]) {
        self.pushInvitations = [value boolValue];
    } else if ([key isEqualToString:@"push_daily"]) {
        self.pushDaily = [value boolValue];
    } else if ([key isEqualToString:@"push_circle_publish"]) {
        self.pushCirclePublish = [value boolValue];
    } else if ([key isEqualToString:@"push_circle_comments"]) {
        self.pushCircleComments = [value boolValue];
    } else if ([key isEqualToString:@"push_weekly"]) {
        self.pushWeekly = [value boolValue];
    } else if ([key isEqualToString:@"push_permissions"]) {
        self.pushPermissions = [value boolValue];
    } else if ([key isEqualToString:@"push_feedbacks"]) {
        self.pushFeedbacks = [value boolValue];
    } else if ([key isEqualToString:@"push_bookmarks"]) {
        self.pushBookmarks = [value boolValue];
    } else if ([key isEqualToString:@"public_stories"]) {
        self.stories = [Utilities storiesFromJSONArray:value];
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

- (void)downloadImageWithURL:(NSURL *)url completionBlock:(void (^)(BOOL succeeded, UIImage *image))completionBlock
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               if ( !error )
                               {
                                   UIImage *image = [[UIImage alloc] initWithData:data];
                                   completionBlock(YES,image);
                               } else{
                                   completionBlock(NO,nil);
                               }
                           }];
}


@end

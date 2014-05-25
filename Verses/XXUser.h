//
//  XXUser.h
//  Verses
//
//  Created by Max Haines-Stiles on 10/7/13.
//  Copyright (c) 2013 Verses. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XXUser : NSObject

@property (strong, nonatomic) NSNumber *identifier;
@property (strong, nonatomic) NSString *email;
@property (strong, nonatomic) NSString *password;
@property (strong, nonatomic) NSString *penName;
@property (strong, nonatomic) NSString *firstName;
@property (strong, nonatomic) NSString *lastName;
@property (strong, nonatomic) NSString *location;
@property (strong, nonatomic) NSString *picLargeUrl;
@property (strong, nonatomic) UIImage *largeImage;
@property (strong, nonatomic) NSString *picMediumUrl;
@property (strong, nonatomic) NSString *picSmallUrl;
@property (strong, nonatomic) UIImage *userImage;
@property (strong, nonatomic) NSNumber *storyCount;
@property (strong, nonatomic) NSNumber *contactCount;
@property (strong, nonatomic) NSString *authToken;
@property (strong, nonatomic) NSArray *stories;
@property BOOL pushBookmarks;
@property BOOL pushCirclePublish;
@property BOOL pushCircleComments;
@property BOOL pushDaily;
@property BOOL pushPermissions;
@property BOOL pushInvitations;
@property BOOL pushSubscribe;
@property BOOL pushWeekly;
@property BOOL pushFeedbacks;

- (id) initWithDictionary:(NSDictionary*)dictionary;

@end

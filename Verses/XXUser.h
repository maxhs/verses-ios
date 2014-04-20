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
@property (strong, nonatomic) NSString *picMediumUrl;
@property (strong, nonatomic) NSString *picSmallUrl;
@property (strong, nonatomic) NSString *picThumbUrl;
@property (strong, nonatomic) NSNumber *storyCount;
@property (strong, nonatomic) NSNumber *contactCount;
@property (strong, nonatomic) UIImage *thumbImage;
@property (strong, nonatomic) NSString *authToken;
@property (strong, nonatomic) NSArray *stories;
@property BOOL pushBookmarks;
@property BOOL pushCirclePublish;
@property BOOL pushDaily;
@property BOOL pushPermissions;
@property BOOL pushInvitations;
@property BOOL pushSubscribe;
@property BOOL pushWeekly;
@property BOOL pushFeedbacks;

- (id) initWithDictionary:(NSDictionary*)dictionary;

@end

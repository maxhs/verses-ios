//
//  XXCircle.h
//  Verses
//
//  Created by Max Haines-Stiles on 3/16/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XXUser.h"
#import "XXComment.h"
#import "XXStory.h"

@interface XXCircle : NSObject
@property (strong, nonatomic) NSNumber *identifier;
@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSString *circleDescription;
@property (strong, nonatomic) XXUser *owner;
@property (strong, nonatomic) NSMutableArray *users;
@property (strong, nonatomic) NSMutableArray *comments;
@property (strong, nonatomic) NSMutableArray *stories;
@property (strong, nonatomic) NSString *titles;
@property (strong, nonatomic) NSNumber *epochTime;
@property (strong, nonatomic) NSDate *createdDate;
@property (strong, nonatomic) NSString *members;
@property (nonatomic) NSUInteger unreadCommentCount;
@property (nonatomic) BOOL publicCircle;
@property (nonatomic) BOOL fresh;

- (id) initWithDictionary:(NSDictionary*)dictionary;
@end

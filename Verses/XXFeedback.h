//
//  XXFeedback.h
//  Verses
//
//  Created by Max Haines-Stiles on 3/16/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XXUser.h"
#import "XXComment.h"
#import "XXStory.h"
#import "XXContribution.h"

@interface XXFeedback : NSObject
@property (strong, nonatomic) NSString *identifier;
@property (strong, nonatomic) NSString *snippet;
@property (strong, nonatomic) XXUser *user;
@property (strong, nonatomic) XXStory *story;
@property (strong, nonatomic) XXUser *recipient;
@property (strong, nonatomic) NSMutableArray *comments;

- (id) initWithDictionary:(NSDictionary*)dictionary;
@end

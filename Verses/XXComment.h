//
//  XXComment.h
//  Verses
//
//  Created by Max Haines-Stiles on 3/17/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XXUser.h"
#import "XXFeedback.h"

@interface XXComment : NSObject
@property (strong, nonatomic) NSString *identifier;
@property (strong, nonatomic) NSString *body;
@property (strong, nonatomic) NSString *type;
@property (strong, nonatomic) NSDate *createdDate;
@property (strong, nonatomic) XXUser *user;
@property (strong, nonatomic) XXUser *targetUser;
@property (nonatomic) CGSize rectSize;
@property (nonatomic) BOOL read;

- (id) initWithDictionary:(NSDictionary*)dictionary;
@end

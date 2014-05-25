//
//  XXContribution.h
//  Verses
//
//  Created by Max Haines-Stiles on 10/7/13.
//  Copyright (c) 2013 Verses. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XXUser.h"

@interface XXContribution : NSObject

@property (strong, nonatomic) NSNumber *identifier;
@property (strong, nonatomic) NSString *body;
@property (strong, nonatomic) XXUser *user;
@property (strong, nonatomic) NSArray *photos;
@property (strong, nonatomic) NSNumber *wordCount;
@property (strong, nonatomic) NSMutableArray *sections;

@property BOOL allowFeedback;

- (id) initWithDictionary:(NSDictionary*)dictionary;

@end

//
//  XXNotification.h
//  Verses
//
//  Created by Max Haines-Stiles on 11/4/13.
//  Copyright (c) 2013 Verses. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XXUser.h"
#import "XXContribution.h"
#import "XXPhoto.h"

@interface XXNotification : NSObject

@property (strong, nonatomic) NSString *identifier;
@property (strong, nonatomic) NSString *userName;
@property (strong, nonatomic) NSString *imageThumb;
@property (strong, nonatomic) NSString *message;
@property (strong, nonatomic) XXContribution *contribution;
@property (strong, nonatomic) NSMutableArray *photos;
@property (nonatomic, strong) NSDate * createdAt;
@property (nonatomic, strong) NSString * createdMonth;
@property (nonatomic, strong) NSString * createdTime;
@property (nonatomic, strong) NSNumber * storyId;
@property (nonatomic, strong) NSString * storyTitle;

- (id) initWithDictionary:(NSDictionary*)dictionary;

@end

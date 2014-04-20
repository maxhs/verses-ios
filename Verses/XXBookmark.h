//
//  XXBookmark.h
//  Verses
//
//  Created by Max Haines-Stiles on 3/26/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XXContribution.h"
#import "XXStory.h"

@interface XXBookmark : NSObject
@property (strong, nonatomic) NSNumber *identifier;
@property (strong, nonatomic) NSDate *createdDate;
@property (strong, nonatomic) XXStory *story;

- (id) initWithDictionary:(NSDictionary*)dictionary;
@end

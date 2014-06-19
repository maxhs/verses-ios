//
//  Tag.h
//  Verses
//
//  Created by Max Haines-Stiles on 6/12/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Contribution, Story;

@interface Tag : NSManagedObject

@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) Story *story;
@property (nonatomic, retain) Contribution *contribution;

@end

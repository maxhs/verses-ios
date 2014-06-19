//
//  Bookmark.h
//  Verses
//
//  Created by Max Haines-Stiles on 6/10/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Contribution, Story;

@interface Bookmark : NSManagedObject

@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSDate * createdDate;
@property (nonatomic, retain) Contribution *contribution;
@property (nonatomic, retain) Story *story;
@property (nonatomic, retain) User *user;

@end

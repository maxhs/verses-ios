//
//  Photo.h
//  Verses
//
//  Created by Max Haines-Stiles on 6/16/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Contribution, Story, User;

@interface Photo : NSManagedObject

@property (nonatomic, retain) NSDate * createdDate;
@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) id image;
@property (nonatomic, retain) NSString * largeUrl;
@property (nonatomic, retain) NSString * mediumUrl;
@property (nonatomic, retain) NSString * smallUrl;
@property (nonatomic, retain) NSString * thumbUrl;
@property (nonatomic, retain) NSDate * updatedDate;
@property (nonatomic, retain) Contribution *contribution;
@property (nonatomic, retain) Story *story;
@property (nonatomic, retain) User *user;

@end

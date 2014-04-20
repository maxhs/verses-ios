//
//  User.h
//  Verses
//
//  Created by Max Haines-Stiles on 3/16/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface User : NSManagedObject

@property (nonatomic, retain) NSString * email;
@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSString * location;
@property (nonatomic, retain) NSString * penName;
@property (nonatomic, retain) NSString * picThumb;
@property (nonatomic, retain) NSString * picSmall;
@property (nonatomic, retain) NSNumber * storyCount;
@property (nonatomic, retain) NSNumber * contactCount;

@end

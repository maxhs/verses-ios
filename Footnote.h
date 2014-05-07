//
//  Footnote.h
//  Verses
//
//  Created by Max Haines-Stiles on 5/2/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Footnote : NSManagedObject

@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSString * body;
@property (nonatomic, retain) NSManagedObject *story;

@end

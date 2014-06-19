//
//  Circle+helper.h
//  Verses
//
//  Created by Max Haines-Stiles on 6/10/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import "Circle.h"
#import "Comment+helper.h"
#import "User+helper.h"

@interface Circle (helper)
- (void)populateFromDict:(NSDictionary*)dictionary;
- (void)addComment:(Comment*)comment;
- (void)removeComment:(Comment*)comment;
@end

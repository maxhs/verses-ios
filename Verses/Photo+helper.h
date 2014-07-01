//
//  Photo+helper.h
//  Verses
//
//  Created by Max Haines-Stiles on 6/8/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import "Photo.h"

@interface Photo (helper)
- (void)populateFromDict:(NSDictionary*)dictionary;
- (void)update:(NSDictionary*)dictionary;
@end

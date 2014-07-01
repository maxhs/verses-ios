//
//  Contribution+helper.h
//  Verses
//
//  Created by Max Haines-Stiles on 6/7/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import "Contribution.h"
#import "Photo+helper.h"

@interface Contribution (helper)
- (void)populateFromDict:(NSDictionary*)dict;
- (void)update:(NSDictionary*)dict;
- (void)addPhoto:(Photo*)photo;
- (void)removePhoto:(Photo*)photo;
@end

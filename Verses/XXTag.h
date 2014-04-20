//
//  XXTag.h
//  Verses
//
//  Created by Max Haines-Stiles on 10/7/13.
//  Copyright (c) 2013 Verses. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XXTag : NSObject

@property (strong, nonatomic) NSString *identifier;
@property (strong, nonatomic) NSString *title;

- (id)initWithDictionary:(NSDictionary *)dictionary;

@end

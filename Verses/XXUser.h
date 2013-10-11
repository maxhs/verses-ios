//
//  XXUser.h
//  Verses
//
//  Created by Max Haines-Stiles on 10/7/13.
//  Copyright (c) 2013 Verses. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XXUser : NSObject

@property (strong, nonatomic) NSString *identifier;
@property (strong, nonatomic) NSString *email;
@property (strong, nonatomic) NSString *password;
@property (strong, nonatomic) NSString *penName;
@property (strong, nonatomic) NSString *location;
@property (strong, nonatomic) NSString *authToken;

- (id) initWithDictionary:(NSDictionary*)dictionary;

@end

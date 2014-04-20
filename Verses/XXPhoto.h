//
//  XXPhoto.h
//  Verses
//
//  Created by Max Haines-Stiles on 10/30/13.
//  Copyright (c) 2013 Verses. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XXPhoto : NSObject
@property (strong, nonatomic) NSString *identifier;
@property (strong, nonatomic) NSURL *imageSmallUrl;
@property (strong, nonatomic) NSURL *imageMediumUrl;
@property (strong, nonatomic) NSURL *imageLargeUrl;
@property (strong, nonatomic) UIImage *smallImage;
@property (strong, nonatomic) UIImage *mediumImage;
@property (strong, nonatomic) UIImage *largeImage;

- (id) initWithDictionary:(NSDictionary*)dictionary;

@end

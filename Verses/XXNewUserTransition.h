//
//  XXNewUserTransition.h
//  Verses
//
//  Created by Max Haines-Stiles on 5/25/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XXNewUserTransition : NSObject <UIViewControllerAnimatedTransitioning>

@property (nonatomic, assign, getter = isPresenting) BOOL presenting;

@end

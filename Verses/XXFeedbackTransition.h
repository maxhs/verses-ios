//
//  XXFeedbackTransition.h
//  Verses
//
//  Created by Max Haines-Stiles on 5/2/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XXFeedbackTransition : NSObject <UIViewControllerAnimatedTransitioning>

@property (nonatomic, assign, getter = isPresenting) BOOL presenting;

@end

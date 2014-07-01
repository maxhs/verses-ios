//
//  XXGuideAnimator.h
//  Verses
//
//  Created by Max Haines-Stiles on 7/1/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XXGuideAnimator : NSObject <UIViewControllerAnimatedTransitioning>

@property (nonatomic, assign, getter = isPresenting) BOOL presenting;



@end

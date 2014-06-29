//
//  XXGuideInteractor.h
//  Verses
//
//  Created by Max Haines-Stiles on 6/5/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "XXGuideViewController.h"

@interface XXGuideInteractor : UIPercentDrivenInteractiveTransition <UIViewControllerAnimatedTransitioning, UIViewControllerTransitioningDelegate, UIViewControllerInteractiveTransitioning, XXGuidePanTarget>

@property (nonatomic, readonly) UIViewController *parentViewController;
@property (nonatomic, assign, getter = isPresenting) BOOL presenting;
@property (nonatomic, assign, getter = isInteractive) BOOL interactive;
@property (nonatomic, strong) id<UIViewControllerContextTransitioning> transitionContext;
-(id)initWithParentViewController:(UIViewController *)viewController;

@end

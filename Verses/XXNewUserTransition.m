//
//  XXNewUserTransition.m
//  Verses
//
//  Created by Max Haines-Stiles on 5/25/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import "XXNewUserTransition.h"

@implementation XXNewUserTransition

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext {
    return .75f;
}

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext {
    // Grab the from and to view controllers from the context
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    if (self.presenting) {
        fromViewController.view.userInteractionEnabled = NO;
        [transitionContext.containerView addSubview:fromViewController.view];
        [transitionContext.containerView addSubview:toViewController.view];
        toViewController.view.alpha = 0;
        
        [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:1.0 usingSpringWithDamping:.85 initialSpringVelocity:.0001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            fromViewController.view.tintAdjustmentMode = UIViewTintAdjustmentModeDimmed;
            
            toViewController.view.alpha = 1.0;
        } completion:^(BOOL finished) {
            [transitionContext completeTransition:YES];
        }];
    } else {
        toViewController.view.userInteractionEnabled = YES;
        [transitionContext.containerView addSubview:toViewController.view];
        [transitionContext.containerView addSubview:fromViewController.view];
        
        [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0 usingSpringWithDamping:.65 initialSpringVelocity:.0001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            toViewController.view.tintAdjustmentMode = UIViewTintAdjustmentModeAutomatic;
            fromViewController.view.alpha = 0.0;
        } completion:^(BOOL finished) {
            [transitionContext completeTransition:YES];
        }];
    }
}

@end

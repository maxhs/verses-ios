//
//  XXGuideInteractor.m
//  Verses
//
//  Created by Max Haines-Stiles on 6/5/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import "XXGuideInteractor.h"
#import "XXStoriesViewController.h"
#import "XXGuideViewController.h"

@implementation XXGuideInteractor

-(id)initWithParentViewController:(UIViewController *)viewController {
    if (!(self = [super init])) return nil;
    
    _parentViewController = viewController;
    
    return self;
}

- (void)showGuide {
    XXGuideViewController *guide = [[(XXAppDelegate*)[UIApplication sharedApplication].delegate window].rootViewController.storyboard instantiateViewControllerWithIdentifier:@"Guide"];
    guide.transitioningDelegate = self;
    guide.modalPresentationStyle = UIModalPresentationCustom;
    [self.parentViewController presentViewController:guide animated:YES completion:nil];
}

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext {
    return .65f;
}

#pragma mark - UIViewControllerTransitioningDelegate Methods

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source {
    return self;
}

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    return self;
}

- (id <UIViewControllerInteractiveTransitioning>)interactionControllerForPresentation:(id <UIViewControllerAnimatedTransitioning>)animator {
    // Return nil if we are not interactive
    if (self.interactive) {
        return self;
    }
    
    return nil;
}

- (id <UIViewControllerInteractiveTransitioning>)interactionControllerForDismissal:(id <UIViewControllerAnimatedTransitioning>)animator {

    // Return nil if we are not interactive
    if (self.interactive) {
        return self;
    }
    
    return nil;
}

- (void)animationEnded:(BOOL)transitionCompleted {
    // Reset to our default state
    self.interactive = NO;
    self.presenting = NO;
    self.transitionContext = nil;
}

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext {
    //NSLog(@"Should be a normal transition here. Confirm not interactive: %u. presenting? %u",self.interactive, self.presenting);
    //we're not interactive anymore
    //self.interactive = NO;
    
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    // Set our ending frame. We'll modify this later if we have to
    CGRect endFrame = [UIScreen mainScreen].bounds;
    
    if (self.presenting) {
        fromViewController.view.userInteractionEnabled = NO;
        
        [transitionContext.containerView addSubview:fromViewController.view];
        [transitionContext.containerView addSubview:toViewController.view];
        
        CGRect startFrame = endFrame;
        startFrame.origin.y -= screenHeight();
        
        CGRect originEndFrame = endFrame;
        originEndFrame.origin.y += screenHeight();
        
        toViewController.view.frame = startFrame;
        
        [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0 usingSpringWithDamping:.8 initialSpringVelocity:.0001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            fromViewController.view.tintAdjustmentMode = UIViewTintAdjustmentModeDimmed;
            toViewController.view.frame = endFrame;
            fromViewController.view.frame = originEndFrame;
        } completion:^(BOOL finished) {
            [transitionContext completeTransition:YES];
        }];
    }
    else {
        toViewController.view.userInteractionEnabled = YES;
        
        [transitionContext.containerView addSubview:toViewController.view];
        [transitionContext.containerView addSubview:fromViewController.view];
        
        endFrame.origin.y -= screenHeight();
        CGRect originStartFrame = toViewController.view.frame;
        originStartFrame.origin.y = screenHeight();
        toViewController.view.frame = originStartFrame;
        CGRect originEndFrame = toViewController.view.frame;
        originEndFrame.origin.y = 0;
        
        [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0 usingSpringWithDamping:.95 initialSpringVelocity:.0001 options:UIViewAnimationOptionCurveEaseOut animations:^{
            toViewController.view.tintAdjustmentMode = UIViewTintAdjustmentModeAutomatic;
            fromViewController.view.frame = endFrame;
            toViewController.view.frame = originEndFrame;
        } completion:^(BOOL finished) {
            [transitionContext completeTransition:YES];
        }];
    }
}

- (void)setPresenting:(BOOL)presenting {
    _presenting = presenting;
}

-(void)userDidPan:(UIScreenEdgePanGestureRecognizer *)recognizer {
    NSLog(@"user did pan. are we interactive? %u",self.interactive);
    CGPoint location = [recognizer locationInView:self.parentViewController.view];
    CGPoint velocity = [recognizer velocityInView:self.parentViewController.view];
    

    if (recognizer.state == UIGestureRecognizerStateBegan) {
        NSLog(@"recognizer state began: y %f, recognizer y: %f",location.y, recognizer.view.bounds.origin.y);
        self.interactive = YES;
        
        // The side of the screen we're panning from determines whether this is a presentation (left) or dismissal (right)
        if (location.y < CGRectGetMidY(recognizer.view.bounds)) {
            self.presenting = YES;
            XXGuideViewController *vc = [[(XXAppDelegate*)[UIApplication sharedApplication].delegate window].rootViewController.storyboard instantiateViewControllerWithIdentifier:@"Guide"];
            vc.panTarget = self;
            vc.modalPresentationStyle = UIModalPresentationCustom;
            vc.transitioningDelegate = self;
            [self.parentViewController presentViewController:vc animated:YES completion:nil];
        }
        else {
            [self.parentViewController dismissViewControllerAnimated:YES completion:nil];
        }
    }
    else if (recognizer.state == UIGestureRecognizerStateChanged) {
        
        // Determine our ratio between the left edge and the right edge. This means our dismissal will go from 1...0.
        CGFloat ratio = location.y / CGRectGetHeight(self.parentViewController.view.bounds);
        NSLog(@"recognizer state changed: %f",ratio);
        [self updateInteractiveTransition:ratio];
    }
    else if (recognizer.state == UIGestureRecognizerStateEnded) {
        NSLog(@"recognizer state ended");
        // Depending on our state and the velocity, determine whether to cancel or complete the transition.
        if (self.presenting) {
            if (velocity.y > 0) {
                [self finishInteractiveTransition];
            }
            else {
                [self cancelInteractiveTransition];
            }
        }
        else {
            if (velocity.y < 0) {
                [self finishInteractiveTransition];
            }
            else {
                [self cancelInteractiveTransition];
            }
        }
    }
}

#pragma mark - UIViewControllerInteractiveTransitioning Methods

-(void)startInteractiveTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    self.transitionContext = transitionContext;
    NSLog(@"start interactive");
    
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    CGRect endFrame = [[transitionContext containerView] bounds];
    
    if (self.presenting)
    {
        // The order of these matters – determines the view hierarchy order.
        [transitionContext.containerView addSubview:fromViewController.view];
        [transitionContext.containerView addSubview:toViewController.view];
        
        endFrame.origin.y -= CGRectGetHeight([[transitionContext containerView] bounds]);
    }
    else {
        [transitionContext.containerView addSubview:toViewController.view];
        [transitionContext.containerView addSubview:fromViewController.view];
    }
    
    toViewController.view.frame = endFrame;
    
}

#pragma mark - UIPercentDrivenInteractiveTransition Overridden Methods

- (void)updateInteractiveTransition:(CGFloat)percentComplete {
    id<UIViewControllerContextTransitioning> transitionContext = self.transitionContext;
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    // Presenting goes from 0...1 and dismissing goes from 1...0
    CGRect frame = CGRectOffset([[transitionContext containerView] bounds], 0, -CGRectGetHeight([[transitionContext containerView] bounds]) * (1.0f - percentComplete));
    //NSLog(@"update interactive: x %f y %f",frame.origin.x, frame.origin.y);
    
    CGRect exitFrame = CGRectOffset([[transitionContext containerView] bounds], 0, -CGRectGetHeight([[transitionContext containerView] bounds]) * (1.0f - percentComplete));
    exitFrame.origin.y += screenHeight();
    
    if (self.presenting)
    {
        toViewController.view.frame = frame;
        fromViewController.view.frame = exitFrame;
    }
    else {
        fromViewController.view.frame = frame;
    }
}

- (void)finishInteractiveTransition {
    id<UIViewControllerContextTransitioning> transitionContext = self.transitionContext;
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    if (self.presenting)
    {
        CGRect endFrame = [[transitionContext containerView] bounds];
        
        [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0 usingSpringWithDamping:.95 initialSpringVelocity:.0001 options:UIViewAnimationOptionCurveEaseOut animations:^{
            toViewController.view.frame = endFrame;
        } completion:^(BOOL finished) {
            [transitionContext completeTransition:YES];
        }];
    }
    else {
        CGRect endFrame = CGRectOffset([[transitionContext containerView] bounds], 0, -CGRectGetHeight([[self.transitionContext containerView] bounds]));
        
        [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0 usingSpringWithDamping:.95 initialSpringVelocity:.0001 options:UIViewAnimationOptionCurveEaseOut animations:^{
            fromViewController.view.frame = endFrame;
        } completion:^(BOOL finished) {
            [transitionContext completeTransition:YES];
        }];
    }
    NSLog(@"finish interactive");
    self.interactive = NO;
}

- (void)cancelInteractiveTransition {
    id<UIViewControllerContextTransitioning> transitionContext = self.transitionContext;
    NSLog(@"cancelled interactive transition");
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    if (self.presenting)
    {
        CGRect endFrame = CGRectOffset([[transitionContext containerView] bounds], 0, -CGRectGetHeight([[transitionContext containerView] bounds]));
        
        [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0 usingSpringWithDamping:.95 initialSpringVelocity:.0001 options:UIViewAnimationOptionCurveEaseOut animations:^{
            toViewController.view.frame = endFrame;
        } completion:^(BOOL finished) {
            [transitionContext completeTransition:NO];
        }];
    }
    else {
        CGRect endFrame = [[transitionContext containerView] bounds];
        
        [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0 usingSpringWithDamping:.95 initialSpringVelocity:.0001 options:UIViewAnimationOptionCurveEaseOut animations:^{
            fromViewController.view.frame = endFrame;
        } completion:^(BOOL finished) {
            [transitionContext completeTransition:NO];
        }];
    }
}


@end

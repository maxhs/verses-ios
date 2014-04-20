//
//  XXProgress.m
//  Verses
//
//  Created by Max Haines-Stiles on 10/11/13.
//  Copyright (c) 2013 Verses. All rights reserved.
//

#import "XXProgress.h"
#import <QuartzCore/QuartzCore.h>

@interface CircleView : UIView
@end

@implementation CircleView

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.opaque = NO;
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [UIColor darkGrayColor].CGColor);
    CGContextFillEllipseInRect(context, rect);
}
@end

@interface XXProgress () {
    CircleView *leftCircle;
    CircleView *middleCircle;
    CircleView *rightCircle;
}
@property float interval;
@property int pointDiameter;

@end

@implementation XXProgress

static XXProgress *sharedView;

+ (XXProgress*)sharedView {
    static dispatch_once_t once;
    dispatch_once(&once, ^ { sharedView = [[XXProgress alloc] initWithFrame:CGRectMake(0,0,120,120) withPointDiameter:14 withInterval:.25]; });
    sharedView.layer.shadowColor = [UIColor blackColor].CGColor;
    sharedView.layer.shadowOpacity = 1;
    sharedView.layer.shadowOffset = CGSizeMake(0, 0);
    sharedView.layer.shadowRadius = 100;
    [sharedView setAlpha:0.0];
    UIWindow *window = [[[UIApplication sharedApplication] delegate] window];
        NSLog(@"window center from progress view: %f, %f",window.center.x, window.center.y);
    [sharedView setCenter:window.center];
    [window addSubview:sharedView];
    [window bringSubviewToFront:sharedView];
    return sharedView;
}

- (void)animateSharedView {
    [UIView animateWithDuration:.35 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [sharedView setAlpha:1.0];
    } completion:^(BOOL finished) {
        
    }];
}

+ (void)dismiss {
    [UIView animateWithDuration:.2 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        sharedView.transform = CGAffineTransformMakeScale(.8, .8);
        [sharedView setAlpha:0.0];
    } completion:^(BOOL finished) {
        [sharedView removeFromSuperview];
    }];
}

#pragma mark - Show Methods


- (id)initWithFrame:(CGRect)frame withPointDiameter:(int)diameter withInterval:(float)interval {
    if ((self = [super initWithFrame:frame])) {
        
        self.interval = interval;
        self.pointDiameter = diameter;
        
        self.backgroundColor = [UIColor whiteColor];
        self.layer.cornerRadius = self.frame.size.height/2;
        
        leftCircle = [self addCircleViewWithXOffsetFromCenter:-30];
        middleCircle = [self addCircleViewWithXOffsetFromCenter:0];
        rightCircle = [self addCircleViewWithXOffsetFromCenter:30];

        
        self.inProgress = YES;
        NSArray *circles = @[leftCircle, middleCircle, rightCircle];
        [self animate:circles];
    }
    return self;
}

- (CircleView*)addCircleViewWithXOffsetFromCenter:(float)offset {
    CGRect rect = CGRectMake(0, 0, self.pointDiameter, self.pointDiameter);
    CircleView *circle = [[CircleView alloc] initWithFrame:rect];
    circle.center = self.center;
    circle.frame = CGRectOffset(circle.frame, offset, 0);
    [self addSubview:circle];
    return circle;
}

- (void)animateWithViews:(NSArray*)circles index:(int)index delay:(float)delay offset:(float)offset {
    UIView *view = ((CircleView*)[circles objectAtIndex:index]);
    [UIView animateWithDuration:0.25 delay:delay options:UIViewAnimationOptionCurveEaseInOut animations:^{
        view.transform = CGAffineTransformMakeTranslation(0, -16);
        view.frame = CGRectMake(view.frame.origin.x - offset/2,
                                view.frame.origin.y - offset/2,
                                view.frame.size.width + offset,
                                view.frame.size.height + offset);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.35 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            view.frame = CGRectMake(view.frame.origin.x + offset/2,
                                    view.frame.origin.y + offset/2,
                                    view.frame.size.width - offset,
                                    view.frame.size.height - offset);
            view.transform = CGAffineTransformMakeTranslation(0, 4);
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:.2 animations:^{
                view.transform = CGAffineTransformIdentity;
            } completion:^(BOOL finished) {
                if (self.inProgress) {
                    if (index == 2) {
                        [self animate:circles];
                    }
                }
            }];
        }];
    }];
}

- (void)animate:(NSArray*)circles{
    [self animateWithViews:circles index:0 delay:self.interval*0.25 offset:self.pointDiameter];
    [self animateWithViews:circles index:1 delay:self.interval*0.75 offset:self.pointDiameter];
    [self animateWithViews:circles index:2 delay:self.interval*1.15 offset:self.pointDiameter];
}

@end

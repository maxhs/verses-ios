//
//  XXAlert.m
//  Verses
//
//  Created by Max Haines-Stiles on 5/17/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import "XXAlert.h"
#import "Constants.h"
#import "UIImage+ImageEffects.h"

@interface XXAlert () {
    CGFloat dismissTime;
    CGFloat width;
    CGFloat height;
}
@end

@implementation XXAlert

@synthesize window, background, label;

+ (XXAlert *)shared {
	static dispatch_once_t once = 0;
	static XXAlert *alert;
	dispatch_once(&once, ^{ alert = [[XXAlert alloc] init]; });
	return alert;
}

+ (void)dismiss {
	[[self shared] hideAlert];
}

+ (void)show:(NSString *)status withTime:(CGFloat)time {
	[[self shared] make:status spin:YES hide:NO withTime:time];
}

+ (void)show:(NSString *)status withTime:(CGFloat)time andOffset:(CGPoint)centerOffset {
	[[self shared] make:status spin:YES hide:NO withTime:time];
}

+ (void)showSuccess:(NSString *)status {
	//[[self shared] make:status imgage:HUD_IMAGE_SUCCESS spin:NO hide:YES];
}

+ (void)showError:(NSString *)status {
	//[[self shared] make:status imgage:HUD_IMAGE_ERROR spin:NO hide:YES];
}

- (id)init {
	self = [super initWithFrame:[[UIScreen mainScreen] bounds]];
	id<UIApplicationDelegate> delegate = [[UIApplication sharedApplication] delegate];
	if ([delegate respondsToSelector:@selector(window)])
		window = [delegate performSelector:@selector(window)];
	else window = [[UIApplication sharedApplication] keyWindow];
    background = nil; label = nil;
	self.alpha = 0;
	return self;
}

- (void)make:(NSString *)status spin:(BOOL)spin hide:(BOOL)hide withTime:(CGFloat)time {
	dismissTime = time;
    [self create];
	label.text = status;
	label.hidden = (status == nil) ? YES : NO;
	[self orient];
	[self showAlert];
}

- (void)create {
	if (background == nil) {
        background = [[UIImageView alloc] initWithImage:[self blurredSnapshot]];
        [background setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
        [background setFrame:self.window.frame];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(rotate:) name:UIDeviceOrientationDidChangeNotification object:nil];
        [self addSubview:background];
	}

	if (label == nil) {
		label = [[UILabel alloc] initWithFrame:CGRectZero];
        if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
            label.font = [UIFont fontWithName:kSourceSansProRegular size:20];
            [label setTextColor:[UIColor whiteColor]];
        } else {
            label.font = [UIFont fontWithName:kSourceSansProLight size:20];
            [label setTextColor:[UIColor blackColor]];
        }
		label.backgroundColor = [UIColor clearColor];
		label.textAlignment = NSTextAlignmentCenter;
		label.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
		label.numberOfLines = 0;
        [background addSubview:label];
        [label setFrame:CGRectMake(10, background.frame.size.height/2-160, background.frame.size.width-20, 320)];
	}
}

-(UIImage *)blurredSnapshot {
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.f || UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation])){
        width = screenWidth();
        height = screenHeight();
    } else {
        width = screenHeight();
        height = screenWidth();
    }
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(width, height), NO, self.window.screen.scale);
    [self.window drawViewHierarchyInRect:CGRectMake(0, 0, width, height) afterScreenUpdates:NO];
    
    UIImage *snapshotImage = UIGraphicsGetImageFromCurrentImageContext();
    UIImage *blurredSnapshotImage;
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
        blurredSnapshotImage = [snapshotImage applyDarkEffect];
    } else {
        blurredSnapshotImage = [snapshotImage applyLightEffect];
    }
    UIGraphicsEndImageContext();
    return blurredSnapshotImage;
}

- (void)rotate:(NSNotification *)notification {
	[self orient];
}

- (void)orient {
	CGFloat rotate = 0.f;
    
	UIInterfaceOrientation orient = [[UIApplication sharedApplication] statusBarOrientation];
    
	if (orient == UIInterfaceOrientationPortrait)			rotate = 0.0;
	if (orient == UIInterfaceOrientationPortraitUpsideDown)	rotate = M_PI;
	if (orient == UIInterfaceOrientationLandscapeLeft)		rotate = - M_PI_2;
	if (orient == UIInterfaceOrientationLandscapeRight)		rotate = + M_PI_2;
    
	background.transform = CGAffineTransformMakeRotation(rotate);
}

- (void)showAlert {
    [self.window addSubview:self];
	if (self.alpha == 0) {
		self.alpha = 1;
		background.alpha = 0;
		NSUInteger options = UIViewAnimationOptionAllowUserInteraction | UIViewAnimationCurveEaseOut;
		[UIView animateWithDuration:0.3 delay:0 options:options animations:^{
			background.alpha = 1;
		} completion:^(BOOL finished){
            [self performSelector:@selector(hideAlert) withObject:nil afterDelay:dismissTime];
        }];
	}
}

- (void)hideAlert {
	if (self.alpha == 1) {
		NSUInteger options = UIViewAnimationOptionAllowUserInteraction | UIViewAnimationCurveEaseIn;
		[UIView animateWithDuration:0.3 delay:0 options:options animations:^{
			background.alpha = 0;
		} completion:^(BOOL finished) {
             [self destroy];
             self.alpha = 0;
        }];
	}
}

- (void)destroy {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
	[label removeFromSuperview];	label = nil;
	[background removeFromSuperview];	background = nil;
}

- (void)timedHide {
	@autoreleasepool
	{
		double length = label.text.length;
		NSTimeInterval sleep = length * 0.04 + 0.5;
		
		[NSThread sleepForTimeInterval:sleep];
		[self hideAlert];
	}
}

@end

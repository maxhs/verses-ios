//
//  XXAlert.h
//  Verses
//
//  Created by Max Haines-Stiles on 5/17/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface XXAlert : UIView 

+ (XXAlert *)shared;

+ (void)dismiss;
+ (void)show:(NSString *)status withTime:(CGFloat)time;
+ (void)showSuccess:(NSString *)status;
+ (void)showError:(NSString *)status;

@property (atomic, strong) UIWindow *window;
@property (atomic, strong) UIImageView *background;
@property (atomic, strong) UILabel *label;
@end

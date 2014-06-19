//
//  Utilities.m
//  Verses
//
//  Created by Max Haines-Stiles on 10/11/13.
//  Copyright (c) 2013 Verses. All rights reserved.
//

#import "Utilities.h"


@implementation Utilities

+ (UIImageView *)findNavShadow:(UIView *)view {
    if ([view isKindOfClass:UIImageView.class] && view.bounds.size.height <= 1.0) {
        return (UIImageView *)view;
    }
    for (UIView *subview in view.subviews) {
        UIImageView *imageView = [self findNavShadow:subview];
        if (imageView) {
            return imageView;
        }
    }
    return nil;
}


@end

//
//  XXClipView.m
//  Verses
//
//  Created by Max Haines-Stiles on 6/7/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import "XXClipView.h"

@implementation XXClipView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

-(UIView*)hitTest:(CGPoint)point withEvent:(UIEvent*)event
{
    UIView* child = nil;
    if ((child = [super hitTest:point withEvent:event]) == self)
    	return _scrollView;
    return child;
}

@end

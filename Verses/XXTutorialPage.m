//
//  XXTutorialPage.m
//  Verses
//
//  Created by Max Haines-Stiles on 3/29/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import "XXTutorialPage.h"

@implementation XXTutorialPage {
    CGRect screen;
    CGFloat width;
    CGFloat height;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        screen = [UIScreen mainScreen].bounds;
        width = screen.size.width;
        height = screen.size.height;
        self.containerView = [[UIView alloc] initWithFrame:frame];
        [self addSubview:self.containerView];
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

-(void)initDesc:(NSString*)string withFrame:(CGRect)frame{
    self.desc = [[UILabel alloc] initWithFrame:frame];
    [self.desc setText:string];
    [self.desc setTextAlignment:NSTextAlignmentCenter];
    [self.desc setNumberOfLines:0];
    [self.desc setFont:[UIFont fontWithName:kSourceSansProLight size:18]];
    [self.desc setBackgroundColor:[UIColor clearColor]];
    [self.containerView addSubview:self.desc];
}

-(void)initExplanation:(NSString*)string withFrame:(CGRect)frame{
    self.explanation = [[UILabel alloc] initWithFrame:frame];
    [self.explanation setText:string];
    [self.explanation setTextAlignment:NSTextAlignmentCenter];
    [self.explanation setNumberOfLines:0];
    [self.explanation setTextColor:[UIColor blackColor]];
    [self.explanation setFont:[UIFont fontWithName:kCrimsonRoman size:23]];
    [self.explanation setBackgroundColor:[UIColor clearColor]];
    [self addSubview:self.explanation];
}

-(void)initTitle:(NSString*)string withFrame:(CGRect)frame{
    self.title = [[UILabel alloc] initWithFrame:frame];
    [self.title setText:string];
    [self.title setTextAlignment:NSTextAlignmentCenter];
    [self.title setNumberOfLines:0];
    [self.title setTextColor:[UIColor blackColor]];
    [self.title setFont:[UIFont fontWithName:kCrimsonRoman size:40]];
    [self.title setBackgroundColor:[UIColor clearColor]];
    [self addSubview:self.title];
}

@end

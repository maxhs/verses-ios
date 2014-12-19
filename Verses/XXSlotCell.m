//
//  XXSlotCell.m
//  Verses
//
//  Created by Max Haines-Stiles on 6/5/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import "XXSlotCell.h"
#import "Constants.h"

@implementation XXSlotCell {
    CGFloat width;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kHasSeenGuideView]){
        //[_rightButton setHidden:YES];
        //[_leftButton setHidden:YES];
    } else {
        //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hideArrow) name:@"HideRightArrow" object:nil];
    }
    
    /*
    [self styleButton:_firstButton];
    [self styleButton:_secondButton];
    [self styleButton:_thirdButton];
     */
}

- (void)styleButton:(UIButton*)button{
    button.layer.borderColor = [UIColor colorWithWhite:1 alpha:1].CGColor;
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
        button.layer.borderWidth = 1.f;
    } else {
        button.layer.borderWidth = 1.f;
    }
    button.layer.cornerRadius = 14.f;
    button.clipsToBounds = YES;
}

- (void)hideArrow {
    [_leftButton setHidden:YES];
    [_rightButton setHidden:YES];
}

- (void)configureWidth:(CGFloat)cellWidth {
    width = cellWidth;
    CGRect frame = self.frame;
    frame.size.width = width;
    [self setFrame:frame];
    [_scrollView setContentSize:CGSizeMake(width*1.5, 0)];
    [_firstButton.titleLabel setFont:[UIFont fontWithName:kSourceSansProSemibold size:18]];
    [_secondButton.titleLabel setFont:[UIFont fontWithName:kSourceSansProSemibold size:18]];
    [_thirdButton.titleLabel setFont:[UIFont fontWithName:kSourceSansProSemibold size:18]];
    [self setSmallAndHidden:_secondButton];
    [self setSmallAndHidden:_thirdButton];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

- (void)setSmallAndHidden:(UIButton*)button {
    CGFloat opacity = 1 - fabs(MIN(width*.625,width/2)/width*.625);
    button.alpha = opacity;
    button.transform = CGAffineTransformMakeScale(1 - fabs(MIN(width,width/2)/width*1.35), 1 - fabs(MIN(width,width/2)/width*1.35));
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView.contentOffset.x != _firstButton.frame.size.width && !_leftButton.isHidden){
        [UIView animateWithDuration:.5 animations:^{
            [_leftButton setAlpha:0.0];
            [_rightButton setAlpha:0.0];
        } completion:^(BOOL finished) {
            [_leftButton setHidden:YES];
            [_rightButton setHidden:YES];
        }];
        
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kHasSeenGuideView];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"HideRightArrow" object:nil];
    }
    
    //keep the arrows fixed inside the scrollview
    CGRect rightFrame = _rightButton.frame;
    rightFrame.origin.x += scrollView.contentOffset.x;
    [_rightButton setFrame:rightFrame];
    CGRect leftFrame = _leftButton.frame;
    leftFrame.origin.x += scrollView.contentOffset.x;
    [_leftButton setFrame:leftFrame];
    
    if (scrollView.contentOffset.x != 0){
        for (UIButton *button in scrollView.subviews) {
            CGFloat distanceFromCenterScreen = fabs(button.center.x - scrollView.frame.size.width/2 - scrollView.contentOffset.x);
            CGFloat opacity = 1 - fabs(MIN(width*.625,distanceFromCenterScreen)/width*.625);
            button.alpha = opacity;
            button.transform = CGAffineTransformMakeScale(1 - fabs(MIN(width,distanceFromCenterScreen)/width*1.35), 1 - fabs(MIN(width,distanceFromCenterScreen)/width*1.35));
        }
    }
}

- (IBAction)scrollRight{
    if (_scrollView.contentOffset.x < _firstButton.frame.size.width*2){
        [_scrollView setContentOffset:CGPointMake(_scrollView.contentOffset.x+_firstButton.frame.size.width, 0) animated:YES];
    }
}

- (IBAction)scrollLeft{
    if (_scrollView.contentOffset.x > 0){
        [_scrollView setContentOffset:CGPointMake(_scrollView.contentOffset.x-_firstButton.frame.size.width, 0) animated:YES];
    }
}

@end

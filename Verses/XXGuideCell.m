//
//  XXGuideCell.m
//  Verses
//
//  Created by Max Haines-Stiles on 6/5/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import "XXGuideCell.h"

@implementation XXGuideCell {
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
    button.transform = CGAffineTransformMakeScale(1 - fabs(MIN(width,width/2)/width), 1 - fabs(MIN(width,width/2)/width));
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    /*CGFloat x = scrollView.contentOffset.x;
    CGFloat alpha = (x/(width*.25));
    [_leftButton setAlpha:alpha];
    [_rightButton setAlpha:alpha];
    [_mainButton setAlpha:1-alpha];*/
    // fade in the labels as they approach the center of the screen
    if (scrollView.contentOffset.x != 0){
        for (UIButton *button in scrollView.subviews) {
            CGFloat distanceFromCenterScreen = fabs(button.center.x - scrollView.frame.size.width/2 - scrollView.contentOffset.x);
            CGFloat opacity = 1 - fabs(MIN(width*.625,distanceFromCenterScreen)/width*.625);
            button.alpha = opacity;
            button.transform = CGAffineTransformMakeScale(1 - fabs(MIN(width,distanceFromCenterScreen)/width), 1 - fabs(MIN(width,distanceFromCenterScreen)/width));
        }
    }
}

@end

//
//  XXTutorialView.m
//  Verses
//
//  Created by Max Haines-Stiles on 3/29/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import "XXTutorialView.h"
#import "XXTutorialPage.h"

@implementation XXTutorialView {
    CGRect screen;
    CGFloat width;
    CGFloat height;
    CGFloat a;
    XXTutorialPage *page1;
    XXTutorialPage *page2;
    XXTutorialPage *page3;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setAlpha:0.0];
        [self setBackgroundColor:[UIColor clearColor]];
        self.scrollView = [[UIScrollView alloc] initWithFrame:frame];
        [self.scrollView setDelegate:self];
        [self.scrollView setBackgroundColor:[UIColor clearColor]];
        self.scrollView.showsVerticalScrollIndicator = NO;
        self.scrollView.showsHorizontalScrollIndicator = NO;
        [self addSubview:self.scrollView];
        screen = [UIScreen mainScreen].bounds;
        width = screen.size.width;
        height = screen.size.height;
        [self.scrollView addSubview:[self createPage1]];
        [self.scrollView addSubview:[self createPage2]];
        [self.scrollView addSubview:[self createPage3]];
        page1.containerView.transform = CGAffineTransformMakeTranslation(0, 200);
        [page1.containerView setAlpha:0.0];
        page2.containerView.transform = CGAffineTransformMakeTranslation(screen.size.width,0);
        page3.containerView.transform = CGAffineTransformMakeTranslation(-2*screen.size.width,0);
        [page3.containerView setAlpha:0.0];
        
        [self.scrollView setContentSize:CGSizeMake(screen.size.width, screen.size.height*2)];
        
    }
    return self;
}

- (XXTutorialPage*)createPage1{
    page1 = [[XXTutorialPage alloc] initWithFrame:screen];
    [page1 initTitle:@"Hello!" withFrame:CGRectMake(30, 70, width-60, 50)];
    [page1 initExplanation:@"Here's a brief guide to getting around the app." withFrame:CGRectMake(20, 120, width-40, 120)];
    
    [page1 initDesc:@"Swipe up from the bottom to view more" withFrame:CGRectMake(40, height-100, width-80, 60)];
    page1.arrowImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"upArrow"]];
    [page1.arrowImageView setFrame:CGRectMake(width/2-32, height-160, 65, 35)];
    [page1.containerView addSubview:page1.arrowImageView];
    return page1;
}
- (XXTutorialPage*)createPage2{
    page2 = [[XXTutorialPage alloc] initWithFrame:screen];
    [page2 initTitle:@"Story Details" withFrame:CGRectMake(30, height+70, width-60, 50)];
    [page2 initExplanation:@"Read about the author, leave feedback, and more." withFrame:CGRectMake(20, height+140, width-40, 120)];
    
    [page2 initDesc:@"Swipe from the right to view story-specific info." withFrame:CGRectMake(40, height*2-100, width-80, 60)];
    page2.arrowImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"leftArrow"]];
    [page2.arrowImageView setFrame:CGRectMake(width-95, screen.size.height*2-180, 35, 65)];
    [page2.containerView addSubview:page2.arrowImageView];

    return page2;
}
- (XXTutorialPage*)createPage3{
    page3 = [[XXTutorialPage alloc] initWithFrame:screen];
    [page3 initTitle:@"Menu" withFrame:CGRectMake(30+width, height+70, width-60, 50)];
    [page3 initExplanation:@"Read, write, and discover - \n all accessible from the drawer on your left." withFrame:CGRectMake(20+width, height+140, width-40, 120)];
    [page3 initDesc:@"Swipe from the left to view your menu" withFrame:CGRectMake(40+width, height*2-100, width-80, 60)];
    
    page3.arrowImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"rightArrow"]];
    [page3.arrowImageView setFrame:CGRectMake(75+width, height*2-180, 35, 65)];
    [page3.containerView addSubview:page3.arrowImageView];
    return page3;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

-(void)showInView:(UIView*)view animateDuration:(CGFloat)duration withBackgroundImage:(UIImage *)image {
    [self setBackgroundColor:[UIColor colorWithPatternImage:image]];
    [view addSubview:self];
    [UIView animateWithDuration:duration animations:^{
        [self setAlpha:1.0];
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:.9 delay:1 usingSpringWithDamping:.5 initialSpringVelocity:.01 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            page1.containerView.transform = CGAffineTransformIdentity;
            [page1.containerView setAlpha:1.0];
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:2 delay:1 usingSpringWithDamping:.5 initialSpringVelocity:.01 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                
            } completion:^(BOOL finished) {
                
            }];
        }];
    }];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    CGFloat y = scrollView.contentOffset.y;
    CGFloat x = scrollView.contentOffset.x;
    
    NSLog(@"scrollview contents offsey x and y %f %f",x,y);
    
    if (y < screen.size.height && x == 0) {
        [scrollView setContentOffset:CGPointMake(0, screen.size.height) animated:YES];
        [self performSelector:@selector(page2transition) withObject:nil afterDelay:.75];
    } else if (y >= 568 && x == 0){
        [self page2transition];
    } else if (x > 0) {
        [scrollView setContentOffset:CGPointMake(screen.size.width, screen.size.height) animated:YES];
        [self performSelector:@selector(page3transition) withObject:nil afterDelay:.75];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    CGFloat y = scrollView.contentOffset.y;
    CGFloat x = scrollView.contentOffset.x;
    NSLog(@"scrollview end dragging x and y %f %f",x,y);
    if (y < screen.size.height && x == 0) {
        [scrollView setContentOffset:CGPointMake(0, screen.size.height) animated:YES];
        [self performSelector:@selector(page2transition) withObject:nil afterDelay:.75];
    } else if (y >= 568 && x == 0){
        
        [self page2transition];
    } else if (x > 0) {
        [scrollView setContentOffset:CGPointMake(screen.size.width, screen.size.height) animated:YES];
        [self performSelector:@selector(page3transition) withObject:nil afterDelay:.75];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat y = scrollView.contentOffset.y;
    CGFloat x = scrollView.contentOffset.x;
    NSLog(@"scrollview did scroll x and y %f %f",x,y);
}

- (void)page2transition{
    [self.scrollView setDirectionalLockEnabled:YES];
    [self.scrollView setContentSize:CGSizeMake(width*2, height*2)];
    [UIView animateWithDuration:.75 delay:0 usingSpringWithDamping:.5 initialSpringVelocity:.01 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        page2.containerView.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:3 delay:0 usingSpringWithDamping:.5 initialSpringVelocity:.01 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            page2.arrowImageView.transform = CGAffineTransformMakeTranslation(-width/2, 0);
        } completion:^(BOOL finished) {
            [self.scrollView setDirectionalLockEnabled:YES];
        }];
        
    }];
}

- (void)page3transition {
    [self.scrollView setDirectionalLockEnabled:YES];
    [self.scrollView setUserInteractionEnabled:NO];
    [UIView animateWithDuration:2 delay:.25 usingSpringWithDamping:.5 initialSpringVelocity:.005 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [page3.containerView setAlpha:1.0];
        page3.containerView.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:3 delay:.75 usingSpringWithDamping:.5 initialSpringVelocity:.01 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            page3.arrowImageView.transform = CGAffineTransformMakeTranslation(width/2, 0);
        } completion:^(BOOL finished) {
            
        }];
        
    }];
}

@end

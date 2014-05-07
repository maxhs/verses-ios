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
    XXTutorialPage *page4;
    UITapGestureRecognizer *page2tap;
    XXAppDelegate *delegate;
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
        self.scrollView.multipleTouchEnabled = YES;
        [self addSubview:self.scrollView];
        screen = frame;
        width = frame.size.width;
        height = frame.size.height;
        [self.scrollView addSubview:[self createPage1]];
        [self.scrollView addSubview:[self createPage2]];
        [self.scrollView addSubview:[self createPage3]];
        [self.scrollView addSubview:[self createPage4]];
        page1.transform = CGAffineTransformMakeTranslation(0, height/3);
        [page1 setAlpha:0.0];
        page3.transform = CGAffineTransformMakeScale(1.2, 1.2);
        [page3 setAlpha:0.0];
        [self.scrollView setContentSize:CGSizeMake(width, height*2)];
        delegate = (XXAppDelegate*)[UIApplication sharedApplication].delegate;
        [delegate.dynamicsDrawerViewController setPaneDragRevealEnabled:NO forDirection:MSDynamicsDrawerDirectionLeft];
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
    [page1 addSubview:page1.arrowImageView];
    return page1;
}
- (XXTutorialPage*)createPage2{
    page2 = [[XXTutorialPage alloc] initWithFrame:CGRectMake(0, height, width, height)];
    [page2 initTitle:@"Reading" withFrame:CGRectMake(30, 70, width-60, 50)];
    [page2 initExplanation:@"Tap story text to show or hide your reading menu." withFrame:CGRectMake(10, 130, width-20, 200)];
    page2tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showMenu)];
    page2tap.numberOfTapsRequired = 1;
    page2tap.delegate = self;
    [page2 initDesc:@"Tap the screen once to bring up your menu." withFrame:CGRectMake(40, height-100, width-80, 90)];
    page2.screenshotImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"menuShot"]];
    [page2.screenshotImageView setAlpha:0.0];
    if (screen.size.height != 568){
         [page2.screenshotImageView setFrame:CGRectMake(width/2-150, height-145, 300, 60)];
    } else {
        [page2.screenshotImageView setFrame:CGRectMake(width/2-150, height-200, 300, 60)];
    }
   
    page2.screenshotImageView.transform = CGAffineTransformMakeScale(.9, .9);
    [page2 addSubview:page2.screenshotImageView];
    
    return page2;
}

- (void)showMenu {
    if (page2.screenshotImageView.alpha == 0.0){
        [UIView animateWithDuration:.7 delay:0 usingSpringWithDamping:.5 initialSpringVelocity:.001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            [page2.screenshotImageView setAlpha:1.0];
            page2.screenshotImageView.transform = CGAffineTransformIdentity;
        } completion:^(BOOL finished) {
            
        }];
        [UIView animateWithDuration:.23 animations:^{
            [page2.desc setAlpha:0.0];
            [page2.explanation setAlpha:0.0];
        } completion:^(BOOL finished) {
            [page2.desc setText:@"Tap again to continue."];
            [page2.explanation setText:@"Use the menu to switch between dark and light settings, bookmark or edit stories, or view the stories menu."];
            [UIView animateWithDuration:.23 animations:^{
                [page2.desc setAlpha:1.0];
                [page2.explanation setAlpha:1.0];
            } completion:^(BOOL finished) {
                
            }];
        }];
    } else {
        [UIView animateWithDuration:1 delay:0 usingSpringWithDamping:.5 initialSpringVelocity:.0001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            page2.transform = CGAffineTransformMakeScale(.8, .8);
            [page2 setAlpha:0.0];
            page3.transform = CGAffineTransformIdentity;
            [page3 setAlpha:1.0];
        } completion:^(BOOL finished) {
            [self.scrollView setContentSize:CGSizeMake(width*2, height*2)];
            [self.scrollView removeGestureRecognizer:page2tap];
            self.scrollView.scrollEnabled = YES;
            [self page2transition];
        }];
    }
}

- (XXTutorialPage*)createPage3{
    page3 = [[XXTutorialPage alloc] initWithFrame:CGRectMake(0, height, width, height)];
    [page3 initTitle:@"Story Details" withFrame:CGRectMake(30, 70, width-60, 50)];
    [page3 initExplanation:@"Read about the author, leave feedback, and more." withFrame:CGRectMake(20, 140, width-40, 120)];
    [page3 initDesc:@"Swipe from the right to view story-specific info." withFrame:CGRectMake(40, height-100, width-80, 60)];
    page3.arrowImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"leftArrow"]];
    [page3.arrowImageView setFrame:CGRectMake(width-95, height-180, 35, 65)];
    [page3 addSubview:page3.arrowImageView];

    return page3;
}
- (XXTutorialPage*)createPage4{
    page4 = [[XXTutorialPage alloc] initWithFrame:CGRectMake(width, height, width, height)];
    [page4 initTitle:@"Menu" withFrame:CGRectMake(30, 70, width-60, 50)];
    [page4 initExplanation:@"Read, write, and discover - \n all accessible from the drawer on your left." withFrame:CGRectMake(20, 140, width-40, 120)];
    [page4 initDesc:@"Swipe from the left to view your menu" withFrame:CGRectMake(40, height-100, width-80, 60)];
    
    page4.arrowImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"rightArrow"]];
    [page4.arrowImageView setFrame:CGRectMake(75, height-180, 35, 65)];
    [page4 addSubview:page4.arrowImageView];
    return page4;
}

-(void)showInView:(UIView*)view animateDuration:(CGFloat)duration withBackgroundImage:(UIImage *)image {
    [self setBackgroundColor:[UIColor colorWithPatternImage:image]];
    [view addSubview:self];
    [UIView animateWithDuration:duration animations:^{
        [self setAlpha:1.0];
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:.9 delay:1 usingSpringWithDamping:.5 initialSpringVelocity:.01 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            page1.transform = CGAffineTransformIdentity;
            [page1 setAlpha:1.0];
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:2 delay:1 usingSpringWithDamping:.5 initialSpringVelocity:.01 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                
            } completion:^(BOOL finished) {
                
            }];
        }];
    }];
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView {
    CGFloat y = scrollView.contentOffset.y;
    CGFloat x = scrollView.contentOffset.x;
    if (y < screenHeight() && y > 0 && x == 0) {
        [scrollView setContentOffset:CGPointMake(0, screen.size.height) animated:YES];
    } else if (x > 0){
        NSLog(@"initiating page4 transition");
        [scrollView setContentOffset:CGPointMake(screen.size.width, screen.size.height) animated:YES];
        [self page4transition];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    CGFloat y = scrollView.contentOffset.y;
    CGFloat x = scrollView.contentOffset.x;
    if (y < screenHeight() && x == 0) {
        [scrollView setContentOffset:CGPointMake(0, screen.size.height) animated:YES];
    } else if (x > 0) {
        [scrollView setContentOffset:CGPointMake(screen.size.width, screen.size.height) animated:YES];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView.contentOffset.y >= screenHeight()){
        if (page2.screenshotImageView.alpha == 1.0){
            self.scrollView.scrollEnabled = YES;
            [self page2transition];
        } else {
             [self.scrollView addGestureRecognizer:page2tap];
        }
    }
}

- (void)page2transition{
    [self.scrollView setDirectionalLockEnabled:YES];
    [UIView animateWithDuration:.75 delay:.5 usingSpringWithDamping:.5 initialSpringVelocity:.01 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        page3.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:3 delay:0 usingSpringWithDamping:.5 initialSpringVelocity:.01 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            page3.arrowImageView.transform = CGAffineTransformMakeTranslation(-width/2, 0);
        } completion:^(BOOL finished) {
            [self.scrollView setContentSize:CGSizeMake(width*2, height*2)];
            [self.scrollView setDirectionalLockEnabled:YES];
        }];
        
    }];
}

- (void)page4transition {
    [self.scrollView setDirectionalLockEnabled:YES];
    [self.scrollView setUserInteractionEnabled:NO];
    [delegate.dynamicsDrawerViewController setPaneDragRevealEnabled:YES forDirection:MSDynamicsDrawerDirectionLeft];
    [UIView animateWithDuration:2 delay:.5 usingSpringWithDamping:.5 initialSpringVelocity:.005 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [page4 setAlpha:1.0];
        page4.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:3 delay:.75 usingSpringWithDamping:.5 initialSpringVelocity:.01 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            page4.arrowImageView.transform = CGAffineTransformMakeTranslation(width/2, 0);
        } completion:^(BOOL finished) {
            
        }];
    }];
}

@end

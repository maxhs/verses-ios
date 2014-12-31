//
//  XXNewUserWalkthroughViewController.m
//  Verses
//
//  Created by Max Haines-Stiles on 5/25/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import "XXAppDelegate.h"
#import "XXNewUserWalkthroughViewController.h"
#import "UIImage+ImageEffects.h"

@interface XXNewUserWalkthroughViewController () <UIScrollViewDelegate> {
    CGFloat height;
    CGFloat width;
    UIScrollView *_scrollView;
    UIImageView *_backgroundImageView;
    UIImageView *_blurredBackgroundImageView;
    NSInteger page;
    UIView *page1;
    UIView *page2;
    UIView *page3;
    UIView *page4;
    UITapGestureRecognizer *tapGesture;
    BOOL animating;
    BOOL swiped;
    BOOL shouldAnimate;
    UILabel *writeLabel;
    UIImageView *writeImage;
    UILabel *circleLabel;
    UIImageView *circleImage;
    UILabel *portfolioLabel;
    UIImageView *portfolioImage;
    UILabel *readLabel;
    UIImageView *readImage;
    UIImageView *rightArrow;
    UIImageView *swipeFromLeft;
    UILabel *moreDotsLabel;
    UILabel *swipeFromLeftLabel;
    UILabel *swipeFromRightLabel;
    UIImageView *swipeFromRight;
    UIButton *tapButton;
    UILabel *tapLabel;
    UIMotionEffectGroup *group;
    XXAppDelegate *delegate;
    UIPageControl *_pageControl;
    User *currentUser;
}

@end

@implementation XXNewUserWalkthroughViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    if (UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation]) || [[[UIDevice currentDevice] systemVersion] floatValue] >= 8.f){
        width = screenWidth();
        height = screenHeight();
    } else {
        width = screenHeight();
        height = screenWidth();
    }
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        currentUser = [User MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
    } completion:^(BOOL success, NSError *error) {
        //NSLog(@"just created a new current user: %@",currentUser);
    }];
    
    delegate = (XXAppDelegate*)[UIApplication sharedApplication].delegate;
    _scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, width, height)];
    [_scrollView setContentSize:CGSizeMake(width*4, height)];
    [_scrollView setPagingEnabled:YES];
    [_scrollView setShowsVerticalScrollIndicator:NO];
    [_scrollView setShowsHorizontalScrollIndicator:NO];
    [_scrollView setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    _scrollView.delegate = self;
    
    _backgroundImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, _scrollView.contentSize.width/2, height)];
    if (IDIOM == IPAD) {
        [_backgroundImageView setImage:[UIImage imageNamed:@"newUserBackgroundiPad"]];
    } else {
        //[_backgroundImageView setImage:[UIImage imageNamed:@"newUserBackground"]];
        [_backgroundImageView setImage:[UIImage imageNamed:@"mountains.jpg"]];
    }
    
    [_backgroundImageView setContentMode:UIViewContentModeScaleAspectFill];
    _blurredBackgroundImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, _scrollView.contentSize.width/2, height)];
    [_blurredBackgroundImageView setImage:[self blurredSnapshot]];
    [_blurredBackgroundImageView setContentMode:UIViewContentModeScaleAspectFill];
    
    UIInterpolatingMotionEffect *verticalMotionEffect = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.y" type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
    verticalMotionEffect.minimumRelativeValue = @(-23);
    verticalMotionEffect.maximumRelativeValue = @(23);
    UIInterpolatingMotionEffect *horizontalMotionEffect = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.x" type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
    horizontalMotionEffect.minimumRelativeValue = @(-23);
    horizontalMotionEffect.maximumRelativeValue = @(23);
    group = [UIMotionEffectGroup new];
    group.motionEffects = @[horizontalMotionEffect, verticalMotionEffect];
    
    shouldAnimate = YES;
    [self.view addSubview:_backgroundImageView];
    [self.view addSubview:_blurredBackgroundImageView];
    [self.view addSubview:_scrollView];
    [self createPage1];
    [self createPage2];
    [self createPage3];
    [self createPage4];
    [super viewDidLoad];
    
    _pageControl = [[UIPageControl alloc] initWithFrame:CGRectMake(width/2-60, height-30, 120, 30)];
    _pageControl.numberOfPages = 4;
    _pageControl.pageIndicatorTintColor = [UIColor colorWithWhite:1 alpha:.4];
    _pageControl.currentPageIndicatorTintColor = [UIColor whiteColor];
    [self.view addSubview:_pageControl];
    [self.view bringSubviewToFront:_pageControl];
}

- (void)createPage1 {
    page1 = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, height)];
    [page1 setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    [page1 setBackgroundColor:[UIColor clearColor]];
    UILabel *welcomeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, width, height/3)];
    [welcomeLabel setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    if (IDIOM == IPAD){
        [welcomeLabel setFont:[UIFont fontWithName:kSourceSansPro size:57]];
    } else {
        [welcomeLabel setFont:[UIFont fontWithName:kSourceSansPro size:47]];
    }
    [welcomeLabel setTextColor:[UIColor whiteColor]];
    [welcomeLabel setText:@"verses"];
    [welcomeLabel setTextAlignment:NSTextAlignmentCenter];
    [welcomeLabel setNumberOfLines:0];
    
    UILabel *descriptionLabel = [[UILabel alloc] initWithFrame:CGRectMake(width/12, height/3, width*5/6, height/3)];
    [descriptionLabel setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    [descriptionLabel setFont:[UIFont fontWithName:kTrashHand size:33]];
    [descriptionLabel setTextColor:[UIColor whiteColor]];
    [descriptionLabel setText:@"Read, write, and discover great stories."];
    [descriptionLabel setTextAlignment:NSTextAlignmentCenter];
    [descriptionLabel setNumberOfLines:0];
    
    UILabel *guideLabel = [[UILabel alloc] initWithFrame:CGRectMake(width/6, height*4/5, 150, height/5)];
    [guideLabel setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    [guideLabel setFont:[UIFont fontWithName:kSourceSansPro size:17]];
    [guideLabel setTextColor:[UIColor whiteColor]];
    [guideLabel setText:@"Here's a brief guide to getting around."];
    [guideLabel setTextAlignment:NSTextAlignmentLeft];
    [guideLabel setNumberOfLines:0];
    
    UIButton *rightArrowButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [rightArrowButton setFrame:CGRectMake(width*2/3, height*4/5, width/3, height/5)];
    [rightArrowButton addTarget:self action:@selector(moveRight) forControlEvents:UIControlEventTouchUpInside];
    
    rightArrow = [[UIImageView alloc] initWithFrame:CGRectMake(width*2/3, height*4/5, width/3, height/5)];
    [rightArrow setImage:[UIImage imageNamed:@"rightWhiteArrow"]];
    [rightArrow setContentMode:UIViewContentModeCenter];
    [self animateRightArrow];
    
    [page1 addSubview:rightArrow];
    [page1 addSubview:rightArrowButton];
    [page1 addSubview:descriptionLabel];
    [page1 addSubview:welcomeLabel];
    [page1 addSubview:guideLabel];
    [_scrollView addSubview:page1];
}

- (void)animateRightArrow {
    
    [UIView animateWithDuration:2 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        rightArrow.transform = CGAffineTransformMakeTranslation(10, 0);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:2 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            rightArrow.transform = CGAffineTransformIdentity;
        } completion:^(BOOL finished) {
            if (shouldAnimate) [self animateRightArrow];
        }];
    }];
}

- (void)moveRight {
    [_scrollView setContentOffset:CGPointMake(_scrollView.contentOffset.x+width, 0) animated:YES];
}

- (void)createPage2 {
    page2 = [[UIView alloc] initWithFrame:CGRectMake(width, 0, width, height)];
    [page2 setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    
    NSString *page1text;
    CGFloat writeY, circleY, portfolioY, readY, sectionHeight;
    if (IDIOM == IPAD) {
        page1text = @"Start new drafts or edit existing work. Easily control whether your work is private or ready to publish.";
        sectionHeight = height/8;
        writeY = height*7/8;
        circleY = height*5/8;
        portfolioY = height*3/4;
        readY = height/2;
    } else {
        page1text = @"Easily start new drafts, edit existing work, or simply jot notes.";
        sectionHeight = height/4;
        writeY = height*3/4;
        circleY = height/4;
        portfolioY = height/2;
        readY = 0;
    }
    
    
    readLabel = [[UILabel alloc] initWithFrame:CGRectMake(width/3, readY, width*2/3-8, sectionHeight)];
    [readLabel setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    [readLabel setFont:[UIFont fontWithName:kCrimsonRoman size:20]];
    [readLabel setTextColor:[UIColor whiteColor]];
    [readLabel setText:@"Read anything you want: no signup required."];
    [readLabel setNumberOfLines:0];
    [readLabel setTextAlignment:NSTextAlignmentLeft];
    [page2 addSubview:readLabel];
    
    readImage = [[UIImageView alloc] initWithFrame:CGRectMake(0, readY, width/3, sectionHeight)];
    [readImage setImage:[UIImage imageNamed:@"newUserRead"]];
    [readImage setContentMode:UIViewContentModeCenter];
    [page2 addSubview:readImage];
    
    writeLabel = [[UILabel alloc] initWithFrame:CGRectMake(width/3,writeY, width*2/3-8, sectionHeight)];
    [writeLabel setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    [writeLabel setFont:[UIFont fontWithName:kCrimsonRoman size:20]];
    [writeLabel setTextColor:[UIColor whiteColor]];
    [writeLabel setText:page1text];
    [writeLabel setNumberOfLines:0];
    [writeLabel setTextAlignment:NSTextAlignmentLeft];
    [page2 addSubview:writeLabel];
    
    writeImage = [[UIImageView alloc] initWithFrame:CGRectMake(0, writeY, width/3, sectionHeight)];
    [writeImage setImage:[UIImage imageNamed:@"newUserWrite"]];
    [writeImage setContentMode:UIViewContentModeCenter];
    [page2 addSubview:writeImage];
    
    circleLabel = [[UILabel alloc] initWithFrame:CGRectMake(width/3, circleY, width*2/3-8, sectionHeight)];
    [circleLabel setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    [circleLabel setFont:[UIFont fontWithName:kCrimsonRoman size:20]];
    [circleLabel setTextColor:[UIColor whiteColor]];
    [circleLabel setText:@"Stay up to date with your writing circles."];
    [circleLabel setNumberOfLines:0];
    [circleLabel setTextAlignment:NSTextAlignmentLeft];
    [page2 addSubview:circleLabel];
    
    circleImage = [[UIImageView alloc] initWithFrame:CGRectMake(0, circleY, width/3, sectionHeight)];
    [circleImage setImage:[UIImage imageNamed:@"newUserCircles"]];
    [circleImage setContentMode:UIViewContentModeCenter];
    [page2 addSubview:circleImage];
    
    portfolioLabel = [[UILabel alloc] initWithFrame:CGRectMake(width/3, portfolioY, width*2/3-8, sectionHeight)];
    [portfolioLabel setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    [portfolioLabel setFont:[UIFont fontWithName:kCrimsonRoman size:20]];
    [portfolioLabel setTextColor:[UIColor whiteColor]];
    [portfolioLabel setText:@"View your own work as well as all the stories shared with you."];
    [portfolioLabel setNumberOfLines:0];
    [portfolioLabel setTextAlignment:NSTextAlignmentLeft];
    [page2 addSubview:portfolioLabel];
    
    portfolioImage = [[UIImageView alloc] initWithFrame:CGRectMake(0, portfolioY, width/3, sectionHeight)];
    [portfolioImage setImage:[UIImage imageNamed:@"newUserPortfolio"]];
    [portfolioImage setContentMode:UIViewContentModeCenter];
    [page2 addSubview:portfolioImage];
    
    [_scrollView addSubview:page2];
    [self deanimateImages];
}

- (void)createPage3 {
    page3 = [[UIView alloc] initWithFrame:CGRectMake(width*2, 0, width, height)];
    [page3 setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    [page3 setBackgroundColor:[UIColor clearColor]];
    
    UIImageView *moreDots = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"moreWhite"]];
    [moreDots setFrame:CGRectMake(width-44, 0, 44, 44)];
    [moreDots setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin];
    [moreDots addMotionEffect:group];
    
    moreDotsLabel = [[UILabel alloc] initWithFrame:CGRectMake(width-234, 6, 180, 55)];
    moreDotsLabel.numberOfLines = 0;
    [moreDotsLabel setAlpha:0.0];
    [moreDotsLabel setTextColor:[UIColor whiteColor]];
    [moreDotsLabel setTextAlignment:NSTextAlignmentRight];
    [moreDotsLabel setFont:[UIFont fontWithName:kCrimsonRoman size:20]];
    [moreDotsLabel setText:@"Tap the dots for your navigation menu."];
    
    CGFloat leftY;
    if (IDIOM == IPAD){
        leftY = 90;
    } else {
        if ([UIScreen mainScreen].bounds.size.height == 568){
            leftY = 90;
        } else {
            leftY = 80;
        }
    }
    swipeFromLeftLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, leftY, width/2, height/4)];
    [swipeFromLeftLabel setAlpha:0.0];
    [swipeFromLeftLabel setFont:[UIFont fontWithName:kCrimsonRoman size:20]];
    [swipeFromLeftLabel setTextColor:[UIColor whiteColor]];
    [swipeFromLeftLabel setText:@"Swipe to the right for updates."];
    [swipeFromLeftLabel setTextAlignment:NSTextAlignmentRight];
    [swipeFromLeftLabel setNumberOfLines:0];
    swipeFromLeft = [[UIImageView alloc] initWithFrame:CGRectMake(width/4, leftY, width/2, height/4)];
    [swipeFromLeft setImage:[UIImage imageNamed:@"rightWhiteArrow"]];
    [swipeFromLeft setAlpha:0.0];
    [swipeFromLeft setContentMode:UIViewContentModeCenter];
    
    
    CGFloat yoffset;
    if (IDIOM == IPAD) {
        yoffset = height/3;
    } else {
        if ([UIScreen mainScreen].bounds.size.height == 568){
            yoffset = 220;
        } else {
            yoffset = 190;
        }
    }
    swipeFromRight = [[UIImageView alloc] initWithFrame:CGRectMake(width/4, yoffset, width/2, height/4)];
    [swipeFromRight setImage:[UIImage imageNamed:@"leftWhiteArrow"]];
    [swipeFromRight setContentMode:UIViewContentModeCenter];
    [swipeFromRight setAlpha:0.0];
    
    swipeFromRightLabel = [[UILabel alloc] initWithFrame:CGRectMake(width*1.25, yoffset, width*.6, height/4)];
    [swipeFromRightLabel setFont:[UIFont fontWithName:kCrimsonRoman size:20]];
    [swipeFromRightLabel setTextColor:[UIColor whiteColor]];
    [swipeFromRightLabel setText:@"Swipe to the left for more story info."];
    [swipeFromRightLabel setTextAlignment:NSTextAlignmentLeft];
    [swipeFromRightLabel setNumberOfLines:0];
    [swipeFromRightLabel setAlpha:0.0];
    
    tapButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [tapButton setImage:[UIImage imageNamed:@"whiteFlag"] forState:UIControlStateNormal];
    [tapButton setFrame:CGRectMake(width/2-30, height*.8, 60, 60)];
    tapButton.clipsToBounds = YES;
    [tapButton setContentMode:UIViewContentModeCenter];
    [tapButton setAlpha:0.0];
    tapButton.transform = CGAffineTransformMakeScale(.5, .5);
    [tapButton addTarget:self action:@selector(moveRight) forControlEvents:UIControlEventTouchUpInside];
    [tapButton addMotionEffect:group];
    
    tapLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, height*.6, width-40, height/4)];
    [tapLabel setFont:[UIFont fontWithName:kCrimsonRoman size:20]];
    [tapLabel setTextColor:[UIColor whiteColor]];
    [tapLabel setText:@"Tap a story for more options. Double tap text to leave feedback."];
    [tapLabel setTextAlignment:NSTextAlignmentCenter];
    [tapLabel setNumberOfLines:0];
    [tapLabel setAlpha:0.0];
    
    [page3 addSubview:moreDots];
    [page3 addSubview:moreDotsLabel];
    [page3 addSubview:swipeFromLeft];
    [page3 addSubview:swipeFromRight];
    [page3 addSubview:swipeFromRightLabel];
    [page3 addSubview:swipeFromLeftLabel];
    [page3 addSubview:tapLabel];
    [page3 addSubview:tapButton];
    [_scrollView addSubview:page3];
}

- (void)animateSwipeFromLeft {
    [UIView animateWithDuration:.5 delay:.1 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [moreDotsLabel setAlpha:1.0];
    }completion:^(BOOL finished) {
        
    }];
    
    [UIView animateWithDuration:2.3 delay:1 usingSpringWithDamping:.5 initialSpringVelocity:.0001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        swipeFromLeft.transform = CGAffineTransformMakeTranslation(width/4, 0);
        swipeFromLeftLabel.transform = CGAffineTransformMakeTranslation(width/8, 0);
        [swipeFromLeftLabel setAlpha:1.0];
        [swipeFromLeft setAlpha:1.0];
    } completion:^(BOOL finished) {
    
    }];
    
    //swipe from right
    [UIView animateWithDuration:2.3 delay:2 usingSpringWithDamping:.5 initialSpringVelocity:.0001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        swipeFromRight.transform = CGAffineTransformMakeTranslation(-width/3, 0);
        swipeFromRightLabel.transform = CGAffineTransformMakeTranslation(-width, 0);
        [swipeFromRight setAlpha:1.0];
        [swipeFromRightLabel setAlpha:1.0];
    } completion:^(BOOL finished) {
        [self animateTap];
    }];
    
    
    UIImageView *sun = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"whiteSun"]];
    [sun setFrame:CGRectMake(width/2-90, height*.8, 60, 60)];
    [sun setTintColor:[UIColor whiteColor]];
    [sun setContentMode:UIViewContentModeCenter];
    [page3 addSubview:sun];
    [sun setAlpha:0.0];
    [sun addMotionEffect:group];
    
    UIImageView *bookmark = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"whiteBookmark"]];
    [bookmark setTintColor:[UIColor whiteColor]];
    [bookmark setFrame:CGRectMake(width/2+30, height*.8, 60, 60)];
    [bookmark setContentMode:UIViewContentModeCenter];
    [page3 addSubview:bookmark];
    [bookmark setAlpha:0.0];
    [bookmark addMotionEffect:group];
    
    //tap animation
    [UIView animateWithDuration:.5 delay:3 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [tapButton setAlpha:1.0];
        [tapLabel setAlpha:1.0];
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:.5 animations:^{
            [sun setAlpha:1.0];
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:.5 animations:^{
                [bookmark setAlpha:1.0];
            } completion:^(BOOL finished) {
                
            }];
        }];
    }];
    
    [UIView animateWithDuration:3.3 delay:3 usingSpringWithDamping:.23 initialSpringVelocity:.001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [tapButton setAlpha:1.0];
        [tapLabel setAlpha:1.0];
        tapButton.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        
    }];
}

- (void)animateTap {
    
}

- (void)createPage4 {
    page4 = [[UIView alloc] initWithFrame:CGRectMake(width*3, 0, width, height)];
    [page4 setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    [page4 setBackgroundColor:[UIColor clearColor]];
    UILabel *endLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, width, height/4)];
    if (IDIOM == IPAD){
        [endLabel setFont:[UIFont fontWithName:kCrimsonRoman size:50]];
    } else {
        [endLabel setFont:[UIFont fontWithName:kCrimsonRoman size:40]];
    }
    
    [endLabel setTextColor:[UIColor whiteColor]];
    [endLabel setText:@"That's it!"];
    [endLabel setTextAlignment:NSTextAlignmentCenter];
    [endLabel setNumberOfLines:0];
    
    UILabel *guideLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, height*3/4, width-20, height/4)];
    [guideLabel setFont:[UIFont fontWithName:kCrimsonRoman size:23]];
    [guideLabel setTextColor:[UIColor whiteColor]];
    [guideLabel setText:@"(Tap anywhere to get started)."];
    [guideLabel setTextAlignment:NSTextAlignmentCenter];
    [guideLabel setNumberOfLines:0];
    
    [page4 addSubview:endLabel];
    [page4 addSubview:guideLabel];
    [_scrollView addSubview:page4];
}

- (void)end {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat x = scrollView.contentOffset.x;
    //NSLog(@"x scroll: %f",x);
    CGRect backgroundRect = _backgroundImageView.frame;
    if (x < 0){
        backgroundRect.origin.x = 0.f;
    } else if (x > _scrollView.contentSize.width){
        backgroundRect.origin.x = _scrollView.contentSize.width;
    } else {
        backgroundRect.origin.x = -x/3;
    }
    [_backgroundImageView setFrame:backgroundRect];
    [_blurredBackgroundImageView setFrame:backgroundRect];
    CGFloat alpha = 3-(x/(_scrollView.contentSize.width/4));
    [_blurredBackgroundImageView setAlpha:alpha];
    //NSLog(@"alpha: %f",alpha);
    //static NSInteger previousPage = 0;
    CGFloat pageWidth = scrollView.frame.size.width;
    float fractionalPage = x / pageWidth;
    page = floorf(fractionalPage);
    if (page == 1 && !animating){
        animating = YES;
        [self animateImages];
    
    } else if (page != 1 && !animating) {
        
        animating = YES;
        [self deanimateImages];
    }
    if (page == 2 && !swiped){
        [self animateSwipeFromLeft];
        swiped = YES;
    }
    if (page == 3 && !tapGesture){
        tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(end)];
        tapGesture.numberOfTapsRequired = 1;
        [self.view addGestureRecognizer:tapGesture];
    }
    int currentPage = floor((scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    _pageControl.currentPage = currentPage;
}

- (void)animateImages {
    animating = YES;
    [UIView animateWithDuration:.75 delay:0 usingSpringWithDamping:.777 initialSpringVelocity:.001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        readLabel.transform = CGAffineTransformIdentity;
        [readLabel setAlpha:1.0];
        readImage.transform = CGAffineTransformIdentity;
        [readImage setAlpha:1.0];
    } completion:^(BOOL finished) {
        
    }];
    [UIView animateWithDuration:.75 delay:.05 usingSpringWithDamping:.777 initialSpringVelocity:.001 options:UIViewAnimationOptionCurveEaseInOut animations:^{

        circleImage.transform = CGAffineTransformIdentity;
        [circleImage setAlpha:1.0];
        circleLabel.transform = CGAffineTransformIdentity;
        [circleLabel setAlpha:1.0];
    } completion:^(BOOL finished) {
        
    }];
    [UIView animateWithDuration:.75 delay:0.1 usingSpringWithDamping:.777 initialSpringVelocity:.001 options:UIViewAnimationOptionCurveEaseInOut animations:^{

        portfolioImage.transform = CGAffineTransformIdentity;
        [portfolioImage setAlpha:1.0];
        portfolioLabel.transform = CGAffineTransformIdentity;
        [portfolioLabel setAlpha:1.0];

    } completion:^(BOOL finished) {
        
    }];
    [UIView animateWithDuration:.75 delay:.15 usingSpringWithDamping:.777 initialSpringVelocity:.001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        writeLabel.transform = CGAffineTransformIdentity;
        [writeLabel setAlpha:1.0];
        writeImage.transform = CGAffineTransformIdentity;
        [writeImage setAlpha:1.0];
        
    } completion:^(BOOL finished) {
        animating = NO;
    }];
}

- (void)deanimateImages {
    [UIView animateWithDuration:.7 delay:0 usingSpringWithDamping:.6 initialSpringVelocity:.001 options:UIViewAnimationOptionCurveEaseIn animations:^{
        [writeImage setAlpha:0.0];
        [writeLabel setAlpha:0.0];
        [readLabel setAlpha:0.0];
        [readImage setAlpha:0.0];
        [circleLabel setAlpha:0.0];
        [circleImage setAlpha:0.0];
        [portfolioLabel setAlpha:0.0];
        [portfolioImage setAlpha:0.0];
        
    } completion:^(BOOL finished) {
        int writex = (int)arc4random_uniform(320)-160;
        int writey = (int)arc4random_uniform(568)-284;
        writeLabel.transform = CGAffineTransformMakeTranslation(writex, writey);
        writeImage.transform = CGAffineTransformMakeTranslation(writex, writey);
        
        int readx = (int)arc4random_uniform(320)-160;
        int ready = (int)arc4random_uniform(568)-284;
        readLabel.transform = CGAffineTransformMakeTranslation(readx, ready);
        readImage.transform = CGAffineTransformMakeTranslation(readx, ready);
        
        int circlex = (int)arc4random_uniform(320)-160;
        int circley = (int)arc4random_uniform(568)-284;
        circleLabel.transform = CGAffineTransformMakeTranslation(circlex, circley);
        circleImage.transform = CGAffineTransformMakeTranslation(circlex, circley);
        
        int portfoliox = (int)arc4random_uniform(320)-160;
        int portfolioy = (int)arc4random_uniform(568)-284;
        portfolioLabel.transform = CGAffineTransformMakeTranslation(portfoliox, portfolioy);
        portfolioImage.transform = CGAffineTransformMakeTranslation(portfoliox, portfolioy);
        animating = NO;
    }];
}

-(UIImage *)blurredSnapshot {
    UIImage *blurredSnapshotImage;
    if (IDIOM == IPAD) {
        blurredSnapshotImage = [[UIImage imageNamed:@"newUserBackgroundiPad"] applyBlurWithRadius:33 blurType:BOXFILTER tintColor:[UIColor clearColor] saturationDeltaFactor:1.8 maskImage:nil];
    } else {
        blurredSnapshotImage = [[UIImage imageNamed:@"mountains.jpg"] applyBlurWithRadius:43 blurType:BOXFILTER tintColor:[UIColor colorWithWhite:0 alpha:.1] saturationDeltaFactor:1.8 maskImage:nil];
    }
    [delegate.windowBackground setImage:blurredSnapshotImage];
    [delegate.windowBackground setContentMode:UIViewContentModeScaleAspectFill];
    currentUser.backgroundImageView = delegate.windowBackground;
    
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
        NSLog(@"%u saving new user",success);
    }];
    return blurredSnapshotImage;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidDisappear:(BOOL)animated {
    shouldAnimate = NO;
    rightArrow = nil;
    [super viewDidDisappear:animated];
}

@end

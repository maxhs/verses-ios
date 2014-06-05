//
//  XXNewUserWalkthroughViewController.m
//  Verses
//
//  Created by Max Haines-Stiles on 5/25/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

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
    UIImageView *swipeFromRight;
    UILabel *fromRightLabel;
    UIButton *tapButton;
    UILabel *tapLabel;
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
    if (UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation])){
        width = screenWidth();
        height = screenHeight();
    } else {
        width = screenHeight();
        height = screenWidth();
    }
    
    _scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, width, height)];
    [_scrollView setContentSize:CGSizeMake(width*4, height)];
    [_scrollView setPagingEnabled:YES];
    [_scrollView setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    [_scrollView setAutoresizingMask:UIViewAutoresizingFlexibleHeight];
    _scrollView.delegate = self;
    
    _backgroundImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, _scrollView.contentSize.width/2, height)];
    if (IDIOM == IPAD) {
        [_backgroundImageView setImage:[UIImage imageNamed:@"newUserBackgroundiPad"]];
    } else {
        [_backgroundImageView setImage:[UIImage imageNamed:@"newUserBackground"]];
    }
    
    [_backgroundImageView setContentMode:UIViewContentModeScaleAspectFill];
    _blurredBackgroundImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, _scrollView.contentSize.width/2, height)];
    [_blurredBackgroundImageView setImage:[self blurredSnapshot]];
    [_blurredBackgroundImageView setContentMode:UIViewContentModeScaleAspectFill];
    
    [self.view addSubview:_backgroundImageView];
    [self.view addSubview:_blurredBackgroundImageView];
    [self.view addSubview:_scrollView];
    [self createPage1];
    [self createPage2];
    [self createPage3];
    [self createPage4];
    [super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
}

- (void)createPage1 {
    page1 = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, height)];
    [page1 setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    [page1 setBackgroundColor:[UIColor clearColor]];
    UILabel *welcomeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, width, height/2)];
    [welcomeLabel setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    if (IDIOM == IPAD){
        [welcomeLabel setFont:[UIFont fontWithName:kSourceSansProRegular size:52]];
    } else {
        [welcomeLabel setFont:[UIFont fontWithName:kSourceSansProRegular size:42]];
    }
    
    [welcomeLabel setTextColor:[UIColor whiteColor]];
    [welcomeLabel setText:@"verses"];
    [welcomeLabel setTextAlignment:NSTextAlignmentCenter];
    [welcomeLabel setNumberOfLines:0];
    
    UILabel *guideLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, height*4/5, width*2/3, height/5)];
    [guideLabel setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    [guideLabel setFont:[UIFont fontWithName:kSourceSansProRegular size:18]];
    [guideLabel setTextColor:[UIColor whiteColor]];
    [guideLabel setText:@"Here's a brief guide to getting around."];
    [guideLabel setTextAlignment:NSTextAlignmentCenter];
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
            [self animateRightArrow];
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
        writeY = height/2;
        circleY = height*5/8;
        portfolioY = height*3/4;
        readY = height*7/8;
    } else {
        page1text = @"Easily start new drafts, edit existing work, or simply jot notes.";
        sectionHeight = height/4;
        writeY = 0;
        circleY = height/4;
        portfolioY = height/2;
        readY = height*3/4;
    }
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
    [circleLabel setText:@"Talk to your writing circles or review recent activity."];
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
    [portfolioLabel setText:@"View your full portfolio as well as the stories that have been shared with you."];
    [portfolioLabel setNumberOfLines:0];
    [portfolioLabel setTextAlignment:NSTextAlignmentLeft];
    [page2 addSubview:portfolioLabel];
    
    portfolioImage = [[UIImageView alloc] initWithFrame:CGRectMake(0, portfolioY, width/3, sectionHeight)];
    [portfolioImage setImage:[UIImage imageNamed:@"newUserPortfolio"]];
    [portfolioImage setContentMode:UIViewContentModeCenter];
    [page2 addSubview:portfolioImage];
    
    readLabel = [[UILabel alloc] initWithFrame:CGRectMake(width/3, readY, width*2/3-8, sectionHeight)];
    [readLabel setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    [readLabel setFont:[UIFont fontWithName:kCrimsonRoman size:20]];
    [readLabel setTextColor:[UIColor whiteColor]];
    [readLabel setText:@"No signup required: browse whatever you like. Bookmark stories you want to come back to."];
    [readLabel setNumberOfLines:0];
    [readLabel setTextAlignment:NSTextAlignmentLeft];
    [page2 addSubview:readLabel];
    
    readImage = [[UIImageView alloc] initWithFrame:CGRectMake(0, readY, width/3, sectionHeight)];
    [readImage setImage:[UIImage imageNamed:@"newUserRead"]];
    [readImage setContentMode:UIViewContentModeCenter];
    [page2 addSubview:readImage];
    
    [_scrollView addSubview:page2];
    [self deanimateImages];
}

- (void)createPage3 {
    page3 = [[UIView alloc] initWithFrame:CGRectMake(width*2, 0, width, height)];
    [page3 setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    [page3 setBackgroundColor:[UIColor clearColor]];
    
    UILabel *fromLeftLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, width-20, height/4)];
    [fromLeftLabel setFont:[UIFont fontWithName:kCrimsonRoman size:20]];
    [fromLeftLabel setTextColor:[UIColor whiteColor]];
    [fromLeftLabel setText:@"Swipe right to see your menu."];
    /*fromLeftLabel.shadowColor = [UIColor colorWithWhite:0 alpha:.1];
    fromLeftLabel.shadowOffset =  CGSizeMake(1, 1);*/
    [fromLeftLabel setTextAlignment:NSTextAlignmentCenter];
    [fromLeftLabel setNumberOfLines:0];
    
    swipeFromLeft = [[UIImageView alloc] initWithFrame:CGRectMake(width/4, 60, width/2, height/4)];
    [swipeFromLeft setImage:[UIImage imageNamed:@"rightWhiteArrow"]];
    [swipeFromLeft setContentMode:UIViewContentModeCenter];
    
    swipeFromRight = [[UIImageView alloc] initWithFrame:CGRectMake(width/4, height/3+60, width/2, height/4)];
    [swipeFromRight setImage:[UIImage imageNamed:@"leftWhiteArrow"]];
    [swipeFromRight setContentMode:UIViewContentModeCenter];
    [swipeFromRight setAlpha:0.0];
    
    fromRightLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, height/3, width-20, height/4)];
    [fromRightLabel setFont:[UIFont fontWithName:kCrimsonRoman size:20]];
    [fromRightLabel setTextColor:[UIColor whiteColor]];
    [fromRightLabel setText:@"Swipe left to see more about the story."];
    [fromRightLabel setTextAlignment:NSTextAlignmentCenter];
    [fromRightLabel setNumberOfLines:0];
    [fromRightLabel setAlpha:0.0];
    
    tapButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [tapButton setFrame:CGRectMake(width/2-30, (height*5/6)+10, 60, 60)];
    [tapButton setBackgroundColor:[UIColor clearColor]];
    [tapButton.layer setBorderColor:[UIColor whiteColor].CGColor];
    [tapButton.layer setBorderWidth:1.f];
    tapButton.layer.cornerRadius = 30.f;
    tapButton.clipsToBounds = YES;
    [tapButton setContentMode:UIViewContentModeCenter];
    [tapButton setAlpha:0.0];
    tapButton.transform = CGAffineTransformMakeScale(.5, .5);
    [tapButton addTarget:self action:@selector(moveRight) forControlEvents:UIControlEventTouchUpInside];
    
    tapLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, height*2/3, width-20, height/4)];
    [tapLabel setFont:[UIFont fontWithName:kCrimsonRoman size:20]];
    [tapLabel setTextColor:[UIColor whiteColor]];
    [tapLabel setText:@"Tap to bring up story controls, leave feedback, and more."];
    [tapLabel setTextAlignment:NSTextAlignmentCenter];
    [tapLabel setNumberOfLines:0];
    [tapLabel setAlpha:0.0];
    
    [page3 addSubview:swipeFromLeft];
    [page3 addSubview:swipeFromRight];
    [page3 addSubview:fromRightLabel];
    [page3 addSubview:fromLeftLabel];
    [page3 addSubview:tapLabel];
    [page3 addSubview:tapButton];
    [_scrollView addSubview:page3];
}

- (void)animateSwipeFromLeft {
    [UIView animateWithDuration:2.3 delay:0 usingSpringWithDamping:.5 initialSpringVelocity:.0001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        swipeFromLeft.transform = CGAffineTransformMakeTranslation(width/4, 0);
    } completion:^(BOOL finished) {
        [self animateSwipeFromRight];
    }];
}

- (void)animateSwipeFromRight {
    [UIView animateWithDuration:.5 animations:^{
        [swipeFromRight setAlpha:1.0];
        [fromRightLabel setAlpha:1.0];
    }];
    [UIView animateWithDuration:2.3 delay:0 usingSpringWithDamping:.5 initialSpringVelocity:.0001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        swipeFromRight.transform = CGAffineTransformMakeTranslation(-width/4, 0);
        
    } completion:^(BOOL finished) {
        [self animateTap];
    }];
}

- (void)animateTap {
    [UIView animateWithDuration:.5 animations:^{
        [tapButton setAlpha:1.0];
        [tapLabel setAlpha:1.0];
    }];
    [UIView animateWithDuration:3.3 delay:0 usingSpringWithDamping:.23 initialSpringVelocity:.001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [tapButton setAlpha:1.0];
        [tapLabel setAlpha:1.0];
        tapButton.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        
    }];
}

- (void)createPage4 {
    page4 = [[UIView alloc] initWithFrame:CGRectMake(width*3, 0, width, height)];
    [page4 setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    [page4 setBackgroundColor:[UIColor clearColor]];
    UILabel *endLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, width, height/2)];
    if (IDIOM == IPAD){
        [endLabel setFont:[UIFont fontWithName:kCrimsonRoman size:40]];
    } else {
        [endLabel setFont:[UIFont fontWithName:kCrimsonRoman size:30]];
    }
    
    [endLabel setTextColor:[UIColor whiteColor]];
    [endLabel setText:@"That's it!"];
    [endLabel setTextAlignment:NSTextAlignmentCenter];
    [endLabel setNumberOfLines:0];
    
    UILabel *guideLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, height*3/4, width-20, height/4)];
    [guideLabel setFont:[UIFont fontWithName:kCrimsonRoman size:20]];
    [guideLabel setTextColor:[UIColor whiteColor]];
    [guideLabel setText:@"(Tap anywhere to get started)."];
    [guideLabel setTextAlignment:NSTextAlignmentCenter];
    [guideLabel setNumberOfLines:0];
    
    [page4 addSubview:endLabel];
    [page4 addSubview:guideLabel];
    [_scrollView addSubview:page4];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    if (toInterfaceOrientation == UIInterfaceOrientationPortrait) {
        [_scrollView setFrame:CGRectMake(0, 0, width, height)];
        [_scrollView setContentSize:CGSizeMake(width*4, height)];
    } else {
        [_scrollView setFrame:CGRectMake(0, 0, height, width)];
        [_scrollView setContentSize:CGSizeMake(height*4, width)];
    }
}

- (void)end {
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
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
        backgroundRect.origin.x = -x/4;
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
}

- (void)animateImages {
    animating = YES;
    [UIView animateWithDuration:.75 delay:0 usingSpringWithDamping:.777 initialSpringVelocity:.001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        writeLabel.transform = CGAffineTransformIdentity;
        [writeLabel setAlpha:1.0];
        writeImage.transform = CGAffineTransformIdentity;
        [writeImage setAlpha:1.0];
        portfolioImage.transform = CGAffineTransformIdentity;
        [portfolioImage setAlpha:1.0];
        portfolioLabel.transform = CGAffineTransformIdentity;
        [portfolioLabel setAlpha:1.0];
        readLabel.transform = CGAffineTransformIdentity;
        [readLabel setAlpha:1.0];
        readImage.transform = CGAffineTransformIdentity;
        [readImage setAlpha:1.0];
        circleImage.transform = CGAffineTransformIdentity;
        [circleImage setAlpha:1.0];
        circleLabel.transform = CGAffineTransformIdentity;
        [circleLabel setAlpha:1.0];
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
        blurredSnapshotImage = [[UIImage imageNamed:@"newUserBackgroundiPad"] applyBlurWithRadius:40 blurType:BOXFILTER tintColor:[UIColor clearColor] saturationDeltaFactor:1.8 maskImage:nil];
    } else {
        blurredSnapshotImage = [[UIImage imageNamed:@"newUserBackground"] applyBlurWithRadius:40 blurType:BOXFILTER tintColor:[UIColor clearColor] saturationDeltaFactor:1.8 maskImage:nil];
    }
    [[(XXAppDelegate*)[UIApplication sharedApplication].delegate windowBackground] setImage:blurredSnapshotImage];
    
    return blurredSnapshotImage;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end

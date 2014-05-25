//
//  XXNewUserWalkthroughViewController.m
//  Verses
//
//  Created by Max Haines-Stiles on 5/25/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import "XXNewUserWalkthroughViewController.h"
#import "XXTutorialPage.h"
#import "XXTutorialView.h"
#import "UIImage+ImageEffects.h"

@interface XXNewUserWalkthroughViewController () <UIScrollViewDelegate> {
    CGFloat height;
    CGFloat width;
    UIScrollView *_scrollView;
    UIImageView *_backgroundImageView;
    XXTutorialView *tutorial;
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
    [super viewDidLoad];
    _scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, width, height)];
    [_scrollView setContentSize:CGSizeMake(width*4, height)];
    [_scrollView setDirectionalLockEnabled:YES];
    [_scrollView setPagingEnabled:YES];
    _scrollView.delegate = self;
    
    [self.view addSubview:_scrollView];
    
    _backgroundImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, _scrollView.contentSize.width, height)];
    [_scrollView addSubview:_backgroundImageView];
    [_backgroundImageView setImage:[UIImage imageNamed:@"blurTest"]];
    [self showPreview];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeTutorial) name:@"MenuRevealed" object:nil];
}

- (void)showPreview {
    if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)){
        tutorial = [[XXTutorialView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    } else {
        tutorial = [[XXTutorialView alloc] initWithFrame:CGRectMake(0, 0, screenHeight(), screenWidth())];
    }
    
    [tutorial showInView:self.view animateDuration:.5 withBackgroundImage:[self blurredSnapshot]];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kExistingUser];
}

- (void)removeTutorial {
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat x = scrollView.contentOffset.x;
    NSLog(@"x scroll: %f",x);
    CGRect backgroundRect = _backgroundImageView.frame;
    
    if (x < 0){
        x = 0.f;
    } else if (x > _scrollView.contentSize.width){
        x = _scrollView.contentSize.width;
    } else {
        backgroundRect.origin.x = x/2;
    }
    
    [_backgroundImageView setFrame:backgroundRect];
}

-(UIImage *)blurredSnapshot {
    if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)){
        UIGraphicsBeginImageContextWithOptions([UIScreen mainScreen].bounds.size, NO, self.view.window.screen.scale);
        [self.view drawViewHierarchyInRect:self.view.frame afterScreenUpdates:YES];
    } else {
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(screenHeight(), screenWidth()), NO, self.view.window.screen.scale);
        [self.view drawViewHierarchyInRect:CGRectMake(0, 0, screenHeight(), screenWidth()) afterScreenUpdates:YES];
    }
    
    UIImage *snapshotImage = UIGraphicsGetImageFromCurrentImageContext();
    UIImage *blurredSnapshotImage = [snapshotImage applyBlurWithRadius:7 blurType:BOXFILTER tintColor:[UIColor colorWithWhite:1 alpha:.7] saturationDeltaFactor:1.8 maskImage:nil];
    UIGraphicsEndImageContext();
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

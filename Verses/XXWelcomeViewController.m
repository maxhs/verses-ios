//
//  XXWelcomeViewController.m
//  Verses
//
//  Created by Max Haines-Stiles on 10/11/13.
//  Copyright (c) 2013 Verses. All rights reserved.
//

#import "XXWelcomeViewController.h"
#import "XXStoryCell.h"
#import "XXProgress.h"
#import "XXContribution.h"
#import "XXUser.h"
#import "XXPhoto.h"
#import "SWTableViewCell.h"
#import "SWRevealViewController.h"
#import "XXStoryViewController.h"
#import "XXAppDelegate.h"
#import "XXTutorialView.h"
#import "UIImage+ImageEffects.h"
#import <DTCoreText/DTCoreText.h>
#import "XXSegmentedControl.h"

@interface XXWelcomeViewController () <UIScrollViewDelegate, SWTableViewCellDelegate, XXSegmentedControlDelegate>{
    AFHTTPRequestOperationManager *manager;
    XXStory *story1;
    XXStory *story2;
    CGFloat width;
    CGFloat height;
    CGFloat lastY;
    UIRefreshControl *refreshControl;
    XXTutorialView *tutorial;
    BOOL loading;
    BOOL canLoadMore;
    XXAppDelegate *delegate;
    NSDateFormatter *_formatter;
    UIColor *textColor;
    XXSegmentedControl *_browseControl;
    BOOL browse;
    BOOL trending;
    BOOL featured;
    NSMutableArray *_featuredStories;
    NSMutableArray *_trendingStories;
}

@end

@implementation XXWelcomeViewController
@synthesize stories = _stories;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(handleRefresh) forControlEvents:UIControlEventValueChanged];
    [refreshControl setTintColor:[UIColor darkGrayColor]];
    [self.tableView addSubview:refreshControl];
    [self.tableView setSeparatorColor:[UIColor clearColor]];
    self.tableView.directionalLockEnabled = YES;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeTutorial) name:@"MenuRevealed" object:nil];
    if (![[NSUserDefaults standardUserDefaults] boolForKey:kExistingUser]) {
        [self performSelector:@selector(showPreview) withObject:nil afterDelay:1];
    }
    delegate = (XXAppDelegate*)[UIApplication sharedApplication].delegate;
    manager = delegate.manager;
    
    self.reloadTheme = NO;
    
    _formatter= [[NSDateFormatter alloc] init];
    [_formatter setLocale:[NSLocale currentLocale]];
    [_formatter setDateFormat:@"MMM d - h:mm a"];
    
    _browseControl = [[XXSegmentedControl alloc] initWithItems:@[@"Browse",@"Featured",@"Trending"]];
    _browseControl.selectedSegmentIndex = 0;
    browse = YES;
    _browseControl.showsCount = NO;
    [_browseControl setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    [_browseControl addTarget:self action:@selector(selectedSegment:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:_browseControl];
    if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)){
        [_browseControl setFrame:CGRectMake(0, 0, screenWidth(), 48)];
        [_browseControl.background setFrame:CGRectMake(0, 0, screenWidth(), 48)];
    } else {
        [_browseControl setFrame:CGRectMake(0, 0, screenHeight(), 48)];
        [_browseControl.background setFrame:CGRectMake(0, 0, screenHeight(), 48)];
    }
    
    [_browseControl setFont:[UIFont fontWithName:kCrimsonRoman size:17]];
    [self.tableView setContentInset:UIEdgeInsetsMake(44, 0, 0, 0)];
    [self.featuredTableView setContentInset:UIEdgeInsetsMake(44, 0, 0, 0)];
    [self.trendingTableView setContentInset:UIEdgeInsetsMake(44, 0, 0, 0)];
    
    _featuredStories = [NSMutableArray array];
    _trendingStories = [NSMutableArray array];
}

- (void)viewWillAppear:(BOOL)animated {
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
    canLoadMore = YES;
    [self.navigationController setNavigationBarHidden:YES];
    [delegate.dynamicsDrawerViewController setPaneDragRevealEnabled:NO forDirection:MSDynamicsDrawerDirectionRight];

    if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
        textColor = [UIColor whiteColor];
        [self.view setBackgroundColor:[UIColor clearColor]];
        [refreshControl setTintColor:[UIColor whiteColor]];
        [_browseControl darkBackground];
    } else {
        textColor = [UIColor blackColor];
        [self.view setBackgroundColor:[UIColor whiteColor]];
        [refreshControl setTintColor:[UIColor darkGrayColor]];
        [_browseControl lightBackground];
    }
    
    if (self.reloadTheme){
        if (browse){
            [self.tableView reloadData];
        } else if (featured){
            [self.featuredTableView reloadData];
        } else if (trending){
            [self.trendingTableView reloadData];
        }
    }
    
    if (featured && self.featuredTableView.alpha == 0.0){
        [UIView animateWithDuration:.25 animations:^{
            [self.featuredTableView setAlpha:1.0];
        }];
    } else if (trending && self.featuredTableView.alpha == 0.0){
        [UIView animateWithDuration:.25 animations:^{
            [self.trendingTableView setAlpha:1.0];
        }];
    } else if (browse && self.tableView.alpha == 0.0){
        [UIView animateWithDuration:.25 animations:^{
            [self.tableView setAlpha:1.0];
        }];
    }
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (!_stories || _stories.count == 0){
        [self loadEtherStories];
    } else if (_stories.count <= 5){
        [self loadMore];
    }
    [self loadFeatured];
    [self loadTrending];
}

- (void)selectedSegment:(XXSegmentedControl*)control {
    switch (control.selectedSegmentIndex) {
        case 0:
            [self reset];
            browse = YES;
            [self hideTableViews];
            [self showTableView:self.tableView];
            break;
        case 1:
            [self reset];
            featured = YES;
            [self hideTableViews];
            [self showTableView:self.featuredTableView];
            [self.featuredTableView reloadData];
            break;
        case 2:
            [self reset];
            trending = YES;
            [self hideTableViews];
            [self showTableView:self.trendingTableView];
            [self.trendingTableView reloadData];
            break;
        default:
            break;
    }
}

- (void)reset {
    browse = NO;
    trending = NO;
    featured = NO;
}

- (void)hideTableViews {
    [UIView animateWithDuration:.5 delay:0 usingSpringWithDamping:.5 initialSpringVelocity:.0001 options:UIViewAnimationOptionCurveEaseIn animations:^{
        [self.tableView setAlpha:0.0];
        self.tableView.transform = CGAffineTransformMakeScale(.87, .87);
        [self.featuredTableView setAlpha:0.0];
        self.featuredTableView.transform = CGAffineTransformMakeScale(.87, .87);
        [self.trendingTableView setAlpha:0.0];
        self.trendingTableView.transform = CGAffineTransformMakeScale(.87, .87);
    } completion:^(BOOL finished) {
        
    }];
}

- (void)showTableView:(UITableView*)showTableView {
    [UIView animateWithDuration:.5 delay:0  usingSpringWithDamping:.5 initialSpringVelocity:.0001 options:UIViewAnimationOptionCurveEaseIn animations:^{
        [showTableView setAlpha:1.0];
        showTableView.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
    }];
}

- (void)showControl {
    [UIView animateWithDuration:.5 delay:0 usingSpringWithDamping:.8 initialSpringVelocity:.0001 options:UIViewAnimationOptionCurveEaseIn animations:^{
        _browseControl.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        
    }];
}

- (void)hideControl {
    [UIView animateWithDuration:.5 delay:0 usingSpringWithDamping:.8 initialSpringVelocity:.0001 options:UIViewAnimationOptionCurveEaseIn animations:^{
        _browseControl.transform = CGAffineTransformMakeTranslation(0, -_browseControl.frame.size.height);
    } completion:^(BOOL finished) {
        
    }];
}

- (void)handleRefresh{
    canLoadMore = YES;
    [self loadEtherStories];
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
    if (tutorial && tutorial.alpha == 1.0){
        [UIView animateWithDuration:.25 delay:.2 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            [tutorial setAlpha:0.0];
        } completion:^(BOOL finished) {
            [tutorial removeFromSuperview];
            [delegate.dynamicsDrawerViewController setPaneDragRevealEnabled:YES forDirection:MSDynamicsDrawerDirectionLeft];
        }];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)loadEtherStories {
    [manager GET:[NSString stringWithFormat:@"%@/stories",kAPIBaseUrl] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"story response: %@",responseObject);
        _stories = [[Utilities storiesFromJSONArray:[responseObject objectForKey:@"stories"]] mutableCopy];
        [ProgressHUD dismiss];
        [self.tableView reloadData];
        if (refreshControl.isRefreshing) [refreshControl endRefreshing];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self.tableView reloadData];
        if (refreshControl.isRefreshing) [refreshControl endRefreshing];
        NSLog(@"Failure getting stories from welcome controller: %@",error.description);
        [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Something went wrong while trying to fetch the latest stories. Please pull down to refresh." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    }];
}

- (void)loadFeatured {
    [manager GET:[NSString stringWithFormat:@"%@/stories/featured",kAPIBaseUrl] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"featured stories response: %@",responseObject);
        _featuredStories = [[Utilities storiesFromJSONArray:[responseObject objectForKey:@"stories"]] mutableCopy];
        [ProgressHUD dismiss];
        [self.tableView reloadData];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self.tableView reloadData];
        if (refreshControl.isRefreshing) [refreshControl endRefreshing];
        NSLog(@"Failure getting featured stories from welcome controller: %@",error.description);
        [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Something went wrong while trying to fetch the latest featured stories. Please pull down to refresh." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    }];
}

- (void)loadTrending {
    [manager GET:[NSString stringWithFormat:@"%@/stories/trending",kAPIBaseUrl] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"trending stories response: %@",responseObject);
        _trendingStories = [[Utilities storiesFromJSONArray:[responseObject objectForKey:@"stories"]] mutableCopy];
        [ProgressHUD dismiss];
        [self.tableView reloadData];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self.tableView reloadData];
        if (refreshControl.isRefreshing) [refreshControl endRefreshing];
        NSLog(@"Failure getting trending stories from welcome controller: %@",error.description);
        [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Something went wrong while trying to fetch what's trending. Please pull down to refresh." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    }];
}

- (void)write{
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
        [self performSegueWithIdentifier:@"Write" sender:self];
    } else {
        [self shouldLogin];
    }
}

- (void)shouldLogin {
    [self performSegueWithIdentifier:@"Login" sender:self];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    if (tutorial && tutorial.alpha == 1.0){
        [self removeTutorial];
    }
    if (UIInterfaceOrientationIsPortrait(toInterfaceOrientation)){
        [_browseControl setFrame:CGRectMake(0, 0, screenWidth(), 48)];
        [_browseControl.background setFrame:CGRectMake(0, 0, screenWidth(), 48)];
    } else {
        [_browseControl setFrame:CGRectMake(0, 0, screenHeight(), 48)];
        [_browseControl.background setFrame:CGRectMake(0, 0, screenHeight(), 48)];
    }

}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == self.tableView){
        return _stories.count;
    } else if (tableView == self.featuredTableView){
        return _featuredStories.count;
    } else if (tableView == self.trendingTableView) {
        return _trendingStories.count;
    } else {
        return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    XXStoryCell *cell = (XXStoryCell *)[tableView dequeueReusableCellWithIdentifier:@"StoryCell"];
    if (cell == nil) {
        cell = [[[NSBundle mainBundle] loadNibNamed:@"XXStoryCell" owner:nil options:nil] lastObject];
    }
    XXStory *story;
    if (tableView == self.tableView){
        story = [_stories objectAtIndex:indexPath.row];
    } else if (tableView == self.featuredTableView){
        story = [_featuredStories objectAtIndex:indexPath.row];
    } else if (tableView == self.trendingTableView) {
        story = [_trendingStories objectAtIndex:indexPath.row];
    }
    
    [cell configureForStory:story textColor:textColor featured:NO cellHeight:170];
    
    if (story.minutesToRead == [NSNumber numberWithInt:0]){
        [cell.infoLabel setText:[NSString stringWithFormat:@"%@ words  |  Quick Read  |  %@",story.wordCount,[_formatter stringFromDate:story.updatedDate]]];
    } else {
        [cell.infoLabel setText:[NSString stringWithFormat:@"%@ words  |  %@ min to read  |  %@",story.wordCount,story.minutesToRead,[_formatter stringFromDate:story.updatedDate]]];
    }
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
        [cell.infoLabel setTextColor:textColor];
        [cell.separatorView setImage:[UIImage imageNamed:@"whiteSeparator"]];
    } else {
        [cell.infoLabel setTextColor:[UIColor lightGrayColor]];
        [cell.separatorView setImage:[UIImage imageNamed:@"blackSeparator"]];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor clearColor];
    UIView *selectedView = [[UIView alloc] initWithFrame:cell.frame];
    [selectedView setBackgroundColor:[UIColor colorWithWhite:.73 alpha:.23]];
    cell.selectedBackgroundView = selectedView;
    
    if([indexPath row] == ((NSIndexPath*)[[tableView indexPathsForVisibleRows] lastObject]).row && tableView == self.tableView){
        //end of loading
        [ProgressHUD dismiss];
        self.reloadTheme = NO;
        [self.tableView setSeparatorColor:[UIColor colorWithWhite:1 alpha:1]];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (IDIOM == IPAD){
        return 256;
    } else {
        return 190;
    }
    
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    CGFloat actualPosition = scrollView.contentOffset.y;
    CGFloat contentHeight = scrollView.contentSize.height - (screenHeight()*2);
    if (actualPosition >= contentHeight && !loading && canLoadMore) {
        NSLog(@"should be loading more");
        [self loadMore];
    }
    
    if (actualPosition <= 0){
        [self showControl];
    } else if (actualPosition >= lastY){
        [self hideControl];
    } else if (actualPosition < lastY) {
        [self showControl];
    }
    lastY = actualPosition;
}

- (void)loadMore {
    loading = YES;
    XXStory *lastStory = _stories.lastObject;
    if (lastStory){
        [manager GET:[NSString stringWithFormat:@"%@/stories",kAPIBaseUrl] parameters:@{@"before_date":lastStory.epochTime, @"count":@"10"} success:^(AFHTTPRequestOperation *operation, id responseObject) {
            //NSLog(@"more stories response: %@",responseObject);
            NSArray *newStories = [Utilities storiesFromJSONArray:[responseObject objectForKey:@"stories"]];
            [_stories addObjectsFromArray:newStories];
            if (newStories.count < 10) {
                canLoadMore = NO;
                NSLog(@"can't load more, we now have %i stories", _stories.count);
            }
            [delegate.menuViewController setStories:_stories];
            [ProgressHUD dismiss];
            loading = NO;
            [self.tableView reloadData];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            
        }];
    } else {
        [self loadEtherStories];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
    [self performSegueWithIdentifier:@"Story" sender:indexPath];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [super prepareForSegue:segue sender:sender];
    if ([segue.identifier isEqualToString:@"Story"]) {
        if ([sender isKindOfClass:[NSIndexPath class]]) {
            XXStory *story;
            if (browse){
                story = [_stories objectAtIndex:[(NSIndexPath*)sender row]];
            } else if (featured){
                story = [_featuredStories objectAtIndex:[(NSIndexPath*)sender row]];
            } else if (trending){
                story = [_trendingStories objectAtIndex:[(NSIndexPath*)sender row]];
            }
            
            XXStoryViewController *vc = [segue destinationViewController];
            [vc setStory:story];
            [vc setStories:_stories];
        }
        if (browse){
            [UIView animateWithDuration:.25 animations:^{
                [self.tableView setAlpha:0.0];
            }];
        } else if (trending){
            [UIView animateWithDuration:.25 animations:^{
                [self.trendingTableView setAlpha:0.0];
            }];
        } else if (featured){
            [UIView animateWithDuration:.25 animations:^{
                [self.featuredTableView setAlpha:0.0];
            }];
        }
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}
@end

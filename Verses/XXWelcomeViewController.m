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
#import "UIImage+ImageEffects.h"
#import <DTCoreText/DTCoreText.h>
#import "XXSegmentedControl.h"
#import "XXNewUserWalkthroughViewController.h"
#import "XXNewUserTransition.h"
#import "XXCollaborateViewController.h"

@interface XXWelcomeViewController () <UIScrollViewDelegate, SWTableViewCellDelegate, XXSegmentedControlDelegate, UIViewControllerTransitioningDelegate>{
    AFHTTPRequestOperationManager *manager;
    XXStory *story1;
    XXStory *story2;
    CGFloat width;
    CGFloat height;
    CGFloat lastY;
    UIInterfaceOrientation orientation;
    UIRefreshControl *refreshControl;
    BOOL loading;
    BOOL canLoadMore;
    BOOL canLoadMoreTrending;
    BOOL canLoadMoreShared;
    XXAppDelegate *delegate;
    NSDateFormatter *_formatter;
    UIColor *textColor;
    XXSegmentedControl *_browseControl;
    BOOL read;
    BOOL trending;
    BOOL shared;
    NSMutableArray *_sharedStories;
    NSMutableArray *_trendingStories;
}

@end

@implementation XXWelcomeViewController
@synthesize stories = _stories;

- (void)viewDidLoad {
    refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(handleRefresh) forControlEvents:UIControlEventValueChanged];
    [refreshControl setTintColor:[UIColor darkGrayColor]];
    [self.tableView addSubview:refreshControl];
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    [self.navigationController setNavigationBarHidden:YES];
    delegate = (XXAppDelegate*)[UIApplication sharedApplication].delegate;
    manager = delegate.manager;
    
    self.reloadTheme = NO;
    
    _formatter = [[NSDateFormatter alloc] init];
    [_formatter setLocale:[NSLocale currentLocale]];
    [_formatter setDateFormat:@"MMM d - h:mm a"];
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
        _browseControl = [[XXSegmentedControl alloc] initWithItems:@[@"Featured",@"Trending",@"Shared"]];
    } else {
        _browseControl = [[XXSegmentedControl alloc] initWithItems:@[@"Featured",@"Trending"]];
    }
    
    _browseControl.selectedSegmentIndex = 0;
    read = YES;
    _browseControl.showsCount = NO;
    [_browseControl setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    [_browseControl addTarget:self action:@selector(selectedSegment:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:_browseControl];
    if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)){
        width = screenWidth();
        height = screenHeight();
        [_browseControl setFrame:CGRectMake(0, 0, width, 48)];
        [_browseControl.background setFrame:CGRectMake(0, 0, width, 48)];
    } else {
        height = screenWidth();
        width = screenHeight();
        [_browseControl setFrame:CGRectMake(0, 0, width, 48)];
        [_browseControl.background setFrame:CGRectMake(0, 0, width, 48)];
    }
    
    if (IDIOM == IPAD){
        self.tableView.rowHeight = height/3;
        self.sharedTableView.rowHeight = height/3;
        self.trendingTableView.rowHeight = height/3;
    } else {
        self.tableView.rowHeight = height/2;
        self.sharedTableView.rowHeight = height/2;
        self.trendingTableView.rowHeight = height/2;
    }
    
    [_browseControl setFont:[UIFont fontWithName:kSourceSansProRegular size:21]];
    [self.tableView setContentInset:UIEdgeInsetsMake(48, 0, 0, 0)];
    [self.tableView setScrollIndicatorInsets:UIEdgeInsetsMake(48, 0, 0, 0)];
    [self.sharedTableView setContentInset:UIEdgeInsetsMake(48, 0, 0, 0)];
    [self.sharedTableView setScrollIndicatorInsets:UIEdgeInsetsMake(48, 0, 0, 0)];
    [self.trendingTableView setContentInset:UIEdgeInsetsMake(48, 0, 0, 0)];
    [self.trendingTableView setScrollIndicatorInsets:UIEdgeInsetsMake(48, 0, 0, 0)];
    
    _sharedStories = [NSMutableArray array];
    _trendingStories = [NSMutableArray array];
    
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(storyFlagged:) name:@"StoryFlagged" object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    orientation = self.interfaceOrientation;
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
    
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
    
    canLoadMore = YES;
    canLoadMoreShared = YES;
    canLoadMoreTrending = YES;
    if (!_stories || _stories.count == 0){
        [self loadEtherStories];
    } else if (_stories.count <= 5){
        [self loadMore];
    }
    [self loadShared];
    [self loadTrending];
    
    if (self.reloadTheme){
        if (read){
            [self.tableView reloadData];
        } else if (shared){
            [self.sharedTableView reloadData];
        } else if (trending){
            [self.trendingTableView reloadData];
        }
    }
    
    if (shared && self.sharedTableView.alpha == 0.0){
        [UIView animateWithDuration:.25 animations:^{
            [self.sharedTableView setAlpha:1.0];
        }];
    } else if (trending && self.sharedTableView.alpha == 0.0){
        [UIView animateWithDuration:.25 animations:^{
            [self.trendingTableView setAlpha:1.0];
        }];
    } else if (read && self.tableView.alpha == 0.0){
        [UIView animateWithDuration:.25 animations:^{
            [self.tableView setAlpha:1.0];
        }];
    }
    
    if (![[NSUserDefaults standardUserDefaults] boolForKey:kExistingUser]) {
        XXNewUserWalkthroughViewController *vc = [[XXNewUserWalkthroughViewController alloc] init];
        vc.transitioningDelegate = self;
        vc.modalPresentationStyle = UIModalPresentationCustom;
        [self presentViewController:vc animated:YES completion:^{
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kExistingUser];
        }];
    }
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented
                                                                  presentingController:(UIViewController *)presenting
                                                                      sourceController:(UIViewController *)source {
    XXNewUserTransition *animator = [XXNewUserTransition new];
    animator.presenting = YES;
    return animator;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    XXNewUserTransition *animator = [XXNewUserTransition new];
    return animator;
}

- (void)selectedSegment:(XXSegmentedControl*)control {
    if (refreshControl.isRefreshing) [refreshControl endRefreshing];
    [self reset];
    switch (control.selectedSegmentIndex) {
        case 0:
            read = YES;
            [self.tableView reloadData];
            [self hideTableViews];
            [self showTableView:self.tableView];
            [self.tableView addSubview:refreshControl];
            break;
        case 1:
            trending = YES;
            [self.trendingTableView reloadData];
            [self hideTableViews];
            [self showTableView:self.trendingTableView];
            [self.trendingTableView addSubview:refreshControl];
            break;
        case 2:
            shared = YES;
            [self.sharedTableView reloadData];
            [self hideTableViews];
            [self showTableView:self.sharedTableView];
            [self.sharedTableView addSubview:refreshControl];
            break;
        default:
            break;
    }
}

- (void)reset {
    read = NO;
    trending = NO;
    shared = NO;
}

- (void)hideTableViews {
    [UIView animateWithDuration:.5 delay:0 usingSpringWithDamping:.7 initialSpringVelocity:.0001 options:UIViewAnimationOptionCurveEaseOut animations:^{
        [self.tableView setAlpha:0.0];
        self.tableView.transform = CGAffineTransformMakeScale(.87, .87);
        [self.sharedTableView setAlpha:0.0];
        self.sharedTableView.transform = CGAffineTransformMakeScale(.87, .87);
        [self.trendingTableView setAlpha:0.0];
        self.trendingTableView.transform = CGAffineTransformMakeScale(.87, .87);
    } completion:^(BOOL finished) {
        
    }];
}

- (void)showTableView:(UITableView*)showTableView {
    [UIView animateWithDuration:.5 delay:0  usingSpringWithDamping:.7 initialSpringVelocity:.0001 options:UIViewAnimationOptionCurveEaseIn animations:^{
        [showTableView setAlpha:1.0];
        showTableView.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
    }];
}

- (void)showControl {
    [UIView animateWithDuration:.23 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        CGRect browseRect = _browseControl.frame;
        browseRect.origin.y = 0;
        [_browseControl setFrame:browseRect];
    } completion:^(BOOL finished) {
        
    }];
}

- (void)hideControl {
    [UIView animateWithDuration:.23 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        CGRect browseRect = _browseControl.frame;
        browseRect.origin.y = -_browseControl.frame.size.height;
        [_browseControl setFrame:browseRect];
    } completion:^(BOOL finished) {
        
    }];
}

- (void)handleRefresh{
    canLoadMore = YES;
    if (read){
        [self loadEtherStories];
    } else if (shared){
        [self loadShared];
    } else if (trending){
        [self loadTrending];
    }
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

- (void)loadEtherStories {
    [manager GET:[NSString stringWithFormat:@"%@/stories",kAPIBaseUrl] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"story response: %@",responseObject);
        NSLog(@"just loaded ether stories");
        _stories = [[Utilities storiesFromJSONArray:[responseObject objectForKey:@"stories"]] mutableCopy];
        if ([_tableView numberOfRowsInSection:0] > 0){
            [_tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
        } else {
            [_tableView reloadData];
        }
        if (refreshControl.isRefreshing) [refreshControl endRefreshing];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (refreshControl.isRefreshing) [refreshControl endRefreshing];
        NSLog(@"Failure getting stories from welcome controller: %@",error.description);
        [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Something went wrong while trying to fetch the latest stories. Please pull down to refresh." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    }];
}

- (void)loadShared {
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
        [manager GET:[NSString stringWithFormat:@"%@/stories/shared",kAPIBaseUrl] parameters:@{@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId],@"count":@"10"} success:^(AFHTTPRequestOperation *operation, id responseObject) {
            //NSLog(@"shared stories response: %@",responseObject);
            _sharedStories = [[Utilities storiesFromJSONArray:[responseObject objectForKey:@"stories"]] mutableCopy];
            if (shared)[self.sharedTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
            if (refreshControl.isRefreshing)[refreshControl endRefreshing];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            if (refreshControl.isRefreshing) [refreshControl endRefreshing];
            NSLog(@"Failure getting shared stories from welcome controller: %@",error.description);
            //[[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Something went wrong while trying to fetch the latest featured stories. Please pull down to refresh." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        }];
    }
}

- (void)loadTrending {
    [manager GET:[NSString stringWithFormat:@"%@/stories/trending",kAPIBaseUrl] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"trending stories response: %@",responseObject);
        _trendingStories = [[Utilities storiesFromJSONArray:[responseObject objectForKey:@"stories"]] mutableCopy];
        if (trending)[self.trendingTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
        if (refreshControl.isRefreshing)[refreshControl endRefreshing];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
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
    if (UIInterfaceOrientationIsPortrait(toInterfaceOrientation)){
        [_browseControl setFrame:CGRectMake(0, 0, screenWidth(), 48)];
        [_browseControl.background setFrame:CGRectMake(0, 0, screenWidth(), 48)];
    } else {
        [_browseControl setFrame:CGRectMake(0, 0, screenHeight(), 48)];
        [_browseControl.background setFrame:CGRectMake(0, 0, screenHeight(), 48)];
    }
    orientation = toInterfaceOrientation;
    if (read){
        [self.tableView reloadData];
    } else if (trending){
        [self.trendingTableView reloadData];
    } else if (shared){
        [self.sharedTableView reloadData];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (read){
        return _stories.count;
    } else if (shared){
        if (_sharedStories.count == 0) {
            return 1;
        } else {
            return _sharedStories.count;
        }
    } else if (trending) {
        return _trendingStories.count;
    } else {
        return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (shared && _sharedStories.count == 0){
        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"NothingCell"];
        UIButton *nothingButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [nothingButton setTitle:@"Nothing shared with you just yet.\n\nTap here to manage your contacts." forState:UIControlStateNormal];
        [nothingButton addTarget:self action:@selector(manageCircles) forControlEvents:UIControlEventTouchUpInside];
        [nothingButton.titleLabel setNumberOfLines:0];
        [nothingButton.titleLabel setFont:[UIFont fontWithName:kSourceSansProLight size:20]];
        [nothingButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
        [nothingButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [nothingButton setBackgroundColor:[UIColor clearColor]];
        [cell addSubview:nothingButton];
        [nothingButton setFrame:CGRectMake(20, 0, screenWidth()-40, screenHeight()-74)];
        [_sharedTableView setScrollEnabled:NO];
        return cell;
    } else {
        XXStoryCell *cell = (XXStoryCell *)[tableView dequeueReusableCellWithIdentifier:@"StoryCell"];
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"XXStoryCell" owner:nil options:nil] lastObject];
        }
        XXStory *story;
        if (read){
            story = [_stories objectAtIndex:indexPath.row];
        } else if (shared){
            [_sharedTableView setScrollEnabled:YES];
            story = [_sharedStories objectAtIndex:indexPath.row];
        } else if (trending) {
            story = [_trendingStories objectAtIndex:indexPath.row];
        }
        [cell resetCell];
        [cell.titleLabel setTextColor:textColor];
        [cell.bodySnippet setTextColor:textColor];
        [cell.countLabel setTextColor:textColor];
        [cell configureForStory:story withOrientation:orientation];
        
        if (tableView == _trendingTableView) {
            if (story.trendingCount && ![story.trendingCount isEqualToNumber:[NSNumber numberWithInt:0]]){
                [cell.countLabel setHidden:NO];
                if ([story.trendingCount isEqualToNumber:[NSNumber numberWithInt:1]]){
                    [cell.countLabel setText:@"1 view"];
                } else {
                    [cell.countLabel setText:[NSString stringWithFormat:@"%@ views",story.trendingCount]];
                }
            } else {
                [cell.countLabel setHidden:YES];
            }
            
        } else if (story.views && ![story.views isEqualToNumber:[NSNumber numberWithInt:0]]) {
            [cell.countLabel setHidden:NO];
            if ([story.views isEqualToNumber:[NSNumber numberWithInt:1]]){
                [cell.countLabel setText:@"1 view"];
            } else {
                [cell.countLabel setText:[NSString stringWithFormat:@"%@ views",story.views]];
            }
        } else {
            [cell.countLabel setHidden:YES];
        }
        
        [cell.scrollView setTag:indexPath.row];
        [cell.scrollTouch addTarget:self action:@selector(storyScrollViewTouched:)];
        
        if (story.minutesToRead == [NSNumber numberWithInt:0]){
            [cell.infoLabel setText:[NSString stringWithFormat:@"%@ words  |  Quick Read  |  %@",story.wordCount,[_formatter stringFromDate:story.updatedDate]]];
        } else {
            [cell.infoLabel setText:[NSString stringWithFormat:@"%@ words  |  %@ min to read  |  %@",story.wordCount,story.minutesToRead,[_formatter stringFromDate:story.updatedDate]]];
        }
        
        if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
            [cell.infoLabel setTextColor:textColor];
        } else {
            [cell.infoLabel setTextColor:[UIColor lightGrayColor]];
        }
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor clearColor];
    UIView *selectedView = [[UIView alloc] initWithFrame:cell.frame];
    [selectedView setBackgroundColor:kSeparatorColor];
    cell.selectedBackgroundView = selectedView;
    
    if([indexPath row] == ((NSIndexPath*)[[tableView indexPathsForVisibleRows] lastObject]).row && tableView == self.tableView && !loading){
        //end of loading
        [ProgressHUD dismiss];
        self.reloadTheme = NO;
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    CGFloat actualPosition = scrollView.contentOffset.y;
    CGFloat contentHeight = scrollView.contentSize.height - (screenHeight()*2);
    
    if (read){
        if (actualPosition >= contentHeight && !loading && canLoadMore) {
            NSLog(@"should be loading more");
            [self loadMore];
        }
    } else if (trending) {
        if (actualPosition >= contentHeight && !loading && canLoadMoreTrending) {
            NSLog(@"should be loading more trending");
            [self loadMoreTrending];
        }
    } else if (shared) {
        if (actualPosition >= contentHeight && !loading && canLoadMoreShared) {
            NSLog(@"should be loading more shared");
            [self loadMoreShared];
        }
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
            NSMutableArray *indexesToInsert = [NSMutableArray array];
            for (int i = _stories.count; i < newStories.count+_stories.count; i++){
                [indexesToInsert addObject:[NSIndexPath indexPathForRow:i inSection:0]];
            }
            [_stories addObjectsFromArray:newStories];
            if (newStories.count < 10) {
                canLoadMore = NO;
                NSLog(@"can't load more, we now have %i stories", _stories.count);
            }
            [delegate setStories:_stories];
            loading = NO;
            if (read) {
                if ([_tableView numberOfRowsInSection:0] > 1){
                    [_tableView insertRowsAtIndexPaths:indexesToInsert withRowAnimation:UITableViewRowAnimationFade];
                } else {
                    [_tableView reloadData];
                }
            }
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            
        }];
    } else {
        [self loadEtherStories];
    }

}

- (void)loadMoreTrending {
    loading = YES;
    XXStory *lastStory = _trendingStories.lastObject;
    if (lastStory){
        [manager GET:[NSString stringWithFormat:@"%@/stories/trending",kAPIBaseUrl] parameters:@{@"before_date":lastStory.epochTime, @"count":@"10"} success:^(AFHTTPRequestOperation *operation, id responseObject) {
            //NSLog(@"more stories response: %@",responseObject);
            NSArray *newStories = [Utilities storiesFromJSONArray:[responseObject objectForKey:@"stories"]];
            NSMutableArray *indexesToInsert = [NSMutableArray array];
            for (int i = _trendingStories.count; i < newStories.count+_trendingStories.count; i++){
                [indexesToInsert addObject:[NSIndexPath indexPathForRow:i inSection:0]];
            }
            [_trendingStories addObjectsFromArray:newStories];
            [_trendingTableView insertRowsAtIndexPaths:indexesToInsert withRowAnimation:UITableViewRowAnimationFade];
            if (newStories.count < 10) {
                canLoadMoreTrending = NO;
                NSLog(@"can't load more trending, we now have %i stories", _stories.count);
            }
            loading = NO;
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Failure loading more trending stories: %@",error.description);
        }];
    } else {
        [self loadTrending];
    }
}

- (void)loadMoreShared {
    loading = YES;
    XXStory *lastStory = _sharedStories.lastObject;
    if (lastStory){
        [manager GET:[NSString stringWithFormat:@"%@/stories/shared",kAPIBaseUrl] parameters:@{@"before_date":lastStory.epochTime, @"count":@"10",@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
            //NSLog(@"more shared stories response: %@",responseObject);
            NSArray *newStories = [Utilities storiesFromJSONArray:[responseObject objectForKey:@"stories"]];
            NSMutableArray *indexesToInsert = [NSMutableArray array];
            for (int i = _sharedStories.count; i < _sharedStories.count+newStories.count; i++){
                [indexesToInsert addObject:[NSIndexPath indexPathForRow:i inSection:0]];
            }
            [_sharedStories addObjectsFromArray:newStories];
            if (newStories.count < 10) {
                canLoadMoreShared = NO;
                NSLog(@"can't load more shared, we now have %i stories", _stories.count);
            }
            loading = NO;
            [self.sharedTableView insertRowsAtIndexPaths:indexesToInsert withRowAnimation:UITableViewRowAnimationFade];
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Failure loading more shared stories: %@",error.description);
        }];
    } else {
        [self loadShared];
    }
}

- (void)storyScrollViewTouched:(UITapGestureRecognizer*)tapGesture {
    XXStory *story;
    if (read){
        story = [_stories objectAtIndex:tapGesture.view.tag];
    } else if (shared){
        story = [_sharedStories objectAtIndex:tapGesture.view.tag];
    } else if (trending){
        story = [_trendingStories objectAtIndex:tapGesture.view.tag];
    }
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
    [self performSegueWithIdentifier:@"Story" sender:story];
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
            if (read){
                story = [_stories objectAtIndex:[(NSIndexPath*)sender row]];
            } else if (shared){
                story = [_sharedStories objectAtIndex:[(NSIndexPath*)sender row]];
            } else if (trending){
                story = [_trendingStories objectAtIndex:[(NSIndexPath*)sender row]];
            }
            
            XXStoryViewController *vc = [segue destinationViewController];
            [vc setStory:story];
            [vc setStories:_stories];
        } else if ([sender isKindOfClass:[XXStory class]]){
            XXStoryViewController *vc = [segue destinationViewController];
            [vc setStory:(XXStory*)sender];
            [vc setStories:_stories];
        }
        if (read){
            [UIView animateWithDuration:.25 animations:^{
                [self.tableView setAlpha:0.0];
            }];
        } else if (trending){
            [UIView animateWithDuration:.25 animations:^{
                [self.trendingTableView setAlpha:0.0];
            }];
        } else if (shared){
            [UIView animateWithDuration:.25 animations:^{
                [self.sharedTableView setAlpha:0.0];
            }];
        }
    }
}

- (void)storyFlagged:(NSNotification*)notification {
    NSLog(@"story flagged");
    XXStory *story = [notification.userInfo objectForKey:@"story"];
    if ([_stories containsObject:story]){
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[_stories indexOfObject:story] inSection:0];
        [_stories removeObject:story];
        [_tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if ([_trendingStories containsObject:story]){
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[_trendingStories indexOfObject:story] inSection:0];
        [_trendingStories removeObject:story];
        [_trendingTableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if ([_sharedStories containsObject:story]){
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[_sharedStories indexOfObject:story] inSection:0];
        [_sharedStories removeObject:story];
        [_sharedTableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

- (void)manageCircles {
    XXCollaborateViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Collaborate"];
    [vc setTitle:@"Contacts"];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    [self presentViewController:nav animated:YES completion:^{
        
    }];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}
@end

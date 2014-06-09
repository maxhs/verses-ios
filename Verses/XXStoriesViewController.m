//
//  XXStoriesViewController.m
//  Verses
//
//  Created by Max Haines-Stiles on 10/11/13.
//  Copyright (c) 2013 Verses. All rights reserved.
//

#import "XXStoriesViewController.h"
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
#import "XXFlagContentViewController.h"
#import "XXGuideTransition.h"
#import "XXGuideViewController.h"
#import "Story+helper.h"

@interface XXStoriesViewController () <UIScrollViewDelegate, SWTableViewCellDelegate, XXSegmentedControlDelegate, UIViewControllerTransitioningDelegate>{
    AFHTTPRequestOperationManager *manager;
    XXStory *story1;
    XXStory *story2;
    CGFloat width;
    CGFloat height;
    CGFloat lastY;
    UIInterfaceOrientation orientation;
    UIRefreshControl *refreshControl;
    BOOL loading;
    BOOL newUser;
    BOOL canLoadMore;
    BOOL canLoadMoreTrending;
    BOOL canLoadMoreShared;
    BOOL canLoadMoreFeatured;
    XXAppDelegate *delegate;
    NSDateFormatter *_formatter;
    UIColor *textColor;
    XXSegmentedControl *_browseControl;
    NSMutableArray *_sharedStories;
    NSMutableArray *_trendingStories;
    NSMutableArray *_featuredStories;
    UIButton *menuButton;
    UIImage *_backgroundImage;
}

@end

@implementation XXStoriesViewController
@synthesize stories = _stories;

- (void)viewDidLoad {
    refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(handleRefresh) forControlEvents:UIControlEventValueChanged];
    [refreshControl setTintColor:[UIColor darkGrayColor]];
    [self.tableView addSubview:refreshControl];
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    delegate = (XXAppDelegate*)[UIApplication sharedApplication].delegate;
    manager = delegate.manager;
    self.reloadTheme = NO;
    _formatter = [[NSDateFormatter alloc] init];
    [_formatter setLocale:[NSLocale currentLocale]];
    [_formatter setDateFormat:@"MMM d - h:mm a"];
    
    if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)){
        width = screenWidth();
        height = screenHeight();
    } else {
        height = screenWidth();
        width = screenHeight();
    }
    
    menuButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [menuButton setImage:[UIImage imageNamed:@"more"] forState:UIControlStateNormal];
    [menuButton addTarget:self action:@selector(showGuide) forControlEvents:UIControlEventTouchUpInside];
    [menuButton setFrame:CGRectMake(width-44, 0, 44, 44)];
    [self.view addSubview:menuButton];
    
    if (IDIOM == IPAD){
        self.tableView.rowHeight = height/3;
    } else {
        self.tableView.rowHeight = height/2;
    }

    _sharedStories = [NSMutableArray array];
    _trendingStories = [NSMutableArray array];
    _featuredStories = [NSMutableArray array];
    
    if (_featured){
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"featured == %@",[NSNumber numberWithBool:YES]];
        _featuredStories = [Story MR_findAllSortedBy:@"updatedDate" ascending:NO withPredicate:predicate].mutableCopy;
        if (_featuredStories.count == 0) {
            NSLog(@"no featured stories");
            [self loadFeatured];
        } else {
            [self.tableView reloadData];
        }
    } else if (_shared) {
        
    } else if (_trending){
        
    } else if (_ether || _stories.count ==0) {
        _stories = [Story MR_findAllSortedBy:@"updatedDate" ascending:NO].mutableCopy;
        if (_stories.count == 0) {
            [self loadEtherStories];
        } else [self.tableView reloadData];
    }
   
    [self.tableView reloadData];
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(storyFlagged:) name:@"StoryFlagged" object:nil];
}

- (void)updateLocalStories:(NSArray*)array{
    for (NSDictionary *dict in array){
        if ([dict objectForKey:@"id"] && [dict objectForKey:@"id"] != [NSNull null]){
            Story *story = [Story MR_findFirstByAttribute:@"identifier" withValue:[dict objectForKey:@"id"]];
            if (!story){
                story = [Story MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [story populateFromDict:dict];
        }
    }
    _stories = [Story MR_findAllSortedBy:@"updatedDate" ascending:NO].mutableCopy;
    [self.tableView reloadData];
    [self saveContext];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    orientation = self.interfaceOrientation;
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    [delegate.dynamicsDrawerViewController setPaneDragRevealEnabled:NO forDirection:MSDynamicsDrawerDirectionRight];

    if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
        textColor = [UIColor whiteColor];
        [self.view setBackgroundColor:[UIColor clearColor]];
        [refreshControl setTintColor:[UIColor whiteColor]];
        [menuButton setImage:[UIImage imageNamed:@"moreWhite"] forState:UIControlStateNormal];
    } else {
        textColor = [UIColor blackColor];
        [self.view setBackgroundColor:[UIColor whiteColor]];
        [refreshControl setTintColor:[UIColor darkGrayColor]];
        [menuButton setImage:[UIImage imageNamed:@"more"] forState:UIControlStateNormal];
    }
    canLoadMore = YES;
    canLoadMoreShared = YES;
    canLoadMoreTrending = YES;
    canLoadMoreFeatured = YES;

    if (self.reloadTheme){
        [self.tableView reloadData];
    }
    
    if (self.tableView.alpha == 0.0){
        [UIView animateWithDuration:.25 animations:^{
            [self.tableView setAlpha:1.0];
        }];
    }
    
    if (![[NSUserDefaults standardUserDefaults] boolForKey:kExistingUser]) {
        XXNewUserWalkthroughViewController *vc = [[XXNewUserWalkthroughViewController alloc] init];
        newUser = YES;
        vc.transitioningDelegate = self;
        vc.modalPresentationStyle = UIModalPresentationCustom;
        [self presentViewController:vc animated:YES completion:^{
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kExistingUser];
        }];
    }
}

- (void)showGuide {
    XXGuideViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Guide"];
    vc.transitioningDelegate = self;
    vc.modalPresentationStyle = UIModalPresentationCustom;
    newUser = NO;
    [self presentViewController:vc animated:YES completion:nil];
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented
                                                                  presentingController:(UIViewController *)presenting
                                                                      sourceController:(UIViewController *)source {
    if (newUser){
        XXNewUserTransition *animator = [XXNewUserTransition new];
        animator.presenting = YES;
        return animator;
    } else {
        XXGuideTransition *animator = [XXGuideTransition new];
        animator.presenting = YES;
        return animator;
    }
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    if (newUser){
        XXNewUserTransition *animator = [XXNewUserTransition new];
        return animator;
    } else {
        XXGuideTransition *animator = [XXGuideTransition new];
        return animator;
    }
}

- (void)handleRefresh{
    canLoadMore = YES;
    if (_featured){
        [self loadFeatured];
    } else if (_shared){
        [self loadShared];
    } else if (_trending){
        [self loadTrending];
    } else if (_ether) {
        [self loadEtherStories];
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
    loading = YES;
    [manager GET:[NSString stringWithFormat:@"%@/stories",kAPIBaseUrl] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"story response: %@",responseObject);
        [self updateLocalStories:[responseObject objectForKey:@"stories"]];
        loading = NO;
        if (refreshControl.isRefreshing) [refreshControl endRefreshing];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (refreshControl.isRefreshing) [refreshControl endRefreshing];
        loading = NO;
        NSLog(@"Failure getting stories from welcome controller: %@",error.description);
        [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Something went wrong while trying to fetch the latest stories. Please pull down to refresh." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    }];
}

- (void)loadShared {
    loading = YES;
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
        [manager GET:[NSString stringWithFormat:@"%@/stories/shared",kAPIBaseUrl] parameters:@{@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId],@"count":@"10"} success:^(AFHTTPRequestOperation *operation, id responseObject) {
            //NSLog(@"shared stories response: %@",responseObject);
            _sharedStories = [[Utilities storiesFromJSONArray:[responseObject objectForKey:@"stories"]] mutableCopy];
            [self.tableView reloadData];
            if (refreshControl.isRefreshing)[refreshControl endRefreshing];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            if (refreshControl.isRefreshing) [refreshControl endRefreshing];
            NSLog(@"Failure getting shared stories from welcome controller: %@",error.description);
            //[[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Something went wrong while trying to fetch the latest featured stories. Please pull down to refresh." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        }];
    }
}

- (void)loadTrending {
    loading = YES;
    [manager GET:[NSString stringWithFormat:@"%@/stories/trending",kAPIBaseUrl] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"trending stories response: %@",responseObject);
        _trendingStories = [[Utilities storiesFromJSONArray:[responseObject objectForKey:@"stories"]] mutableCopy];
        [self.tableView reloadData];
        if (refreshControl.isRefreshing)[refreshControl endRefreshing];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (refreshControl.isRefreshing) [refreshControl endRefreshing];
        NSLog(@"Failure getting trending stories from welcome controller: %@",error.description);
        [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Something went wrong while trying to fetch what's trending. Please pull down to refresh." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    }];
}

- (void)loadFeatured {
    loading = YES;
    [manager GET:[NSString stringWithFormat:@"%@/stories/featured",kAPIBaseUrl] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"featured stories response: %@",responseObject);
        _featuredStories = [[Utilities storiesFromJSONArray:[responseObject objectForKey:@"stories"]] mutableCopy];
        [self.tableView reloadData];
        if (refreshControl.isRefreshing)[refreshControl endRefreshing];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (refreshControl.isRefreshing) [refreshControl endRefreshing];
        NSLog(@"Failure getting featured stories from welcome controller: %@",error.description);
        [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Something went wrong while trying to fetch what's featured. Please pull down to refresh." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
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
        width = screenWidth();
        height = screenHeight();
    } else {
        height = screenWidth();
        width = screenHeight();
    }
    
    if (IDIOM == IPAD){
        self.tableView.rowHeight = height/3;
    } else {
        self.tableView.rowHeight = height/2;
    }
    [menuButton setFrame:CGRectMake(width-44, 0, 44, 44)];
    orientation = toInterfaceOrientation;
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (_featured){
        NSLog(@"Drawing %d featured stories",_featuredStories.count);
        return _featuredStories.count;
    } else if (_shared){
        if (_sharedStories.count == 0 && !loading) {
            return 1;
        } else {
            NSLog(@"Drawing %d shared stories",_sharedStories.count);
            return _sharedStories.count;
        }
    } else if (_trending) {
        NSLog(@"Drawing %d trending stories",_trendingStories.count);
        return _trendingStories.count;
    } else if (_ether) {
        NSLog(@"Drawing %d stories",_stories.count);
        return _stories.count;
    } else {
        return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_shared && _sharedStories.count == 0){
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
        [self.tableView setScrollEnabled:NO];
        return cell;
    } else {
        XXStoryCell *cell = (XXStoryCell *)[tableView dequeueReusableCellWithIdentifier:@"StoryCell"];
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"XXStoryCell" owner:nil options:nil] lastObject];
        }
        Story *story;
        if (_featured){
            story = [_featuredStories objectAtIndex:indexPath.row];
        } else if (_shared){
            story = [_sharedStories objectAtIndex:indexPath.row];
        } else if (_trending) {
            story = [_trendingStories objectAtIndex:indexPath.row];
        } else {
            story = [_stories objectAtIndex:indexPath.row];
        }
        [cell resetCell];
        [cell.titleLabel setTextColor:textColor];
        [cell.countLabel setTextColor:textColor];
        [cell.authorLabel setTextColor:textColor];
        
        [cell configureForStory:story withOrientation:orientation];
        [cell.bodySnippet setTextColor:textColor];
        [cell.flagButton setTag:indexPath.row];
        [cell.flagButton addTarget:self action:@selector(flagStory:) forControlEvents:UIControlEventTouchUpInside];
        
        if (_trending) {
            if (story.trendingCount && ![story.trendingCount isEqualToNumber:[NSNumber numberWithInt:0]]){
                [cell.countLabel setHidden:NO];
                if ([story.trendingCount isEqualToNumber:[NSNumber numberWithInt:1]]){
                    [cell.countLabel setText:@"1 recent view"];
                } else {
                    [cell.countLabel setText:[NSString stringWithFormat:@"%@ recent views",story.trendingCount]];
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
    
    if (actualPosition >= contentHeight && !loading) {
        if (_featured && canLoadMoreFeatured){
            NSLog(@"should be loading more featured");
            [self loadMoreFeatured];
        } else if (_trending && canLoadMoreTrending) {
            NSLog(@"should be loading more trending");
            [self loadMoreTrending];
        } else if (_shared && canLoadMoreShared) {
            NSLog(@"should be loading more shared");
            [self loadMoreShared];
        } else if (_ether && canLoadMore) {
            NSLog(@"should be loading more");
            [self loadMore];
        }
    }

    lastY = actualPosition;
}

- (void)loadMore {
    loading = YES;
    Story *lastStory = _stories.lastObject;
    if (lastStory){
        [manager GET:[NSString stringWithFormat:@"%@/stories",kAPIBaseUrl] parameters:@{@"before_date":lastStory.epochTime, @"count":@"10"} success:^(AFHTTPRequestOperation *operation, id responseObject) {
            //NSLog(@"more stories response: %@",responseObject);
            NSArray *newStories = [Utilities storiesFromJSONArray:[responseObject objectForKey:@"stories"]];
            NSLog(@"new stories count: %d",newStories.count);
            NSMutableArray *indexesToInsert = [NSMutableArray array];
            for (int i = _stories.count; i < newStories.count+_stories.count; i++){
                [indexesToInsert addObject:[NSIndexPath indexPathForRow:i inSection:0]];
            }
            [_stories addObjectsFromArray:newStories];
            if (newStories.count < 10) {
                canLoadMore = NO;
                NSLog(@"Can't load more, we now have %i stories", _stories.count);
            }
            [delegate setStories:_stories];
            loading = NO;
            if ([_tableView numberOfRowsInSection:0] > 1 && indexesToInsert.count){
                [_tableView insertRowsAtIndexPaths:indexesToInsert withRowAnimation:UITableViewRowAnimationFade];
            } else {
                [_tableView reloadData];
            }
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            
        }];
    } else {
        [self loadEtherStories];
    }
}

- (void)loadMoreFeatured {
    loading = YES;
    Story *lastStory = _featuredStories.lastObject;
    if (lastStory){
        [manager GET:[NSString stringWithFormat:@"%@/stories/featured",kAPIBaseUrl] parameters:@{@"before_date":lastStory.epochTime, @"count":@"10"} success:^(AFHTTPRequestOperation *operation, id responseObject) {
            //NSLog(@"more stories response: %@",responseObject);
            NSArray *newStories = [Utilities storiesFromJSONArray:[responseObject objectForKey:@"stories"]];
            NSMutableArray *indexesToInsert = [NSMutableArray array];
            for (int i = _featuredStories.count; i < newStories.count+_featuredStories.count; i++){
                [indexesToInsert addObject:[NSIndexPath indexPathForRow:i inSection:0]];
            }
            [_featuredStories addObjectsFromArray:newStories];
            [_tableView insertRowsAtIndexPaths:indexesToInsert withRowAnimation:UITableViewRowAnimationFade];
            if (newStories.count < 10) {
                canLoadMoreFeatured = NO;
                NSLog(@"can't load more featured, we now have %i stories", _featuredStories.count);
            }
            loading = NO;
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Failure loading more featured stories: %@",error.description);
        }];
    } else {
        [self loadFeatured];
    }
}

- (void)loadMoreTrending {
    loading = YES;
    Story *lastStory = _trendingStories.lastObject;
    if (lastStory){
        [manager GET:[NSString stringWithFormat:@"%@/stories/trending",kAPIBaseUrl] parameters:@{@"before_date":lastStory.epochTime, @"count":@"10"} success:^(AFHTTPRequestOperation *operation, id responseObject) {
            //NSLog(@"more stories response: %@",responseObject);
            NSArray *newStories = [Utilities storiesFromJSONArray:[responseObject objectForKey:@"stories"]];
            NSMutableArray *indexesToInsert = [NSMutableArray array];
            for (int i = _trendingStories.count; i < newStories.count+_trendingStories.count; i++){
                [indexesToInsert addObject:[NSIndexPath indexPathForRow:i inSection:0]];
            }
            [_trendingStories addObjectsFromArray:newStories];
            [_tableView insertRowsAtIndexPaths:indexesToInsert withRowAnimation:UITableViewRowAnimationFade];
            if (newStories.count < 10) {
                canLoadMoreTrending = NO;
                NSLog(@"can't load more trending, we now have %i stories", _trendingStories.count);
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
    Story *lastStory = _sharedStories.lastObject;
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
                NSLog(@"can't load more shared, we now have %i stories", _sharedStories.count);
            }
            loading = NO;
            [self.tableView insertRowsAtIndexPaths:indexesToInsert withRowAnimation:UITableViewRowAnimationFade];
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Failure loading more shared stories: %@",error.description);
        }];
    } else {
        [self loadShared];
    }
}

- (void)storyScrollViewTouched:(UITapGestureRecognizer*)tapGesture {
    XXStory *story = nil;
    if (_featured && _featuredStories.count > tapGesture.view.tag){
        story = [_featuredStories objectAtIndex:tapGesture.view.tag];
    } else if (_shared && _sharedStories.count > tapGesture.view.tag){
        story = [_sharedStories objectAtIndex:tapGesture.view.tag];
    } else if (_trending && _trendingStories.count > tapGesture.view.tag){
        story = [_trendingStories objectAtIndex:tapGesture.view.tag];
    } else if (_ether && _stories.count > tapGesture.view.tag) {
        story = [_stories objectAtIndex:tapGesture.view.tag];
    }
    if (story != nil) {
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
        [self performSegueWithIdentifier:@"Story" sender:story];
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
            if (_featured){
                story = [_featuredStories objectAtIndex:[(NSIndexPath*)sender row]];
            } else if (_shared){
                story = [_sharedStories objectAtIndex:[(NSIndexPath*)sender row]];
            } else if (_trending){
                story = [_trendingStories objectAtIndex:[(NSIndexPath*)sender row]];
            } else {
                story = [_stories objectAtIndex:[(NSIndexPath*)sender row]];
            }
            
            XXStoryViewController *vc = [segue destinationViewController];
            [vc setStory:story];
            [vc setStories:_stories];
        } else if ([sender isKindOfClass:[XXStory class]]){
            XXStoryViewController *vc = [segue destinationViewController];
            [vc setStory:(XXStory*)sender];
            [vc setStories:_stories];
        }
        
        [UIView animateWithDuration:.25 animations:^{
            [self.tableView setAlpha:0.0];
        }];
        
    }
}

- (void)flagStory:(UIButton*)button {
    XXStory *story = [_stories objectAtIndex:button.tag];
    NSLog(@"should be flagging story: %@",story.title);
    XXFlagContentViewController *flagVC = [[self storyboard] instantiateViewControllerWithIdentifier:@"Flag"];
    [flagVC setStory:story];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:flagVC];
    [self presentViewController:nav animated:YES completion:^{
        
    }];
}

- (void)storyFlagged:(NSNotification*)notification {
    NSLog(@"story flagged");
    XXStory *story = [notification.userInfo objectForKey:@"story"];
    if ([_stories containsObject:story]){
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[_stories indexOfObject:story] inSection:0];
        [_stories removeObject:story];
        [_tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

- (void)manageCircles {
    XXCollaborateViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Collaborate"];
    [vc setTitle:@"Contacts"];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    [self presentViewController:nav animated:YES completion:^{
        
    }];
}

-(UIImage *)blurredSnapshot:(BOOL)light {
    if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)){
        UIGraphicsBeginImageContextWithOptions([UIScreen mainScreen].bounds.size, NO, self.view.window.screen.scale);
        [self.view drawViewHierarchyInRect:self.view.frame afterScreenUpdates:NO];
    } else {
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(screenHeight(), screenWidth()), NO, self.view.window.screen.scale);
        [self.view drawViewHierarchyInRect:CGRectMake(0, 0, screenHeight(), screenWidth()) afterScreenUpdates:NO];
    }
    
    UIImage *snapshotImage = UIGraphicsGetImageFromCurrentImageContext();
    UIImage *blurredSnapshotImage = [snapshotImage applyBlurWithRadius:50 blurType:BOXFILTER tintColor:[UIColor colorWithWhite:0 alpha:0.53] saturationDeltaFactor:1.8 maskImage:nil];
    
    UIGraphicsEndImageContext();
    return blurredSnapshotImage;
}

- (void)saveContext {
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
        NSLog(@"%u saving stories.",success);
    }];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}
@end

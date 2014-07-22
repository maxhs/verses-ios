//
//  XXStoriesViewController.m
//  Verses
//
//  Created by Max Haines-Stiles on 10/11/13.
//  Copyright (c) 2013 Verses. All rights reserved.
//

#import "XXStoriesViewController.h"
#import "XXStoryCell.h"
#import "XXNoRotateNavController.h"
#import "XXProgress.h"
#import "Contribution.h"
#import "User.h"
#import "Photo.h"
#import "XXStoryViewController.h"
#import "XXAppDelegate.h"
#import "UIImage+ImageEffects.h"
#import <DTCoreText/DTCoreText.h>
#import "XXNewUserWalkthroughViewController.h"
#import "XXNoRotateNavController.h"
#import "XXCollaborateViewController.h"
#import "XXFlagContentViewController.h"
#import "XXGuideViewController.h"
#import "Story+helper.h"
#import "XXNothingCell.h"
#import "XXGuideAnimator.h"

@interface XXStoriesViewController () <UIScrollViewDelegate, UIViewControllerTransitioningDelegate>{
    AFHTTPRequestOperationManager *manager;
    CGFloat width;
    CGFloat height;
    CGFloat lastY;
    UIInterfaceOrientation orientation;
    UIRefreshControl *refreshControl;
    BOOL loading;
    BOOL canLoadMore;
    BOOL canLoadMoreTrending;
    BOOL canLoadMoreShared;
    BOOL canLoadMoreFeatured;
    XXAppDelegate *delegate;
    NSDateFormatter *_formatter;
    UIColor *textColor;
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
    [super viewDidLoad];
    refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(handleRefresh) forControlEvents:UIControlEventValueChanged];
    [refreshControl setTintColor:[UIColor darkGrayColor]];
    [self.view setBackgroundColor:[UIColor clearColor]];
    [self.tableView addSubview:refreshControl];
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    delegate = (XXAppDelegate*)[UIApplication sharedApplication].delegate;
    manager = delegate.manager;
    self.reloadTheme = NO;
    _formatter = [[NSDateFormatter alloc] init];
    [_formatter setLocale:[NSLocale currentLocale]];
    [_formatter setDateFormat:@"MMM d - h:mm a"];
    
    orientation = self.interfaceOrientation;
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
    [menuButton setAutoresizingMask:UIViewAutoresizingFlexibleRightMargin];
    [self.view addSubview:menuButton];
    
    _sharedStories = [NSMutableArray array];
    _trendingStories = [NSMutableArray array];
    _featuredStories = [NSMutableArray array];
        
    if (_featured){
        _featuredStories = [Story MR_findByAttribute:@"featured" withValue:[NSNumber numberWithBool:YES] andOrderBy:@"publishedDate" ascending:NO inContext:[NSManagedObjectContext MR_defaultContext]].mutableCopy;
        if (_featuredStories.count == 0) {
            [self loadFeatured];
        } else {
            [self.tableView reloadData];
            [self loadMoreFeatured];
        }
    } else if (_shared) {
        NSPredicate *userPredicate = [NSPredicate predicateWithFormat:@"ANY users.identifier == %@",[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]];
        NSPredicate *ownerPredicate = [NSPredicate predicateWithFormat:@"ownerId != %@",[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]];
        NSPredicate *compoundPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[userPredicate,ownerPredicate]];
        
        _sharedStories = [Story MR_findAllSortedBy:@"updatedDate" ascending:NO withPredicate:compoundPredicate inContext:[NSManagedObjectContext MR_defaultContext]].mutableCopy;
        if (_sharedStories.count == 0) {
            [self loadShared];
        } else {
            [self.tableView reloadData];
        }
    } else if (_trending){
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"trendingCount != %@ and publishedDate != %@",[NSNumber numberWithInt:0], [NSDate dateWithTimeIntervalSince1970:0]];
        _trendingStories = [Story MR_findAllSortedBy:@"trendingCount" ascending:NO withPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]].mutableCopy;
        [self loadTrending];
    } else if (_ether || _stories.count == 0) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"inviteOnly == %@ and draft == %@ and publishedDate != %@",[NSNumber numberWithBool:NO],[NSNumber numberWithBool:NO], [NSDate dateWithTimeIntervalSince1970:0]];
        _stories = [Story MR_findAllSortedBy:@"publishedDate" ascending:NO withPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]].mutableCopy;
        if (_stories.count == 0) {
            [self loadEtherStories];
        } else {
            [self.tableView reloadData];
        }
    }
   
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(storyFlagged:) name:@"StoryFlagged" object:nil];
}

- (void)showGuide {
    XXGuideViewController *guide = [[self storyboard] instantiateViewControllerWithIdentifier:@"Guide"];
    guide.transitioningDelegate = self;
    guide.modalPresentationStyle = UIModalPresentationCustom;
    [self presentViewController:guide animated:YES completion:nil];
}

- (NSMutableArray*)updateLocalStories:(NSArray*)array{
    NSMutableArray *storyArray = [NSMutableArray array];
    for (NSDictionary *dict in array){
        if ([dict objectForKey:@"id"] && [dict objectForKey:@"id"] != [NSNull null]){
            Story *story = [Story MR_findFirstByAttribute:@"identifier" withValue:[dict objectForKey:@"id"] inContext:[NSManagedObjectContext MR_defaultContext]];
            if (!story){
                story = [Story MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [story populateFromDict:dict];
            [storyArray addObject:story];
        }
    }
    
    //this is synchronous so the tableview datasource can update properly.
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
    
    if (_featured){
        if (_featuredStories.count) [_featuredStories removeAllObjects];
        _featuredStories = [Story MR_findByAttribute:@"featured" withValue:[NSNumber numberWithBool:YES] andOrderBy:@"publishedDate" ascending:NO inContext:[NSManagedObjectContext MR_defaultContext]].mutableCopy;
    } else if (_shared) {
        if (_sharedStories.count) [_sharedStories removeAllObjects];
        NSPredicate *userPredicate = [NSPredicate predicateWithFormat:@"ANY users.identifier CONTAINS[cd] %@",[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]];
        NSPredicate *ownerPredicate = [NSPredicate predicateWithFormat:@"ownerId != %@",[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]];
        NSPredicate *compoundPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[userPredicate,ownerPredicate]];
        _sharedStories = [Story MR_findAllSortedBy:@"updatedDate" ascending:NO withPredicate:compoundPredicate inContext:[NSManagedObjectContext MR_defaultContext]].mutableCopy;
        NSLog(@"total shared stories count: %d",_sharedStories.count);
    } else if (_trending){
        if (_trendingStories.count) [_trendingStories removeAllObjects];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"trendingCount != %@ and publishedDate != %@",[NSNumber numberWithInt:0], [NSDate dateWithTimeIntervalSince1970:0]];
        _trendingStories = [Story MR_findAllSortedBy:@"trendingCount" ascending:NO withPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]].mutableCopy;
    } else if (_ether || _stories.count == 0) {
        if (_stories.count) [_stories removeAllObjects];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"inviteOnly == %@ and draft == %@ and publishedDate != %@",[NSNumber numberWithBool:NO],[NSNumber numberWithBool:NO], [NSDate dateWithTimeIntervalSince1970:0]];
        _stories = [Story MR_findAllSortedBy:@"publishedDate" ascending:NO withPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]].mutableCopy;
    }
    
    //done loading! what a relief
    loading = NO;
    return storyArray;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    orientation = self.interfaceOrientation;
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    [delegate.dynamicsDrawerViewController setPaneDragRevealEnabled:NO forDirection:MSDynamicsDrawerDirectionRight];

    if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
        textColor = [UIColor whiteColor];
        [self.view setBackgroundColor:[UIColor clearColor]];
        [refreshControl setTintColor:[UIColor whiteColor]];
        [menuButton setImage:[UIImage imageNamed:@"moreWhite"] forState:UIControlStateNormal];
        [_tableView setIndicatorStyle:UIScrollViewIndicatorStyleWhite];
    } else {
        textColor = [UIColor blackColor];
        [self.view setBackgroundColor:[UIColor whiteColor]];
        [refreshControl setTintColor:[UIColor darkGrayColor]];
        [_tableView setIndicatorStyle:UIScrollViewIndicatorStyleBlack];
        [menuButton setImage:[UIImage imageNamed:@"more"] forState:UIControlStateNormal];
    }
    canLoadMore = YES;
    canLoadMoreShared = YES;
    canLoadMoreTrending = YES;
    canLoadMoreFeatured = YES;

    if (self.reloadTheme)
        [self.tableView reloadData];
    
    if (self.tableView.alpha == 0.0){
        [UIView animateWithDuration:.25 animations:^{
            [self.tableView setAlpha:1.0];
        }];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (![[NSUserDefaults standardUserDefaults] boolForKey:kExistingUser]) {
        double delayInSeconds = 0.0;
        dispatch_time_t delayTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds *   NSEC_PER_SEC));
        dispatch_after(delayTime, dispatch_get_main_queue(), ^(void){
            
            XXNewUserWalkthroughViewController *vc = [[XXNewUserWalkthroughViewController alloc] init];
            XXNoRotateNavController *nav = [[XXNoRotateNavController alloc] initWithRootViewController:vc];
            nav.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
            [self.view.window.rootViewController presentViewController:nav animated:YES completion:^{
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kExistingUser];
            }];
            
        });
    }
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented
                                                                  presentingController:(UIViewController *)presenting
                                                                      sourceController:(UIViewController *)source {
    XXGuideAnimator *animator = [XXGuideAnimator new];
    animator.presenting = YES;
    return animator;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {

    XXGuideAnimator *animator = [XXGuideAnimator new];
    return animator;
}

- (void)handleRefresh{
    if (_featured){
        canLoadMoreFeatured = YES;
        [self loadFeatured];
    } else if (_shared){
        canLoadMoreShared = YES;
        [self loadShared];
    } else if (_trending){
        canLoadMoreTrending = YES;
        [self loadTrending];
    } else if (_ether) {
        canLoadMore = YES;
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
    if (!loading){
        loading = YES;
        [manager GET:[NSString stringWithFormat:@"%@/stories",kAPIBaseUrl] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
            //NSLog(@"story response: %@",responseObject);
            [self updateLocalStories:[responseObject objectForKey:@"stories"]];
            if (refreshControl.isRefreshing) [refreshControl endRefreshing];
            [self.tableView reloadData];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            if (refreshControl.isRefreshing) [refreshControl endRefreshing];
            NSLog(@"Failure getting stories from welcome controller: %@",error.description);
            canLoadMore = NO;
            //[[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Something went wrong while trying to fetch the latest stories. Please pull down to refresh." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        }];
    }
}

- (void)loadShared {
    if (!loading){
        loading = YES;
        if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
            [manager GET:[NSString stringWithFormat:@"%@/stories/shared",kAPIBaseUrl] parameters:@{@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId],@"count":@"10"} success:^(AFHTTPRequestOperation *operation, id responseObject) {
                //NSLog(@"shared stories response: %@",responseObject);
                [self updateLocalStories:[responseObject objectForKey:@"stories"]];
                [self.tableView reloadData];
                if (refreshControl.isRefreshing)[refreshControl endRefreshing];
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                if (refreshControl.isRefreshing) [refreshControl endRefreshing];
                canLoadMoreShared = NO;
                NSLog(@"Failure getting shared stories from welcome controller: %@",error.description);
                //[[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Something went wrong while trying to fetch the latest featured stories. Please pull down to refresh." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
            }];
        }
    }
}

- (void)loadTrending {
    if (!loading){
        loading = YES;
        [manager GET:[NSString stringWithFormat:@"%@/stories/trending",kAPIBaseUrl] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
            //NSLog(@"trending stories response: %@",responseObject);
            [self updateLocalStories:[responseObject objectForKey:@"stories"]];
            [self.tableView reloadData];
            if (refreshControl.isRefreshing)[refreshControl endRefreshing];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            if (refreshControl.isRefreshing) [refreshControl endRefreshing];
            NSLog(@"Failure getting trending stories from welcome controller: %@",error.description);
            canLoadMoreTrending = NO;
            [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Something went wrong while trying to fetch what's trending. Please pull down to refresh." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        }];
    }
}

- (void)loadFeatured {
    loading = YES;
    [manager GET:[NSString stringWithFormat:@"%@/stories/featured",kAPIBaseUrl] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"featured stories response: %@",responseObject);
        [self updateLocalStories:[responseObject objectForKey:@"stories"]];
        [self.tableView reloadData];
        if (refreshControl.isRefreshing)[refreshControl endRefreshing];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (refreshControl.isRefreshing) [refreshControl endRefreshing];
        NSLog(@"Failure getting featured stories from welcome controller: %@",error.description);
        canLoadMoreFeatured = NO;
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
        return _featuredStories.count;
    } else if (_shared){
        if (_sharedStories.count == 0 && !loading) {
            return 1;
        } else {
            return _sharedStories.count;
        }
    } else if (_trending) {
        return _trendingStories.count;
    } else if (_ether) {
        return _stories.count;
    } else {
        return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_shared && _sharedStories.count == 0){
        XXNothingCell *cell = (XXNothingCell *)[tableView dequeueReusableCellWithIdentifier:@"NothingCell"];
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"XXNothingCell" owner:nil options:nil] lastObject];
        }
        [cell.promptButton setTitle:@"Nothing shared just yet.\nTap here to manage your contacts." forState:UIControlStateNormal];
        [cell.promptButton addTarget:self action:@selector(manageCircles) forControlEvents:UIControlEventTouchUpInside];
        [cell.promptButton.titleLabel setNumberOfLines:0];
        [cell.promptButton.titleLabel setFont:[UIFont fontWithName:kSourceSansProLight size:20]];
        [cell.promptButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
        [cell.promptButton setTitleColor:textColor forState:UIControlStateNormal];
        [cell.promptButton setBackgroundColor:[UIColor clearColor]];
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
        [cell.flagButton setTitleColor:textColor forState:UIControlStateNormal];
        [cell.flagButton addTarget:self action:@selector(flagStory:) forControlEvents:UIControlEventTouchUpInside];
        
        if (_trending) {
            if (story.trendingCount && ![story.trendingCount isEqualToNumber:[NSNumber numberWithInt:0]]){
                [cell.countLabel setHidden:NO];
                NSString *countLabelText;
                if ([story.trendingCount isEqualToNumber:[NSNumber numberWithInt:1]]){
                    if ([story.mystery isEqualToNumber:[NSNumber numberWithBool:YES]]){
                        countLabelText = [NSString stringWithFormat:@"Slow Reveal \u2022 1 recent view"];
                    } else {
                        countLabelText = @"1 recent view";
                    }
                } else {
                    if ([story.mystery isEqualToNumber:[NSNumber numberWithBool:YES]]){
                        countLabelText = [NSString stringWithFormat:@"Slow Reveal \u2022 %@ recent views",story.trendingCount];
                    } else {
                        countLabelText = [NSString stringWithFormat:@"%@ recent views",story.trendingCount];
                    }
                }
                [cell.countLabel setText:countLabelText];
            } else {
                [cell.countLabel setHidden:YES];
            }
            
        } else if (story.views && ![story.views isEqualToNumber:[NSNumber numberWithInt:0]]) {
            [cell.countLabel setHidden:NO];
            NSString *countLabelText;
            
            if (story.views.intValue == 1){
                if ([story.mystery isEqualToNumber:[NSNumber numberWithBool:YES]]){
                    countLabelText = [NSString stringWithFormat:@"Slow Reveal \u2022 1 view"];
                } else {
                    countLabelText = @"1 view";
                }
            } else {
                if ([story.mystery isEqualToNumber:[NSNumber numberWithBool:YES]]){
                    countLabelText = @"Slow Reveal \u2022 1 view";
                } else {
                    countLabelText = [NSString stringWithFormat:@"%@ views",story.views];
                }
            }
            [cell.countLabel setText:countLabelText];
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


-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (_shared && _sharedStories.count == 0 && !loading) return screenHeight();
    else {
        if (UIInterfaceOrientationIsPortrait(orientation)){
            if (IDIOM == IPAD){
                return height/3;
            } else {
                return height/2;
            }
        } else {
            if (IDIOM == IPAD){
                return height/2;
            } else {
                return height;
            }
        }
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
            //NSLog(@"should be loading more featured");
            [self loadMoreFeatured];
        }/* else if (_trending && canLoadMoreTrending) {
            NSLog(@"should be loading more trending");
            [self loadMoreTrending];
        }*/ else if (_shared && canLoadMoreShared) {
            //NSLog(@"should be loading more shared");
            [self loadMoreShared];
        } else if (_ether && canLoadMore) {
            //NSLog(@"should be loading more");
            [self loadMore];
        }
    }
    lastY = actualPosition;
}

- (void)loadMore {
    loading = YES;
    Story *lastStory = _stories.lastObject;
    if (lastStory){
        [manager GET:[NSString stringWithFormat:@"%@/stories",kAPIBaseUrl] parameters:@{@"before_date":[NSNumber numberWithDouble:[lastStory.publishedDate timeIntervalSince1970]], @"count":@"10"} success:^(AFHTTPRequestOperation *operation, id responseObject) {
            //NSLog(@"more stories response: %@",responseObject);
            int currentCount = _stories.count;
            NSArray *newStories = [self updateLocalStories:[responseObject objectForKey:@"stories"]];
            NSMutableArray *indexesToInsert = [NSMutableArray array];
            for (int i = currentCount; i < newStories.count+currentCount; i++){
                [indexesToInsert addObject:[NSIndexPath indexPathForRow:i inSection:0]];
            }
            if (newStories.count < 10) {
                canLoadMore = NO;
                //NSLog(@"Can't load more, we now have %i stories", _stories.count);
            }
            
            if (self.tableView.numberOfSections){
                [_tableView beginUpdates];
                [_tableView insertRowsAtIndexPaths:indexesToInsert withRowAnimation:UITableViewRowAnimationFade];
                [_tableView endUpdates];
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
        [manager GET:[NSString stringWithFormat:@"%@/stories/featured",kAPIBaseUrl] parameters:@{@"before_date":[NSNumber numberWithDouble:[lastStory.updatedDate timeIntervalSince1970]], @"count":@"10"} success:^(AFHTTPRequestOperation *operation, id responseObject) {
            //NSLog(@"more featured stories response: %@",responseObject);
            int currentCount = _featuredStories.count;
            NSArray *newStories = [self updateLocalStories:[responseObject objectForKey:@"stories"]];
            NSMutableArray *indexesToInsert = [NSMutableArray array];
            for (int i = currentCount; i < newStories.count+currentCount; i++){
                [indexesToInsert addObject:[NSIndexPath indexPathForRow:i inSection:0]];
            }
            if (newStories.count < 10) {
                canLoadMoreFeatured = NO;
                NSLog(@"Can't load more featured, we now have %i stories.", _featuredStories.count);
            }
            
            if (self.tableView.numberOfSections){
                [_tableView beginUpdates];
                [_tableView insertRowsAtIndexPaths:indexesToInsert withRowAnimation:UITableViewRowAnimationFade];
                [_tableView endUpdates];
            } else {
                [_tableView reloadData];
            }
            if (refreshControl.isRefreshing) [refreshControl endRefreshing];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            if (refreshControl.isRefreshing) [refreshControl endRefreshing];
            canLoadMoreFeatured = NO;
            NSLog(@"Failure loading more featured stories: %@",error.description);
        }];
    } else {
        [self loadFeatured];
    }
}

/*- (void)loadMoreTrending {
    loading = YES;
    Story *lastStory = _trendingStories.lastObject;
    if (lastStory){
        [manager GET:[NSString stringWithFormat:@"%@/stories/trending",kAPIBaseUrl] parameters:@{@"before_date":[NSNumber numberWithDouble:[lastStory.updatedDate timeIntervalSince1970]], @"count":@"10"} success:^(AFHTTPRequestOperation *operation, id responseObject) {
            //NSLog(@"more stories response: %@",responseObject);
            int currentCount = _trendingStories.count;
            NSArray *newStories = [self updateLocalStories:[responseObject objectForKey:@"stories"]];
            NSMutableArray *indexesToInsert = [NSMutableArray array];
            for (int i = currentCount; i < newStories.count+currentCount; i++){
                [indexesToInsert addObject:[NSIndexPath indexPathForRow:i inSection:0]];
            }
            NSLog(@"new trending stories: %d",newStories.count);
            if (newStories.count > 0){
                [_tableView insertRowsAtIndexPaths:indexesToInsert withRowAnimation:UITableViewRowAnimationFade];
            }
            if (newStories.count < 10) {
                canLoadMoreTrending = NO;
                NSLog(@"can't load more trending, we now have %i stories", _trendingStories.count);
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Failure loading more trending stories: %@",error.description);
        }];
    } else {
        [self loadTrending];
    }
}*/

- (void)loadMoreShared {
    loading = YES;
    Story *lastStory = _sharedStories.lastObject;
    if (lastStory){
        [manager GET:[NSString stringWithFormat:@"%@/stories/shared",kAPIBaseUrl] parameters:@{@"before_date":[NSNumber numberWithDouble:[lastStory.updatedDate timeIntervalSince1970]], @"count":@"10",@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
            //NSLog(@"more shared stories response: %@",responseObject);
            int currentCount = _sharedStories.count;
            NSArray *newStories = [self updateLocalStories:[responseObject objectForKey:@"stories"]];
            NSMutableArray *indexesToInsert = [NSMutableArray array];
            for (int i = currentCount; i < newStories.count + currentCount; i++){
                [indexesToInsert addObject:[NSIndexPath indexPathForRow:i inSection:0]];
            }
            
            if (newStories.count < 10) {
                canLoadMoreShared = NO;
                NSLog(@"can't load more shared, we now have %i stories", _sharedStories.count);
            }
            if (newStories.count){
                if (self.tableView.numberOfSections > 0){
                    [self.tableView beginUpdates];
                    [self.tableView insertRowsAtIndexPaths:indexesToInsert withRowAnimation:UITableViewRowAnimationFade];
                    [self.tableView endUpdates];
                } else {
                    [self.tableView reloadData];
                }
            }
            if (refreshControl.isRefreshing) [refreshControl endRefreshing];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            if (refreshControl.isRefreshing) [refreshControl endRefreshing];
            NSLog(@"Failure loading more shared stories: %@",error.description);
        }];
    } else {
        [self loadShared];
    }
}

- (void)storyScrollViewTouched:(UITapGestureRecognizer*)tapGesture {
    Story *story = nil;
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
            Story *story;
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
        } else if ([sender isKindOfClass:[Story class]]){
            XXStoryViewController *vc = [segue destinationViewController];
            [vc setStory:(Story*)sender];
        }
        
        [UIView animateWithDuration:.25 animations:^{
            [self.tableView setAlpha:0.0];
        }];
        
    }
}

- (void)flagStory:(UIButton*)button {
    Story *story = [_stories objectAtIndex:button.tag];
    XXFlagContentViewController *flagVC = [[self storyboard] instantiateViewControllerWithIdentifier:@"Flag"];
    [flagVC setStory:story];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:flagVC];
    [self presentViewController:nav animated:YES completion:^{
        
    }];
}

- (void)storyFlagged:(NSNotification*)notification {
    Story *story = [notification.userInfo objectForKey:@"story"];
    [story MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
    if ([_stories containsObject:story]){
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[_stories indexOfObject:story] inSection:0];
        [_stories removeObject:story];
        
        [_tableView beginUpdates];
        [_tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        [_tableView endUpdates];
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

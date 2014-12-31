//
//  XXPortfolioViewController.m
//  Verses
//
//  Created by Max Haines-Stiles on 3/16/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import "XXAppDelegate.h"
#import "XXPortfolioViewController.h"
#import "Story+helper.h"
#import "XXStoryCell.h"
#import "XXPortfolioCell.h"
#import "XXSearchCell.h"
#import "XXStoryViewController.h"
#import "XXWriteViewController.h"
#import "XXGuideInteractor.h"
#import "XXGuideViewController.h"
#import "XXNothingCell.h"

@interface XXPortfolioViewController () <UIViewControllerTransitioningDelegate, UIGestureRecognizerDelegate> {
    NSMutableArray *_filteredResults;
    AFHTTPRequestOperationManager *manager;
    BOOL loading;
    BOOL canLoadMore;
    BOOL canLoadMoreDrafts;
    NSDateFormatter *_formatter;
    UIColor *textColor;
    NSMutableArray *_openCells;
    User *currentUser;
    UIRefreshControl *refreshControl;
    NSMutableArray *drafts;
    NSMutableArray *stories;
    CGFloat height;
    CGFloat width;
}

@end

@implementation XXPortfolioViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    manager = [(XXAppDelegate*)[UIApplication sharedApplication].delegate manager];
    currentUser = [(XXAppDelegate*)[UIApplication sharedApplication].delegate currentUser];
    [self.view setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation) || [[[UIDevice currentDevice] systemVersion] floatValue] >= 8.f){
        width = screenWidth();
        height = screenHeight();
    } else {
        height = screenWidth();
        width = screenHeight();
    }
    
    refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(handleRefresh) forControlEvents:UIControlEventValueChanged];
    [refreshControl setTintColor:[UIColor darkGrayColor]];
    [self.tableView addSubview:refreshControl];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeStory:) name:@"RemoveStory" object:nil];
    _formatter= [[NSDateFormatter alloc] init];
    [_formatter setLocale:[NSLocale currentLocale]];
    [_formatter setDateFormat:@"MMM d - h:mm a"];
    canLoadMore = YES;
    canLoadMoreDrafts = YES;
    loading = YES;
    
    if (_draftMode){
        [self.searchBar setPlaceholder:@"Search my drafts"];
    } else {
        [self.searchBar setPlaceholder:@"Search my portfolio"];
    }
    self.searchBar.delegate = self;
    [self.searchResultsTableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    UITapGestureRecognizer *dismissSearch = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(endSearch)];
    dismissSearch.numberOfTapsRequired = 1;
    dismissSearch.numberOfTouchesRequired = 1;
    dismissSearch.delegate = self;
    dismissSearch.cancelsTouchesInView = YES;
    [self.searchResultsTableView addGestureRecognizer:dismissSearch];
    self.searchBar.searchBarStyle = UISearchBarStyleMinimal;
    _openCells = [NSMutableArray array];
    _filteredResults = [NSMutableArray array];
    if (_draftMode){
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"ownerId == %@ && draft == 1",[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]];
        drafts = [Story MR_findAllSortedBy:@"updatedDate" ascending:NO withPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]].mutableCopy;
        if (drafts.count < 2){
            [self loadDrafts];
        } else {
            [self.tableView reloadData];
        }
    } else {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"ownerId == %@",[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]];
        stories = [Story MR_findAllSortedBy:@"updatedDate" ascending:NO withPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]].mutableCopy;
        if (stories.count < 2){
            [self loadStories];
        } else {
            [self.tableView reloadData];
        }
    }
    
    [_moreButton.titleLabel setFont:[UIFont fontWithName:kSourceSansPro size:15]];
}

- (void)removeStory:(NSNotification*)notification {
    if (_draftMode){
        for (Story *story in drafts){
            if([story.identifier isEqualToNumber:[notification.userInfo objectForKey:@"story_id"]]) {
      
                [drafts removeObject:story];
                [self.tableView beginUpdates];
                [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
                [self.tableView endUpdates];
                break;
            }
        }
    } else {
        for (Story *story in stories){
            if([story.identifier isEqualToNumber:[notification.userInfo objectForKey:@"story_id"]]) {
                [stories removeObject:story];
                [self.tableView beginUpdates];
                [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
                [self.tableView endUpdates];
                break;
            }
        }
    }
}

- (void)handleRefresh {
    if (_draftMode){
        [ProgressHUD show:@"Refreshing your drafts..."];
        [self loadDrafts];
    } else {
        [ProgressHUD show:@"Refreshing your portfolio..."];
        [self loadStories];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [[(XXAppDelegate*)[UIApplication sharedApplication].delegate dynamicsDrawerViewController] setPaneDragRevealEnabled:NO forDirection:MSDynamicsDrawerDirectionRight];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
        [_tableView setIndicatorStyle:UIScrollViewIndicatorStyleWhite];
        [self.view setBackgroundColor:[UIColor clearColor]];
        textColor = [UIColor whiteColor];
        [refreshControl setTintColor:[UIColor whiteColor]];
        [self.searchResultsTableView setBackgroundColor:[UIColor colorWithWhite:0.025 alpha:.93]];
        [_moreButton setImage:[UIImage imageNamed:@"moreWhite"] forState:UIControlStateNormal];
        [_moreButton setTitleColor:textColor forState:UIControlStateNormal];
        for (id subview in [self.searchBar.subviews.firstObject subviews]){
            if ([subview isKindOfClass:[UITextField class]]){
                [(UITextField*)subview setKeyboardAppearance:UIKeyboardAppearanceDark];
                [(UITextField*)subview setFont:[UIFont fontWithName:kSourceSansPro size:15]];
                break;
            }
        }
        [self.searchBar setBackgroundColor:[UIColor colorWithWhite:0 alpha:.87]];
    } else {
        [_tableView setIndicatorStyle:UIScrollViewIndicatorStyleBlack];
        [self.searchBar setBackgroundColor:[UIColor whiteColor]];
        [self.searchResultsTableView setBackgroundColor:[UIColor colorWithWhite:1 alpha:.97]];
        for (id subview in [self.searchBar.subviews.firstObject subviews]){
            if ([subview isKindOfClass:[UITextField class]]){
                [(UITextField*)subview setTextColor:[UIColor blackColor]];
                [(UITextField*)subview setFont:[UIFont fontWithName:kSourceSansPro size:15]];
                [(UITextField*)subview setKeyboardAppearance:UIKeyboardAppearanceDefault];
            }
        }
        
        [self.view setBackgroundColor:[UIColor whiteColor]];
        textColor = [UIColor blackColor];
        [refreshControl setTintColor:[UIColor blackColor]];
        [_moreButton setImage:[UIImage imageNamed:@"more"] forState:UIControlStateNormal];
        [_moreButton setTitleColor:textColor forState:UIControlStateNormal];
    }
    
    self.searchBar.layer.cornerRadius = 7.f;
    self.searchBar.clipsToBounds = YES;
    
    //transition
    if (self.tableView.alpha != 1.0){
        [UIView animateWithDuration:.23 animations:^{
            [self.tableView setAlpha:1.0];
            [self.searchBar setAlpha:1.0];
            self.tableView.transform = CGAffineTransformIdentity;
        }];
        //[self.tableView reloadData];
    }
    
}

- (void)loadDrafts {
    loading = YES;
    [manager GET:[NSString stringWithFormat:@"%@/stories/drafts",kAPIBaseUrl] parameters:@{@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]/*,@"count":@"10"*/} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"success getting my stories: %@",[responseObject objectForKey:@"stories"]);
        [self updateLocalStories:[responseObject objectForKey:@"stories"]];
     
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
       
        if (refreshControl.isRefreshing) [refreshControl endRefreshing];
        [ProgressHUD dismiss];
        NSLog(@"Failure getting stories drafts: %@",error.description);
    }];
}

- (void)loadStories {
    loading = YES;
    [manager GET:[NSString stringWithFormat:@"%@/stories/portfolio",kAPIBaseUrl] parameters:@{@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]/*,@"count":@"10"*/} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"success getting portfolio: %@",[responseObject objectForKey:@"stories"]);
        [self updateLocalStories:[responseObject objectForKey:@"stories"]];
  
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (refreshControl.isRefreshing) [refreshControl endRefreshing];
        [ProgressHUD dismiss];
        loading = NO;
        NSLog(@"Failure getting stories from stories controller: %@",error.description);
    }];
}

- (IBAction)showGuide {
    XXGuideViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Guide"];
    vc.transitioningDelegate = self;
    vc.modalPresentationStyle = UIModalPresentationCustom;
    [self presentViewController:vc animated:YES completion:nil];
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented
                                                                  presentingController:(UIViewController *)presenting
                                                                      sourceController:(UIViewController *)source {

    XXGuideInteractor *animator = [XXGuideInteractor new];
    animator.presenting = YES;
    return animator;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    XXGuideInteractor *animator = [XXGuideInteractor new];
    return animator;
}


/*- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat actualPosition = scrollView.contentOffset.y;
    CGFloat contentHeight = scrollView.contentSize.height - (screenHeight()*2);
    if (actualPosition >= contentHeight && !loading) {
        if (canLoadMore){
            NSLog(@"Should be loading more portfolio");
            [self loadMore];
        } else if (_draftMode && canLoadMoreDrafts){
            NSLog(@"Should be loading more drafts");
            [self loadMoreDrafts];
        }
    }
}*/

- (void)loadMore {
    loading = YES;
    Story *lastStory = stories.lastObject;
    NSUInteger currentCount = stories.count;
    if (lastStory){
        [manager GET:[NSString stringWithFormat:@"%@/stories/portfolio",kAPIBaseUrl] parameters:@{@"before_date":[NSNumber numberWithDouble:[lastStory.updatedDate timeIntervalSince1970]], @"count":@"10", @"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
            //NSLog(@"Loaded more portfolio response: %@",responseObject);
            NSMutableArray *newStoryArray = [NSMutableArray array];
            for (NSDictionary *dict in [responseObject objectForKey:@"stories"]){
                if ([dict objectForKey:@"id"] && [dict objectForKey:@"id"] != [NSNull null]){
                    Story *story = [Story MR_findFirstByAttribute:@"identifier" withValue:[dict objectForKey:@"id"] inContext:[NSManagedObjectContext MR_defaultContext]];
                    if (!story){
                        story = [Story MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                    }
                    [story populateFromDict:dict];
                    [newStoryArray addObject:story];
                }
            }
            
            NSMutableArray *indexesToInsert = [NSMutableArray array];
            for (NSUInteger i = currentCount; i < newStoryArray.count+currentCount; i++){
                [indexesToInsert addObject:[NSIndexPath indexPathForRow:i inSection:0]];
            }
            
            if ([(NSArray*)[responseObject objectForKey:@"stories"] count] < 10) {
                canLoadMore = NO;
                NSLog(@"Can't load more, we now have %lu portfolio stories", (unsigned long)stories.count);
            }
            [ProgressHUD dismiss];
            loading = NO;
            [self.tableView beginUpdates];
            [self.tableView insertRowsAtIndexPaths:indexesToInsert withRowAnimation:UITableViewRowAnimationFade];
            //[self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView endUpdates];
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            
        }];
    } else {
        [self loadStories];
    }
}

- (void)loadMoreDrafts {
    loading = YES;
    Story *lastStory = stories.lastObject;
    NSUInteger currentCount = stories.count;
    if (lastStory){
        [manager GET:[NSString stringWithFormat:@"%@/stories/portfolio",kAPIBaseUrl] parameters:@{@"before_date":[NSNumber numberWithDouble:[lastStory.updatedDate timeIntervalSince1970]], @"count":@"10", @"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
            //NSLog(@"loaded more of draft response: %@",responseObject);
            NSMutableArray *newStoryArray = [NSMutableArray array];
            for (NSDictionary *dict in [responseObject objectForKey:@"stories"]){
                if ([dict objectForKey:@"id"] && [dict objectForKey:@"id"] != [NSNull null]){
                    Story *story = [Story MR_findFirstByAttribute:@"identifier" withValue:[dict objectForKey:@"id"] inContext:[NSManagedObjectContext MR_defaultContext]];
                    if (!story){
                        story = [Story MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                    }
                    [story populateFromDict:dict];
                    [newStoryArray addObject:story];
                }
            }
            
            NSMutableArray *indexesToInsert = [NSMutableArray array];
            for (NSUInteger i = currentCount; i < newStoryArray.count+currentCount; i++){
                [indexesToInsert addObject:[NSIndexPath indexPathForRow:i inSection:0]];
            }
            
            if ([(NSArray*)[responseObject objectForKey:@"stories"] count] < 10) {
                canLoadMoreDrafts = NO;
                NSLog(@"can't load more, we now have %lu of my stories", (unsigned long)drafts.count);
            }
            [ProgressHUD dismiss];
            loading = NO;
            [self.tableView beginUpdates];
            //[self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView insertRowsAtIndexPaths:indexesToInsert withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView endUpdates];
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            
        }];
    } else {
        [self loadStories];
    }
}

- (void)updateLocalStories:(NSArray*)array{
    NSMutableOrderedSet *storySet = [NSMutableOrderedSet orderedSet];
    for (NSDictionary *dict in array){
        Story *story = [Story MR_findFirstByAttribute:@"identifier" withValue:[dict objectForKey:@"id"] inContext:[NSManagedObjectContext MR_defaultContext]];
        if (!story){
            story = [Story MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
        }
        [story populateFromDict:dict];
        [storySet addObject:story];
        if (_draftMode){
            
        } else {
            
        }
    }
    
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
        if (refreshControl.isRefreshing) [refreshControl endRefreshing];
        [ProgressHUD dismiss];
        
        if (_draftMode){
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"ownerId == %@ && draft == 1",[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]];
            drafts = [Story MR_findAllSortedBy:@"updatedDate" ascending:NO withPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]].mutableCopy;
            [self.tableView beginUpdates];
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView endUpdates];
        } else {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"ownerId == %@",[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]];
            stories = [Story MR_findAllSortedBy:@"updatedDate" ascending:NO withPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]].mutableCopy;
            [self.tableView beginUpdates];
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView endUpdates];
        }
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == self.searchResultsTableView){
        return _filteredResults.count;
    } else {
        if (_draftMode){
            if (drafts.count == 0 && !loading){
                return 1;
            } else {
                return drafts.count;
            }
        } else {
            if (stories.count == 0 && !loading){
                return 1;
            } else {
                return stories.count;
            }
        }
        
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.searchResultsTableView){
        XXSearchCell *cell = (XXSearchCell *)[tableView dequeueReusableCellWithIdentifier:@"SearchCell"];
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"XXSearchCell" owner:nil options:nil] lastObject];
        }
        Story *story = [_filteredResults objectAtIndex:indexPath.row];
        [cell configure:story];
        [cell.storyTitle setTextColor:textColor];
        [cell.authorLabel setTextColor:textColor];
        return cell;
    } else {
        if (_draftMode && drafts.count){
            XXPortfolioCell *cell = (XXPortfolioCell *)[tableView dequeueReusableCellWithIdentifier:@"PortfolioCell"];
            if (cell == nil) {
                cell = [[[NSBundle mainBundle] loadNibNamed:@"XXPortfolioCell" owner:nil options:nil] lastObject];
            }
            Story *story = [drafts objectAtIndex:indexPath.row];
            [cell configureForStory:story textColor:textColor withOrientation:self.interfaceOrientation];
            if (cell.background.alpha == 1.0) [self swipeCell:cell];
            [cell.readButton addTarget:self action:@selector(readStory:) forControlEvents:UIControlEventTouchUpInside];
            [cell.readButton setTag:[drafts indexOfObject:story]];
            [cell.editButton addTarget:self action:@selector(editStory:) forControlEvents:UIControlEventTouchUpInside];
            [cell.editButton setTag:[drafts indexOfObject:story]];
            [cell.wordCountLabel setText:[NSString stringWithFormat:@"%@ words  |  Last updated: %@",story.wordCount,[_formatter stringFromDate:story.updatedDate]]];
            return cell;
        } else if (!_draftMode && stories.count){
            XXPortfolioCell *cell = (XXPortfolioCell *)[tableView dequeueReusableCellWithIdentifier:@"PortfolioCell"];
            if (cell == nil) {
                cell = [[[NSBundle mainBundle] loadNibNamed:@"XXPortfolioCell" owner:nil options:nil] lastObject];
            }
            Story *story = [stories objectAtIndex:indexPath.row];
            [cell configureForStory:story textColor:textColor withOrientation:self.interfaceOrientation];
            if (cell.background.alpha == 1.0) [self swipeCell:cell];
            [cell.readButton addTarget:self action:@selector(readStory:) forControlEvents:UIControlEventTouchUpInside];
            [cell.readButton setTag:[stories indexOfObject:story]];
            [cell.editButton addTarget:self action:@selector(editStory:) forControlEvents:UIControlEventTouchUpInside];
            [cell.editButton setTag:[stories indexOfObject:story]];
            [cell.wordCountLabel setText:[NSString stringWithFormat:@"%@ words  |  Last updated: %@",story.wordCount,[_formatter stringFromDate:story.updatedDate]]];
            return cell;
        } else {
            XXNothingCell *cell = (XXNothingCell *)[tableView dequeueReusableCellWithIdentifier:@"NothingCell"];
            if (cell == nil) {
                cell = [[[NSBundle mainBundle] loadNibNamed:@"XXNothingCell" owner:nil options:nil] lastObject];
            }
            [cell.promptButton setTitle:@"You don't have any stories yet.\nTap here to start writing." forState:UIControlStateNormal];
            [cell.promptButton addTarget:self action:@selector(startWriting) forControlEvents:UIControlEventTouchUpInside];
            [cell.promptButton.titleLabel setNumberOfLines:0];
            [cell.promptButton.titleLabel setFont:[UIFont fontWithName:kSourceSansProLight size:20]];
            [cell.promptButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
            [cell.promptButton setTitleColor:textColor forState:UIControlStateNormal];
            [cell.promptButton setBackgroundColor:[UIColor clearColor]];
            return cell;
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == _searchResultsTableView){
        return 60;
    } else if (_draftMode && drafts.count == 0 && !loading){
        return height-84;
    } else if (stories.count == 0 && !loading){
        return height-84;
    } else {
        if (IDIOM == IPAD) {
            return height/3;
        } else {
            return height/2;
        }
    }
}

- (void)startWriting {
    XXWriteViewController *write = [[self storyboard] instantiateViewControllerWithIdentifier:@"Write"];
    
    //not really edit mode, obviously, but this just ensures the write vc dismisses properly
    [write setEditMode:YES];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:write];
    [self presentViewController:nav animated:YES completion:^{
        
    }];
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if([indexPath row] == ((NSIndexPath*)[[tableView indexPathsForVisibleRows] lastObject]).row && tableView == self.tableView){
        //end of loading
        [ProgressHUD dismiss];
    }
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
        cell.backgroundColor = [UIColor clearColor];
    } else {
        if (tableView == _searchResultsTableView){
            cell.backgroundColor = [UIColor clearColor];
        } else {
            cell.backgroundColor = [UIColor whiteColor];
        }
    }
}

- (void)readStory:(UIButton*)button {
    Story *story;
    if (_draftMode){
        story = [drafts objectAtIndex:button.tag];
    } else {
        story = [stories objectAtIndex:button.tag];
    }

    if (story.wordCount.intValue > 2000){
        [ProgressHUD show:@"Fetching story..."];
    }
    [self performSegueWithIdentifier:@"Read" sender:story];
}

- (void)editStory:(UIButton*)button {
    Story *story;
    if (_draftMode){
        story = [drafts objectAtIndex:button.tag];
    } else {
        story = [stories objectAtIndex:button.tag];
    }
    
    XXWriteViewController *write = [[self storyboard] instantiateViewControllerWithIdentifier:@"Write"];
    [write setStory:story];
    [write setEditMode:YES];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:write];
    [self presentViewController:nav animated:YES completion:nil];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
        [UIView animateWithDuration:.23 animations:^{
            self.tableView.transform = CGAffineTransformMakeScale(.9, .9);
            [self.tableView setAlpha:0.0];
        }];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == _searchResultsTableView) {
        Story *story = [_filteredResults objectAtIndex:indexPath.row];
        [self performSegueWithIdentifier:@"Read" sender:story];
    } else {
        XXPortfolioCell *selectedCell = (XXPortfolioCell*)[tableView cellForRowAtIndexPath:indexPath];
        [self swipeCell:selectedCell];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)swipeCell:(XXPortfolioCell*)cell {
    if (cell.background.alpha == 1.0){
        [_openCells removeObject:cell];
    } else {
        for (XXPortfolioCell *cell in _openCells){
            [cell swipe];
        }
        [_openCells removeAllObjects];
        [_openCells addObject:cell];
    }
    [cell swipe];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    [self.searchResultsTableView setHidden:NO];
    
    [UIView animateWithDuration:.23 animations:^{
        [self.searchResultsTableView setAlpha:1.0];
        [self.moreButton setTitle:@"Cancel" forState:UIControlStateNormal];
        [self.moreButton setImage:nil forState:UIControlStateNormal];
    } completion:^(BOOL finished) {
        [self.moreButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
        [self.moreButton addTarget:self action:@selector(endSearch) forControlEvents:UIControlEventTouchUpInside];
    }];
}

- (BOOL)searchBar:(UISearchBar *)searchBar shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    NSString* newText = [searchBar.text stringByReplacingCharactersInRange:range withString:text];
    [self filterContentForSearchText:newText scope:nil];
    return YES;
}

- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope {
    [_filteredResults removeAllObjects]; // First clear the filtered array.
    NSArray *array;
    if (_draftMode) {
        array = drafts;
    } else {
        array = stories;
    }
    for (Story *story in array){
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF contains[cd] %@", searchText];
        if([predicate evaluateWithObject:story.title]) {
            [_filteredResults addObject:story];
        }
    }
    [self.searchResultsTableView reloadData];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [self endSearch];
}

- (void)endSearch {
    [self.searchBar resignFirstResponder];
    //[self.view endEditing:YES];
    [UIView animateWithDuration:.23 animations:^{
        [self.searchResultsTableView setAlpha:0.0];
        if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
            [self.moreButton setImage:[UIImage imageNamed:@"moreWhite"] forState:UIControlStateNormal];
        } else {
            [self.moreButton setImage:[UIImage imageNamed:@"more"] forState:UIControlStateNormal];
        }
        
        [self.moreButton setTitle:nil forState:UIControlStateNormal];
    } completion:^(BOOL finished) {
        [self.searchResultsTableView setHidden:YES];
        [self.moreButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
        [self.moreButton addTarget:self action:@selector(showGuide) forControlEvents:UIControlEventTouchUpInside];
    }];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if ([touch.view.superview.superview isKindOfClass:[UITableViewCell class]] || [touch.view.superview isKindOfClass:[UITableViewCell class]]) {
        return NO;
    } else {
        return YES;
    }
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    [super prepareForSegue:segue sender:sender];
    if ([segue.identifier isEqualToString:@"Read"]){
        XXStoryViewController *vc = [segue destinationViewController];
        
        if ([sender isKindOfClass:[Story class]]){
            [ProgressHUD show:@"Fetching story..."];
            [vc setStory:(Story*)sender];
        }
        
        [UIView animateWithDuration:.23 animations:^{
            [self.tableView setAlpha:0.0];
            [self.searchBar setAlpha:0.0];
            self.tableView.transform = CGAffineTransformMakeScale(.8, .8);
        }];
    }
}

- (void)saveContext {
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
        NSLog(@"%u success saving portfolio stories.",success);
    }];
}
@end

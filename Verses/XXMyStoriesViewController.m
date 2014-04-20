//
//  XXMyStoriesViewController.m
//  Verses
//
//  Created by Max Haines-Stiles on 3/16/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import "XXMyStoriesViewController.h"
#import "XXStory.h"
#import "XXStoryCell.h"
#import "XXMyStoryCell.h"
#import "XXStoryViewController.h"
#import "XXWriteViewController.h"

@interface XXMyStoriesViewController () {
    NSMutableArray *_stories;
    NSMutableArray *_titles;
    AFHTTPRequestOperationManager *manager;
    UIRefreshControl *refreshControl;
    BOOL loading;
    BOOL canLoadMore;
    NSDateFormatter *_formatter;
    UIColor *textColor;
}

@end

@implementation XXMyStoriesViewController

- (void)viewDidLoad {
    manager = [AFHTTPRequestOperationManager manager];
    [self.tableView setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    [self.view setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    [self loadStories];
    /*refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(handleRefresh) forControlEvents:UIControlEventValueChanged];
    [refreshControl setTintColor:[UIColor darkGrayColor]];
    refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull to refresh"];
    [self.tableView addSubview:refreshControl];*/
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeStory:) name:@"RemoveStory" object:nil];
    _formatter= [[NSDateFormatter alloc] init];
    [_formatter setLocale:[NSLocale currentLocale]];
    [_formatter setDateFormat:@"MMM, d hh:mm a"];
    canLoadMore = YES;
    [self.searchDisplayController.searchBar setPlaceholder:@"Search my stories"];
    [self.searchDisplayController setSearchResultsDelegate:self];
    [self.searchDisplayController setSearchResultsDataSource:self];
    self.searchDisplayController.searchBar.searchBarStyle = UISearchBarStyleMinimal;
    [self.searchDisplayController.searchResultsTableView setSeparatorColor:[UIColor colorWithWhite:1 alpha:.1]];
    //self.tableView.tableHeaderView = self.searchDisplayController.searchBar;
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
    [self loadTitles];
    [super viewDidLoad];
}

- (void)removeStory:(NSNotification*)notification {
    for (XXStory *story in _stories){
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [notification.userInfo objectForKey:@"story_id"]];
        if([predicate evaluateWithObject:story]) {
            [_stories removeObject:story];
            [self.tableView reloadData];
            break;
        }
    }
}

- (void)handleRefresh {
    [ProgressHUD show:@"Refreshing your stories..."];
    [self loadStories];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [[(XXAppDelegate*)[UIApplication sharedApplication].delegate dynamicsDrawerViewController] setPaneDragRevealEnabled:NO forDirection:MSDynamicsDrawerDirectionRight];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
        [self.view setBackgroundColor:[UIColor clearColor]];
        textColor = [UIColor whiteColor];
    } else {
        [self.view setBackgroundColor:[UIColor whiteColor]];
        textColor = [UIColor blackColor];
    }
    if (self.tableView.alpha < 1.0){
        [UIView animateWithDuration:.23 animations:^{
            [self.tableView setAlpha:1.0];
            self.tableView.transform = CGAffineTransformIdentity;
        }];
    }
}

- (void)loadStories {
    loading = YES;
    [manager GET:[NSString stringWithFormat:@"%@/stories/feed",kAPIBaseUrl] parameters:@{@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId],@"count":@"10"} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"success getting my stories: %i",[[responseObject objectForKey:@"stories"] count]);
        _stories = [[Utilities storiesFromJSONArray:[responseObject objectForKey:@"stories"]] mutableCopy];
        loading = NO;
        [self.tableView reloadData];
        if (refreshControl.isRefreshing) [refreshControl endRefreshing];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self.tableView reloadData];
        if (refreshControl.isRefreshing) [refreshControl endRefreshing];
        NSLog(@"Failure getting stories from stories controller: %@",error.description);
    }];
}

- (void)loadTitles {
    loading = YES;
    [manager GET:[NSString stringWithFormat:@"%@/stories/titles",kAPIBaseUrl] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        _titles = [[Utilities storiesFromJSONArray:[responseObject objectForKey:@"titles"]] mutableCopy];
        NSLog(@"success fetching my stories titles: %i count, %@",_titles.count, responseObject);
        //[self.searchDisplayController.searchResultsTableView reloadData];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failure getting search stories titles: %@",error.description);
    }];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat actualPosition = scrollView.contentOffset.y;
    CGFloat contentHeight = scrollView.contentSize.height - (screenHeight());
    if (actualPosition >= contentHeight && !loading && canLoadMore) {
        NSLog(@"should be loading more");
        [self loadMore];
    }

}

- (void)loadMore {
    loading = YES;
    XXStory *lastStory = _stories.lastObject;
    if (lastStory){
        [manager GET:[NSString stringWithFormat:@"%@/stories/feed",kAPIBaseUrl] parameters:@{@"before_date":lastStory.epochTime, @"count":@"10", @"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"more of my stories response: %@",responseObject);
            NSArray *newStories = [Utilities storiesFromJSONArray:[responseObject objectForKey:@"stories"]];
            [_stories addObjectsFromArray:newStories];
            if (newStories.count < 10) {
                canLoadMore = NO;
                NSLog(@"can't load more, we now have %i of my stories", _stories.count);
            }
            [ProgressHUD dismiss];
            loading = NO;
            [self.tableView reloadData];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            
        }];
    } else {
        [self loadStories];
    }
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
    if (_stories.count == 0 && !loading){
        return 1;
    } else {
        return _stories.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_stories.count){
        XXMyStoryCell *cell = (XXMyStoryCell *)[tableView dequeueReusableCellWithIdentifier:@"MyStoryCell"];
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"XXMyStoryCell" owner:nil options:nil] lastObject];
        }
        XXStory *story = [_stories objectAtIndex:indexPath.row];
        [cell configureForStory:story textColor:textColor];
        if (cell.background.alpha == 1.0) [cell swipe];
        [cell.readButton addTarget:self action:@selector(readStory:) forControlEvents:UIControlEventTouchUpInside];
        [cell.readButton setTag:[_stories indexOfObject:story]];
        [cell.writeButton addTarget:self action:@selector(writeStory:) forControlEvents:UIControlEventTouchUpInside];
        [cell.writeButton setTag:[_stories indexOfObject:story]];
        [cell.wordCountLabel setText:[NSString stringWithFormat:@"%@ words  |  Last updated: %@",story.wordCount,[_formatter stringFromDate:story.updatedDate]]];
        return cell;
    } else {
        static NSString *CellIdentifier = @"NothingCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        UIButton *nothingButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [nothingButton setTitle:@"You don't have any stories yet.\nTap here to start writing." forState:UIControlStateNormal];
        [nothingButton addTarget:self action:@selector(startWriting) forControlEvents:UIControlEventTouchUpInside];
        [nothingButton.titleLabel setNumberOfLines:0];
        [nothingButton.titleLabel setFont:[UIFont fontWithName:kSourceSansProLight size:20]];
        [nothingButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
        [nothingButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [nothingButton setBackgroundColor:[UIColor clearColor]];
        [cell addSubview:nothingButton];
        [nothingButton setFrame:CGRectMake(20, 0, screenWidth()-40, screenHeight()-64)];
        cell.backgroundView = [[UIView alloc] initWithFrame:cell.frame];
        [cell.backgroundView setBackgroundColor:[UIColor clearColor]];
        //[self.tableView setScrollEnabled:NO];
        return cell;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (_stories.count && !loading){
        return 170;
    } else {
        return screenHeight()-64;
    }
}

- (void)startWriting {
    UIStoryboard *storyboard;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone){
        storyboard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle:nil];
    } else {
        storyboard = [UIStoryboard storyboardWithName:@"Main_iPad" bundle:nil];
    }
    XXWriteViewController *write = [storyboard instantiateViewControllerWithIdentifier:@"Write"];
    [self presentViewController:write animated:YES completion:^{
        
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
        cell.backgroundColor = [UIColor whiteColor];
    }
}

- (void)readStory:(UIButton*)button {
    XXStory *story = [_stories objectAtIndex:button.tag];
    [self performSegueWithIdentifier:@"Read" sender:story];
}

- (void)writeStory:(UIButton*)button {
    XXStory *story = [_stories objectAtIndex:button.tag];
    UIStoryboard *storyboard;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone){
        storyboard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle:nil];
    } else {
        storyboard = [UIStoryboard storyboardWithName:@"Main_iPad" bundle:nil];
    }
    XXWriteViewController *write = [storyboard instantiateViewControllerWithIdentifier:@"Write"];
    [write setStory:story];
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
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    XXMyStoryCell *selectedCell = (XXMyStoryCell*)[tableView cellForRowAtIndexPath:indexPath];
    [selectedCell swipe];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(XXStory*)story
{
    if ([segue.identifier isEqualToString:@"Read"]){
        XXStoryViewController *vc = [segue destinationViewController];
        [vc setStory:story];
        [vc setStories:[[(XXAppDelegate*)[UIApplication sharedApplication].delegate menuViewController] stories]];
        [UIView animateWithDuration:.23 animations:^{
            [self.tableView setAlpha:0.0];
        }];
    } /*else if ([segue.identifier isEqualToString:@"Write"]) {
        XXWriteViewController *vc = [segue destinationViewController];
        [vc setStory:story];
    }*/
}

@end

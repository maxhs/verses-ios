//
//  XXPortfolioViewController.m
//  Verses
//
//  Created by Max Haines-Stiles on 3/16/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import "XXPortfolioViewController.h"
#import "XXStory.h"
#import "XXStoryCell.h"
#import "XXPortfolioCell.h"
#import "XXSearchCell.h"
#import "XXStoryViewController.h"
#import "XXWriteViewController.h"

@interface XXPortfolioViewController () {
    NSMutableArray *_stories;
    NSMutableArray *_titles;
    NSMutableArray *_filteredResults;
    AFHTTPRequestOperationManager *manager;
    UIRefreshControl *refreshControl;
    BOOL loading;
    BOOL canLoadMore;
    NSDateFormatter *_formatter;
    UIColor *textColor;
    NSMutableArray *_openCells;
}

@end

@implementation XXPortfolioViewController

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
    [_formatter setDateFormat:@"MMM d - h:mm a"];
    canLoadMore = YES;
    [self.searchDisplayController.searchBar setPlaceholder:@"Search my portfolio"];
    self.searchDisplayController.delegate = self;
    [self.searchDisplayController setSearchResultsDelegate:self];
    [self.searchDisplayController setSearchResultsDataSource:self];
    [self.searchDisplayController.searchResultsTableView setSeparatorColor:[UIColor colorWithWhite:1 alpha:.1]];
    self.searchDisplayController.searchBar.searchBarStyle = UISearchBarStyleMinimal;
    _openCells = [NSMutableArray array];
    
    [self loadTitles];
    [super viewDidLoad];
    _filteredResults = [NSMutableArray array];
}

- (void)removeStory:(NSNotification*)notification {
    for (XXStory *story in _stories){
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [notification.userInfo objectForKey:@"story_id"]];
        if([predicate evaluateWithObject:story]) {
            [_stories removeObject:story];
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
            break;
        }
    }
}

- (void)handleRefresh {
    [ProgressHUD show:@"Refreshing your stories..."];
    [self loadStories];
}

- (void)viewWillAppear:(BOOL)animated {
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [[(XXAppDelegate*)[UIApplication sharedApplication].delegate dynamicsDrawerViewController] setPaneDragRevealEnabled:NO forDirection:MSDynamicsDrawerDirectionRight];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
        [self.view setBackgroundColor:[UIColor clearColor]];
        textColor = [UIColor whiteColor];
        [self.searchDisplayController.searchResultsTableView setBackgroundColor:[UIColor colorWithWhite:0.025 alpha:.93]];
        for (id subview in [self.searchDisplayController.searchBar.subviews.firstObject subviews]){
            if ([subview isKindOfClass:[UITextField class]]){
                [(UITextField*)subview setKeyboardAppearance:UIKeyboardAppearanceDark];
                [(UITextField*)subview setFont:[UIFont fontWithName:kSourceSansProRegular size:15]];
                break;
            }
        }
    } else {
        for (id subview in [self.searchDisplayController.searchBar.subviews.firstObject subviews]){
            if ([subview isKindOfClass:[UITextField class]]){
                [(UITextField*)subview setTextColor:[UIColor blackColor]];
                [(UITextField*)subview setFont:[UIFont fontWithName:kSourceSansProRegular size:15]];
                [(UITextField*)subview setKeyboardAppearance:UIKeyboardAppearanceDefault];
            } else if ([subview isKindOfClass:[UIButton class]]){
                [(UIButton*)subview setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            }
        }
        [self.view setBackgroundColor:[UIColor whiteColor]];
        textColor = [UIColor blackColor];
    }
    
    //transition
    if (self.tableView.alpha != 1.0){
        [UIView animateWithDuration:.23 animations:^{
            [self.tableView setAlpha:1.0];
            [self.searchDisplayController.searchBar setAlpha:1.0];
            self.tableView.transform = CGAffineTransformIdentity;
        }];
        [self.tableView reloadData];
    }
    
    [super viewWillAppear:animated];
}

- (void)loadStories {
    loading = YES;
    [manager GET:[NSString stringWithFormat:@"%@/stories/feed",kAPIBaseUrl] parameters:@{@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId],@"count":@"10"} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"success getting my stories: %@",[responseObject objectForKey:@"stories"]);
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
    [manager GET:[NSString stringWithFormat:@"%@/stories/feed_titles",kAPIBaseUrl] parameters:@{@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        _titles = [[Utilities storiesFromJSONArray:[responseObject objectForKey:@"titles"]] mutableCopy];
        //NSLog(@"success fetching my stories titles: %i count, %@",_titles.count, responseObject);
        //[self.searchDisplayController.searchResultsTableView reloadData];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failure getting search stories titles: %@",error.description);
    }];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat actualPosition = scrollView.contentOffset.y;
    CGFloat contentHeight = scrollView.contentSize.height - (screenHeight()*2);
    if (actualPosition >= contentHeight && !loading && canLoadMore) {
        NSLog(@"should be loading more of my stories");
        [self loadMore];
    }

}

- (void)loadMore {
    loading = YES;
    XXStory *lastStory = _stories.lastObject;
    if (lastStory){
        [manager GET:[NSString stringWithFormat:@"%@/stories/feed",kAPIBaseUrl] parameters:@{@"before_date":lastStory.epochTime, @"count":@"10", @"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
            //NSLog(@"more of my stories response: %@",responseObject);
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
    if (tableView == self.searchDisplayController.searchResultsTableView){
        return _filteredResults.count;
    } else {
        if (_stories.count == 0 && !loading){
            return 1;
        } else {
            return _stories.count;
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.searchDisplayController.searchResultsTableView){
        XXSearchCell *cell = (XXSearchCell *)[tableView dequeueReusableCellWithIdentifier:@"SearchCell"];
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"XXSearchCell" owner:nil options:nil] lastObject];
        }
        XXStory *story = [_filteredResults objectAtIndex:indexPath.row];
        [cell configure:story];
        [cell.storyTitle setTextColor:textColor];
        [cell.authorLabel setTextColor:textColor];
        return cell;
    } else {
        if (_stories.count){
            XXPortfolioCell *cell = (XXPortfolioCell *)[tableView dequeueReusableCellWithIdentifier:@"PortfolioCell"];
            if (cell == nil) {
                cell = [[[NSBundle mainBundle] loadNibNamed:@"XXPortfolioCell" owner:nil options:nil] lastObject];
            }
            XXStory *story = [_stories objectAtIndex:indexPath.row];
            [cell configureForStory:story textColor:textColor];
            if (cell.background.alpha == 1.0) [self swipeCell:cell];
            [cell.readButton addTarget:self action:@selector(readStory:) forControlEvents:UIControlEventTouchUpInside];
            [cell.readButton setTag:[_stories indexOfObject:story]];
            [cell.editButton addTarget:self action:@selector(editStory:) forControlEvents:UIControlEventTouchUpInside];
            [cell.editButton setTag:[_stories indexOfObject:story]];
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
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.searchDisplayController.searchResultsTableView){
        return 60;
    } else {
        if (_stories.count && !loading){
            if (IDIOM == IPAD) {
                return screenHeight()/3;
            } else {
                return screenHeight()/2;
            }
        } else {
            return screenHeight()-64;
        }
    }
}

- (void)startWriting {
    XXWriteViewController *write = [[self storyboard] instantiateViewControllerWithIdentifier:@"Write"];
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
        cell.backgroundColor = [UIColor whiteColor];
    }
}

- (void)readStory:(UIButton*)button {
    XXStory *story = [_stories objectAtIndex:button.tag];

    if (story.wordCount.intValue > 2000){
        [ProgressHUD show:@"Fetching story..."];
    }
    [self performSegueWithIdentifier:@"Read" sender:story];
}

- (void)editStory:(UIButton*)button {
    Story *story = [_stories objectAtIndex:button.tag];
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
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        XXStory *story = [_filteredResults objectAtIndex:indexPath.row];
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
        
        NSLog(@"should be seguing to story");
        [UIView animateWithDuration:.23 animations:^{
            [self.tableView setAlpha:0.0];
            [self.searchDisplayController.searchBar setAlpha:0.0];
            self.tableView.transform = CGAffineTransformMakeScale(.8, .8);
        }];
    }
}

- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope {
    [_filteredResults removeAllObjects]; // First clear the filtered array.
    for (XXStory *story in _titles){
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF contains[cd] %@", searchText];
        if([predicate evaluateWithObject:story.title]) {
            [_filteredResults addObject:story];
        }
    }
}

-(BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
    [self filterContentForSearchText:searchString scope:nil];
    return YES;
}

@end

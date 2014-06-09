//
//  XXGuideViewController.m
//  Verses
//
//  Created by Max Haines-Stiles on 6/5/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import "XXGuideViewController.h"
#import "XXGuideCell.h"
#import "XXWriteViewController.h"
#import "XXSearchCell.h"
#import "XXPortfolioViewController.h"
#import "XXAlert.h"
#import "XXLoginController.h"
#import "XXStoryViewController.h"
#import "XXGalleryViewController.h"

@interface XXGuideViewController () <UISearchBarDelegate> {
    UIButton *dismissButton;
    NSAttributedString *searchPlaceholder;
    BOOL searching;
    NSMutableArray *_filteredResults;
    NSMutableArray *_searchResults;
    AFHTTPRequestOperationManager *manager;
    UIView *headerView;
    CGRect headerRect;
    XXStoriesViewController *stories;
}

@end

@implementation XXGuideViewController

- (void)viewDidLoad {
    dismissButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.view addSubview:dismissButton];
    if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)){
        [dismissButton setFrame:CGRectMake(screenWidth()-44, screenHeight()-44, 44, 44)];
    } else {
        [dismissButton setFrame:CGRectMake(screenHeight()-44, screenWidth()-44, 44, 44)];
    }
    
    //dismissButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [dismissButton setImage:[UIImage imageNamed:@"whiteX"] forState:UIControlStateNormal];
    [dismissButton addTarget:self action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
    self.automaticallyAdjustsScrollViewInsets = NO;
    [self.view setBackgroundColor:[UIColor blackColor]];
    [self.tableView setBackgroundColor:[UIColor clearColor]];
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    [super viewDidLoad];
    manager = [(XXAppDelegate*)[UIApplication sharedApplication].delegate manager];
    [self.view setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    UIImageView *backgroundImageView = [[UIImageView alloc] initWithFrame:self.view.frame];
    [backgroundImageView setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    [backgroundImageView setContentMode:UIViewContentModeScaleAspectFill];
    [backgroundImageView setImage:[(XXAppDelegate*)[UIApplication sharedApplication].delegate windowBackground].image];
    backgroundImageView.clipsToBounds = YES;
    _filteredResults = [NSMutableArray array];
    _searchResults = [NSMutableArray array];
    
    self.tableView.rowHeight = screenHeight()/5;
    self.searchResultsTableView.rowHeight = 60.f;
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
        [backgroundImageView setAlpha:.43];
    } else {
        [backgroundImageView setAlpha:.87];
    }
    
    [self.view addSubview:backgroundImageView];
    [self.view sendSubviewToBack:backgroundImageView];
    [self.searchBar setImage:[UIImage imageNamed:@"whiteSearchIcon"] forSearchBarIcon:UISearchBarIconSearch state:UIControlStateNormal];
    
    searchPlaceholder = [[NSAttributedString alloc] initWithString:@"Search stories" attributes:@{ NSForegroundColorAttributeName : [UIColor whiteColor] }];
    for (id subview in [self.searchBar.subviews.firstObject subviews]){
        [subview setTintColor:[UIColor whiteColor]];
        if ([subview isKindOfClass:[UITextField class]]){
            UITextField *searchTextField = (UITextField*)subview;
            [searchTextField setKeyboardAppearance:UIKeyboardAppearanceDark];
            [searchTextField setBackgroundColor:[UIColor clearColor]];
            searchTextField.layer.borderColor = [UIColor colorWithWhite:1 alpha:.9].CGColor;
            searchTextField.layer.borderWidth = 1.f;
            searchTextField.layer.cornerRadius = 14.f;
            searchTextField.clipsToBounds = YES;
            searchTextField.attributedPlaceholder = searchPlaceholder;
            [searchTextField setFont:[UIFont fontWithName:kSourceSansProRegular size:16]];
            break;
        }
    }
    headerRect = CGRectMake(0, screenHeight()/5, screenWidth(), screenHeight()/5);
    headerView = [[UIView alloc] initWithFrame:headerRect];
    [headerView addSubview:self.searchBar];
    [self.searchBar setFrame:CGRectMake(0, 0, screenWidth(), 44)];
    self.tableView.tableHeaderView = headerView;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, screenHeight()/5, screenWidth(), screenHeight()/5)];
    
    [self.searchResultsTableView setBackgroundColor:[UIColor colorWithWhite:0 alpha:.67]];
    [self.searchResultsTableView setAlpha:0.0];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(willShowKeyboard:)
                                                 name:UIKeyboardWillShowNotification object:nil];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    if (UIInterfaceOrientationIsPortrait(toInterfaceOrientation)){
        NSLog(@"portrait");
        //[self.view setFrame:CGRectMake(0, 0, screenWidth(), screenHeight())];
    } else {
        NSLog(@"landscape");
        //[self.view setFrame:CGRectMake(0, 0, screenHeight(), screenWidth())];
    }
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    searching = YES;
    [self.searchBar setShowsCancelButton:YES animated:YES];
    
    [UIView animateWithDuration:.33 animations:^{
        [self.searchResultsTableView setAlpha:1.0];
    }];
    
    if (!_searchResults.count && !self.searchBar.text.length){
        [manager GET:[NSString stringWithFormat:@"%@/stories/titles",kAPIBaseUrl] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
            //NSLog(@"success fetching titles from guide view: %@",responseObject);
            _searchResults = [[Utilities storiesFromJSONArray:[responseObject objectForKey:@"titles"]] mutableCopy];
            [_filteredResults removeAllObjects];
            [_filteredResults addObjectsFromArray:_searchResults];
            [self.searchResultsTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            //NSLog(@"Failure getting search stories titles: %@",error.description);
        }];
        [self.searchResultsTableView reloadData];
    }
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    searching = NO;
    [self.searchBar setText:@""];
    [self.searchBar setShowsCancelButton:NO animated:YES];
    [self.view endEditing:YES];
    [UIView animateWithDuration:.33 animations:^{
        [self.searchResultsTableView setAlpha:0.0];
    }];
    
}

- (BOOL)searchBar:(UISearchBar *)searchBar shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    NSString* newText = [searchBar.text stringByReplacingCharactersInRange:range withString:text];
    [self filterContentForSearchText:newText scope:nil];
    return YES;
}

- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope {
    [_filteredResults removeAllObjects]; // First clear the filtered array.
    for (XXStory *story in _searchResults){
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF contains[cd] %@", searchText];
        if([predicate evaluateWithObject:story.title]) {
            [_filteredResults addObject:story];
        }
    }
    [self.searchResultsTableView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (scrollView == self.tableView && scrollView.contentOffset.y > 60.f && UIInterfaceOrientationIsPortrait(self.interfaceOrientation)){
        [self dismiss];
    }
}

-(void)willShowKeyboard:(NSNotification*)notification {
    NSDictionary* keyboardInfo = [notification userInfo];
    NSValue* keyboardFrameBegin = [keyboardInfo valueForKey:UIKeyboardFrameBeginUserInfoKey];
    CGFloat keyboardHeight = [keyboardFrameBegin CGRectValue].size.height;
    self.searchResultsTableView.contentInset = UIEdgeInsetsMake(0, 0, keyboardHeight, 0);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (searching){
        if (_filteredResults.count){
            return _filteredResults.count;
        } else if (self.searchBar.text) {
            return 1;
        } else {
            return 0;
        }
    } else {
        return 3;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (searching && tableView == self.searchResultsTableView){
        if (_filteredResults.count){
            XXSearchCell *cell = (XXSearchCell *)[tableView dequeueReusableCellWithIdentifier:@"SearchCell"];
            if (cell == nil) {
                cell = [[[NSBundle mainBundle] loadNibNamed:@"XXSearchCell" owner:nil options:nil] lastObject];
            }
            XXStory *story;
            if (searching){
                story = [_filteredResults objectAtIndex:indexPath.row];
            } else {
                story = [_searchResults objectAtIndex:indexPath.row];
            }
            
            [cell configure:story];
            return cell;
        } else {
            XXSearchCell *cell = (XXSearchCell *)[tableView dequeueReusableCellWithIdentifier:@"SearchCell"];
            if (cell == nil) {
                cell = [[[NSBundle mainBundle] loadNibNamed:@"XXSearchCell" owner:nil options:nil] lastObject];
            }
            [cell.storyTitle setText:@"No results."];
            [cell.authorLabel setText:@""];
            //[cell.authorLabel setText:@"Tap to search again..."];
            [cell.authorLabel setFont:[UIFont fontWithName:kSourceSansProItalic size:15]];
            return cell;
        }
    } else {
        XXGuideCell *cell = (XXGuideCell *)[tableView dequeueReusableCellWithIdentifier:@"GuideCell"];
        if (cell == nil) {
            if (IDIOM == IPAD){
                cell = [[[NSBundle mainBundle] loadNibNamed:@"XXGuideCell_ipad" owner:nil options:nil] lastObject];
            } else {
                cell = [[[NSBundle mainBundle] loadNibNamed:@"XXGuideCell" owner:nil options:nil] lastObject];
            }
            
        }
        if (indexPath.row == 0){
            [cell.topSeparator setHidden:NO];
        } else {
            [cell.topSeparator setHidden:YES];
        }
        [cell configureWidth:screenWidth()];
        cell.scrollView.scrollEnabled = YES;
        CGFloat buttonWidth = cell.firstButton.frame.size.width;
        switch (indexPath.row) {
            case 0:
                [cell.firstButton setTitle:@"BROWSE" forState:UIControlStateNormal];
                [cell.firstButton addTarget:self action:@selector(goBrowse) forControlEvents:UIControlEventTouchUpInside];
                [cell.secondButton setTitle:@"FEATURED" forState:UIControlStateNormal];
                [cell.secondButton addTarget:self action:@selector(goFeatured) forControlEvents:UIControlEventTouchUpInside];
                [cell.thirdButton setTitle:@"TRENDING" forState:UIControlStateNormal];
                [cell.thirdButton addTarget:self action:@selector(goTrending) forControlEvents:UIControlEventTouchUpInside];
                [cell.scrollView setContentSize:CGSizeMake(buttonWidth*3, 0)];
                break;
            case 1:
                [cell.firstButton setTitle:@"WRITE" forState:UIControlStateNormal];
                [cell.firstButton addTarget:self action:@selector(goWrite) forControlEvents:UIControlEventTouchUpInside];
                [cell.secondButton setTitle:@"SLOW REVEAL" forState:UIControlStateNormal];
                [cell.secondButton addTarget:self action:@selector(goSlowReveal) forControlEvents:UIControlEventTouchUpInside];
                [cell.scrollView setContentSize:CGSizeMake(buttonWidth*2, 0)];
                break;
            case 2:
                if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
                    [cell.firstButton setTitle:@"PORTFOLIO" forState:UIControlStateNormal];
                    [cell.firstButton addTarget:self action:@selector(goToPortfolio) forControlEvents:UIControlEventTouchUpInside];
                    [cell.secondButton setTitle:@"SHARED WITH ME" forState:UIControlStateNormal];
                    [cell.secondButton addTarget:self action:@selector(goShared) forControlEvents:UIControlEventTouchUpInside];
                    [cell.thirdButton setTitle:@"PHOTO GALLERY" forState:UIControlStateNormal];
                    [cell.thirdButton addTarget:self action:@selector(goGallery) forControlEvents:UIControlEventTouchUpInside];
                    cell.scrollView.scrollEnabled = YES;
                    [cell.scrollView setContentSize:CGSizeMake(buttonWidth*3, 0)];
                } else {
                    [cell.firstButton setTitle:@"PORTFOLIO" forState:UIControlStateNormal];
                    [cell.firstButton addTarget:self action:@selector(login) forControlEvents:UIControlEventTouchUpInside];
                    cell.scrollView.scrollEnabled = NO;
                }
                
                break;
                
            default:
                break;
        }
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor clearColor];
    UIView *selectionView = [[UIView alloc] initWithFrame:cell.frame];
    [selectionView setBackgroundColor:[UIColor clearColor]];
    cell.selectedBackgroundView = selectionView;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (tableView == self.searchResultsTableView && _filteredResults.count){
        XXStory *story = [_filteredResults objectAtIndex:indexPath.row];
        XXStoryViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Story"];
        [vc setStoryId:story.identifier];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        [[(XXAppDelegate*)[UIApplication sharedApplication].delegate dynamicsDrawerViewController] setPaneViewController:nav];
        [self dismissViewControllerAnimated:YES completion:^{
            
        }];
    }
}

- (void)goBrowse {
    [self setStoriesAsPane];
    stories.ether = YES;
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)goFeatured {
    [self setStoriesAsPane];
    stories.featured = YES;
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)goTrending {
    [self setStoriesAsPane];
    stories.trending = YES;
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)goShared {
    [self setStoriesAsPane];
    stories.shared = YES;
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)goGallery {
    XXGalleryViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Gallery"];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    [[(XXAppDelegate*)[UIApplication sharedApplication].delegate dynamicsDrawerViewController] setPaneViewController:nav];
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)setStoriesAsPane {
    stories = [[self storyboard] instantiateViewControllerWithIdentifier:@"Stories"];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:stories];
    [[(XXAppDelegate*)[UIApplication sharedApplication].delegate dynamicsDrawerViewController] setPaneViewController:nav];
}

- (void)goWrite {
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
        XXWriteViewController *write = [[self storyboard] instantiateViewControllerWithIdentifier:@"Write"];
        write.mystery = NO;
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:write];
        [[(XXAppDelegate*)[UIApplication sharedApplication].delegate dynamicsDrawerViewController] setPaneViewController:nav];
        [self dismissViewControllerAnimated:YES completion:^{
            
        }];
    } else {
        [self login];
    }
    
}
- (void)goSlowReveal {
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
        XXWriteViewController *write = [[self storyboard] instantiateViewControllerWithIdentifier:@"Write"];
        write.mystery = YES;
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:write];
        [[(XXAppDelegate*)[UIApplication sharedApplication].delegate dynamicsDrawerViewController] setPaneViewController:nav];
        [self dismissViewControllerAnimated:YES completion:^{
            [XXAlert show:@"Participants will only see the last 250 characters of each contribution." withTime:3.3f];
        }];
    } else {
        [self login];
    }
}

- (void)login {
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    XXLoginController *login = [[self storyboard] instantiateViewControllerWithIdentifier:@"Login"];
    [self presentViewController:login animated:YES completion:^{
        
    }];
}

- (void)goToPortfolio {
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    XXPortfolioViewController *portfolio = [[self storyboard] instantiateViewControllerWithIdentifier:@"Portfolio"];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:portfolio];
    [[(XXAppDelegate*)[UIApplication sharedApplication].delegate dynamicsDrawerViewController] setPaneViewController:nav];
    [self dismissViewControllerAnimated:YES completion:^{
    
    }];
}


- (void)dismiss {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end

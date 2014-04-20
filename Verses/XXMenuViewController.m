//
//  XXMenuViewController.m
//  Verses
//
//  Created by Max Haines-Stiles on 11/3/13.
//  Copyright (c) 2013 Verses. All rights reserved.
//

#import "XXMenuViewController.h"
#import "XXLoginController.h"
#import "SWRevealViewController/SWRevealViewController.h"
#import "XXUserNameCell.h"
#import "User.h"
#import "XXStoriesViewController.h"
#import "XXStoryViewController.h"
#import "XXSettingsViewController.h"
#import "XXNotificationCell.h"
#import "XXDraftsViewController.h"
#import "XXMyStoriesViewController.h"
#import "XXCirclesViewController.h"
#import "XXWelcomeViewController.h"
#import "XXFeedbackViewController.h"
#import "XXWriteViewController.h"
#import "XXMenuCell.h"
#import "XXSearchCell.h"
#import "XXBookmarksViewController.h"
#import "XXStoriesViewController.h"

@interface XXMenuViewController () <UIAlertViewDelegate,UISearchDisplayDelegate,UISearchBarDelegate> {
    AFHTTPRequestOperationManager *manager;
    BOOL loggedIn;
    User *savedUser;
    NSMutableArray *notifications;
    CGRect screen;
    NSIndexPath *indexPathForDeletion;
    UIStoryboard *storyboard;
    NSMutableArray *_searchResults;
    NSMutableArray *_filteredResults;
    CGRect searchRect;
    BOOL searching;
    NSDateFormatter *_monthFormatter;
    NSDateFormatter *_timeFormatter;
    UIButton *_loginButton;
    NSInteger _circleAlertCount;
}

@end

@implementation XXMenuViewController
@synthesize stories = _stories;
- (void)viewDidLoad
{
    if (!manager) {
        manager = [AFHTTPRequestOperationManager manager];
        manager.requestSerializer = [AFJSONRequestSerializer serializer];
    }
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    [self.view setBackgroundColor:[UIColor clearColor]];
    _filteredResults = [NSMutableArray array];
    notifications = [NSMutableArray array];
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.separatorColor = [UIColor colorWithWhite:1.0 alpha:0.05];
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginSuccessful) name:@"LoginSuccessful" object:nil];
    screen = [UIScreen mainScreen].bounds;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone){
        storyboard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle:nil];
    } else {
        storyboard = [UIStoryboard storyboardWithName:@"Main_iPad" bundle:nil];
    }
    searching = NO;
    [self.searchBar setPlaceholder:@"Search stories"];
    self.searchBar.searchBarStyle = UISearchBarStyleMinimal;
    _monthFormatter = [[NSDateFormatter alloc] init];
    [_monthFormatter setLocale:[NSLocale currentLocale]];
    [_monthFormatter setDateFormat:@"MMM, d"];
    _timeFormatter = [[NSDateFormatter alloc] init];
    [_timeFormatter setLocale:[NSLocale currentLocale]];
    [_timeFormatter setDateFormat:@"hh:mm a"];
}

- (void)viewWillAppear:(BOOL)animated {
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"MenuRevealed" object:nil];
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]) {
        savedUser = [User MR_findFirstByAttribute:@"identifier" withValue:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]];
        loggedIn = YES;
        self.tableView.scrollEnabled = YES;
        [self loadNotifications];
        self.tableView.rowHeight = 56;
    } else {
        savedUser = nil;
        self.tableView.rowHeight = screen.size.height;
        self.tableView.scrollEnabled = NO;
        loggedIn = NO;
        [self.tableView reloadData];
    }
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
        [self.searchDisplayController.searchResultsTableView setBackgroundColor:[UIColor colorWithWhite:0 alpha:.77]];

    } else {
        
        [self.searchDisplayController.searchResultsTableView setBackgroundColor:[UIColor clearColor]];
        [self.searchDisplayController.searchResultsTableView setBackgroundView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"blue"]]];
    }
    
    if (self.tableView.alpha < 1.0){
        [UIView animateWithDuration:.25 animations:^{
            [self.tableView setAlpha:1.0];
        }];
    }
    [self loadCirclesAlert];
    if (!searching)[super viewWillAppear:animated];
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
}

- (void)loadCirclesAlert {
    [manager GET:[NSString stringWithFormat:@"%@/circles/alert",kAPIBaseUrl] parameters:@{@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"circle alert response: %@",responseObject);
        _circleAlertCount = [[responseObject objectForKeyedSubscript:@"count"] integerValue];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failure getting circle alerts: %@",error.description);
    }];
}

- (void)loadNotifications {
    [manager.requestSerializer setValue:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsAuthToken] forHTTPHeaderField:@"Authorization"];
    [manager GET:[NSString stringWithFormat:@"%@/notifications",kAPIBaseUrl] parameters:@{@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"success fetching user notifications: %@",responseObject);
        notifications = [[Utilities notificationsFromJSONArray:[responseObject objectForKey:@"notifications"]] mutableCopy];
        [self.tableView reloadData];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failure getting user notifications: %@",error.description);
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (searching){
        return 1;
    } else if (loggedIn) {
        [self.searchDisplayController.searchBar setHidden:NO];
        CGRect rect = self.tableView.frame;
        rect.origin.y = 44;
        [self.tableView setFrame:rect];
        return 2;
    } else {
        [self.searchDisplayController.searchBar setHidden:YES];
        CGRect rect = self.tableView.frame;
        rect.origin.y = 0;
        [self.tableView setFrame:rect];
        return 1;
    }
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
       
    } else if (loggedIn) {
        if (section == 0){
            return 6;
        } else {
            return notifications.count;
        }
    } else {
        return 1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (searching){
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
            [cell.authorLabel setText:@"Tap to search again..."];
            [cell.authorLabel setFont:[UIFont fontWithName:kSourceSansProItalic size:15]];
            return cell;
        }
    } else if (loggedIn){
        if (indexPath.section == 0){
            static NSString *NameCellIdentifier = @"MenuCell";
            XXMenuCell *cell = (XXMenuCell *)[tableView dequeueReusableCellWithIdentifier:NameCellIdentifier];
            if (cell == nil) {
                cell = [[[NSBundle mainBundle] loadNibNamed:@"XXMenuCell" owner:nil options:nil] lastObject];
            }
            [cell.firstButton.titleLabel setFont:[UIFont fontWithName:kSourceSansProSemibold size:18]];
            if (indexPath.row == 3) [cell configureAlert:_circleAlertCount];
            else [cell configureAlert:0];
            UIView *selectedBackgroundView = [[UIView alloc] initWithFrame:cell.frame];
            [selectedBackgroundView setBackgroundColor:[UIColor colorWithWhite:1 alpha:.5]];
            cell.selectedBackgroundView = selectedBackgroundView;
            
            switch (indexPath.row) {
                case 0:
                {
                    [cell.firstButton setTitle:@"Browse" forState:UIControlStateNormal];
                    [cell.firstButton addTarget:self action:@selector(goHome) forControlEvents:UIControlEventTouchUpInside];
                    return cell;
                }
                    break;
                case 1:
                {
                    [cell.firstButton setTitle:@"Write" forState:UIControlStateNormal];
                    [cell.firstButton addTarget:self action:@selector(goWrite) forControlEvents:UIControlEventTouchUpInside];
                    return cell;
                }
                    break;
                case 2:
                {
                    [cell.firstButton setTitle:@"My Stories" forState:UIControlStateNormal];
                    [cell.firstButton addTarget:self action:@selector(goToMyStories) forControlEvents:UIControlEventTouchUpInside];
                    return cell;
                }
                    break;
                case 3:
                {
                    [cell.firstButton setTitle:@"Writing Circles" forState:UIControlStateNormal];
                    [cell.firstButton addTarget:self action:@selector(goToCircles) forControlEvents:UIControlEventTouchUpInside];
                    return cell;
                }
                    break;
                case 4:
                {
                    [cell.firstButton setTitle:@"Bookmarks" forState:UIControlStateNormal];
                    [cell.firstButton addTarget:self action:@selector(goToBookmarks) forControlEvents:UIControlEventTouchUpInside];
                    return cell;
                }
                    break;
                case 5:
                {
                    [cell.firstButton setTitle:@"Settings" forState:UIControlStateNormal];
                    [cell.firstButton addTarget:self action:@selector(goToSettings) forControlEvents:UIControlEventTouchUpInside];
                    return cell;
                }
                    break;
                default:
                    return nil;
                    break;
            }
        } else {
            XXNotificationCell *cell = (XXNotificationCell *)[tableView dequeueReusableCellWithIdentifier:@"NotificationCell"];
            if (cell == nil) {
                cell = [[[NSBundle mainBundle] loadNibNamed:@"XXNotificationCell" owner:nil options:nil] lastObject];
            }
            XXNotification *notification = [notifications objectAtIndex:indexPath.row];
            [cell configureCell:notification];
            [cell.monthLabel setText:[_monthFormatter stringFromDate:notification.createdAt]];
            [cell.timeLabel setText:[_timeFormatter stringFromDate:notification.createdAt]];
            return cell;
        }
        
    } else {
        static NSString *CellIdentifier = @"WelcomeCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        if (!_loginButton){
            _loginButton = [UIButton buttonWithType:UIButtonTypeCustom];
            [_loginButton setTitle:@"Log in, have fun" forState:UIControlStateNormal];
            [_loginButton.titleLabel setFont:[UIFont fontWithName:kSourceSansProLight size:27]];
            [_loginButton.titleLabel setTextColor:[UIColor whiteColor]];
            [_loginButton addTarget:self action:@selector(login) forControlEvents:UIControlEventTouchUpInside];
            [_loginButton setBackgroundColor:[UIColor clearColor]];
            [cell addSubview:_loginButton];
        }
        [_loginButton setFrame:CGRectMake(0, 0, self.tableView.frame.size.width, self.tableView.frame.size.height)];
        [_loginButton setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
        [_loginButton setAutoresizingMask:UIViewAutoresizingFlexibleHeight];
        [_loginButton setAutoresizingMask:UIViewAutoresizingFlexibleRightMargin];
        [_loginButton setAutoresizingMask:UIViewAutoresizingFlexibleBottomMargin];
        cell.backgroundView = [[UIView alloc] initWithFrame:cell.frame];
        [cell.backgroundView setBackgroundColor:[UIColor clearColor]];
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor clearColor];
    UIView *selectedView = [[UIView alloc] initWithFrame:cell.frame];
    [selectedView setBackgroundColor:[UIColor colorWithWhite:1 alpha:.5]];
    cell.selectedBackgroundView = selectedView;
}

- (void)login {
    [self performSegueWithIdentifier:@"Login" sender:nil];
}

- (void)loginSuccessful {
    NSLog(@"Login successful from Menu");
    [self.revealViewController setFrontViewPosition:FrontViewPositionLeft animated:YES];
}

- (void)goHome {
    if ([[(UINavigationController*)self.dynamicsDrawerViewController.paneViewController viewControllers].lastObject isKindOfClass:[XXWelcomeViewController class]]){
        [self.dynamicsDrawerViewController setPaneState:MSDynamicsDrawerPaneStateClosed inDirection:MSDynamicsDrawerDirectionLeft animated:YES allowUserInterruption:YES completion:nil];
    } else {
        [ProgressHUD show:@"Fetching the latest..."];
        XXWelcomeViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"Welcome"];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        [self.dynamicsDrawerViewController setPaneViewController:nav animated:YES completion:^{
            if (_stories.count){
                [vc setStories:_stories];
            } else {
                [vc loadEtherStories];
            }
        }];
    }
}
- (void)goToSettings {
    if ([[(UINavigationController*)self.dynamicsDrawerViewController.paneViewController viewControllers].lastObject isKindOfClass:[XXSettingsViewController class]]){
        [self.dynamicsDrawerViewController setPaneState:MSDynamicsDrawerPaneStateClosed inDirection:MSDynamicsDrawerDirectionLeft animated:YES allowUserInterruption:YES completion:nil];
    } else {
        [ProgressHUD show:@"Getting settings..."];
        XXSettingsViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"Settings"];
        [vc setTitle:@"Settings"];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        [self.dynamicsDrawerViewController setPaneViewController:nav animated:YES completion:^{
            [vc setDynamicsDrawerViewController:self.dynamicsDrawerViewController];
        }];
    }
}
- (void)goToFeatured {
    if ([[(UINavigationController*)self.dynamicsDrawerViewController.paneViewController viewControllers].lastObject isKindOfClass:[XXStoriesViewController class]]){
        [self.dynamicsDrawerViewController setPaneState:MSDynamicsDrawerPaneStateClosed inDirection:MSDynamicsDrawerDirectionLeft animated:YES allowUserInterruption:YES completion:nil];
    } else {
        [ProgressHUD show:@"Fetching what's featured..."];
        XXStoriesViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"Stories"];
        [vc setFeatured:YES];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        [self.dynamicsDrawerViewController setPaneViewController:nav animated:YES completion:nil];
    }
}
- (void)goToMyStories {
    if ([[(UINavigationController*)self.dynamicsDrawerViewController.paneViewController viewControllers].lastObject isKindOfClass:[XXMyStoriesViewController class]]){
        [self.dynamicsDrawerViewController setPaneState:MSDynamicsDrawerPaneStateClosed inDirection:MSDynamicsDrawerDirectionLeft animated:YES allowUserInterruption:YES completion:nil];
    } else {
        [ProgressHUD show:@"Grabbing your stories..."];
        XXMyStoriesViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"My Stories"];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        [self.dynamicsDrawerViewController setPaneViewController:nav animated:YES completion:nil];
    }
}
- (void)goWrite {
    if ([[(UINavigationController*)self.dynamicsDrawerViewController.paneViewController viewControllers].lastObject isKindOfClass:[XXWriteViewController class]]){
        XXWriteViewController *writeVc = [(UINavigationController*)self.dynamicsDrawerViewController.paneViewController viewControllers].lastObject;
        [writeVc setStory:nil];
        [writeVc prepareStory];
        [self.dynamicsDrawerViewController setPaneState:MSDynamicsDrawerPaneStateClosed inDirection:MSDynamicsDrawerDirectionLeft animated:YES allowUserInterruption:YES completion:^{
            
        }];
    } else {
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
        XXWriteViewController *write = [storyboard instantiateViewControllerWithIdentifier:@"Write"];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:write];
        [self presentViewController:nav animated:YES completion:^{
            //[self.dynamicsDrawerViewController setPaneState:MSDynamicsDrawerPaneStateClosed];
        }];
        
        if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
            [UIView animateWithDuration:.3 animations:^{
                [self.dynamicsDrawerViewController.paneViewController.view setAlpha:0.0];
                [self.tableView setAlpha:0.0];
            }];
        }
    }
}

- (void)goToDrafts {
    if ([[(UINavigationController*)self.dynamicsDrawerViewController.paneViewController viewControllers].lastObject isKindOfClass:[XXDraftsViewController class]]){
        [self.dynamicsDrawerViewController setPaneState:MSDynamicsDrawerPaneStateClosed inDirection:MSDynamicsDrawerDirectionLeft animated:YES allowUserInterruption:YES completion:nil];
    } else {
        [ProgressHUD show:@"Drying off your drafts..."];
        XXDraftsViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"Drafts"];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        [self.dynamicsDrawerViewController setPaneDragRevealEnabled:NO forDirection:MSDynamicsDrawerDirectionRight];
        [self.dynamicsDrawerViewController setPaneViewController:nav animated:YES completion:nil];
    }
}
- (void)goToCircles {
    if ([[(UINavigationController*)self.dynamicsDrawerViewController.paneViewController viewControllers].lastObject isKindOfClass:[XXCirclesViewController class]]){
        XXCirclesViewController *vc = [(UINavigationController*)self.dynamicsDrawerViewController.paneViewController viewControllers].lastObject;
        [vc loadCircles];
        [self.dynamicsDrawerViewController setPaneState:MSDynamicsDrawerPaneStateClosed inDirection:MSDynamicsDrawerDirectionLeft animated:YES allowUserInterruption:YES completion:nil];
    } else {
        [ProgressHUD show:@"Gathering your circles..."];
        XXCirclesViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"Circles"];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        [self.dynamicsDrawerViewController setPaneViewController:nav animated:YES completion:nil];
    }
}
- (void)goToFeedback {
    if ([[(UINavigationController*)self.dynamicsDrawerViewController.paneViewController viewControllers].lastObject isKindOfClass:[XXFeedbackViewController class]]){
        [self.dynamicsDrawerViewController setPaneState:MSDynamicsDrawerPaneStateClosed inDirection:MSDynamicsDrawerDirectionLeft animated:YES allowUserInterruption:YES completion:nil];
    } else {
        [ProgressHUD show:@"Fetching your feedback..."];
        XXFeedbackViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"Feedback"];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        [self.dynamicsDrawerViewController setPaneViewController:nav animated:YES completion:nil];
    }
}
- (void)goToBookmarks {
    if ([[(UINavigationController*)self.dynamicsDrawerViewController.paneViewController viewControllers].lastObject isKindOfClass:[XXBookmarksViewController class]]){
        [self.dynamicsDrawerViewController setPaneState:MSDynamicsDrawerPaneStateClosed inDirection:MSDynamicsDrawerDirectionLeft animated:YES allowUserInterruption:YES completion:nil];
    } else {
        [ProgressHUD show:@"Grabbing your bookmarks..."];
        XXBookmarksViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"Bookmarks"];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        [self.dynamicsDrawerViewController setPaneViewController:nav animated:YES completion:nil];
    }
}

- (void)search {
    if (!searching){
        searching = YES;
        [manager GET:[NSString stringWithFormat:@"%@/stories/search",kAPIBaseUrl] parameters:@{@"search":self.searchDisplayController.searchBar.text} success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"Successful story search: %@",responseObject);
            searching = NO;
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Failed to search: %@",error.description);
        }];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (searching) {
        if (_filteredResults.count){
            [self.view endEditing:YES];
            XXStory *story;
            if (_filteredResults.count && searching && self.searchBar.text){
                story = [_filteredResults objectAtIndex:indexPath.row];
            } else if (_searchResults.count) {
                story = [_searchResults objectAtIndex:indexPath.row];
            }
            XXStoryViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"Story"];
            if (story && story.identifier){
                [ProgressHUD show:@"Fetching story..."];
                [vc setStories:_stories];
                [vc setStoryId:story.identifier];
                UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
                [self.dynamicsDrawerViewController setPaneViewController:nav animated:YES completion:nil];
            }
        } else if (self.searchBar.text) {
            NSLog(@"should be searching more extensively");
            [self search];
        }
    } else if (loggedIn) {
        if (indexPath.section == 0){
            switch (indexPath.row) {
                case 0:
                    [self goHome];
                    break;
                case 1:
                    [self goWrite];
                    break;
                case 2:
                    [self goToMyStories];
                    break;
                case 3:
                    [self goToCircles];
                    break;
                case 4:
                    [self goToBookmarks];
                    break;
                case 5:
                    [self goToSettings];
                    break;
                default:
                    break;
            }
        } else if (indexPath.section == 1){
            XXNotification *notification = [notifications objectAtIndex:indexPath.row];
            XXStoryViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"Story"];
            if (notification.storyId){
                [ProgressHUD show:@"Fetching story..."];
                [vc setStories:_stories];
                [vc setStoryId:notification.storyId];
                UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
                [self.dynamicsDrawerViewController setPaneViewController:nav animated:YES completion:nil];
            }
        }
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return 60;
    } else if (loggedIn){
        if (indexPath.section == 0) {
            return 60;
        } else {
            return 54;
        }
    } else {
        return screen.size.height;
    }
}

/*- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, tableView.frame.size.width-20, 22)];
    [headerLabel setBackgroundColor:[UIColor clearColor]];
    [headerLabel setTextColor:[UIColor whiteColor]];
    [headerLabel setTextAlignment:NSTextAlignmentCenter];
    
    if (IDIOM == IPAD){
        [headerLabel setFont:[UIFont fontWithName:kSourceSansProLight size:17]];
    } else {
        [headerLabel setFont:[UIFont fontWithName:kGotham size:14]];
    }
    
    if (tableView == self.tableView && section == 1 && loggedIn){
        headerLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [headerLabel setText:@"NOTIFICATIONS"];
    } else {
        [headerLabel setFrame:CGRectMake(0, 0, 0, 0)];
    }
    return headerLabel;
}*/

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    searching = YES;
    [self.searchBar setShowsCancelButton:YES animated:YES];
    if (!_searchResults.count && !self.searchBar.text.length){
        [manager GET:[NSString stringWithFormat:@"%@/stories/titles",kAPIBaseUrl] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
            //NSLog(@"success fetching titles: %@",responseObject);
            _searchResults = [[Utilities storiesFromJSONArray:[responseObject objectForKey:@"titles"]] mutableCopy];
            [_filteredResults removeAllObjects];
            [_filteredResults addObjectsFromArray:_searchResults];
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            //NSLog(@"Failure getting search stories titles: %@",error.description);
        }];
        [self.tableView reloadData];
    }
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    searching = NO;
    [self.searchBar setText:@""];
    [self.searchBar setShowsCancelButton:NO animated:YES];
    [self.view endEditing:YES];
    [self.tableView reloadData];
    [self.dynamicsDrawerViewController setPaneState:MSDynamicsDrawerPaneStateOpen animated:YES allowUserInterruption:YES completion:^{
        [self.searchDisplayController.searchBar setFrame:searchRect];
    }];
}

- (BOOL)searchBar:(UISearchBar *)searchBar shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    NSString* newText = [searchBar.text stringByReplacingCharactersInRange:range withString:text];
    [self filterContentForSearchText:newText scope:nil];
    return YES;
}

- (void)transitionToViewController:(MSPaneViewControllerType)paneViewControllerType
{
    if (paneViewControllerType == self.paneViewControllerType) {
        [self.dynamicsDrawerViewController setPaneState:MSDynamicsDrawerPaneStateClosed animated:YES allowUserInterruption:YES completion:nil];
        return;
    }
    
    BOOL animateTransition = self.dynamicsDrawerViewController.paneViewController != nil;
    
    UIViewController *paneViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"Welcome"];
    paneViewController.navigationItem.title = @"Welcome";
    
    UINavigationController *paneNavigationViewController = [[UINavigationController alloc] initWithRootViewController:paneViewController];
    [self.dynamicsDrawerViewController setPaneViewController:paneNavigationViewController animated:animateTransition completion:nil];
    
    self.paneViewControllerType = paneViewControllerType;
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 1){
        return YES;
    } else {
        return NO;
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        indexPathForDeletion = indexPath;
        [[[UIAlertView alloc] initWithTitle:@"Just checking" message:@"Are you sure you want to delete this notification?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil] show];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Yes"]){
        [self deleteNotification];
    } else {
        indexPathForDeletion = nil;
    }
}

- (void)deleteNotification{
    [ProgressHUD show:@"Deleting..."];
    XXNotification *notification = [notifications objectAtIndex:indexPathForDeletion.row];
    [manager DELETE:[NSString stringWithFormat:@"%@/notifications/%@",kAPIBaseUrl,notification.identifier] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [notifications removeObject:notification];
        [self.tableView deleteRowsAtIndexPaths:@[indexPathForDeletion] withRowAnimation:UITableViewRowAnimationFade];
        [ProgressHUD dismiss];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [ProgressHUD dismiss];
        [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Something went wrong while trying to delete this notification. Please try again soon." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        //NSLog(@"Failure deleting notification: %@",error.description);
    }];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    // Fades out top and bottom cells in table view as they leave the screen
    NSArray *visibleCells = [self.tableView visibleCells];
    
    if (visibleCells != nil  &&  [visibleCells count] != 0) {       // Don't do anything for empty table view
        
        /* Get top and bottom cells */
        UITableViewCell *topCell = [visibleCells objectAtIndex:0];
        UITableViewCell *bottomCell = [visibleCells lastObject];
        
        /* Make sure other cells stay opaque */
        // Avoids issues with skipped method calls during rapid scrolling
        for (UITableViewCell *cell in visibleCells) {
            cell.contentView.alpha = 1.0;
        }
        
        /* Set necessary constants */
        NSInteger cellHeight = topCell.frame.size.height - 1;   // -1 To allow for typical separator line height
        NSInteger tableViewTopPosition = self.tableView.frame.origin.y;
        NSInteger tableViewBottomPosition = self.tableView.frame.origin.y + self.tableView.frame.size.height;
        
        /* Get content offset to set opacity */
        CGRect topCellPositionInTableView = [self.tableView rectForRowAtIndexPath:[self.tableView indexPathForCell:topCell]];
        CGRect bottomCellPositionInTableView = [self.tableView rectForRowAtIndexPath:[self.tableView indexPathForCell:bottomCell]];
        CGFloat topCellPosition = [self.tableView convertRect:topCellPositionInTableView toView:[self.tableView superview]].origin.y;
        CGFloat bottomCellPosition = ([self.tableView convertRect:bottomCellPositionInTableView toView:[self.tableView superview]].origin.y + cellHeight);
        
        /* Set opacity based on amount of cell that is outside of view */
        /*CGFloat modifier = 2.0;*/     /* Increases the speed of fading (1.0 for fully transparent when the cell is entirely off the screen,
                                     2.0 for fully transparent when the cell is half off the screen, etc) */
        CGFloat topCellOpacity = (1.0f - ((tableViewTopPosition - topCellPosition) / cellHeight) * 1.0);
        CGFloat bottomCellOpacity = (1.0f - ((bottomCellPosition - tableViewBottomPosition) / cellHeight*2) * 1.0/*modifier*/);
        
        /* Set cell opacity */
        if (topCell) {
            topCell.contentView.alpha = topCellOpacity;
        }
        if (bottomCell) {
            bottomCell.contentView.alpha = bottomCellOpacity;
        }
    }
}

- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope {
    [_filteredResults removeAllObjects]; // First clear the filtered array.
    for (XXStory *story in _searchResults){
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF contains[cd] %@", searchText];
        if([predicate evaluateWithObject:story.title]) {
            [_filteredResults addObject:story];
        }
    }
    [self.tableView reloadData];
}
@end
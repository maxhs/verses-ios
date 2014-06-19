//
//  XXMenuViewController.m
//  Verses
//
//  Created by Max Haines-Stiles on 11/3/13.
//  Copyright (c) 2013 Verses. All rights reserved.
//

#import "XXMenuViewController.h"
#import "XXLoginController.h"
#import "XXNoRotateNavController.h"
#import "XXUserNameCell.h"
#import "User+helper.h"
#import "Notification+helper.h"
#import "Circle+helper.h"
#import "XXStoryViewController.h"
#import "XXSettingsViewController.h"
#import "XXNotificationCell.h"
#import "XXPortfolioViewController.h"
#import "XXCirclesViewController.h"
#import "XXStoriesViewController.h"
#import "XXFeedbackViewController.h"
#import "XXWriteViewController.h"
#import "XXMenuCell.h"
#import "XXSearchCell.h"
#import "XXBookmarksViewController.h"
#import "XXCircleDetailViewController.h"
#import "XXProfileViewController.h"

@interface XXMenuViewController () <UIAlertViewDelegate,UISearchDisplayDelegate,UISearchBarDelegate, UIPopoverControllerDelegate> {
    AFHTTPRequestOperationManager *manager;
    BOOL loggedIn;
    BOOL loading;
    BOOL canLoadMore;
    BOOL searching;
    NSIndexPath *indexPathForDeletion;
    NSMutableArray *_searchResults;
    NSMutableArray *_filteredResults;
    CGRect searchRect;
    NSDateFormatter *_monthFormatter;
    NSDateFormatter *_timeFormatter;
    UIButton *_loginButton;
    NSInteger _circleAlertCount;
    NSAttributedString *searchPlaceholder;
    MSDynamicsDrawerViewController *dynamicsViewController;
    User *currentUser;
}

@end

@implementation XXMenuViewController

- (void)viewDidLoad
{
    manager = [(XXAppDelegate*)[UIApplication sharedApplication].delegate manager];
    dynamicsViewController = [(XXAppDelegate*)[UIApplication sharedApplication].delegate dynamicsDrawerViewController];
    [self.view setBackgroundColor:[UIColor clearColor]];
    _filteredResults = [NSMutableArray array];
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.separatorColor = [UIColor colorWithWhite:1.0 alpha:0.05];

    searching = NO;
    [self.searchBar setPlaceholder:@"Search stories"];
    self.tableView.tableHeaderView = self.searchBar;
    _monthFormatter = [[NSDateFormatter alloc] init];
    [_monthFormatter setLocale:[NSLocale currentLocale]];
    [_monthFormatter setDateFormat:@"MMM d"];
    _timeFormatter = [[NSDateFormatter alloc] init];
    [_timeFormatter setLocale:[NSLocale currentLocale]];
    [_timeFormatter setDateFormat:@"h:mm a"];
    currentUser = [User MR_findFirstByAttribute:@"identifier" withValue:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]];
    [super viewDidLoad];
    searchPlaceholder = [[NSAttributedString alloc] initWithString:@"Search stories" attributes:@{ NSForegroundColorAttributeName : [UIColor whiteColor] }];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reloadMenu)
                                                 name:@"ReloadMenu"
                                               object:nil];
}

- (void)reloadMenu {
    currentUser = [(XXAppDelegate*)[UIApplication sharedApplication].delegate currentUser];
    [self loadNotifications];
}

- (void)viewWillAppear:(BOOL)animated {
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"MenuRevealed" object:nil];
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]) {
        loggedIn = YES;
        self.tableView.scrollEnabled = YES;
        [self loadNotifications];
        self.tableView.rowHeight = 56;
        [self.searchBar setHidden:NO];
    } else {
        [self.searchBar setHidden:YES];
        self.tableView.rowHeight = screenHeight();
        self.tableView.scrollEnabled = NO;
        loggedIn = NO;
    }
    
    [self.tableView reloadData];
    [self.searchBar setImage:[UIImage imageNamed:@"whiteSearchIcon"] forSearchBarIcon:UISearchBarIconSearch state:UIControlStateNormal];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
        for (id subview in [self.searchBar.subviews.firstObject subviews]){
            if ([subview isKindOfClass:[UITextField class]]){
                UITextField *searchTextField = (UITextField*)subview;
                [searchTextField setKeyboardAppearance:UIKeyboardAppearanceDark];
                [searchTextField setBackgroundColor:[UIColor clearColor]];
                searchTextField.layer.borderColor = [UIColor colorWithWhite:1 alpha:.9].CGColor;
                searchTextField.layer.borderWidth = 1.f;
                searchTextField.layer.cornerRadius = 14.f;
                searchTextField.clipsToBounds = YES;
                searchTextField.attributedPlaceholder = searchPlaceholder;
                [searchTextField setFont:[UIFont fontWithName:kSourceSansProRegular size:15]];
                break;
            }
        }
    } else {
        for (id subview in [self.searchBar.subviews.firstObject subviews]){
            if ([subview isKindOfClass:[UITextField class]]){
                UITextField *searchTextField = (UITextField*)subview;
                [searchTextField setKeyboardAppearance:UIKeyboardAppearanceDefault];
                [searchTextField setBackgroundColor:[UIColor clearColor]];
                searchTextField.layer.borderColor = [UIColor colorWithWhite:1 alpha:.9].CGColor;
                searchTextField.layer.borderWidth = 1.f;
                searchTextField.layer.cornerRadius = 14.f;
                searchTextField.clipsToBounds = YES;
                searchTextField.attributedPlaceholder = searchPlaceholder;
                [searchTextField setFont:[UIFont fontWithName:kSourceSansProRegular size:15]];
                break;
            }
        }
    }
    
    if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)){
        [self.tableView setFrame:CGRectMake(0, 0, screenWidth()-screenWidth()*1/8, screenHeight())];
    } else {
        if (IDIOM == IPAD){
            [self.tableView setFrame:CGRectMake(0, 0, screenHeight()*.66, screenHeight())];
        } else {
            [self.tableView setFrame:CGRectMake(0, 0, screenHeight()/2, screenHeight())];
        }
    }
    
    if (self.tableView.alpha < 1.0){
        [UIView animateWithDuration:.25 animations:^{
            [self.tableView setAlpha:1.0];
        }];
    }
    canLoadMore = YES;
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
}

/*- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)){
        [self.tableView setFrame:CGRectMake(0, 0, screenWidth()-screenWidth()*1/8, screenHeight())];
    } else {
        [self.tableView setFrame:CGRectMake(0, 0, screenHeight()/2, screenHeight())];
    }
}*/

- (void)loadCirclesAlert {
    if (loggedIn){
        [manager GET:[NSString stringWithFormat:@"%@/circles/alert",kAPIBaseUrl] parameters:@{@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
            //NSLog(@"circle alert response: %@",responseObject);
            _circleAlertCount = [[responseObject objectForKeyedSubscript:@"count"] integerValue];
            
            [self.tableView beginUpdates];
            if (self.tableView.visibleCells)[self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
            else [self.tableView reloadData];
            [self.tableView endUpdates];
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Failure getting circle alerts: %@",error.description);
        }];
    }
}

- (void)loadNotifications {
    if (loggedIn){
        //[manager.requestSerializer setValue:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsAuthToken] forHTTPHeaderField:@"Authorization"];
        [manager GET:[NSString stringWithFormat:@"%@/notifications",kAPIBaseUrl] parameters:@{@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId],@"count":@"30"} success:^(AFHTTPRequestOperation *operation, id responseObject) {
            //NSLog(@"success fetching user notifications: %@",responseObject);
            NSMutableOrderedSet *notificationSet = [NSMutableOrderedSet orderedSet];
            for (NSDictionary *dict in [responseObject objectForKey:@"notifications"]){
                Notification *notification = [Notification MR_findFirstByAttribute:@"identifier" withValue:[dict objectForKey:@"id"]];
                if (!notification){
                    notification = [Notification MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                }
                [notification populateFromDict:dict];
                [notificationSet addObject:notification];
            }
            currentUser.notifications = notificationSet;
            [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                [self.tableView reloadData];
                [self loadCirclesAlert];
            }];
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Failure getting user notifications: %@",error.description);
        }];
    }
}

- (void)loadMoreNotifications {
    if (loggedIn){
        loading = YES;
        Notification *lastNotification = currentUser.notifications.lastObject;
        if (lastNotification){
            [manager GET:[NSString stringWithFormat:@"%@/stories",kAPIBaseUrl] parameters:@{@"before_date":[NSNumber numberWithDouble:[lastNotification.createdDate timeIntervalSince1970]], @"count":@"30",@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
                //NSLog(@"more notificaitons response: %@",responseObject);
                NSMutableOrderedSet *notificationSet = [NSMutableOrderedSet orderedSetWithOrderedSet:currentUser.notifications];
                int count = 0;
                for (NSDictionary *dict in [responseObject objectForKey:@"notifications"]){
                    Notification *notification = [Notification MR_findFirstByAttribute:@"identifier" withValue:[dict objectForKey:@"id"]];
                    if (!notification){
                        notification = [Notification MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                    }
                    [notification populateFromDict:dict];
                    [notificationSet addObject:notification];
                    count ++;
                }
                for (Notification *notification in currentUser.notifications){
                    if (![notificationSet containsObject:notification]){
                        NSLog(@"Deleting a notification that no longer exists: %@",notification.message);
                        [notification MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
                    }
                }
                currentUser.notifications = notificationSet;
                
                if (count < 30) {
                    canLoadMore = NO;
                    NSLog(@"Can't load more, we now have %i notifications", currentUser.notifications.count);
                }
                [ProgressHUD dismiss];
                loading = NO;
                [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationFade];
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                
            }];
        } else {
            [self loadNotifications];
        }
    }
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
        return 2;
    } else {
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
            return 4;
        } else {
            return currentUser.notifications.count;
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
            Story *story;
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
            
            if (indexPath.row == 1) [cell configureAlert:_circleAlertCount];
            else [cell configureAlert:0];
            
            UIView *selectedBackgroundView = [[UIView alloc] initWithFrame:cell.frame];
            [selectedBackgroundView setBackgroundColor:[UIColor colorWithWhite:1 alpha:.5]];
            cell.selectedBackgroundView = selectedBackgroundView;
            
            switch (indexPath.row) {
                case 0:
                {
                    [cell.menuImage setImage:[UIImage imageNamed:@"menuHome"]];
                    [cell.menuLabel setText:@"Home"];
                    return cell;
                }
                    break;
                /*case 1:
                {
                    [cell.menuImage setImage:[UIImage imageNamed:@"menuWrite"]];
                    [cell.menuLabel setText:@"Write"];
                    return cell;
                }
                    break;
                case 2:
                {
                    [cell.menuImage setImage:[UIImage imageNamed:@"menuMy"]];
                    [cell.menuLabel setText:@"Portfolio"];
                    return cell;
                }
                    break;*/
                case 1:
                {
                    [cell.menuImage setImage:[UIImage imageNamed:@"menuCircles"]];
                    [cell.menuLabel setText:@"Writing Circles"];
                    return cell;
                }
                    break;
                case 2:
                {
                    [cell.menuImage setImage:[UIImage imageNamed:@"menuBookmarks"]];
                    [cell.menuLabel setText:@"Bookmarks"];
                    return cell;
                }
                    break;
                case 3:
                {
                    [cell.menuImage setImage:[UIImage imageNamed:@"menuSettings"]];
                    [cell.menuLabel setText:@"Settings"];
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
            Notification *notification = [currentUser.notifications objectAtIndex:indexPath.row];
            [cell configureCell:notification];
            [cell.monthLabel setText:[_monthFormatter stringFromDate:notification.createdDate]];
            [cell.timeLabel setText:[_timeFormatter stringFromDate:notification.createdDate]];
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
        [_loginButton setFrame:CGRectMake(0, 0, screenWidth()*.923, self.tableView.frame.size.height-self.tableView.tableHeaderView.frame.size.height-44)];
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
    XXLoginController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Login"];
    XXNoRotateNavController *nav = [[XXNoRotateNavController alloc] initWithRootViewController:vc];
    [self presentViewController:nav animated:YES completion:^{
        
    }];
}

- (void)goHome {
    if ([[(UINavigationController*)dynamicsViewController.paneViewController viewControllers].lastObject isKindOfClass:[XXStoriesViewController class]]){
        [dynamicsViewController setPaneState:MSDynamicsDrawerPaneStateClosed inDirection:MSDynamicsDrawerDirectionLeft animated:YES allowUserInterruption:YES completion:nil];
    } else {
        [ProgressHUD show:@"Fetching the latest..."];
        XXStoriesViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Stories"];
        vc.ether = YES;
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        [dynamicsViewController setPaneViewController:nav animated:YES completion:^{
            
        }];
    }
}
- (void)goToSettings {
    if ([[(UINavigationController*)dynamicsViewController.paneViewController viewControllers].lastObject isKindOfClass:[XXSettingsViewController class]]){
        [dynamicsViewController setPaneState:MSDynamicsDrawerPaneStateClosed inDirection:MSDynamicsDrawerDirectionLeft animated:YES allowUserInterruption:YES completion:nil];
    } else {
        [ProgressHUD show:@"Getting settings..."];
        XXSettingsViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Settings"];
        [vc setTitle:@"Settings"];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        [dynamicsViewController setPaneViewController:nav animated:YES completion:^{
            //[vc setDynamicsDrawerViewController:dynamicsViewController];
        }];
    }
}
/*- (void)goToFeatured {
    if ([[(UINavigationController*)dynamicsViewController.paneViewController viewControllers].lastObject isKindOfClass:[XXStoriesViewController class]]){
        [dynamicsViewController setPaneState:MSDynamicsDrawerPaneStateClosed inDirection:MSDynamicsDrawerDirectionLeft animated:YES allowUserInterruption:YES completion:nil];
    } else {
        [ProgressHUD show:@"Fetching what's featured..."];
        XXStoriesViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Stories"];
        [vc setFeatured:YES];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        [dynamicsViewController setPaneViewController:nav animated:YES completion:nil];
    }
}*/
- (void)goToMyStories {
    if ([[(UINavigationController*)dynamicsViewController.paneViewController viewControllers].lastObject isKindOfClass:[XXPortfolioViewController class]]){
        [dynamicsViewController setPaneState:MSDynamicsDrawerPaneStateClosed inDirection:MSDynamicsDrawerDirectionLeft animated:YES allowUserInterruption:YES completion:nil];
    } else {
        [ProgressHUD show:@"Grabbing your work..."];
        XXPortfolioViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Portfolio"];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        [dynamicsViewController setPaneViewController:nav animated:YES completion:nil];
    }
}
- (void)goWrite {
    if ([[(UINavigationController*)dynamicsViewController.paneViewController viewControllers].lastObject isKindOfClass:[XXWriteViewController class]]){
        XXWriteViewController *writeVc = [(UINavigationController*)dynamicsViewController.paneViewController viewControllers].lastObject;
        [writeVc setStory:nil];
        [writeVc prepareStory];
        [dynamicsViewController setPaneState:MSDynamicsDrawerPaneStateClosed inDirection:MSDynamicsDrawerDirectionLeft animated:YES allowUserInterruption:YES completion:^{
            
        }];
    } else {
        XXWriteViewController *write = [[self storyboard] instantiateViewControllerWithIdentifier:@"Write"];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:write];
        [dynamicsViewController setPaneViewController:nav animated:YES completion:nil];
        
        if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
            [UIView animateWithDuration:.3 animations:^{
                [dynamicsViewController.paneViewController.view setAlpha:0.0];
                [self.tableView setAlpha:0.0];
            }];
        }
    }
}

- (void)goToCircles {
    if ([[(UINavigationController*)dynamicsViewController.paneViewController viewControllers].lastObject isKindOfClass:[XXCirclesViewController class]]){
        XXCirclesViewController *vc = [(UINavigationController*)dynamicsViewController.paneViewController viewControllers].lastObject;
        [vc loadCircles];
        [dynamicsViewController setPaneState:MSDynamicsDrawerPaneStateClosed inDirection:MSDynamicsDrawerDirectionLeft animated:YES allowUserInterruption:YES completion:nil];
    } else {
        [ProgressHUD show:@"Gathering your circles..."];
        XXCirclesViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Circles"];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        [dynamicsViewController setPaneViewController:nav animated:YES completion:nil];
    }
}
- (void)goToFeedback {
    if ([[(UINavigationController*)dynamicsViewController.paneViewController viewControllers].lastObject isKindOfClass:[XXFeedbackViewController class]]){
        [dynamicsViewController setPaneState:MSDynamicsDrawerPaneStateClosed inDirection:MSDynamicsDrawerDirectionLeft animated:YES allowUserInterruption:YES completion:nil];
    } else {
        [ProgressHUD show:@"Fetching your feedback..."];
        XXFeedbackViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Feedback"];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        [dynamicsViewController setPaneViewController:nav animated:YES completion:nil];
    }
}
- (void)goToBookmarks {
    if ([[(UINavigationController*)dynamicsViewController.paneViewController viewControllers].lastObject isKindOfClass:[XXBookmarksViewController class]]){
        [dynamicsViewController setPaneState:MSDynamicsDrawerPaneStateClosed inDirection:MSDynamicsDrawerDirectionLeft animated:YES allowUserInterruption:YES completion:nil];
    } else {
        [ProgressHUD show:@"Grabbing your bookmarks..."];
        XXBookmarksViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Bookmarks"];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        [dynamicsViewController setPaneViewController:nav animated:YES completion:nil];
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
            Story *story;
            if (_filteredResults.count && searching && self.searchBar.text){
                story = [_filteredResults objectAtIndex:indexPath.row];
            } else if (_searchResults.count) {
                story = [_searchResults objectAtIndex:indexPath.row];
            }
            XXStoryViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Story"];
            if (story && story.identifier){
                [ProgressHUD show:@"Fetching story..."];
                [vc setStory:story];
                UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
                [dynamicsViewController setPaneViewController:nav animated:YES completion:nil];
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
                /*case 1:
                    [self goWrite];
                    break;
                case 2:
                    [self goToMyStories];
                    break;*/
                case 1:
                    [self goToCircles];
                    break;
                case 2:
                    [self goToBookmarks];
                    break;
                case 3:
                    [self goToSettings];
                    break;
                default:
                    break;
            }
        } else if (indexPath.section == 1){
            Notification *notification = [currentUser.notifications objectAtIndex:indexPath.row];
            if (notification.story.identifier){
                XXStoryViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Story"];
                [ProgressHUD show:@"Fetching story..."];
                [vc setStoryId:notification.story.identifier];
                UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
                [dynamicsViewController setPaneViewController:nav animated:YES completion:nil];
            } else if (notification.circle.identifier){
                [ProgressHUD show:@"Writing circle..."];
                XXCircleDetailViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"CircleDetail"];
                [vc setCircle:notification.circle];
                [vc setNeedsNavigation:YES];
                UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
                [dynamicsViewController setPaneViewController:nav animated:YES completion:nil];
            } else if ([notification.type isEqualToString:kSubscription]){
                if (IDIOM == IPAD){
                    XXProfileViewController* vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Profile"];
                    [vc setUser:notification.targetUser];
                    self.popover = [[UIPopoverController alloc] initWithContentViewController:vc];
                    self.popover.delegate = self;
                    
                    XXNotificationCell *cell = (XXNotificationCell*)[self.tableView cellForRowAtIndexPath:indexPath];
                    CGRect displayFrom = CGRectMake(cell.frame.origin.x, cell.frame.origin.y, screenWidth()/2, screenHeight()/2);
                    [self.popover presentPopoverFromRect:displayFrom inView:self.view permittedArrowDirections:UIPopoverArrowDirectionLeft animated:YES];
                } else {
                    XXProfileViewController* vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Profile"];
                    [vc setUser:notification.targetUser];
                    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
                    [self presentViewController:nav animated:YES completion:^{
                        
                    }];
                }
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
        return screenHeight();
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
            _searchResults = [self updateLocalStories:[responseObject objectForKey:@"titles"]];
            [_filteredResults removeAllObjects];
            [_filteredResults addObjectsFromArray:_searchResults];
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            //NSLog(@"Failure getting search stories titles: %@",error.description);
        }];
        [self.tableView reloadData];
    }
}

- (NSMutableArray*)updateLocalStories:(NSArray*)array{
    NSMutableArray *storyArray = [NSMutableArray array];
    for (NSDictionary *dict in array){
        if ([dict objectForKey:@"id"] && [dict objectForKey:@"id"] != [NSNull null]){
            Story *story = [Story MR_findFirstByAttribute:@"identifier" withValue:[dict objectForKey:@"id"]];
            if (!story){
                story = [Story MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [story populateFromDict:dict];
            [storyArray addObject:story];
        }
    }
    //[self saveContext];
    return storyArray;
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    searching = NO;
    [self.searchBar setText:@""];
    [self.searchBar setShowsCancelButton:NO animated:YES];
    [self.view endEditing:YES];
    [self.tableView reloadData];
    [dynamicsViewController setPaneState:MSDynamicsDrawerPaneStateOpen animated:YES allowUserInterruption:YES completion:nil];
}

- (BOOL)searchBar:(UISearchBar *)searchBar shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    NSString* newText = [searchBar.text stringByReplacingCharactersInRange:range withString:text];
    [self filterContentForSearchText:newText scope:nil];
    return YES;
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
    Notification *notification = [currentUser.notifications objectAtIndex:indexPathForDeletion.row];
    [manager DELETE:[NSString stringWithFormat:@"%@/notifications/%@",kAPIBaseUrl,notification.identifier] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [currentUser removeNotification:notification];
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
    CGFloat actualPosition = scrollView.contentOffset.y;
    CGFloat contentHeight = scrollView.contentSize.height - (screenHeight()*2);
    if (actualPosition >= contentHeight && !loading && canLoadMore) {
        //NSLog(@"should be loading more. content height: %f actual position: %f",contentHeight,actualPosition);
        [self loadMoreNotifications];
    }
    
    // Fades out top and bottom cells in table view as they leave the screen
   /* NSArray *visibleCells = [self.tableView visibleCells];
    
    if (visibleCells != nil  &&  [visibleCells count] != 0) {       // Don't do anything for empty table view
    
        UITableViewCell *topCell = [visibleCells objectAtIndex:0];
        UITableViewCell *bottomCell = [visibleCells lastObject];
    
        // Avoids issues with skipped method calls during rapid scrolling
        for (UITableViewCell *cell in visibleCells) {
            cell.contentView.alpha = 1.0;
        }
    
        NSInteger cellHeight = topCell.frame.size.height - 1;   // -1 To allow for typical separator line height
        NSInteger tableViewTopPosition = self.tableView.frame.origin.y;
        NSInteger tableViewBottomPosition = self.tableView.frame.origin.y + self.tableView.frame.size.height;
    
        CGRect topCellPositionInTableView = [self.tableView rectForRowAtIndexPath:[self.tableView indexPathForCell:topCell]];
        CGRect bottomCellPositionInTableView = [self.tableView rectForRowAtIndexPath:[self.tableView indexPathForCell:bottomCell]];
        CGFloat topCellPosition = [self.tableView convertRect:topCellPositionInTableView toView:[self.tableView superview]].origin.y;
        CGFloat bottomCellPosition = ([self.tableView convertRect:bottomCellPositionInTableView toView:[self.tableView superview]].origin.y + cellHeight);
    
        //CGFloat modifier = 2.0;
        CGFloat topCellOpacity = (1.0f - ((tableViewTopPosition - topCellPosition) / cellHeight) * 1.0);
        CGFloat bottomCellOpacity = (1.0f - ((bottomCellPosition - tableViewBottomPosition) / cellHeight*2) * modifier);
        
        if (topCell) {
            topCell.contentView.alpha = topCellOpacity;
        }
        if (bottomCell) {
            bottomCell.contentView.alpha = bottomCellOpacity;
        }
    }*/
}

- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope {
    [_filteredResults removeAllObjects]; // First clear the filtered array.
    for (Story *story in _searchResults){
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF contains[cd] %@", searchText];
        if([predicate evaluateWithObject:story.title]) {
            [_filteredResults addObject:story];
        }
    }
    [self.tableView reloadData];
}
@end

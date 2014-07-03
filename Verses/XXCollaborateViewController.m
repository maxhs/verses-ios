//
//  XXCollaborateViewController.m
//  Verses
//
//  Created by Max Haines-Stiles on 3/31/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import "XXCollaborateViewController.h"
#import "XXContactCell.h"
#import "XXNothingCell.h"
#import "Circle+helper.h"
#import "XXAlert.h"
#import "XXAddCollaboratorsViewController.h"
#import "XXProfileViewController.h"
#import "XXCollaboratorsTransition.h"
#import "XXManageCircleViewController.h"

@interface XXCollaborateViewController () <UIViewControllerTransitioningDelegate> {
    AFHTTPRequestOperationManager *manager;
    BOOL loadingCircles;
    BOOL loadingContacts;
    NSIndexPath *indexPathToRemove;
    UIBarButtonItem *cancelButton;
    UIAlertView *addContactAlert;
    UIColor *textColor;
    UIImageView *navBarShadowView;
    UIBarButtonItem *addButton;
    User *currentUser;
    UIRefreshControl *refreshControl;
}

@end

@implementation XXCollaborateViewController
@synthesize story = _story;

- (void)viewDidLoad
{
    [super viewDidLoad];
    manager = [(XXAppDelegate*)[UIApplication sharedApplication].delegate manager];
    currentUser = [User MR_findFirstByAttribute:@"identifier" withValue:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]];
    if (self.navigationController.viewControllers.firstObject == self){
        cancelButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"blackX"] style:UIBarButtonItemStylePlain target:self action:@selector(dismissView)];
        self.navigationItem.leftBarButtonItem = cancelButton;
    } else {
        self.title = @"Contacts";
    }
    
    if (_manageContacts){
        addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addContact)];
        self.navigationItem.rightBarButtonItem = addButton;
        [self loadContacts];
    } else {
        self.navigationItem.rightBarButtonItem = nil;
        [self loadContacts];
        [self loadCircles];
    }
    
    refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(handleRefresh) forControlEvents:UIControlEventValueChanged];
    [refreshControl setTintColor:[UIColor darkGrayColor]];
    [self.tableView addSubview:refreshControl];
    
    [self.tableView setSeparatorColor:[UIColor colorWithWhite:0 alpha:.05]];
    navBarShadowView = [Utilities findNavShadow:self.navigationController.navigationBar];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addContactObserver:) name:@"AddContact" object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.manageContacts) [[(XXAppDelegate*)[UIApplication sharedApplication].delegate dynamicsDrawerViewController] registerTouchForwardingClass:[XXContactCell class]];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
        [self.view setBackgroundColor:[UIColor clearColor]];
        textColor = [UIColor whiteColor];
        [refreshControl setTintColor:[UIColor whiteColor]];
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
    } else {
        [self.view setBackgroundColor:[UIColor whiteColor]];
        textColor = [UIColor blackColor];
        [refreshControl setTintColor:[UIColor blackColor]];
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
    }
    navBarShadowView.hidden = YES;
    
    //reset view after custom transition
    if (self.navigationController.view.alpha != 1.0){
        [UIView animateWithDuration:.23 animations:^{
            self.navigationController.view.transform = CGAffineTransformIdentity;
            [self.navigationController.view setAlpha:1.0];
        } completion:^(BOOL finished) {
        }];
    }
}

- (void)handleRefresh {
    [self loadContacts];
    [self loadCircles];
}

- (void)loadContacts {
    [ProgressHUD show:@"Refreshing your contacts..."];
    loadingContacts = YES;
    [manager GET:[NSString stringWithFormat:@"%@/users/%@/contacts",kAPIBaseUrl,[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"success getting user's contacts: %@",[responseObject objectForKey:@"users"]);
        NSMutableOrderedSet *contactSet = [NSMutableOrderedSet orderedSet];
        for (NSDictionary *userDict in [responseObject objectForKey:@"users"]){
            User *user = [User MR_findFirstByAttribute:@"identifier" withValue:[userDict objectForKey:@"id"]];
            if (!user){
                user = [User MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [user populateFromDict:userDict];
            [contactSet addObject:user];
        }
        for (User *user in currentUser.contacts){
            if (![contactSet containsObject:user]){
                NSLog(@"Deleting a contact that no longer exists: %@",user.penName);
                [user MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
            }
        }
        
        currentUser.contacts = contactSet;
        loadingContacts = NO;
        
        if (_manageContacts){
            [self.tableView reloadData];
        } else {
            [self.tableView beginUpdates];
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView endUpdates];
        }
        [ProgressHUD dismiss];
        if (refreshControl.isRefreshing) [refreshControl endRefreshing];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        loadingContacts = NO;
        if (refreshControl.isRefreshing) [refreshControl endRefreshing];
        NSLog(@"error getting user's contacts: %@",error.description);
    }];
}

- (void)loadCircles {
    loadingCircles = YES;
    [manager GET:[NSString stringWithFormat:@"%@/circles",kAPIBaseUrl] parameters:@{@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"success fetching circles: %@",responseObject);
        NSMutableOrderedSet *circleSet = [NSMutableOrderedSet orderedSet];
        for (NSDictionary *circleDict in [responseObject objectForKey:@"circles"]){
            Circle *circle = [Circle MR_findFirstByAttribute:@"identifier" withValue:[circleDict objectForKey:@"id"]];
            if (!circle){
                circle = [Circle MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [circle populateFromDict:circleDict];
            [circleSet addObject:circle];
        }
        for (Circle *circle in currentUser.circles){
            if (![circleSet containsObject:circle]){
                NSLog(@"Deleting a circle that no longer exists: %@",circle.name);
                [circle MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
            }
        }
        currentUser.circles = circleSet;
        loadingCircles = NO;
        
        [self.tableView beginUpdates];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView endUpdates];
        [ProgressHUD dismiss];
        if (refreshControl.isRefreshing) [refreshControl endRefreshing];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failure getting circles: %@",error.description);
        loadingCircles = NO;
        [ProgressHUD dismiss];
        if (refreshControl.isRefreshing) [refreshControl endRefreshing];
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (_manageContacts && loadingContacts){
        return 0;
    } else {
        if (_manageContacts){
            return 1;
        } else {
            return 2;
        }
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0){
        if (self.manageContacts){
            if (currentUser.contacts.count == 0 && !loadingContacts) {
                return 1;
            } else {
                return currentUser.contacts.count;
            }
        } else if (currentUser.circles.count == 0 && !loadingCircles){
            return 1;
        } else {
            return currentUser.circles.count;
        }
    } else {
        if (currentUser.contacts.count == 0 && !loadingContacts){
            return 1;
        } else {
            return currentUser.contacts.count;
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0 && !self.manageContacts){
        if (currentUser.contacts.count){
            XXContactCell *cell = (XXContactCell *)[tableView dequeueReusableCellWithIdentifier:@"ContactCell"];
            if (cell == nil) {
                cell = [[[NSBundle mainBundle] loadNibNamed:@"XXContactCell" owner:nil options:nil] lastObject];
            }
            Circle *circle = [currentUser.circles objectAtIndex:indexPath.row];
            [cell configureCircle:circle];
            [cell.locationLabel setTextColor:textColor];
            [cell.nameLabel setTextColor:textColor];
            
            if ([_story.circles containsObject:circle]){
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            } else {
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
        
            return cell;
        } else {
            XXNothingCell *cell = (XXNothingCell *)[tableView dequeueReusableCellWithIdentifier:@"NothingCell"];
            if (cell == nil) {
                cell = [[[NSBundle mainBundle] loadNibNamed:@"XXNothingCell" owner:nil options:nil] lastObject];
            }
            [cell.promptButton setTitle:@"Tap here to create your first writing circle." forState:UIControlStateNormal];
            [cell.promptButton addTarget:self action:@selector(newCircle) forControlEvents:UIControlEventTouchUpInside];
            [cell.promptButton.titleLabel setNumberOfLines:0];
            [cell.promptButton.titleLabel setFont:[UIFont fontWithName:kSourceSansProLight size:20]];
            [cell.promptButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
            cell.promptButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
            [cell.promptButton setTitleColor:textColor forState:UIControlStateNormal];
            [cell.promptButton setBackgroundColor:[UIColor clearColor]];

            return cell;
        }
    } else {
        if (currentUser.contacts.count){
            XXContactCell *cell = (XXContactCell *)[tableView dequeueReusableCellWithIdentifier:@"ContactCell"];
            if (cell == nil) {
                cell = [[[NSBundle mainBundle] loadNibNamed:@"XXContactCell" owner:nil options:nil] lastObject];
            }
            User *contact = [currentUser.contacts objectAtIndex:indexPath.row];
            [cell configureContact:contact];
            [cell.locationLabel setTextColor:textColor];
            [cell.nameLabel setTextColor:textColor];
            cell.accessoryType = UITableViewCellAccessoryNone;
            if (self.manageContacts){
                
            } else {
                if ([_story.users containsObject:contact]){
                    cell.accessoryType = UITableViewCellAccessoryCheckmark;
                } else {
                    cell.accessoryType = UITableViewCellAccessoryNone;
                }
            }
            return cell;
        } else {
            XXNothingCell *cell = (XXNothingCell *)[tableView dequeueReusableCellWithIdentifier:@"NothingCell"];
            if (cell == nil) {
                cell = [[[NSBundle mainBundle] loadNibNamed:@"XXNothingCell" owner:nil options:nil] lastObject];
            }
            [cell.promptButton setTitle:@"Tap to add your first collaborator" forState:UIControlStateNormal];
            [cell.promptButton addTarget:self action:@selector(addContact) forControlEvents:UIControlEventTouchUpInside];
            [cell.promptButton.titleLabel setNumberOfLines:0];
            [cell.promptButton.titleLabel setFont:[UIFont fontWithName:kSourceSansProLight size:20]];
            [cell.promptButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
            cell.promptButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
            [cell.promptButton setTitleColor:textColor forState:UIControlStateNormal];
            [cell.promptButton setBackgroundColor:[UIColor clearColor]];

            return cell;
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (currentUser.contacts.count == 0){
        return screenHeight()-84;
    } else {
        return 80;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (_manageContacts){
        return 0;
    } else {
        return 34;
    }
}

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIToolbar *backgroundToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, screenWidth(), 34)];
    backgroundToolbar.clipsToBounds = YES;
    backgroundToolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    UILabel *headerLabel = [[UILabel alloc] init];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
        [backgroundToolbar setBarStyle:UIBarStyleBlackTranslucent];
        [headerLabel setTextColor:textColor];
    } else {
        [backgroundToolbar setBarStyle:UIBarStyleDefault];
        [backgroundToolbar setBackgroundColor:[UIColor colorWithWhite:0 alpha:.025]];
        [headerLabel setTextColor:[UIColor blackColor]];
    }
    
    if (IDIOM == IPAD){
        [headerLabel setFont:[UIFont fontWithName:kSourceSansProSemibold size:16]];
    } else {
        [headerLabel setFont:[UIFont fontWithName:kSourceSansProSemibold size:15]];
    }
    
    [headerLabel setTextAlignment:NSTextAlignmentCenter];
    if (!_manageContacts){
        switch (section) {
            case 0:
                [headerLabel setText:@"CIRCLES"];
                break;
            case 1:
                [headerLabel setText:@"CONTACTS"];
                break;

            default:
                [headerLabel setText:@""];
                break;
        }
        [backgroundToolbar addSubview:headerLabel];
        [headerLabel setFrame:backgroundToolbar.frame];
        headerLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    }

    return backgroundToolbar;
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if([indexPath row] == ((NSIndexPath*)[[tableView indexPathsForVisibleRows] lastObject]).row && tableView == self.tableView){
        //end of loading
        [ProgressHUD dismiss];
        [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
    }
    cell.backgroundColor = [UIColor clearColor];
    UIView *selectionView = [[UIView alloc] initWithFrame:cell.frame];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
        [selectionView setBackgroundColor:kTableViewCellSelectionColorDark];
    } else {
        [selectionView setBackgroundColor:[UIColor colorWithWhite:.9 alpha:.23]];
    }
    cell.selectedBackgroundView = selectionView;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (_manageContacts){
        User *contact = [currentUser.contacts objectAtIndex:indexPath.row];
        XXProfileViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Profile"];
        [vc setUserId:contact.identifier];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        nav.transitioningDelegate = self;
        nav.modalPresentationStyle = UIModalPresentationCustom;
        
        [self presentViewController:nav animated:YES completion:^{
            
        }];
    } else {
        if (indexPath.section == 0){
            Circle *circle= [currentUser.circles objectAtIndex:indexPath.row];
            if ([_story.circles containsObject:circle]){
                [_story removeCircle:circle];
            } else {
                [_story addCircle:circle];
            }
        } else {
            User *contact = [currentUser.contacts objectAtIndex:indexPath.row];
            if ([_story.users containsObject:contact]){
                [_story removeUser:contact];
            } else {
                [_story addUser:contact];
            }
        }
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}


- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented
                                                                  presentingController:(UIViewController *)presenting
                                                                      sourceController:(UIViewController *)source {
    XXCollaboratorsTransition *animator = [XXCollaboratorsTransition new];
    animator.presenting = YES;
    return animator;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    
    XXCollaboratorsTransition *animator = [XXCollaboratorsTransition new];
    return animator;
}

- (void)newCircle {
    XXManageCircleViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"ManageCircle"];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
        [UIView animateWithDuration:.23 animations:^{
            self.navigationController.view.transform = CGAffineTransformMakeScale(.77, .77);
            [self.navigationController.view setAlpha:0.0];
        } completion:^(BOOL finished) {
            
        }];
    }
    
    [self presentViewController:nav animated:YES completion:^{
        
    }];
}

- (void)addContact{
    XXAddCollaboratorsViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"AddCollaborators"];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
        [UIView animateWithDuration:.23 animations:^{
            self.navigationController.view.transform = CGAffineTransformMakeScale(.77, .77);
            [self.navigationController.view setAlpha:0.0];
        } completion:^(BOOL finished) {
            
        }];
    }
    
    [self presentViewController:nav animated:YES completion:^{
        
    }];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Remove"]){
        [self removeContact];
    }
}

- (void)confirmRemove:(NSIndexPath*)indexPath {
    [[[UIAlertView alloc] initWithTitle:@"Confirmation" message:@"Are you sure you want to remove this contact?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Remove", nil] show];
    indexPathToRemove = indexPath;
}

- (void)addContactObserver:(NSNotification*)notification {
    User *newContact = [notification.userInfo objectForKey:@"contact"];
    if (newContact){
        [currentUser addContact:newContact];
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            NSLog(@"Saving a new contact for user");
        }];
        NSMutableOrderedSet *set = [NSMutableOrderedSet orderedSetWithOrderedSet:currentUser.contacts];
        [set insertObject:newContact atIndex:0];
        currentUser.contacts = set;
        if (newContact && currentUser.contacts.count > 1){
            [self.tableView beginUpdates];
            [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationTop];
            [self.tableView endUpdates];
        }
        else {
            [self.tableView beginUpdates];
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView endUpdates];
        }
    }
}

- (void)removeContact {
    User *removeContact = [currentUser.contacts objectAtIndex:indexPathToRemove.row];
    [manager DELETE:[NSString stringWithFormat:@"%@/users/%@/remove_contact",kAPIBaseUrl,removeContact.identifier] parameters:@{@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"successfully removed contact: %@",responseObject);
        [currentUser removeContact:removeContact];
        [removeContact MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
        [currentUser removeContact:removeContact];
        if (currentUser.contacts.count){
            [self.tableView beginUpdates];
            [self.tableView deleteRowsAtIndexPaths:@[indexPathToRemove] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView endUpdates];
        } else {
            [self.tableView reloadData];
        }
        indexPathToRemove = nil;
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        //NSLog(@"Failed to remove contact: %@",error.description);
        [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Something went wrong while trying to remove this contact. Please try again soon." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    }];
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.manageContacts){
        return YES;
    } else {
        return NO;
    }
}


// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self confirmRemove:indexPath];
        //[tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}

- (void)dismissView {
    if (!_manageContacts){
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
    }
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}


@end

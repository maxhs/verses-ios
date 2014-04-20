//
//  XXSettingsViewController.m
//  Verses
//
//  Created by Max Haines-Stiles on 11/4/13.
//  Copyright (c) 2013 Verses. All rights reserved.
//

#import "XXSettingsViewController.h"
#import "XXUser.h"
#import "User.h"
#import "XXWelcomeViewController.h"
#import "XXSettingsCell.h"
#import "XXAppDelegate.h"
#import <MessageUI/MessageUI.h>
#import "XXLoginController.h"

@interface XXSettingsViewController () <UITextFieldDelegate,UITextViewDelegate, MFMailComposeViewControllerDelegate> {
    UIBarButtonItem *doneButton;
    UIBarButtonItem *saveButton;
    AFHTTPRequestOperationManager *manager;
    UISwitch *pushSwitch;
    UISwitch *feedbackPushSwitch;
    UISwitch *circlePublishPushSwitch;
    UISwitch *bookmarkPushSwitch;
    UISwitch *dailyPushSwitch;
    UISwitch *subscriptionPushSwitch;
    UISwitch *invitationsPushSwitch;
    UISwitch *contributionsPushSwitch;
    UITextField *penNameTextField;
    UITextField *emailTextField;
    UITextField *firstNameTextField;
    UITextField *lastNameTextField;
    UITextField *locationTextField;
    CGRect screen;
    XXUser *currentUser;
    UIBarButtonItem *cancelButton;
    UIColor *textColor;
    UIImageView *navBarShadowView;
    UISwitch *backgroundThemeSwitch;
    UISwitch *storyPagingSwitch;
}

@end

@implementation XXSettingsViewController
@synthesize dynamicsDrawerViewController = _dynamicsDrawerViewController;

- (void)viewDidLoad
{
    [super viewDidLoad];
    manager = [AFHTTPRequestOperationManager manager];
    saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(save)];
    doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneEditing)];
    self.navigationItem.rightBarButtonItem = saveButton;
    [self.logoutButton.titleLabel setFont:[UIFont fontWithName:kSourceSansProLight size:17]];
    self.tableView.tableFooterView = self.logoutButton;
    screen = [UIScreen mainScreen].bounds;
    [self loadProfile];
    cancelButton = [[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"back"] style:UIBarButtonItemStylePlain target:self action:@selector(back)];
    self.navigationItem.leftBarButtonItem = cancelButton;
    navBarShadowView = [Utilities findNavShadow:self.navigationController.navigationBar];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    navBarShadowView.hidden = YES;
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
        [self.view setBackgroundColor:[UIColor clearColor]];
        [self.logoutButton setBackgroundColor:[UIColor clearColor]];
        textColor = [UIColor whiteColor];
    } else {
        //[self.view setBackgroundColor:[UIColor whiteColor]];
        textColor = [UIColor blackColor];
        [self.logoutButton setBackgroundColor:[UIColor colorWithWhite:0 alpha:.035]];
        [self.view setBackgroundColor:[UIColor colorWithWhite:1 alpha:1]];
    }
    [self.logoutButton setTitleColor:textColor forState:UIControlStateNormal];
    [self.tableView setAlpha:1.0];
}

- (void)loadProfile {
    [manager GET:[NSString stringWithFormat:@"%@/users/%@/edit",kAPIBaseUrl,[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]] parameters:@{@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"success getting profile: %@",responseObject);
        currentUser = [[XXUser alloc] initWithDictionary:[responseObject objectForKey:@"user"]];
        [self synchronizeUserDefaults];
        [self.tableView reloadData];
        [ProgressHUD dismiss];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (operation.response.statusCode == 401){
            UIStoryboard *storyboard;
            if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone){
                storyboard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle:nil];
            } else {
                storyboard = [UIStoryboard storyboardWithName:@"Main_iPad" bundle:nil];
            }
            XXLoginController *login = [storyboard instantiateViewControllerWithIdentifier:@"Login"];
            [self presentViewController:login animated:YES completion:^{
                
            }];
        } else {
            [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"We couldn't fetch your details just now. Please try again soon." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        }
        [ProgressHUD dismiss];
    }];
}

- (void)synchronizeUserDefaults {
    [[NSUserDefaults standardUserDefaults] setObject:currentUser.email forKey:kUserDefaultsEmail];
    [[NSUserDefaults standardUserDefaults] setObject:currentUser.penName forKey:kUserDefaultsPenName];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    NSIndexPath *indexPath = nil;
    if (textField == emailTextField){
        indexPath = [NSIndexPath indexPathForRow:0 inSection:1];
    } else if (textField == firstNameTextField){
        indexPath = [NSIndexPath indexPathForRow:1 inSection:1];
    } else if (textField == lastNameTextField){
        indexPath = [NSIndexPath indexPathForRow:2 inSection:1];
    } else if (textField == penNameTextField) {
        indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    } else if (textField == locationTextField) {
        indexPath = [NSIndexPath indexPathForRow:1 inSection:0];
    }
    if (indexPath != nil) [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
    self.navigationItem.leftBarButtonItem = nil;
    self.navigationItem.rightBarButtonItem = doneButton;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    self.navigationItem.leftBarButtonItem = cancelButton;
    self.navigationItem.rightBarButtonItem = saveButton;
}

- (void)doneEditing {
    [self.view endEditing:YES];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
        textColor = [UIColor whiteColor];
    } else {
        textColor = [UIColor blackColor];
    }
    return 5;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return 2;
            break;
        case 1:
            return 3;
            break;
        case 2:
            return 2;
            break;
        case 3:
            return 6;
            break;
        default:
            return 1;
            break;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0){
        XXSettingsCell *cell = (XXSettingsCell *)[tableView dequeueReusableCellWithIdentifier:@"SettingsCell"];
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"XXSettingsCell" owner:nil options:nil] lastObject];
        }
        [cell configure:nil];
        if (indexPath.row == 0){
            [cell.textField setText:currentUser.penName];
            penNameTextField = cell.textField;
            [penNameTextField setPlaceholder:@"Your pen name"];
            penNameTextField.delegate = self;
        } else {
            locationTextField = cell.textField;
            [cell.textField setPlaceholder:@"Where you're from"];
            [cell.textField setText:currentUser.location];
            [locationTextField setDelegate:self];
        }
        [penNameTextField setTextColor:textColor];
        [locationTextField setTextColor:textColor];
        return cell;
    } else if (indexPath.section == 1){
        XXSettingsCell *cell = (XXSettingsCell *)[tableView dequeueReusableCellWithIdentifier:@"SettingsCell"];
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"XXSettingsCell" owner:nil options:nil] lastObject];
        }
        [cell configure:nil];
        switch (indexPath.row) {
            case 0:
            {
                emailTextField = cell.textField;
                [cell.textField setPlaceholder:@"Your email"];
                [cell.textField setText:currentUser.email];
                break;
            }
            case 1:
            {
                firstNameTextField = cell.textField;
                [cell.textField setPlaceholder:@"Your first name"];
                [cell.textField setText:currentUser.firstName];
                break;
            }
            case 2:
            {
                lastNameTextField = cell.textField;
                [cell.textField setPlaceholder:@"Your last name"];
                [cell.textField setText:currentUser.lastName];
                break;
            }
            default:
                break;
        }
        [emailTextField setTextColor:textColor];
        [firstNameTextField setTextColor:textColor];
        [lastNameTextField setTextColor:textColor];
        cell.textField.delegate = self;
        return cell;
    } else if (indexPath.section == 2) {
        if (indexPath.row == 0){
            static NSString *MyIdentifier = @"VersionCell";
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MyIdentifier];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            [cell.textLabel setText:@"Dark background"];
            [cell.textLabel setFont:[UIFont fontWithName:kSourceSansProRegular size:16]];
            backgroundThemeSwitch = [[UISwitch alloc] init];
            [backgroundThemeSwitch addTarget:self action:@selector(themeSwitch) forControlEvents:UIControlEventValueChanged];
            if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
                [backgroundThemeSwitch setOn:YES animated:NO];
            } else {
                [backgroundThemeSwitch setOn:NO animated:NO];
            }
            cell.accessoryView = backgroundThemeSwitch;
            [cell.textLabel setTextColor:textColor];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            return cell;
        } else {
            static NSString *MyIdentifier = @"VersionCell";
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MyIdentifier];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            [cell.textLabel setText:@"Story paging"];
            [cell.textLabel setFont:[UIFont fontWithName:kSourceSansProRegular size:16]];
            storyPagingSwitch = [[UISwitch alloc] init];
            [storyPagingSwitch addTarget:self action:@selector(pagingSwitch) forControlEvents:UIControlEventValueChanged];
            if ([[NSUserDefaults standardUserDefaults] boolForKey:kStoryPaging]){
                [storyPagingSwitch setOn:YES animated:NO];
            } else {
                [storyPagingSwitch setOn:NO animated:NO];
            }
            cell.accessoryView = storyPagingSwitch;
            [cell.textLabel setTextColor:textColor];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            return cell;
        }
        
    } else if (indexPath.section == 3) {
        static NSString *CellIdentifier = @"PushCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        cell.textLabel.numberOfLines = 0;
        [cell.textLabel setFont:[UIFont fontWithName:kSourceSansProRegular size:15]];
        [cell.textLabel setTextColor:textColor];
        switch (indexPath.row) {
            case 0:
                if (!pushSwitch) {
                    pushSwitch = [[UISwitch alloc] init];
                    [pushSwitch addTarget:self action:@selector(masterPushChanged) forControlEvents:UIControlEventValueChanged];
                }
                
                if (currentUser.pushPermissions) {
                    [pushSwitch setOn:YES animated:YES];
                } else {
                    [cell.textLabel setFont:[UIFont fontWithName:kSourceSansProLight size:15]];
                    [pushSwitch setOn:NO animated:YES];
                }
                cell.accessoryView = pushSwitch;
                [cell.textLabel setText:@"All push notifications"];
                break;
            case 1:
                if (!feedbackPushSwitch) {
                    feedbackPushSwitch = [[UISwitch alloc] init];
                    [feedbackPushSwitch addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
                }
                
                if (currentUser.pushFeedbacks) {

                    [feedbackPushSwitch setOn:YES animated:YES];
                } else {
                    [cell.textLabel setFont:[UIFont fontWithName:kSourceSansProLight size:15]];
                    [feedbackPushSwitch setOn:NO animated:YES];
                }
                cell.accessoryView = feedbackPushSwitch;
                [cell.textLabel setText:@"Feedback"];
                break;
            case 2:
                if (!circlePublishPushSwitch) {
                    circlePublishPushSwitch = [[UISwitch alloc] init];
                    [circlePublishPushSwitch addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
                }
                if (currentUser.pushCirclePublish) {
                    [circlePublishPushSwitch setOn:YES animated:YES];
                
                } else {
                    [cell.textLabel setFont:[UIFont fontWithName:kSourceSansProLight size:15]];
                    [circlePublishPushSwitch setOn:NO animated:YES];
                }
                cell.accessoryView = circlePublishPushSwitch;
                [cell.textLabel setText:@"Published to writing circle"];
                break;
            case 3:
                if (!subscriptionPushSwitch) {
                    subscriptionPushSwitch = [[UISwitch alloc] init];
                    [subscriptionPushSwitch addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
                }
                
                if (currentUser.pushSubscribe) {
                    [subscriptionPushSwitch setOn:YES animated:YES];
                } else {
                    [cell.textLabel setFont:[UIFont fontWithName:kSourceSansProLight size:15]];
                    [subscriptionPushSwitch setOn:NO animated:YES];
                }
                
                cell.accessoryView = subscriptionPushSwitch;
                [cell.textLabel setText:@"Subscribed to you"];
                break;
            case 4:
                if (!invitationsPushSwitch) {
                    invitationsPushSwitch = [[UISwitch alloc] init];
                    [invitationsPushSwitch addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
                }
                if (currentUser.pushInvitations) {
                    [invitationsPushSwitch setOn:YES animated:YES];
                } else {
                    [cell.textLabel setFont:[UIFont fontWithName:kSourceSansProLight size:15]];
                    [invitationsPushSwitch setOn:NO animated:YES];
                }
                
                cell.accessoryView = invitationsPushSwitch;
                [cell.textLabel setText:@"Invitations to contribute"];
                break;
            case 5:
                if (!bookmarkPushSwitch) {
                    bookmarkPushSwitch = [[UISwitch alloc] init];
                    [bookmarkPushSwitch addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
                }
                
                if (currentUser.pushBookmarks) {
                    [bookmarkPushSwitch setOn:YES animated:YES];
                } else {
                    [cell.textLabel setFont:[UIFont fontWithName:kSourceSansProLight size:15]];
                    [bookmarkPushSwitch setOn:NO animated:YES];
                }
                
                cell.accessoryView = bookmarkPushSwitch;
                [cell.textLabel setText:@"When your stories get bookmarked"];

                break;
                
            default:
                break;
        }
        return cell;
    } else {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"VersionCell"];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        [cell.textLabel setText:@"Send us feedback"];
        [cell.textLabel setFont:[UIFont fontWithName:kSourceSansProRegular size:16]];
        [cell.textLabel setTextColor:textColor];
        return cell;
    }
}

- (void)masterPushChanged {
    if (pushSwitch.isOn){
        [pushSwitch setOn:YES animated:YES];
        [self.tableView performSelector:@selector(reloadData) withObject:nil afterDelay:.25];
    } else {
        [pushSwitch setOn:NO animated:YES];
        [invitationsPushSwitch setOn:NO animated:YES];
        [feedbackPushSwitch setOn:NO animated:YES];
        [dailyPushSwitch setOn:NO animated:YES];
        [circlePublishPushSwitch setOn:NO animated:YES];
        [bookmarkPushSwitch setOn:NO animated:YES];
        [subscriptionPushSwitch setOn:NO animated:YES];
    }
}

- (void)switchChanged:(UISwitch*)theSwitch {
    if (theSwitch == pushSwitch){
        currentUser.pushPermissions = theSwitch.isOn;
    } else if (theSwitch == bookmarkPushSwitch) {
        currentUser.pushBookmarks = theSwitch.isOn;
    } else if (theSwitch == subscriptionPushSwitch) {
        currentUser.pushSubscribe = theSwitch.isOn;
    } else if (theSwitch == invitationsPushSwitch) {
        currentUser.pushInvitations = theSwitch.isOn;
    } else if (theSwitch == circlePublishPushSwitch) {
        currentUser.pushCirclePublish = theSwitch.isOn;
    } else if (theSwitch == dailyPushSwitch) {
        currentUser.pushDaily = theSwitch.isOn;
    } else if (theSwitch == feedbackPushSwitch) {
        currentUser.pushFeedbacks = theSwitch.isOn;
    }
    [self.tableView performSelector:@selector(reloadData) withObject:nil afterDelay:.25];
}

- (void)pagingSwitch {
    [[NSUserDefaults standardUserDefaults] setBool:![[NSUserDefaults standardUserDefaults] boolForKey:kStoryPaging] forKey:kStoryPaging];
}

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIToolbar *backgroundToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, screen.size.width, 32)];
    backgroundToolbar.clipsToBounds = YES;
    backgroundToolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    UILabel *headerLabel = [[UILabel alloc] init];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
        [backgroundToolbar setBarStyle:UIBarStyleBlackTranslucent];
        [headerLabel setTextColor:textColor];
    } else {
        [backgroundToolbar setBarStyle:UIBarStyleDefault];
        [backgroundToolbar setBackgroundColor:[UIColor colorWithWhite:0 alpha:.025]];
        [headerLabel setTextColor:[UIColor lightGrayColor]];
    }
    
    if (IDIOM == IPAD){
        [headerLabel setFont:[UIFont fontWithName:kSourceSansProLight size:18]];
    } else {
        [headerLabel setFont:[UIFont fontWithName:kSourceSansProLight size:17]];
    }
    
    [headerLabel setTextAlignment:NSTextAlignmentCenter];
    switch (section) {
        case 0:
            [headerLabel setText:@"PUBLIC DETAILS"];
            break;
        case 1:
            [headerLabel setText:@"YOUR INFO (NOT PUBLIC)"];
            break;
        case 2:
            [headerLabel setText:@"PREFERENCES"];
            break;
        case 3:
            [headerLabel setText:@"NOTIFICATION PERMISSIONS"];
            break;
        case 4:
            [headerLabel setText:[NSString stringWithFormat:@"VERSION: %@", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]]];
            break;
        default:
            [headerLabel setText:@""];
            break;
    }
    [backgroundToolbar addSubview:headerLabel];
    [headerLabel setFrame:backgroundToolbar.frame];
    headerLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    return backgroundToolbar;
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if([indexPath row] == ((NSIndexPath*)[[tableView indexPathsForVisibleRows] lastObject]).row && tableView == self.tableView){
        //end of loading
        [ProgressHUD dismiss];
    }
    cell.backgroundColor = [UIColor clearColor];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 34;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 || indexPath.section == 1){
        return 50;
    } else {
        return 60;
    }
}

- (void)themeSwitch {
    NSShadow *clearShadow = [[NSShadow alloc] init];
    clearShadow.shadowColor = [UIColor clearColor];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kDarkBackground];
        [backgroundThemeSwitch setOn:NO animated:YES];
        [UIView animateWithDuration:UINavigationControllerHideShowBarDuration animations:^{
            [self.view setBackgroundColor:[UIColor whiteColor]];
        } completion:^(BOOL finished) {
        
        }];
        [self.navigationController.navigationBar setBarStyle:UIBarStyleDefault];
        
        [self.navigationController.navigationBar setTitleTextAttributes:@{
                                                                          NSForegroundColorAttributeName: [UIColor blackColor],
                                                                          NSFontAttributeName: [UIFont fontWithName:kSourceSansProSemibold size:23],
                                                                          NSShadowAttributeName: clearShadow,
                                                                          }];
        textColor = [UIColor blackColor];
        [self.navigationItem.leftBarButtonItem setTintColor:[UIColor blackColor]];
    } else {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kDarkBackground];
        [backgroundThemeSwitch setOn:YES animated:YES];
        [UIView animateWithDuration:UINavigationControllerHideShowBarDuration animations:^{
            [self.view setBackgroundColor:[UIColor clearColor]];
        } completion:^(BOOL finished) {
        }];
        [self.navigationController.navigationBar setBarStyle:UIBarStyleBlackTranslucent];
        [self.navigationController.navigationBar setTitleTextAttributes:@{
                                                                          NSForegroundColorAttributeName: [UIColor whiteColor],
                                                                          NSFontAttributeName: [UIFont fontWithName:kSourceSansProSemibold size:23],
                                                                          NSShadowAttributeName: clearShadow,
                                                                          }];
        [self.navigationItem.leftBarButtonItem setTintColor:[UIColor whiteColor]];
        textColor = [UIColor whiteColor];
    }
    [(XXAppDelegate*)[UIApplication sharedApplication].delegate switchBackgroundTheme];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 5)] withRowAnimation:UITableViewRowAnimationFade];
}

- (void)save {
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    if (pushSwitch.isOn){
        [parameters setObject:@YES forKey:@"user[push_permissions]"];
    } else {
        [parameters setObject:@NO forKey:@"user[push_permissions]"];
    }
    if (invitationsPushSwitch.isOn){
        [parameters setObject:@YES forKey:@"user[push_invitations]"];
    } else {
        [parameters setObject:@NO forKey:@"user[push_invitations]"];
    }
    if (bookmarkPushSwitch.isOn){
        [parameters setObject:@YES forKey:@"user[push_bookmarks]"];
    } else {
        [parameters setObject:@NO forKey:@"user[push_bookmarks]"];
    }
    if (subscriptionPushSwitch.isOn){
        [parameters setObject:@YES forKey:@"user[push_subscribe]"];
    } else {
        [parameters setObject:@NO forKey:@"user[push_subscribe]"];
    }
    if (circlePublishPushSwitch.isOn){
        [parameters setObject:@YES forKey:@"user[push_circle_publish]"];
    } else {
        [parameters setObject:@NO forKey:@"user[push_circle_publish]"];
    }
    if (contributionsPushSwitch.isOn){
        [parameters setObject:@YES forKey:@"user[push_contributions]"];
    } else {
        [parameters setObject:@NO forKey:@"user[push_contributions]"];
    }
    if (feedbackPushSwitch.isOn){
        [parameters setObject:@YES forKey:@"user[push_feedbacks]"];
    } else {
        [parameters setObject:@NO forKey:@"user[push_feedbacks]"];
    }
    
    if (penNameTextField.text.length){
        [parameters setObject:penNameTextField.text forKey:@"user[pen_name]"];
    }
    if (firstNameTextField.text.length){
        [parameters setObject:firstNameTextField.text forKey:@"user[first_name]"];
    }
    if (lastNameTextField.text.length){
        [parameters setObject:lastNameTextField.text forKey:@"user[last_name]"];
    }
    if (emailTextField.text.length){
        [parameters setObject:emailTextField.text forKey:@"user[email]"];
    }
    if (locationTextField.text.length){
        [parameters setObject:locationTextField.text forKey:@"user[location]"];
    }
    
    [manager PATCH:[NSString stringWithFormat:@"%@/users/%@",kAPIBaseUrl,[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"success updating user: %@",responseObject);
        currentUser = [[XXUser alloc] initWithDictionary:[responseObject objectForKey:@"user"]];
        [self synchronizeUserDefaults];
        [self.tableView reloadData];
        [[[UIAlertView alloc] initWithTitle:@"Word" message:@"We successfully updated your profile." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failure updating user: %@",error.description);
        [[[UIAlertView alloc] initWithTitle:@"Shoot" message:@"Something went wrong while updating your profile. Please try again soon." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    }];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 2){
        if (indexPath.row == 0){
            [self themeSwitch];
        } else if (indexPath.row == 1) {
            //[self pagingSwitch];
        }
    } else if (indexPath.section == 4){
        if (indexPath.row == 0){
            [self sendMail];
        }
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - MFMailComposeViewControllerDelegate Methods

- (void)sendMail {

    if ([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController* controller = [[MFMailComposeViewController alloc] init];
        controller.navigationBar.barStyle = UIBarStyleBlack;
        controller.mailComposeDelegate = self;
        [controller setSubject:@"Verses Feedback"];
        [controller setToRecipients:@[kFeedbackEmail]];
        if (controller) [self presentViewController:controller animated:YES completion:nil];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Sorry" message:@"But we weren't able to send mail on this device." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil];
        [alert show];
    }

}
- (void)mailComposeController:(MFMailComposeViewController*)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError*)error;
{
    if (result == MFMailComposeResultSent) {}
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)back {
    [[(XXAppDelegate*)[UIApplication sharedApplication].delegate dynamicsDrawerViewController] setPaneState:MSDynamicsDrawerPaneStateOpen inDirection:MSDynamicsDrawerDirectionLeft animated:YES allowUserInterruption:YES completion:^{
        
    }];
}

- (IBAction)logout {
    UIStoryboard *storyboard;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone){
        storyboard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle:nil];
    } else {
        storyboard = [UIStoryboard storyboardWithName:@"Main_iPad" bundle:nil];
    }
    NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];
    [NSUserDefaults resetStandardUserDefaults];
    
    XXWelcomeViewController *welcomeVC = [storyboard instantiateViewControllerWithIdentifier:@"Welcome"];
    [self.navigationController pushViewController:welcomeVC animated:YES];
    [welcomeVC loadEtherStories];
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [UIView animateWithDuration:.15 animations:^{
        [self.tableView setAlpha:0.0];
    }];
}
#pragma mark - Navigation




@end

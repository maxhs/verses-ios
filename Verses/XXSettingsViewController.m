//
//  XXSettingsViewController.m
//  Verses
//
//  Created by Max Haines-Stiles on 11/4/13.
//  Copyright (c) 2013 Verses. All rights reserved.
//

#import "XXSettingsViewController.h"
#import "User+helper.h"
#import "XXStoriesViewController.h"
#import "XXSettingsCell.h"
#import "XXAppDelegate.h"
#import <MessageUI/MessageUI.h>
#import "XXLoginController.h"
#import <SDWebImage/UIButton+WebCache.h>
#import "XXAlert.h"
#import "XXGuideViewController.h"
#import "XXGuideInteractor.h"
#import "XXSettingsBackgroundCell.h"

@interface XXSettingsViewController () <UITextFieldDelegate,UITextViewDelegate, MFMailComposeViewControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIActionSheetDelegate, UIViewControllerTransitioningDelegate> {
    UIBarButtonItem *doneButton;
    UIBarButtonItem *saveButton;
    AFHTTPRequestOperationManager *manager;
    UISwitch *pushSwitch;
    UISwitch *feedbackPushSwitch;
    UISwitch *circlePublishPushSwitch;
    UISwitch *circleCommentsPushSwitch;
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
    User *currentUser;
    UIBarButtonItem *guideButton;
    UIColor *textColor;
    UIImageView *navBarShadowView;
    UISwitch *backgroundThemeSwitch;
    UISwitch *storyPagingSwitch;
    BOOL avatar;
}

@end

@implementation XXSettingsViewController
@synthesize dynamicsDrawerViewController = _dynamicsDrawerViewController;

- (void)viewDidLoad
{
    [super viewDidLoad];
    manager = [(XXAppDelegate*)[UIApplication sharedApplication].delegate manager];
    saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(save)];
    doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneEditing)];
    guideButton = [[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"more"] style:UIBarButtonItemStylePlain target:self action:@selector(showGuide)];
    UIBarButtonItem *negativeRightButton = [[UIBarButtonItem alloc]
                                            initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
                                            target:nil action:nil];
    negativeRightButton.width = -14.f;
    self.navigationItem.rightBarButtonItems = @[negativeRightButton,guideButton];
    self.navigationItem.leftBarButtonItem = saveButton;
    [self.logoutButton.titleLabel setFont:[UIFont fontWithName:kSourceSansProSemibold size:16]];
    self.tableView.tableFooterView = self.logoutButton;
    screen = [UIScreen mainScreen].bounds;
    [self loadProfile];
    
    
    navBarShadowView = [Utilities findNavShadow:self.navigationController.navigationBar];
    
    if (![(XXAppDelegate*)[UIApplication sharedApplication].delegate currentUser]){
        currentUser = [User MR_findFirstByAttribute:@"identifier" withValue:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]];
    } else {
        currentUser = [(XXAppDelegate*)[UIApplication sharedApplication].delegate currentUser];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
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
    self.tableView.tableFooterView = self.logoutButton;
    [self.tableView setAlpha:1.0];
}

- (void)loadProfile {
    [manager GET:[NSString stringWithFormat:@"%@/users/%@/edit",kAPIBaseUrl,[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]] parameters:@{@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"success getting profile: %@",responseObject);
        [currentUser populateFromDict:[responseObject objectForKey:@"user"]];
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            //NSLog(@"current user: %@",currentUser);
            [self.tableView reloadData];
            [ProgressHUD dismiss];
        }];
        [self synchronizeUserDefaults];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (operation.response.statusCode == 401){
            XXLoginController *login = [[self storyboard] instantiateViewControllerWithIdentifier:@"Login"];
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
    [[NSUserDefaults standardUserDefaults] setObject:currentUser.picSmall forKey:kUserDefaultsPicSmall];
    [[NSUserDefaults standardUserDefaults] setObject:currentUser.location forKey:kUserDefaultsLocation];
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
    
    self.navigationItem.rightBarButtonItem = doneButton;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    self.navigationItem.rightBarButtonItem = guideButton;
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
            return 3;
            break;
        case 1:
            return 3;
            break;
        case 2:
            return 2;
            break;
        case 3:
            return 7;
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
        
        switch (indexPath.row) {
            case 0:
                [cell configure:nil];
                [cell.imageLabel setHidden:YES];
                [cell.imageButton setHidden:YES];
                [cell.textField setText:currentUser.penName];
                penNameTextField = cell.textField;
                [penNameTextField setPlaceholder:@"Your pen name"];
                penNameTextField.delegate = self;
                break;
            case 1:
                [cell configure:nil];
                [cell.imageLabel setHidden:YES];
                [cell.imageButton setHidden:YES];
                locationTextField = cell.textField;
                [cell.textField setPlaceholder:@"Where you're from"];
                [cell.textField setText:currentUser.location];
                [locationTextField setDelegate:self];
                break;
            case 2:
            {
                [cell configure:currentUser];
                [cell.imageLabel setHidden:NO];
                [cell.imageLabel setTextColor:textColor];
                [cell.imageButton setHidden:NO];
                [cell.textField setHidden:YES];
                if (currentUser.picSmall.length){
                    [cell.imageButton setImageWithURL:[NSURL URLWithString:currentUser.picSmall] forState:UIControlStateNormal completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
                       [UIView animateWithDuration:.23 animations:^{
                           [cell.imageButton setAlpha:1.0];
                       }];
                    }];
                } else if (currentUser.thumbImage) {
                    [cell.imageButton setImage:currentUser.thumbImage forState:UIControlStateNormal];
                    [UIView animateWithDuration:.23 animations:^{
                        [cell.imageButton setAlpha:1.0];
                    }];
                } else {
                    [cell.imageLabel setText:@"Your profile photo"];
                    [cell.imageButton setImage:nil forState:UIControlStateNormal];
                    [cell.imageButton setTitle:[currentUser.penName substringToIndex:2] forState:UIControlStateNormal];
                    [UIView animateWithDuration:.23 animations:^{
                        [cell.imageButton setAlpha:1.0];
                    }];
                }
            }
                break;
                
            default:
                break;
        }
        cell.textField.layer.rasterizationScale = [UIScreen mainScreen].scale;
        cell.textField.layer.shouldRasterize = YES;
        [penNameTextField setTextColor:textColor];
        [locationTextField setTextColor:textColor];
        return cell;
    } else if (indexPath.section == 1){
        XXSettingsCell *cell = (XXSettingsCell *)[tableView dequeueReusableCellWithIdentifier:@"SettingsCell"];
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"XXSettingsCell" owner:nil options:nil] lastObject];
        }
        [cell configure:currentUser];
        switch (indexPath.row) {
            case 0:
            {
                [cell.imageLabel setHidden:YES];
                [cell.imageButton setHidden:YES];
                [cell.textField setHidden:NO];
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
            XXSettingsBackgroundCell *cell = (XXSettingsBackgroundCell *)[tableView dequeueReusableCellWithIdentifier:@"SettingsBackgroundCell"];
            if (cell == nil) {
                cell = [[[NSBundle mainBundle] loadNibNamed:@"XXSettingsBackgroundCell" owner:nil options:nil] lastObject];
            }
            NSLog(@"user background image: %@",currentUser.backgroundImageView);
            if (currentUser.backgroundImageView){
                cell.backgroundImageView = currentUser.backgroundImageView;
                [cell.backgroundImageView setHidden:NO];
                NSLog(@"cell background image view: %@",cell.backgroundImageView);
                [cell.backgroundImageViewLabel setHidden:YES];
            } else {
                [cell.backgroundImageViewLabel setHidden:NO];
                [cell.backgroundImageView setHidden:YES];
                [cell.backgroundImageViewLabel setText:@"Set your background image"];
                [cell.backgroundImageViewLabel setFont:[UIFont fontWithName:kSourceSansProRegular size:16]];
                [cell.backgroundImageViewLabel setTextColor:textColor];
            }
            
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
                
                if ([currentUser.pushPermissions isEqualToNumber:[NSNumber numberWithBool:YES]]) {
                    [pushSwitch setOn:YES animated:YES];
                } else {
                    [cell.textLabel setFont:[UIFont fontWithName:kSourceSansProLight size:15]];
                    [pushSwitch setOn:NO animated:YES];
                }
                cell.accessoryView = pushSwitch;
                [cell.textLabel setText:@"All push notifications"];
                break;
            case 1:
                if (!circleCommentsPushSwitch) {
                    circleCommentsPushSwitch = [[UISwitch alloc] init];
                    [circleCommentsPushSwitch addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
                }
                
                if ([currentUser.pushCircleComments isEqualToNumber:[NSNumber numberWithBool:YES]]) {
                    [circleCommentsPushSwitch setOn:YES animated:YES];
                } else {
                    [cell.textLabel setFont:[UIFont fontWithName:kSourceSansProLight size:15]];
                    [circleCommentsPushSwitch setOn:NO animated:YES];
                }
                cell.accessoryView = circleCommentsPushSwitch;
                [cell.textLabel setText:@"Writing circle comments"];
                break;
            case 2:
                if (!feedbackPushSwitch) {
                    feedbackPushSwitch = [[UISwitch alloc] init];
                    [feedbackPushSwitch addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
                }
                
                if ([currentUser.pushFeedbacks isEqualToNumber:[NSNumber numberWithBool:YES]]) {
                    
                    [feedbackPushSwitch setOn:YES animated:YES];
                } else {
                    [cell.textLabel setFont:[UIFont fontWithName:kSourceSansProLight size:15]];
                    [feedbackPushSwitch setOn:NO animated:YES];
                }
                cell.accessoryView = feedbackPushSwitch;
                [cell.textLabel setText:@"Receive feedback"];
                break;
            case 3:
                if (!circlePublishPushSwitch) {
                    circlePublishPushSwitch = [[UISwitch alloc] init];
                    [circlePublishPushSwitch addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
                }
                if ([currentUser.pushCirclePublish isEqualToNumber:[NSNumber numberWithBool:YES]]) {
                    [circlePublishPushSwitch setOn:YES animated:YES];
                
                } else {
                    [cell.textLabel setFont:[UIFont fontWithName:kSourceSansProLight size:15]];
                    [circlePublishPushSwitch setOn:NO animated:YES];
                }
                cell.accessoryView = circlePublishPushSwitch;
                [cell.textLabel setText:@"New writing circle stories"];
                break;
            case 4:
                if (!subscriptionPushSwitch) {
                    subscriptionPushSwitch = [[UISwitch alloc] init];
                    [subscriptionPushSwitch addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
                }
                
                if ([currentUser.pushSubscribe isEqualToNumber:[NSNumber numberWithBool:YES]]) {
                    [subscriptionPushSwitch setOn:YES animated:YES];
                } else {
                    [cell.textLabel setFont:[UIFont fontWithName:kSourceSansProLight size:15]];
                    [subscriptionPushSwitch setOn:NO animated:YES];
                }
                
                cell.accessoryView = subscriptionPushSwitch;
                [cell.textLabel setText:@"Someone subscribes to you"];
                break;
            case 5:
                if (!invitationsPushSwitch) {
                    invitationsPushSwitch = [[UISwitch alloc] init];
                    [invitationsPushSwitch addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
                }
                if ([currentUser.pushInvitations isEqualToNumber:[NSNumber numberWithBool:YES]]) {
                    [invitationsPushSwitch setOn:YES animated:YES];
                } else {
                    [cell.textLabel setFont:[UIFont fontWithName:kSourceSansProLight size:15]];
                    [invitationsPushSwitch setOn:NO animated:YES];
                }
                
                cell.accessoryView = invitationsPushSwitch;
                [cell.textLabel setText:@"Invitations to contribute"];
                break;
            case 6:
                if (!bookmarkPushSwitch) {
                    bookmarkPushSwitch = [[UISwitch alloc] init];
                    [bookmarkPushSwitch addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
                }
                
                if ([currentUser.pushBookmarks isEqualToNumber:[NSNumber numberWithBool:YES]]) {
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
        cell.accessoryView = nil;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        [cell.textLabel setText:@"Send us feedback"];
        [cell.textLabel setFont:[UIFont fontWithName:kSourceSansProRegular size:16]];
        [cell.textLabel setTextColor:textColor];
        return cell;
    }
}

- (void)masterPushChanged {
    if (pushSwitch.isOn){
        [currentUser setPushPermissions:[NSNumber numberWithBool:YES]];
        [currentUser setPushDaily: [NSNumber numberWithBool:YES]];
        currentUser.pushCirclePublish = [NSNumber numberWithBool:YES];
        currentUser.pushBookmarks = [NSNumber numberWithBool:YES];
        currentUser.pushFeedbacks = [NSNumber numberWithBool:YES];
        currentUser.pushSubscribe = [NSNumber numberWithBool:YES];
        currentUser.pushInvitations = [NSNumber numberWithBool:YES];
        currentUser.pushCircleComments = [NSNumber numberWithBool:YES];
    } else {
        currentUser.pushPermissions = [NSNumber numberWithBool:NO];
        currentUser.pushDaily = [NSNumber numberWithBool:NO];
        currentUser.pushCirclePublish = [NSNumber numberWithBool:NO];
        currentUser.pushBookmarks = [NSNumber numberWithBool:NO];
        currentUser.pushFeedbacks = [NSNumber numberWithBool:NO];
        currentUser.pushSubscribe = [NSNumber numberWithBool:NO];
        currentUser.pushInvitations = [NSNumber numberWithBool:NO];
        currentUser.pushCircleComments = [NSNumber numberWithBool:NO];
    }
    [self.tableView performSelector:@selector(reloadData) withObject:nil afterDelay:.25];
}

- (void)switchChanged:(UISwitch*)theSwitch {
    if (theSwitch == pushSwitch){
        currentUser.pushPermissions = [NSNumber numberWithBool:theSwitch.isOn];
    } else if (theSwitch == bookmarkPushSwitch) {
        currentUser.pushBookmarks = [NSNumber numberWithBool:theSwitch.isOn];
    } else if (theSwitch == subscriptionPushSwitch) {
        currentUser.pushSubscribe = [NSNumber numberWithBool:theSwitch.isOn];
    } else if (theSwitch == invitationsPushSwitch) {
        currentUser.pushInvitations = [NSNumber numberWithBool:theSwitch.isOn];
    } else if (theSwitch == circlePublishPushSwitch) {
        currentUser.pushCirclePublish = [NSNumber numberWithBool:theSwitch.isOn];
    } else if (theSwitch == dailyPushSwitch) {
        currentUser.pushDaily = [NSNumber numberWithBool:theSwitch.isOn];
    } else if (theSwitch == feedbackPushSwitch) {
        currentUser.pushFeedbacks = [NSNumber numberWithBool:theSwitch.isOn];
    } else if (theSwitch == circleCommentsPushSwitch) {
        currentUser.pushCircleComments = [NSNumber numberWithBool:theSwitch.isOn];
    }
    [self.tableView performSelector:@selector(reloadData) withObject:nil afterDelay:.25];
}

- (void)pagingSwitch {
    [[NSUserDefaults standardUserDefaults] setBool:![[NSUserDefaults standardUserDefaults] boolForKey:kStoryPaging] forKey:kStoryPaging];
}

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIToolbar *backgroundToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, screen.size.width, 44)];
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
        [headerLabel setFont:[UIFont fontWithName:kSourceSansProRegular size:14]];
    } else {
        [headerLabel setFont:[UIFont fontWithName:kSourceSansProRegular size:13]];
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
            [headerLabel setTextColor:[UIColor lightGrayColor]];
            [headerLabel setFont:[UIFont fontWithName:kSourceSansProRegular size:15]];
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
    return 44;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 || indexPath.section == 1){
        return 50;
    } else if (indexPath.section == 2 && indexPath.row == 1) {
        return 100;
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
        [self.navigationItem.rightBarButtonItem setTintColor:[UIColor blackColor]];
        textColor = [UIColor blackColor];
    } else {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kDarkBackground];
        [backgroundThemeSwitch setOn:YES animated:YES];
        [UIView animateWithDuration:UINavigationControllerHideShowBarDuration animations:^{
            [self.view setBackgroundColor:[UIColor clearColor]];
        } completion:^(BOOL finished) {
        }];
        [self.navigationController.navigationBar setBarStyle:UIBarStyleBlackTranslucent];
        [self.navigationItem.rightBarButtonItem setTintColor:[UIColor whiteColor]];
        textColor = [UIColor whiteColor];
    }
    [(XXAppDelegate*)[UIApplication sharedApplication].delegate switchBackgroundTheme];
    //[self.tableView reloadData];
    
    [self.tableView beginUpdates];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 5)] withRowAnimation:UITableViewRowAnimationFade];
    [self.tableView endUpdates];
}

- (void)save {
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    if (pushSwitch.isOn){
        [parameters setObject:@YES forKey:@"push_permissions"];
    } else {
        [parameters setObject:@NO forKey:@"push_permissions"];
    }
    if (invitationsPushSwitch.isOn){
        [parameters setObject:@YES forKey:@"push_invitations"];
    } else {
        [parameters setObject:@NO forKey:@"push_invitations"];
    }
    if (bookmarkPushSwitch.isOn){
        [parameters setObject:@YES forKey:@"push_bookmarks"];
    } else {
        [parameters setObject:@NO forKey:@"push_bookmarks"];
    }
    if (subscriptionPushSwitch.isOn){
        [parameters setObject:@YES forKey:@"push_subscribe"];
    } else {
        [parameters setObject:@NO forKey:@"push_subscribe"];
    }
    if (circlePublishPushSwitch.isOn){
        [parameters setObject:@YES forKey:@"push_circle_publish"];
    } else {
        [parameters setObject:@NO forKey:@"push_circle_publish"];
    }
    /*if (contributionsPushSwitch.isOn){
        [parameters setObject:@YES forKey:@"push_contributions"];
    } else {
        [parameters setObject:@NO forKey:@"push_contributions"];
    }*/
    if (feedbackPushSwitch.isOn){
        [parameters setObject:@YES forKey:@"push_feedbacks"];
    } else {
        [parameters setObject:@NO forKey:@"push_feedbacks"];
    }
    if (circleCommentsPushSwitch.isOn){
        [parameters setObject:@YES forKey:@"push_circle_comments"];
    } else {
        [parameters setObject:@NO forKey:@"push_circle_comments"];
    }
    
    if (penNameTextField.text.length){
        [parameters setObject:penNameTextField.text forKey:@"pen_name"];
    }
    if (firstNameTextField.text.length){
        [parameters setObject:firstNameTextField.text forKey:@"first_name"];
    }
    if (lastNameTextField.text.length){
        [parameters setObject:lastNameTextField.text forKey:@"last_name"];
    }
    if (emailTextField.text.length){
        [parameters setObject:emailTextField.text forKey:@"email"];
    }
    if (locationTextField.text.length){
        [parameters setObject:locationTextField.text forKey:@"location"];
    }
    
    [manager PATCH:[NSString stringWithFormat:@"%@/users/%@",kAPIBaseUrl,[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]] parameters:@{@"user":parameters} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"success updating user: %@",responseObject);
        [currentUser populateFromDict:[responseObject objectForKey:@"user"]];
        [self synchronizeUserDefaults];
        [self.tableView reloadData];
        [XXAlert show:@"Profile updated" withTime:2.7f];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        //NSLog(@"Failure updating user: %@",error.description);
        if (operation.response.statusCode == 401) {
            if ([operation.responseString isEqualToString:@"Pen name taken"]) {
                
                [XXAlert show:@"Sorry, but that pen name has already been taken." withTime:2.7f];
                //[self addShakeAnimationForView:self.registerPenNameTextField withDuration:.77];
            }
        } else {
            [[[UIAlertView alloc] initWithTitle:@"Shoot" message:@"Something went wrong while updating your profile. Please try again soon." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        }
    }];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 && indexPath.row == 2){
        avatar = YES;
        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]){
            if (currentUser.thumbImage || currentUser.picSmall){
                [[[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Remove Photo" otherButtonTitles:@"Take Photo",@"Pick from Photo Library", nil] showInView:self.view];
            } else {
                [[[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Take Photo",@"Pick from Photo Library", nil] showInView:self.view];
            }
        } else {
            [self choosePhoto];
        }
    } else if (indexPath.section == 2){
        if (indexPath.row == 0){
            [self themeSwitch];
        } else if (indexPath.row == 1) {
            avatar = NO;
            if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]){
                if (currentUser.thumbImage || currentUser.picSmall){
                    [[[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Remove Photo" otherButtonTitles:@"Take Photo",@"Pick from Photo Library", nil] showInView:self.view];
                } else {
                    [[[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Take Photo",@"Pick from Photo Library", nil] showInView:self.view];
                }
            } else {
                [self choosePhoto];
            }
        }
    } else if (indexPath.section == 4){
        if (indexPath.row == 0){
            [self sendMail];
        }
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Take Photo"]){
        [self takePhoto];
    } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Pick from Photo Library"]){
        [self choosePhoto];
    } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Remove Photo"]){
        [self removePhoto];
    }
}

- (void)removePhoto {
    [ProgressHUD show:@"Removing photo..."];
    [[SDImageCache sharedImageCache] removeImageForKey:currentUser.picSmall fromDisk:YES];
    [manager POST:[NSString stringWithFormat:@"%@/users/%@/remove_photo",kAPIBaseUrl,currentUser.identifier] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [ProgressHUD dismiss];
        currentUser.thumbImage = nil;
        currentUser.picSmall = @"";
        [[NSUserDefaults standardUserDefaults] setObject:nil forKey:kUserDefaultsPicSmall];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:2 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
        NSLog(@"Success removing photo");
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failed to remove profile photo: %@",error.description);
        [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Something went wrong while trying to delete your photo. Please try again soon." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    }];
}

- (void)choosePhoto {
    UIImagePickerController *vc = [[UIImagePickerController alloc] init];
    [vc setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
    [vc setDelegate:self];
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)takePhoto {
    UIImagePickerController *vc = [[UIImagePickerController alloc] init];
    [vc setSourceType:UIImagePickerControllerSourceTypeCamera];
    [vc setDelegate:self];
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [picker dismissViewControllerAnimated:YES completion:nil];
    if (avatar){
        [currentUser setThumbImage:[info objectForKey:UIImagePickerControllerOriginalImage]];
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:2 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
        [self uploadUserImage:currentUser.thumbImage];
    } else {
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        imageView.clipsToBounds = YES;
        [imageView setContentMode:UIViewContentModeScaleAspectFill];
        [imageView setImage:[info objectForKey:UIImagePickerControllerOriginalImage]];
        [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
            User *theUser = [currentUser MR_inContext:localContext];
            [theUser setBackgroundImageView:imageView];
        } completion:^(BOOL success, NSError *error) {
            NSLog(@"any success? %u",success);
            [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:2]] withRowAnimation:UITableViewRowAnimationFade];
        }];
    }
}

- (void)uploadUserImage:(UIImage*)image {
    NSData *imageData = UIImageJPEGRepresentation(image, 1);
    [manager POST:[NSString stringWithFormat:@"%@/users/%@/add_photo",kAPIBaseUrl,currentUser.identifier] parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        [formData appendPartWithFileData:imageData name:@"photo" fileName:@"photo.jpg" mimeType:@"image/jpg"];
    } success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Success uploading user profile image: %@",responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failure posting user profile image: %@",error.description);
    }];
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
    NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];
    [NSUserDefaults resetStandardUserDefaults];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kExistingUser];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [[[SDWebImageManager sharedManager] imageCache] clearDisk];
    //re-fetch the user's push credentials
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound)];
    XXStoriesViewController *welcomeVC = [[self storyboard] instantiateViewControllerWithIdentifier:@"Stories"];
    welcomeVC.ether = YES;
    [self.navigationController pushViewController:welcomeVC animated:YES];
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

- (void)showGuide {
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

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [UIView animateWithDuration:.15 animations:^{
        [self.tableView setAlpha:0.0];
    }];
}
#pragma mark - Navigation




@end

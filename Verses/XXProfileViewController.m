//
//  XXProfileViewController.m
//  Verses
//
//  Created by Max Haines-Stiles on 4/14/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import "XXProfileViewController.h"
#import "XXProfileCell.h"
#import "XXProfileStoryCell.h"
#import <SDWebImage/UIButton+WebCache.h>
#import "XXStoryViewController.h"
#import "XXLoginController.h"
#import "XXStoriesViewController.h"

@interface XXProfileViewController () {
    AFHTTPRequestOperationManager *manager;
    UIColor *textColor;
    UIBarButtonItem *backButton;
    //UIImageView *navBarShadowView;
    NSDateFormatter *_dateFormatter;
    UIImageView *userBlurredBackground;
    UIView *profileCellContentView;
    XXAppDelegate *delegate;
}

@end

@implementation XXProfileViewController

@synthesize user = _user;
@synthesize userId = _userId;

- (void)viewDidLoad
{
    [super viewDidLoad];
    delegate = (XXAppDelegate*)[UIApplication sharedApplication].delegate;
    manager = [delegate manager];
    if (_user){
        [self loadUserDetails:_user.identifier];
    } else if (_userId) {
        [self loadUserDetails:_userId];
    }
    [self.tableView setSeparatorColor:[UIColor colorWithWhite:1 alpha:0]];
    
    _dateFormatter = [[NSDateFormatter alloc] init];
    [_dateFormatter setLocale:[NSLocale currentLocale]];
    [_dateFormatter setDateFormat:@"MMM, d  |  h:mm a"];
    //navBarShadowView = [Utilities findNavShadow:self.navigationController.navigationBar];
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.shadowImage = [UIImage new];
    self.navigationController.navigationBar.translucent = YES;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showLogin) name:@"ShowLogin" object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    [self setNeedsStatusBarAppearanceUpdate];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
        [self.view setBackgroundColor:[UIColor clearColor]];
        textColor = [UIColor whiteColor];
        backButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"blackX"] style:UIBarButtonItemStylePlain target:self action:@selector(back)];
        [backButton setTintColor:[UIColor whiteColor]];
    } else {
        [self.view setBackgroundColor:[UIColor whiteColor]];
        textColor = [UIColor blackColor];
        backButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"blackX"] style:UIBarButtonItemStylePlain target:self action:@selector(back)];
    }
    self.navigationItem.leftBarButtonItem = backButton;
    //navBarShadowView.hidden = YES;
    if (self.tableView.alpha != 1.0){
        [UIView animateWithDuration:.23 animations:^{
            [self.tableView setAlpha:1.0];
            self.tableView.transform = CGAffineTransformIdentity;
        }];
    }
}

- (void)showLogin {
    XXLoginController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Login"];
    [self presentViewController:vc animated:YES completion:^{
        
    }];
}

- (void)back {
    MSDynamicsDrawerViewController *drawerView = [delegate dynamicsDrawerViewController];
    if ([[(UINavigationController*)drawerView.paneViewController viewControllers] firstObject] == self){
        [[delegate dynamicsDrawerViewController] setPaneState:MSDynamicsDrawerPaneStateOpen inDirection:MSDynamicsDrawerDirectionLeft animated:YES allowUserInterruption:NO completion:nil];
    } else {
        [self dismissViewControllerAnimated:YES completion:^{
            
        }];
    }
}

- (void)loadUserDetails:(NSNumber*)identifier {
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
        [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"user_id"];
    }
    [manager GET:[NSString stringWithFormat:@"%@/users/%@",kAPIBaseUrl,identifier] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (_user){
            [_user populateFromDict:[responseObject objectForKey:@"user"]];
        } else {
            _user = [User MR_findFirstByAttribute:@"identifier" withValue:[[responseObject objectForKey:@"user"] objectForKey:@"id"]];
            if (!_user){
                _user = [User MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [_user populateFromDict:[responseObject objectForKey:@"user"]];
        }
        
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            if (self.tableView.numberOfSections){
                [self.tableView beginUpdates];
                [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];
                [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationFade];
                [self.tableView endUpdates];
            } else {
                [self.tableView reloadData];
            }
        }];
    
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Something went wrong while trying to load this profile. Please try again soon." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        NSLog(@"Failed to get user details: %@",error.description);
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
    if (_user) return 2;
    else return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0){
        return 1;
    } else {
        if (_user.stories.count){
            return _user.stories.count;
        } else {
            return 1;
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0){
        XXProfileCell *cell = (XXProfileCell *)[tableView dequeueReusableCellWithIdentifier:@"ProfileCell"];
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"XXProfileCell" owner:nil options:nil] lastObject];
        }
        cell.imageButton.imageView.layer.cornerRadius = cell.imageButton.frame.size.height/2;
        cell.imageButton.layer.backgroundColor = [UIColor clearColor].CGColor;
        cell.imageButton.backgroundColor = [UIColor clearColor];
        [cell.locationLabel setTextColor:textColor];
        [cell configureForUser:_user];
        userBlurredBackground = cell.blurredBackground;
        profileCellContentView = cell.contentView;
        
        if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
            [cell.nameLabel setTextColor:[UIColor whiteColor]];
            [cell.dayJobLabel setTextColor:[UIColor whiteColor]];
            [cell.locationLabel setTextColor:[UIColor whiteColor]];
            [cell.bioLabel setTextColor:[UIColor whiteColor]];
        } else {
            [cell.dayJobLabel setTextColor:[UIColor blackColor]];
            [cell.locationLabel setTextColor:[UIColor blackColor]];
            [cell.nameLabel setTextColor:[UIColor blackColor]];
            [cell.bioLabel setTextColor:[UIColor blackColor]];
        }
        
        return cell;
    } else {
        XXProfileStoryCell *cell = (XXProfileStoryCell *)[tableView dequeueReusableCellWithIdentifier:@"ProfileStoryCell"];
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"XXProfileStoryCell" owner:nil options:nil] lastObject];
        }
        if (_user.stories.count){
            Story *story = [_user.stories objectAtIndex:indexPath.row];
            [cell configureStory:story withTextColor:textColor];
            [cell.subtitleLabel setText:[_dateFormatter stringFromDate:story.updatedDate]];
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        } else {
            [cell.textLabel setText:@"No published stories"];
            if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
                [cell.textLabel setTextColor:[UIColor whiteColor]];
            } else {
                [cell.textLabel setTextColor:[UIColor lightGrayColor]];
            }
            [cell.textLabel setFont:[UIFont fontWithName:kSourceSansProItalic size:15]];
            [cell.textLabel setTextAlignment:NSTextAlignmentCenter];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        return cell;
    }
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if([indexPath row] == ((NSIndexPath*)[[tableView indexPathsForVisibleRows] lastObject]).row && tableView == self.tableView){
        //end of loading
        [ProgressHUD dismiss];
    }
    cell.backgroundColor = [UIColor clearColor];
    UIView *selectedView = [[UIView alloc] initWithFrame:cell.frame];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
        [selectedView setBackgroundColor:kTableViewCellSelectionColorDark];
    } else {
        [selectedView setBackgroundColor:kTableViewCellSelectionColor];
    }
    
    cell.selectedBackgroundView = selectedView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0){
        if (IDIOM == IPAD){
            return screenHeight()/3;
        } else {
            return screenHeight()/2;
        }
        
    } else if (indexPath.section == 1){
        return 80;
    } else {
        return 44;
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat y = scrollView.contentOffset.y;
    if (y <= 0){
        CGRect profileFrame = profileCellContentView.frame;
        profileFrame.origin.y = y;
        [profileCellContentView setFrame:profileFrame];
        CGFloat alpha = (1+y/screenHeight());
        [userBlurredBackground setAlpha:alpha];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 1){
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        if (_user.stories.count){
            Story *story = [_user.stories objectAtIndex:indexPath.row];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ResetStory" object:nil userInfo:@{@"story":story}];
            [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
            
            if (IDIOM == IPAD){
                [ProgressHUD show:@"Fetching story..."];
                _storyInfoVc.story = story;
                [_storyInfoVc.popover dismissPopoverAnimated:YES];
                [[delegate dynamicsDrawerViewController] setPaneState:MSDynamicsDrawerPaneStateClosed animated:YES allowUserInterruption:YES completion:^{
                    
                }];
            } else {
                XXStoriesViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Stories"];
                [vc setEther:YES];
                XXStoryViewController *storyVC = [[self storyboard] instantiateViewControllerWithIdentifier:@"Story"];
                [storyVC setStoryId:story.identifier];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"ReloadStoryInfo" object:nil userInfo:@{@"story":story}];
                UINavigationController *nav = [[UINavigationController alloc] init];
                nav.viewControllers = @[vc,storyVC];
                [[delegate dynamicsDrawerViewController] setPaneViewController:nav];
                
                if ([self.presentingViewController isKindOfClass:[MSDynamicsDrawerViewController class]]){
                    [[delegate dynamicsDrawerViewController] setPaneState:MSDynamicsDrawerPaneStateClosed animated:NO allowUserInterruption:NO completion:^{
                        [self dismissViewControllerAnimated:YES completion:nil];
                    }];
                } else if ([self.presentingViewController isKindOfClass:[UINavigationController class]] && [(UINavigationController*)self.presentingViewController viewControllers]) {
                    [self.presentingViewController.presentingViewController dismissViewControllerAnimated:YES completion:^{
                        
                    }];
                }
            }
        }
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(NSIndexPath*)indexPath {
    [super prepareForSegue:segue sender:indexPath];
    
    if ([segue.identifier isEqualToString:@"Read"]){
        XXStoryViewController *storyVC = [segue destinationViewController];
        Story *story = [_user.stories objectAtIndex:indexPath.row];
        [storyVC setStory:story];
        [ProgressHUD show:@"Fetching story..."];
        if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
            [UIView animateWithDuration:.23 animations:^{
                [self.tableView setAlpha:0.0];
                self.tableView.transform = CGAffineTransformMakeScale(.8, .8);
            }];
        }
    }
}

@end

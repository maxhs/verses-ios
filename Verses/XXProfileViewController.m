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

@interface XXProfileViewController () {
    AFHTTPRequestOperationManager *manager;
    UIColor *textColor;
    UIBarButtonItem *backButton;
    //UIImageView *navBarShadowView;
    NSDateFormatter *_dateFormatter;
    UIImageView *userBlurredBackground;
    UIView *profileCellContentView;
}

@end

@implementation XXProfileViewController

@synthesize user = _user;
@synthesize userId = _userId;

- (void)viewDidLoad
{
    [super viewDidLoad];
    manager = [(XXAppDelegate*)[UIApplication sharedApplication].delegate manager];
    if (_user){
        [self loadUserDetails:_user.identifier];
    } else if (_userId) {
        [self loadUserDetails:_userId];
    }
    
   
    [self.tableView setSeparatorColor:[UIColor colorWithWhite:1 alpha:0]];
    self.title = _user.penName;
    
    _dateFormatter = [[NSDateFormatter alloc] init];
    [_dateFormatter setLocale:[NSLocale currentLocale]];
    [_dateFormatter setDateFormat:@"MMM, d  |  h:mm a"];
    //navBarShadowView = [Utilities findNavShadow:self.navigationController.navigationBar];
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new]
                             forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.shadowImage = [UIImage new];
    self.navigationController.navigationBar.translucent = YES;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
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

- (void)back {
    MSDynamicsDrawerViewController *drawerView = [(XXAppDelegate*)[UIApplication sharedApplication].delegate dynamicsDrawerViewController];
    if ([[(UINavigationController*)drawerView.paneViewController viewControllers] firstObject] == self){
        [[(XXAppDelegate*)[UIApplication sharedApplication].delegate dynamicsDrawerViewController] setPaneState:MSDynamicsDrawerPaneStateOpen inDirection:MSDynamicsDrawerDirectionLeft animated:YES allowUserInterruption:NO completion:nil];
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
    NSLog(@"should be loading user details");
    [manager GET:[NSString stringWithFormat:@"%@/users/%@",kAPIBaseUrl,identifier] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        _user = [[XXUser alloc] initWithDictionary:[responseObject objectForKey:@"user"]];
        NSLog(@"user stories: %d",_user.stories.count);
        NSLog(@"success getting user details: %@",responseObject);
        if (self.tableView.numberOfSections){
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationFade];
        } else {
            [self.tableView reloadData];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
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
        return _user.stories.count;
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
        
        return cell;
    } else {
        XXProfileStoryCell *cell = (XXProfileStoryCell *)[tableView dequeueReusableCellWithIdentifier:@"ProfileStoryCell"];
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"XXProfileStoryCell" owner:nil options:nil] lastObject];
        }
        XXStory *story = [_user.stories objectAtIndex:indexPath.row];
        [cell configureStory:story withTextColor:textColor];
        [cell.subtitleLabel setText:[_dateFormatter stringFromDate:story.updatedDate]];
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
    [selectedView setBackgroundColor:[UIColor colorWithWhite:.9 alpha:.1]];
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
        if (IDIOM == IPAD){
            XXStory *story = [_user.stories objectAtIndex:indexPath.row];
            [ProgressHUD show:@"Fetching story..."];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ResetStory" object:nil userInfo:@{@"story":story}];
            _storyInfoVc.story = story;
            [_storyInfoVc.popover dismissPopoverAnimated:YES];
            [[(XXAppDelegate*)[UIApplication sharedApplication].delegate dynamicsDrawerViewController] setPaneState:MSDynamicsDrawerPaneStateClosed animated:YES allowUserInterruption:YES completion:^{
                
            }];
        } else {
            [self performSegueWithIdentifier:@"Read" sender:indexPath];
        }
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(NSIndexPath*)indexPath {
    [super prepareForSegue:segue sender:indexPath];
    
    if ([segue.identifier isEqualToString:@"Read"]){
        XXStoryViewController *storyVC = [segue destinationViewController];
        XXStory *story = [_user.stories objectAtIndex:indexPath.row];
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
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    //[[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
}

@end

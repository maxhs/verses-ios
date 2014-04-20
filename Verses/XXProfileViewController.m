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
    XXAppDelegate *delegate;
    UIImageView *navBarShadowView;
}

@end

@implementation XXProfileViewController

@synthesize user = _user;

- (void)viewDidLoad
{
    [super viewDidLoad];
    manager = [AFHTTPRequestOperationManager manager];
    [self.tableView setSeparatorColor:[UIColor colorWithWhite:1 alpha:0]];
    self.title = _user.penName;
    [self loadUserDetails];
    navBarShadowView = [Utilities findNavShadow:self.navigationController.navigationBar];
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
    navBarShadowView.hidden = YES;
    if (self.tableView.alpha != 1.0){
        [UIView animateWithDuration:.23 animations:^{
            [self.tableView setAlpha:1.0];
            self.tableView.transform = CGAffineTransformIdentity;
        }];
    }
    
}

- (void)back {
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)loadUserDetails {
    [ProgressHUD show:@"Fetching profile..."];
    [manager GET:[NSString stringWithFormat:@"%@/users/%@",kAPIBaseUrl,_user.identifier] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        _user = [[XXUser alloc] initWithDictionary:[responseObject objectForKey:@"user"]];
        NSLog(@"success getting user details: %@",responseObject);
        [self.tableView reloadData];
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
    return 2;
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
        
        if (_user.location.length){
            [cell.locationLabel setFont:[UIFont fontWithName:kSourceSansProRegular size:18]];
            [cell.locationLabel setTextColor:textColor];
            [cell.locationLabel setText:_user.location];
            [cell.locationLabel setHidden:NO];
        } else {
            [cell.locationLabel setHidden:YES];
        }
        
        if (_user.picSmallUrl){
            [cell.imageButton setImageWithURL:[NSURL URLWithString:_user.picMediumUrl] forState:UIControlStateNormal completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
                [UIView animateWithDuration:.23 animations:^{
                    [cell.imageButton setAlpha:1.0];
                    [cell.locationLabel setAlpha:1.0];
                }];
            }];
        } else {
            [cell.imageButton setTitle:@"NO PHOTO" forState:UIControlStateNormal];
            [cell.imageButton.titleLabel setFont:[UIFont fontWithName:kSourceSansProLight size:14]];
            [UIView animateWithDuration:.23 animations:^{
                [cell.imageButton setAlpha:1.0];
            }];
        }
        return cell;
    } else {
        XXProfileStoryCell *cell = (XXProfileStoryCell *)[tableView dequeueReusableCellWithIdentifier:@"ProfileStoryCell"];
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"XXProfileStoryCell" owner:nil options:nil] lastObject];
        }
        XXStory *story = [_user.stories objectAtIndex:indexPath.row];
        [cell configureStory:story withTextColor:textColor];
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
        return 140;
    } else if (indexPath.section == 1){
        return 60;
    } else {
        return 44;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 1){
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        [self performSegueWithIdentifier:@"Read" sender:indexPath];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(NSIndexPath*)indexPath {
    if ([segue.identifier isEqualToString:@"Read"]){
        XXStoryViewController *storyVC = [segue destinationViewController];
        XXStory *story = [_user.stories objectAtIndex:indexPath.row];
        [storyVC setStoryId:story.identifier];
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
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
}

@end

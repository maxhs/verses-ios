//
//  XXBookmarksViewController.m
//  Verses
//
//  Created by Max Haines-Stiles on 3/26/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import "XXBookmarksViewController.h"
#import "XXBookmarkCell.h"
#import "XXBookmark.h"
#import "XXStoryViewController.h"

@interface XXBookmarksViewController () <UIAlertViewDelegate> {
    NSMutableArray *_bookmarks;
    AFHTTPRequestOperationManager *manager;
    NSDateFormatter *_formatter;
    UIBarButtonItem *backButton;
    NSIndexPath *indexPathForDeletion;
    XXAppDelegate *delegate;
    BOOL loading;
    CGRect screen;
    UIColor *textColor;
    UIImageView *navBarShadowView;
}

@end

@implementation XXBookmarksViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    manager = [AFHTTPRequestOperationManager manager];
    self.title = @"Bookmarks";
    _formatter = [[NSDateFormatter alloc] init];
    [_formatter setLocale:[NSLocale currentLocale]];
    [_formatter setDateStyle:NSDateFormatterMediumStyle];
    [_formatter setTimeStyle:NSDateFormatterShortStyle];
    screen = [UIScreen mainScreen].bounds;
    delegate = (XXAppDelegate*)[UIApplication sharedApplication].delegate;
    [delegate.dynamicsDrawerViewController registerTouchForwardingClass:[XXBookmarkCell class]];
    [self loadBookmarks];
    navBarShadowView = [Utilities findNavShadow:self.navigationController.navigationBar];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)back {
    [delegate.dynamicsDrawerViewController setPaneState:MSDynamicsDrawerPaneStateOpen inDirection:MSDynamicsDrawerDirectionLeft animated:YES allowUserInterruption:YES completion:^{
        
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    [delegate.dynamicsDrawerViewController setPaneDragRevealEnabled:NO forDirection:MSDynamicsDrawerDirectionRight];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
        [self.view setBackgroundColor:[UIColor clearColor]];
        textColor = [UIColor whiteColor];
        backButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"whiteBack"] style:UIBarButtonItemStylePlain target:self action:@selector(back)];
        if (self.tableView.alpha != 1.0){
            [UIView animateWithDuration:.23 animations:^{
                [self.tableView setAlpha:1.0];
                self.tableView.transform = CGAffineTransformIdentity;
            }];
        }
    } else {
        [self.view setBackgroundColor:[UIColor whiteColor]];
        textColor = [UIColor blackColor];
        backButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"back"] style:UIBarButtonItemStylePlain target:self action:@selector(back)];
    }
    self.navigationItem.leftBarButtonItem = backButton;
    navBarShadowView.hidden = YES;
    
}

- (void)loadBookmarks {
    loading = YES;
    [manager GET:[NSString stringWithFormat:@"%@/bookmarks",kAPIBaseUrl] parameters:@{@"user_id":[[NSUserDefaults standardUserDefaults]objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"success getting bookmarks: %@",responseObject);
        _bookmarks = [[Utilities bookmarksFromJSONArray:[responseObject objectForKey:@"bookmarks"]] mutableCopy];
        loading = NO;
        [self.tableView reloadData];
        [ProgressHUD dismiss];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failure getting bookmarks; %@",error.description);
        [ProgressHUD dismiss];
    }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (_bookmarks.count == 0 && !loading){
        return 1;
    } else {
        return _bookmarks.count;
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_bookmarks.count && !loading){
        XXBookmarkCell *cell = (XXBookmarkCell *)[tableView dequeueReusableCellWithIdentifier:@"BookmarkCell"];
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"XXBookmarkCell" owner:nil options:nil] lastObject];
        }
        XXBookmark *bookmark = [_bookmarks objectAtIndex:indexPath.row];
        [cell configureBookmark:bookmark];
        [cell.createdLabel setText:[_formatter stringFromDate:bookmark.createdDate]];
        [cell.createdLabel setTextColor:textColor];
        [cell.bookmarkLabel setTextColor:textColor];
        return cell;
    } else {
        static NSString *CellIdentifier = @"NothingCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        UIButton *nothingButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [nothingButton setTitle:@"You don't have any bookmarks." forState:UIControlStateNormal];
        [nothingButton.titleLabel setFont:[UIFont fontWithName:kSourceSansProLight size:20]];
        [nothingButton setTitleColor:textColor forState:UIControlStateNormal];
        [nothingButton setBackgroundColor:[UIColor clearColor]];
        [cell addSubview:nothingButton];
        [nothingButton setFrame:CGRectMake(20, 0, screen.size.width-40, screen.size.height-64)];
        cell.backgroundView = [[UIView alloc] initWithFrame:cell.frame];
        [cell.backgroundView setBackgroundColor:[UIColor clearColor]];
        [self.tableView setScrollEnabled:NO];
        return cell;
    }
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if([indexPath row] == ((NSIndexPath*)[[tableView indexPathsForVisibleRows] lastObject]).row && tableView == self.tableView){
        //end of loading
        [ProgressHUD dismiss];
    }
    cell.backgroundColor = [UIColor clearColor];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (_bookmarks.count && !loading){
        return 80;
    } else {
        return screen.size.height-64;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self performSegueWithIdentifier:@"Read" sender:indexPath];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(NSIndexPath*)indexPath {
    if ([segue.identifier isEqualToString:@"Read"]){
        XXStoryViewController *storyVC = [segue destinationViewController];
        XXStory *story = [(XXBookmark*)[_bookmarks objectAtIndex:indexPath.row] story];
        [storyVC setStoryId:story.identifier];
        [storyVC setStories:delegate.menuViewController.stories];
        [ProgressHUD show:@"Fetching story..."];
        if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
            [UIView animateWithDuration:.23 animations:^{
                [self.tableView setAlpha:0.0];
                self.tableView.transform = CGAffineTransformMakeScale(.8, .8);
            }];
        }
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0){
        return YES;
    } else {
        return NO;
    }
}
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        indexPathForDeletion = indexPath;
        [self confirmDeletion];
    }/* else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }*/
}

- (void)confirmDeletion {
    [[[UIAlertView alloc] initWithTitle:nil message:@"Are you sure you want to delete this bookmark?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil] show];
}

- (void)deleteBookmark {
    if (indexPathForDeletion){
        XXBookmark *bookmark = [_bookmarks objectAtIndex:indexPathForDeletion.row];
        [manager DELETE:[NSString stringWithFormat:@"%@/bookmarks/%@",kAPIBaseUrl,bookmark.identifier] parameters:@{@"story_id":bookmark.story.identifier,@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"Success deleting bookmark: %@",responseObject);
            [_bookmarks removeObject:bookmark];
            if (_bookmarks.count == 0){
                [self.tableView reloadData];
            } else {
                [self.tableView deleteRowsAtIndexPaths:@[indexPathForDeletion] withRowAnimation:UITableViewRowAnimationFade];
            }
            indexPathForDeletion = nil;
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            indexPathForDeletion = nil;
            NSLog(@"Failed to delete bookmark: %@",error.description);
        }];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Yes"]){
        [self deleteBookmark];
    }
}
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

@end

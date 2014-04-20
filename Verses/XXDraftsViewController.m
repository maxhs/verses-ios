//
//  XXDraftsViewController.m
//  Verses
//
//  Created by Max Haines-Stiles on 3/14/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import "XXDraftsViewController.h"
#import "XXDraftCell.h"
#import "XXWriteViewController.h"
#import "XXStory.h"

@interface XXDraftsViewController ()  <UITableViewDataSource, UITableViewDelegate> {
    AFHTTPRequestOperationManager *manager;
    NSMutableArray *_drafts;
    UIRefreshControl *refreshControl;
    NSDateFormatter *_formatter;
    UIBarButtonItem *backButton;
    BOOL loading;
    CGRect screen;
    UIColor *textColor;
}

@end

@implementation XXDraftsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    manager = [AFHTTPRequestOperationManager manager];
    screen = [UIScreen mainScreen].bounds;
    refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(handleRefresh) forControlEvents:UIControlEventValueChanged];
    [refreshControl setTintColor:[UIColor darkGrayColor]];
    refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull to refresh"];
    [self.tableView addSubview:refreshControl];
    self.title = @"Drafts";
    _formatter= [[NSDateFormatter alloc] init];
    [_formatter setLocale:[NSLocale currentLocale]];
    [_formatter setDateStyle:NSDateFormatterMediumStyle];
    [_formatter setTimeStyle:NSDateFormatterMediumStyle];
    backButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"back"] style:UIBarButtonItemStylePlain target:self action:@selector(back)];
    self.navigationItem.leftBarButtonItem = backButton;
    [self loadDrafts];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeStory:) name:@"RemoveStory" object:nil];
}

- (void)removeStory:(NSNotification*)notification {
    for (XXStory *story in _drafts){
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [notification.userInfo objectForKey:@"story_id"]];
        if([predicate evaluateWithObject:story]) {
            [_drafts removeObject:story];
            [self.tableView reloadData];
            break;
        }
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
        [self.view setBackgroundColor:[UIColor clearColor]];
        textColor = [UIColor whiteColor];
        backButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"whiteBack"] style:UIBarButtonItemStylePlain target:self action:@selector(back)];
    } else {
        [self.view setBackgroundColor:[UIColor whiteColor]];
        textColor = [UIColor blackColor];
        backButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"back"] style:UIBarButtonItemStylePlain target:self action:@selector(back)];
    }
    self.navigationItem.leftBarButtonItem = backButton;
}

- (void)back {
    [[(XXAppDelegate*)[UIApplication sharedApplication].delegate dynamicsDrawerViewController] setPaneState:MSDynamicsDrawerPaneStateOpen inDirection:MSDynamicsDrawerDirectionLeft animated:YES allowUserInterruption:YES completion:^{
        
    }];
}

- (void)handleRefresh {
    [self loadDrafts];
}

- (void)loadDrafts {
    loading = YES;
    [manager GET:[NSString stringWithFormat:@"%@/stories/drafts",kAPIBaseUrl] parameters:@{@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"success fetching drafts: %@",responseObject);
        _drafts = [[Utilities storiesFromJSONArray:[responseObject objectForKey:@"stories"]] mutableCopy];
        loading = NO;
        [self.tableView reloadData];
        if (refreshControl.isRefreshing) [refreshControl endRefreshing];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failure getting drafts: %@",error.description);
        if (refreshControl.isRefreshing) [refreshControl endRefreshing];
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
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (_drafts.count == 0 && !loading){
        return 1;
    } else {
        return _drafts.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_drafts.count && !loading){
        XXDraftCell *cell = (XXDraftCell *)[tableView dequeueReusableCellWithIdentifier:@"DraftCell"];
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"XXDraftCell" owner:nil options:nil] lastObject];
        }
        XXStory *story = [_drafts objectAtIndex:indexPath.row];
        [cell configure:story];
        [cell.lastUpdatedLabel setText:[NSString stringWithFormat:@"Last updated: %@",[_formatter stringFromDate:story.updatedDate]]];
        [cell.wordCountLabel setText:[NSString stringWithFormat:@"%@ words",story.wordCount]];
        return cell;
    } else {
        static NSString *CellIdentifier = @"NothingCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        UIButton *nothingButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [nothingButton setTitle:@"You don't have any drafts yet.\nTap here to start writing" forState:UIControlStateNormal];
        [nothingButton.titleLabel setNumberOfLines:0];
        [nothingButton addTarget:self action:@selector(startWriting) forControlEvents:UIControlEventTouchUpInside];
        [nothingButton.titleLabel setFont:[UIFont fontWithName:kSourceSansProLight size:20]];
        nothingButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
        [nothingButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [nothingButton setBackgroundColor:[UIColor clearColor]];
        [cell addSubview:nothingButton];
        [nothingButton setFrame:CGRectMake(20, 0, screen.size.width-40, screen.size.height-64)];
        cell.backgroundView = [[UIView alloc] initWithFrame:cell.frame];
        [cell.backgroundView setBackgroundColor:[UIColor clearColor]];
        [self.tableView setScrollEnabled:NO];
        return cell;
    }
}

- (void)startWriting {
    UIStoryboard *storyboard;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone){
        storyboard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle:nil];
    } else {
        storyboard = [UIStoryboard storyboardWithName:@"Main_iPad" bundle:nil];
    }
    XXWriteViewController *write = [storyboard instantiateViewControllerWithIdentifier:@"Write"];
    [self.navigationController pushViewController:write animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (_drafts.count && !loading){
        return 100;
    } else {
        return screen.size.height-64;
    }
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if([indexPath row] == ((NSIndexPath*)[[tableView indexPathsForVisibleRows] lastObject]).row && tableView == self.tableView){
        //end of loading
        [ProgressHUD dismiss];
        if (_drafts.count)[self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self performSegueWithIdentifier:@"Edit" sender:indexPath];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(NSIndexPath*)indexPath {
    if ([segue.identifier isEqualToString:@"Edit"]){
        XXStory *story = [_drafts objectAtIndex:indexPath.row];
        XXWriteViewController *vc = [segue destinationViewController];
        [vc setStory:story];
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

/*
#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

 */

@end

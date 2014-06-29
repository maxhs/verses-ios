//
//  XXFeedbackViewController.m
//  Verses
//
//  Created by Max Haines-Stiles on 3/16/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import "XXFeedbackViewController.h"
#import "XXFeedbackCell.h"
#import "Feedback.h"
#import "XXFeedbackDetailViewController.h"

@interface XXFeedbackViewController () {
    AFHTTPRequestOperationManager *manager;
    NSMutableArray *_feedbacks;
    UIBarButtonItem *backButton;
    CGRect screen;
    BOOL loading;
    UIColor *textColor;
}

@end

@implementation XXFeedbackViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    manager = [AFHTTPRequestOperationManager manager];
    screen = [UIScreen mainScreen].bounds;
    _feedbacks = [NSMutableArray array];
    self.title = @"Feedback";
    backButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"back"] style:UIBarButtonItemStylePlain target:self action:@selector(back)];
    self.navigationItem.leftBarButtonItem = backButton;
    [self loadFeedback];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
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

- (void)loadFeedback {
    loading = YES;
    [manager GET:[NSString stringWithFormat:@"%@/feedbacks",kAPIBaseUrl] parameters:@{@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"success fetching feedback: %@",responseObject);
        for (NSDictionary *feedbackDict in [responseObject objectForKey:@"feedbacks"]){
            Feedback *feedback = [Feedback MR_findFirstByAttribute:@"identifier" withValue:[feedbackDict objectForKey:@"id"]];
            if (!feedback){
                feedback = [Feedback MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [feedback populateFromDict:feedbackDict];
        }
        
        loading = NO;
        [self.tableView reloadData];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failure loading feedback: %@",error.description);
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
    if (_feedbacks.count == 0 && !loading){
        return 1;
    } else {
        return _feedbacks.count;
    }
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_feedbacks.count && !loading){
        XXFeedbackCell *cell = [tableView dequeueReusableCellWithIdentifier:@"FeedbackCell"];
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"XXFeedbackCell" owner:nil options:nil] lastObject];
        }
        Feedback *feedback = [_feedbacks objectAtIndex:indexPath.row];
        [cell configure:feedback textColor:[UIColor blackColor]];
        return cell;
    } else {
        static NSString *CellIdentifier = @"NothingCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        UIButton *nothingButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [nothingButton setTitle:@"You don't have any feedback." forState:UIControlStateNormal];
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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (_feedbacks.count && !loading){
        Feedback *feedback = [_feedbacks objectAtIndex:indexPath.row];
        if (feedback.snippet.length){
            return 150;
        } else {
            return 90;
        }
    } else {
        return screen.size.height-64;
    }
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if([indexPath row] == ((NSIndexPath*)[[tableView indexPathsForVisibleRows] lastObject]).row && tableView == self.tableView){
        //end of loading
        [ProgressHUD dismiss];
        [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self performSegueWithIdentifier:@"FeedbackDetail" sender:indexPath];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(NSIndexPath*)indexPath
{
    [super prepareForSegue:segue sender:indexPath];
    
    if ([[segue identifier] isEqualToString:@"FeedbackDetail"]){
        XXFeedbackDetailViewController *vc = [segue destinationViewController];
        [vc setFeedback:[_feedbacks objectAtIndex:indexPath.row]];
    }
}


/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

@end

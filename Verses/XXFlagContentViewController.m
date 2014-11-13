//
//  XXFlagContentViewController.m
//  Verses
//
//  Created by Max Haines-Stiles on 5/30/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import "XXFlagContentViewController.h"
#import "XXAlert.h"
#import "XXLoginController.h"
#import "XXNoRotateNavController.h"

@interface XXFlagContentViewController () {
    UIBarButtonItem *backButton;
    CGFloat height;
    CGFloat width;
}

@end

@implementation XXFlagContentViewController

@synthesize story = _story;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    backButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"blackX"] style:UIBarButtonItemStylePlain target:self action:@selector(back)];
    self.navigationItem.leftBarButtonItem = backButton;
    self.tableView.rowHeight = 66;
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new]
                             forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.shadowImage = [UIImage new];
    self.navigationController.navigationBar.translucent = YES;
    
    if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation) || [[[UIDevice currentDevice] systemVersion] floatValue] >= 8.f){
        width = screenWidth();
        height = screenHeight();
    } else {
        width = screenHeight();
        height = screenWidth();
    }
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, 66)];
    UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(40, 0, width-80, 66)];
    [headerLabel setNumberOfLines:0];
    [headerLabel setTextColor:[UIColor colorWithWhite:.5 alpha:1]];
    [headerLabel setTextAlignment:NSTextAlignmentCenter];
    [headerLabel setFont:[UIFont fontWithName:kSourceSansProLight size:16]];
    NSString *title;
    if (_story && _story.title.length){
        title = [NSString stringWithFormat:@"\"%@\"",_story.title];
    } else {
        title = @"this content";
    }
    [headerLabel setText:[NSString stringWithFormat:@"Please tell us a little about why you're flagging %@:",title]];
    [headerLabel setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    [headerView addSubview:headerLabel];
    self.tableView.tableHeaderView = headerView;
    
    //hide empty tableview cells
    UIView *emptyFooter = [[UIView alloc] initWithFrame:CGRectZero];
    emptyFooter.backgroundColor = [UIColor clearColor];
    [self.tableView setTableFooterView:emptyFooter];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 5;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"FlagCell" forIndexPath:indexPath];
    /*if (cell == nil) {
        cell = [[[NSBundle mainBundle] loadNibNamed:@"XXLeaveFeedbackCell" owner:nil options:nil] lastObject];
    }*/
    [cell.textLabel setFont:[UIFont fontWithName:kSourceSansProRegular size:17]];
    [cell.textLabel setTextAlignment:NSTextAlignmentCenter];
    switch (indexPath.row) {
        case 0:
            [cell.textLabel setText:@"I don't like it"];
            break;
        case 1:
            [cell.textLabel setText:@"Inappropriate"];
            break;
        case 2:
            [cell.textLabel setText:@"Offensive"];
            break;
        case 3:
            [cell.textLabel setText:@"Too graphic"];
            break;
        case 4:
            [cell.textLabel setTextColor:[UIColor redColor]];
            [cell.textLabel setText:@"Cancel"];
            break;
        default:
            break;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor clearColor];
    UIView *selectedView = [[UIView alloc] initWithFrame:cell.frame];
    [selectedView setBackgroundColor:kSeparatorColor];
    cell.selectedBackgroundView = selectedView;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    BOOL cancel = NO;
    NSString *description;
    switch (indexPath.row) {
        case 0:
        {
            XXLoginController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Login"];
            XXNoRotateNavController *nav = [[XXNoRotateNavController alloc] initWithRootViewController:vc];
            return [self presentViewController:nav animated:YES completion:^{
                [XXAlert show:@"Please log in to remove content that is not otherwise objectionable." withTime:3.f];
            }];
        }
            break;
        case 1:
            description = @"Inappropriate";
            break;
        case 2:
            description = @"Offensive";
            break;
        case 3:
            description = @"Too graphic";
            break;
        case 4:
            cancel = YES;
            break;
        default:
            break;
    }
    if (cancel){
        [self back];
    } else {
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        if (description.length){
            [parameters setObject:description forKey:@"description"];
        }
        if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]) {
            [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"user_id"];
        }
        if (_story) {
            [parameters setObject:_story.identifier forKey:@"story_id"];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"StoryFlagged" object:nil userInfo:@{@"story":_story}];
        }
        [XXAlert show:[NSString stringWithFormat:@"Thanks for flagging \"%@\"",_story.title] withTime:2.7f];
        
        [[(XXAppDelegate*)[UIApplication sharedApplication].delegate manager] POST:[NSString stringWithFormat:@"%@/users/flag_content",kAPIBaseUrl] parameters:@{@"flag":parameters} success:^(AFHTTPRequestOperation *operation, id responseObject) {
            //NSLog(@"success creating flag: %@",responseObject);
            if ([[responseObject objectForKey:@"success"] isEqualToNumber:@YES]){
                [self back];
            }
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"error creating flag: %@",error.description);
            [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Something went wrong while trying to flag this content. Please try again soon." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        }];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)back {
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

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

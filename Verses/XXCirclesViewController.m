//
//  XXCirclesViewController.m
//  Verses
//
//  Created by Max Haines-Stiles on 3/14/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import "XXCirclesViewController.h"
#import "XXCircleCell.h"
#import "XXCircle.h"
#import "XXCollaborateViewController.h"
#import "XXCircleDetailViewController.h"

@interface XXCirclesViewController () {
    AFHTTPRequestOperationManager *manager;
    NSMutableArray *_circles;
    XXAppDelegate *delegate;
    UIColor *textColor;
    UIBarButtonItem *backButton;
    UIBarButtonItem *contactsButton;
    UIImageView *navBarShadowView;
    NSDateFormatter *_formatter;
    CGRect screen;
    
}

@end

@implementation XXCirclesViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Writing Circles";
    _formatter = [[NSDateFormatter alloc] init];
    [_formatter setLocale:[NSLocale currentLocale]];
    [_formatter setDateStyle:NSDateFormatterMediumStyle];
    [_formatter setTimeStyle:NSDateFormatterShortStyle];
    screen = [UIScreen mainScreen].bounds;
    manager = [AFHTTPRequestOperationManager manager];
    navBarShadowView = [Utilities findNavShadow:self.navigationController.navigationBar];
    [self.tableView setBackgroundColor:[UIColor clearColor]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self loadCircles];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    delegate = (XXAppDelegate*)[UIApplication sharedApplication].delegate;
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
    contactsButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"contact"] style:UIBarButtonItemStylePlain target:self action:@selector(viewContacts)];
    self.navigationItem.rightBarButtonItem = contactsButton;
    self.navigationItem.leftBarButtonItem = backButton;
    navBarShadowView.hidden = YES;
    if (self.tableView.alpha != 1.0){
        [UIView animateWithDuration:.23 animations:^{
            [self.tableView setAlpha:1.0];
        }];
    }
    if (self.navigationController.view.alpha != 1.0){
        [UIView animateWithDuration:.23 animations:^{
            self.navigationController.view.transform = CGAffineTransformIdentity;
            [self.navigationController.view setAlpha:1.0];
        } completion:^(BOOL finished) {
        }];
    }
    [self.navigationController setNavigationBarHidden:NO animated:NO];
}

- (void)viewDidAppear:(BOOL)animated {
    [delegate.dynamicsDrawerViewController setPaneDragRevealEnabled:NO forDirection:MSDynamicsDrawerDirectionRight];
    [super viewDidAppear:animated];
    
}

- (void)back {
    [delegate.dynamicsDrawerViewController setPaneState:MSDynamicsDrawerPaneStateOpen inDirection:MSDynamicsDrawerDirectionLeft animated:YES allowUserInterruption:YES completion:^{
        
    }];
}

- (void)viewContacts{
    XXCollaborateViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Collaborate"];
    [vc setTitle:@"Collaborators"];
    [vc setModal:YES];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
        [UIView animateWithDuration:.23 animations:^{
            self.navigationController.view.transform = CGAffineTransformMakeScale(.77, .77);
            [self.navigationController.view setAlpha:0.0];
        } completion:^(BOOL finished) {
            
        }];
    }
    [self presentViewController:[[UINavigationController alloc] initWithRootViewController:vc] animated:YES completion:^{
        
    }];
}

- (void)loadCircles {
    [manager GET:[NSString stringWithFormat:@"%@/circles",kAPIBaseUrl] parameters:@{@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"success fetching circles: %@",responseObject);
        _circles = [[Utilities circlesFromJSONArray:[responseObject objectForKey:@"circles"]] mutableCopy];
        if (_circles.count == 0){
            [ProgressHUD dismiss];
        } else {
            [self.tableView reloadData];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failure getting circles: %@",error.description);
        [ProgressHUD dismiss];
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
    return _circles.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    XXCircleCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CircleCell"];
    if (cell == nil) {
        cell = [[[NSBundle mainBundle] loadNibNamed:@"XXCircleCell" owner:nil options:nil] lastObject];
    }
    XXCircle *circle = [_circles objectAtIndex:indexPath.row];
    [cell configureCell:circle withTextColor:textColor];
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 100;
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if([indexPath row] == ((NSIndexPath*)[[tableView indexPathsForVisibleRows] lastObject]).row && tableView == self.tableView){
        //end of loading
        [ProgressHUD dismiss];
    }
    UIView *selectionView = [[UIView alloc] initWithFrame:cell.frame];
    [selectionView setBackgroundColor:[UIColor colorWithWhite:.9 alpha:.23]];
    cell.selectedBackgroundView = selectionView;
    cell.backgroundColor = [UIColor clearColor];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    XXCircle *circle = [_circles objectAtIndex:indexPath.row];
    circle.unreadCommentCount = 0;
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
    [self performSegueWithIdentifier:@"CircleDetail" sender:circle];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([[segue identifier] isEqualToString:@"CircleDetail"]){
        XXCircleDetailViewController *vc = [segue destinationViewController];
        [vc setCircle:(XXCircle*)sender];
        if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
            [UIView animateWithDuration:.23 animations:^{
                [self.tableView setAlpha:0.0];
                self.tableView.transform = CGAffineTransformMakeScale(.8, .8);
            }];
        }
    }
}


@end

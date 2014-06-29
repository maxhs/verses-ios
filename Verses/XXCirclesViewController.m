//
//  XXCirclesViewController.m
//  Verses
//
//  Created by Max Haines-Stiles on 3/14/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import "XXCirclesViewController.h"
#import "XXCircleCell.h"
#import "Circle.h"
#import "User+helper.h"
#import "XXCollaborateViewController.h"
#import "XXCircleDetailViewController.h"
#import "XXNothingCell.h"
#import "XXManageCircleViewController.h"
#import "XXCollaboratorsTransition.h"

@interface XXCirclesViewController () <UIViewControllerTransitioningDelegate>{
    AFHTTPRequestOperationManager *manager;
    XXAppDelegate *delegate;
    UIColor *textColor;
    UIBarButtonItem *backButton;
    UIBarButtonItem *contactsButton;
    UIImageView *navBarShadowView;
    NSDateFormatter *_formatter;
    BOOL loading;
    User *currentUser;
    NSArray *_circles;
}

@end

@implementation XXCirclesViewController

@synthesize freshCircles = _freshCircles;

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Writing Circles";
    delegate = (XXAppDelegate*)[UIApplication sharedApplication].delegate;
    _formatter = [[NSDateFormatter alloc] init];
    [_formatter setLocale:[NSLocale currentLocale]];
    [_formatter setDateStyle:NSDateFormatterMediumStyle];
    [_formatter setTimeStyle:NSDateFormatterShortStyle];
    manager = [delegate manager];
    if (delegate.currentUser){
        currentUser = [delegate currentUser];
    } else {
        currentUser = [User MR_findFirstByAttribute:@"identifier" withValue:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]];
    }
    _circles = currentUser.circles.array;
    loading = YES;
    [self.tableView reloadData];
    navBarShadowView = [Utilities findNavShadow:self.navigationController.navigationBar];
    [self.tableView setBackgroundColor:[UIColor clearColor]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    [self loadCircles];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
        [self.view setBackgroundColor:[UIColor clearColor]];
        textColor = [UIColor whiteColor];
        backButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"whiteBack"] style:UIBarButtonItemStylePlain target:self action:@selector(back)];
    } else {
        [self.view setBackgroundColor:[UIColor whiteColor]];
        textColor = [UIColor blackColor];
        backButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"back"] style:UIBarButtonItemStylePlain target:self action:@selector(back)];
    }
    contactsButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"contact"] style:UIBarButtonItemStylePlain target:self action:@selector(viewContacts)];
    self.navigationItem.rightBarButtonItem = contactsButton;
    self.navigationItem.leftBarButtonItem = backButton;
    navBarShadowView.hidden = YES;
    
    //reset views after custom modal transition
    if (self.tableView.alpha != 1.0){
        [UIView animateWithDuration:.23 animations:^{
            [self.tableView setAlpha:1.0];
            self.tableView.transform = CGAffineTransformIdentity;
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
    [vc setManageContacts:YES];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    nav.modalPresentationStyle = UIModalPresentationCustom;
    nav.transitioningDelegate = self;
    [self presentViewController:nav animated:YES completion:^{
        
    }];
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented
                                                                  presentingController:(UIViewController *)presenting
                                                                      sourceController:(UIViewController *)source {
    XXCollaboratorsTransition *animator = [XXCollaboratorsTransition new];
    animator.presenting = YES;
    return animator;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    
    XXCollaboratorsTransition *animator = [XXCollaboratorsTransition new];
    return animator;
}

- (void)loadCircles {
    loading = YES;
    [manager GET:[NSString stringWithFormat:@"%@/circles",kAPIBaseUrl] parameters:@{@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"success fetching circles: %@",responseObject);
        NSMutableOrderedSet *circleSet = [NSMutableOrderedSet orderedSet];
        for (NSDictionary *circleDict in [responseObject objectForKey:@"circles"]){
            Circle *circle = [Circle MR_findFirstByAttribute:@"identifier" withValue:[circleDict objectForKey:@"id"]];
            if (!circle){
                circle = [Circle MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [circle populateFromDict:circleDict];
            [circleSet addObject:circle];
        }
        for (Circle *circle in currentUser.circles){
            if (![circleSet containsObject:circle]){
                NSLog(@"Deleting a circle that no longer exists: %@",circle.name);
                [circle MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
            }
        }
        currentUser.circles = circleSet;
        _circles = circleSet.array;
        loading = NO;
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            if (self.isViewLoaded && self.view.window && self.tableView.numberOfSections){
                [self.tableView beginUpdates];
                [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
                [self.tableView endUpdates];
            } else {
                [self.tableView reloadData];
            }
        }];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failure getting circles: %@",error.description);
        loading = NO;
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
    if (loading) return 0;
    else return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (_circles.count == 0 && !loading) return 1;
    else if (section == 0) return _circles.count;
    else if (section == 1) return 1;
    else return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_circles.count == 0){
        XXNothingCell *cell = (XXNothingCell *)[tableView dequeueReusableCellWithIdentifier:@"NothingCell"];
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"XXNothingCell" owner:nil options:nil] lastObject];
        }
        [cell.promptButton setTitle:@"Tap to add your first writing circle." forState:UIControlStateNormal];
        [cell.promptButton addTarget:self action:@selector(newCircle) forControlEvents:UIControlEventTouchUpInside];
        [cell.promptButton setBackgroundColor:[UIColor colorWithWhite:.7 alpha:1]];
        [cell.promptButton.titleLabel setNumberOfLines:0];
        [cell.promptButton.titleLabel setFont:[UIFont fontWithName:kSourceSansProLight size:20]];
        [cell.promptButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
        cell.promptButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
        [cell.promptButton setTitleColor:textColor forState:UIControlStateNormal];
        [cell.promptButton setBackgroundColor:[UIColor clearColor]];
        
        return cell;
    } else if (indexPath.section == 0) {
        XXCircleCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CircleCell"];
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"XXCircleCell" owner:nil options:nil] lastObject];
        }
        Circle *circle = [_circles objectAtIndex:indexPath.row];
        [cell configureCell:circle withTextColor:textColor];
        [cell.textLabel setText:@""];
        return cell;
    } else {
        XXCircleCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CircleCell"];
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"XXCircleCell" owner:nil options:nil] lastObject];
        }
        [cell.circleName setText:@""];
        [cell.infoLabel setText:@""];
        [cell.textLabel setText:@"Add new circle"];
        [cell.textLabel setTextAlignment:NSTextAlignmentCenter];
        [cell.textLabel setFont:[UIFont fontWithName:kCrimsonItalic size:17]];
        [cell.textLabel setTextColor:textColor];
        return cell;
    }
}

- (void)newCircle {
    XXManageCircleViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"ManageCircle"];
    [vc setTitle:@"New Writing Circle"];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
        [UIView animateWithDuration:.23 animations:^{
            self.navigationController.view.transform = CGAffineTransformMakeScale(.77, .77);
            [self.navigationController.view setAlpha:0.0];
        } completion:^(BOOL finished) {
            
        }];
    }
    [self presentViewController:nav animated:YES completion:^{
        
    }];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (_circles.count == 0 && !loading) return screenHeight() - 84;
    else return 70;
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if([indexPath row] == ((NSIndexPath*)[[tableView indexPathsForVisibleRows] lastObject]).row && tableView == self.tableView){
        //end of loading
        [ProgressHUD dismiss];
    }
    UIView *selectionView = [[UIView alloc] initWithFrame:cell.frame];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
        [selectionView setBackgroundColor:kTableViewCellSelectionColorDark];
    } else {
        [selectionView setBackgroundColor:[UIColor colorWithWhite:.9 alpha:.23]];
    }
    
    cell.selectedBackgroundView = selectionView;
    cell.backgroundColor = [UIColor clearColor];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (_circles.count){
        if (indexPath.section == 0){
            Circle *circle = [_circles objectAtIndex:indexPath.row];
            circle.unreadCommentCount = 0;
            circle.fresh = NO;
            
            /*[self.tableView beginUpdates];
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView endUpdates];*/
            
            [self performSegueWithIdentifier:@"CircleDetail" sender:circle];
        } else {
            [self newCircle];
        }
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    [super prepareForSegue:segue sender:sender];
    
    if ([[segue identifier] isEqualToString:@"CircleDetail"]){
        XXCircleDetailViewController *vc = [segue destinationViewController];
        [vc setCircle:(Circle*)sender];
        if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
            [UIView animateWithDuration:.23 animations:^{
                [self.tableView setAlpha:0.0];
                self.tableView.transform = CGAffineTransformMakeScale(.77, .77);
            }];
        }
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self saveContext];
}

- (void)saveContext {
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
        NSLog(@"Saving circles: %u",success);
    }];
}
@end

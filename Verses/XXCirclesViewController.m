//
//  XXCirclesViewController.m
//  Verses
//
//  Created by Max Haines-Stiles on 3/14/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import "XXAppDelegate.h"
#import "XXCirclesViewController.h"
#import "XXCircleCell.h"
#import "Circle.h"
#import "User+helper.h"
#import "XXCollaborateViewController.h"
#import "XXCircleDetailViewController.h"
#import "XXNothingCell.h"
#import "XXManageCircleViewController.h"
#import "XXCollaboratorsTransition.h"
#import "XXGuideInteractor.h"
#import "XXGuideViewController.h"

@interface XXCirclesViewController () <UIViewControllerTransitioningDelegate>{
    AFHTTPRequestOperationManager *manager;
    XXAppDelegate *delegate;
    CGFloat width;
    CGFloat height;
    UIColor *textColor;
    UIBarButtonItem *guideButton;
    UIBarButtonItem *contactsButton;
    UIImageView *navBarShadowView;
    NSDateFormatter *_formatter;
    BOOL loading;
    BOOL showGuide;
}

@end

@implementation XXCirclesViewController

@synthesize freshCircles = _freshCircles;
@synthesize currentUser = _currentUser;

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Writing Circles";
    delegate = (XXAppDelegate*)[UIApplication sharedApplication].delegate;
    manager = [delegate manager];
    _formatter = [[NSDateFormatter alloc] init];
    [_formatter setLocale:[NSLocale currentLocale]];
    [_formatter setDateStyle:NSDateFormatterMediumStyle];
    [_formatter setTimeStyle:NSDateFormatterShortStyle];
    
    if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation) || [[[UIDevice currentDevice] systemVersion] floatValue] >= 8.f){
        width = screenWidth();
        height = screenHeight();
    } else {
        width = screenHeight();
        height = screenWidth();
    }
    
    [self.tableView reloadData];
    loading = YES;
    [self loadCircles];
    
    navBarShadowView = [Utilities findNavShadow:self.navigationController.navigationBar];
    [self.tableView setBackgroundColor:[UIColor clearColor]];
    [delegate.dynamicsDrawerViewController setPaneDragRevealEnabled:NO forDirection:MSDynamicsDrawerDirectionRight];
    guideButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"more"] style:UIBarButtonItemStylePlain target:self action:@selector(showGuide)];
    contactsButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"contact"] style:UIBarButtonItemStylePlain target:self action:@selector(viewContacts)];
    
    UIBarButtonItem *negativeRightButton = [[UIBarButtonItem alloc]
                                            initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
                                            target:nil action:nil];
    negativeRightButton.width = -14.f;
   
    self.navigationItem.leftBarButtonItem = contactsButton;
    self.navigationItem.rightBarButtonItems = @[negativeRightButton,guideButton];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(createCircle:) name:@"CreateCircle" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deleteCircle:) name:@"DeleteCircle" object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
        [self.view setBackgroundColor:[UIColor clearColor]];
        textColor = [UIColor whiteColor];
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
    } else {
        [self.view setBackgroundColor:[UIColor whiteColor]];
        textColor = [UIColor blackColor];
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
    }
   
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
    showGuide = NO;
    [self presentViewController:nav animated:YES completion:^{
        
    }];
}

- (void)showGuide {
    XXGuideViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Guide"];
    vc.transitioningDelegate = self;
    vc.modalPresentationStyle = UIModalPresentationCustom;
    showGuide = YES;
    [self presentViewController:vc animated:YES completion:nil];
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented
                                                                  presentingController:(UIViewController *)presenting
                                                                      sourceController:(UIViewController *)source {
    if (showGuide){
        XXGuideInteractor *animator = [XXGuideInteractor new];
        animator.presenting = YES;
        return animator;
    } else {
        XXCollaboratorsTransition *animator = [XXCollaboratorsTransition new];
        animator.presenting = YES;
        return animator;
    }
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    if (showGuide){
        XXGuideInteractor *animator = [XXGuideInteractor new];
        return animator;
    } else {
        XXCollaboratorsTransition *animator = [XXCollaboratorsTransition new];
        return animator;
    }
}

- (void)loadCircles {
    loading = YES;
    [manager GET:[NSString stringWithFormat:@"%@/circles",kAPIBaseUrl] parameters:@{@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"success fetching circles: %@",responseObject);
        NSMutableOrderedSet *circleSet = [NSMutableOrderedSet orderedSet];
        for (NSDictionary *circleDict in [responseObject objectForKey:@"circles"]){
            Circle *circle = [Circle MR_findFirstByAttribute:@"identifier" withValue:[circleDict objectForKey:@"id"] inContext:[NSManagedObjectContext MR_defaultContext]];
            if (circle){
                //circle already exists. only perform the pertinent updates
                [circle update:circleDict];
            } else {
                //create a new circle
                circle = [Circle MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                [circle populateFromDict:circleDict];
            }
            [circleSet addObject:circle];
        }
        for (Circle *circle in _currentUser.circles){
            if (![circleSet containsObject:circle]){
                NSLog(@"Deleting a circle that no longer exists: %@",circle.name);
                [circle MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
            }
        }
        _currentUser.circles = circleSet;
        loading = NO;
        if (self.tableView.numberOfSections){
            [self.tableView beginUpdates];
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView endUpdates];
        } else {
            [self.tableView reloadData];
        }
        
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
    if (_currentUser.circles.count == 0 && !loading) self.tableView.rowHeight = height - 84;
    else self.tableView.rowHeight = 80;
    
    if (loading) return 0;
    else return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (_currentUser.circles.count == 0 && !loading) return 1;
    else if (section == 0) return _currentUser.circles.count;
    else if (section == 1) return 1;
    else return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_currentUser.circles.count == 0 && indexPath.section == 0){
        XXNothingCell *cell = (XXNothingCell *)[tableView dequeueReusableCellWithIdentifier:@"NothingCell"];
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"XXNothingCell" owner:nil options:nil] lastObject];
        }
        [cell.promptButton setTitle:@"Tap to add a writing circle." forState:UIControlStateNormal];
        [cell.promptButton addTarget:self action:@selector(newCircle) forControlEvents:UIControlEventTouchUpInside];
        [cell.promptButton setBackgroundColor:[UIColor colorWithWhite:.7 alpha:1]];
        [cell.promptButton.titleLabel setNumberOfLines:0];
        [cell.promptButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleSubheadline forFont:kSourceSansProLight] size:0]];
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
        Circle *circle = [_currentUser.circles objectAtIndex:indexPath.row];
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
        [cell.textLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kCrimsonItalic] size:0]];
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
        [selectionView setBackgroundColor:kTableViewCellSelectionColor];
    }
    
    cell.selectedBackgroundView = selectionView;
    cell.backgroundColor = [UIColor clearColor];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"indexPath section %ld, row %ld, and cricles count: %lu",(long)indexPath.section, (long)indexPath.row, (unsigned long)_currentUser.circles.count);
    if (_currentUser.circles.count && indexPath.section == 0){
        if (_currentUser.circles.count > indexPath.row){
            Circle *circle = [_currentUser.circles objectAtIndex:indexPath.row];
            if (circle.unreadCommentCount.intValue > 0 || [circle.fresh isEqualToNumber:@YES]){
                circle.unreadCommentCount = 0;
                circle.fresh = @NO;
                //[self.tableView beginUpdates];
                [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
                //[self.tableView endUpdates];
            }
            
            [self performSegueWithIdentifier:@"CircleDetail" sender:circle];
        }
    } else if (indexPath.section == 1) {
        [self newCircle];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    [super prepareForSegue:segue sender:sender];
    
    if ([[segue identifier] isEqualToString:@"CircleDetail"]){
        XXCircleDetailViewController *vc = [segue destinationViewController];
        [vc setCircle:(Circle*)sender];
        [vc setCurrentUser:_currentUser];
        if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
            [UIView animateWithDuration:.23 animations:^{
                [self.tableView setAlpha:0.0];
                self.tableView.transform = CGAffineTransformMakeScale(.77, .77);
            }];
        }
    }
}

- (void)createCircle:(NSNotification*)notification{
    Circle *circle = [notification.userInfo objectForKey:@"circle"];
    [_currentUser addCircle:circle];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[_currentUser.circles indexOfObject:circle] inSection:0];
    
    if (_currentUser.circles.count > 1){
        [self.tableView beginUpdates];
        [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView endUpdates];
    } else {
        [self.tableView reloadData];
    }
}

- (void)deleteCircle:(NSNotification*)notification{
    Circle *circle = [notification.userInfo objectForKey:@"circle"];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[_currentUser.circles indexOfObject:circle] inSection:0];
    [_currentUser removeCircle:circle];
    [circle MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];

    if (_currentUser.circles.count){
        [self.tableView beginUpdates];
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView endUpdates];
    } else {
        [self.tableView reloadData];
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

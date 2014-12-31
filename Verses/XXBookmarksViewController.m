//
//  XXBookmarksViewController.m
//  Verses
//
//  Created by Max Haines-Stiles on 3/26/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import "XXAppDelegate.h"
#import "XXBookmarksViewController.h"
#import "XXBookmarkCell.h"
#import "Bookmark+helper.h"
#import "XXStoryViewController.h"
#import "XXGuideInteractor.h"

@interface XXBookmarksViewController () <UIAlertViewDelegate, UIViewControllerTransitioningDelegate> {
    AFHTTPRequestOperationManager *manager;
    NSDateFormatter *_formatter;
    CGFloat width;
    CGFloat height;
    UIBarButtonItem *backButton;
    UIBarButtonItem *guideButton;
    NSIndexPath *indexPathForDeletion;
    XXAppDelegate *delegate;
    BOOL loading;
    UIColor *textColor;
    UIImageView *navBarShadowView;
    User *currentUser;
}

@end

@implementation XXBookmarksViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Bookmarks";
    _formatter = [[NSDateFormatter alloc] init];
    [_formatter setLocale:[NSLocale currentLocale]];
    [_formatter setDateStyle:NSDateFormatterMediumStyle];
    [_formatter setTimeStyle:NSDateFormatterShortStyle];
    self.reloadTheme = NO;
    delegate = (XXAppDelegate*)[UIApplication sharedApplication].delegate;
    
    if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation) || [[[UIDevice currentDevice] systemVersion] floatValue] >= 8.f){
        width = screenWidth();
        height = screenHeight();
    } else {
        width = screenHeight();
        height = screenWidth();
    }
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
        currentUser = [User MR_findFirstByAttribute:@"identifier" withValue:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] inContext:[NSManagedObjectContext MR_defaultContext]];
    }
    guideButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"more"] style:UIBarButtonItemStylePlain target:self action:@selector(showGuide)];
    UIBarButtonItem *negativeRightButton = [[UIBarButtonItem alloc]
                                            initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
                                            target:nil action:nil];
    negativeRightButton.width = -14.f;
    self.navigationItem.rightBarButtonItems = @[negativeRightButton,guideButton];

    backButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"back"] style:UIBarButtonItemStylePlain target:self action:@selector(back)];
    
    manager = delegate.manager;
    [delegate.dynamicsDrawerViewController registerTouchForwardingClass:[XXBookmarkCell class]];
    navBarShadowView = [Utilities findNavShadow:self.navigationController.navigationBar];
}

- (void)back {
    [delegate.dynamicsDrawerViewController setPaneState:MSDynamicsDrawerPaneStateOpen inDirection:MSDynamicsDrawerDirectionLeft animated:YES allowUserInterruption:YES completion:^{
        
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self loadBookmarks];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    [delegate.dynamicsDrawerViewController setPaneDragRevealEnabled:NO forDirection:MSDynamicsDrawerDirectionRight];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
        [self.view setBackgroundColor:[UIColor clearColor]];
        textColor = [UIColor whiteColor];
        [backButton setImage:[UIImage imageNamed:@"whiteBack"]];
        if (self.tableView.alpha != 1.0){
            [UIView animateWithDuration:.23 animations:^{
                [self.tableView setAlpha:1.0];
                self.tableView.transform = CGAffineTransformIdentity;
            }];
        }
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
    } else {
        [self.view setBackgroundColor:[UIColor whiteColor]];
        textColor = [UIColor blackColor];
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
    }
    self.navigationItem.leftBarButtonItem = backButton;
    navBarShadowView.hidden = YES;
    
    if (self.reloadTheme){
        loading = NO;
    }
}

- (void)showGuide {
    XXGuideViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Guide"];
    vc.transitioningDelegate = self;
    vc.modalPresentationStyle = UIModalPresentationCustom;
    [self presentViewController:vc animated:YES completion:nil];
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented
                                                                  presentingController:(UIViewController *)presenting
                                                                      sourceController:(UIViewController *)source {
    
    XXGuideInteractor *animator = [XXGuideInteractor new];
    animator.presenting = YES;
    return animator;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    XXGuideInteractor *animator = [XXGuideInteractor new];
    return animator;
}

- (void)loadBookmarks {
    loading = YES;
    [manager GET:[NSString stringWithFormat:@"%@/bookmarks",kAPIBaseUrl] parameters:@{@"user_id":[[NSUserDefaults standardUserDefaults]objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"success getting bookmarks: %@",responseObject);
        NSMutableOrderedSet *bookmarkSet = [NSMutableOrderedSet orderedSet];
        for (NSDictionary *bookmarkDict in [responseObject objectForKey:@"bookmarks"]){
            Bookmark *bookmark = [Bookmark MR_findFirstByAttribute:@"identifier" withValue:[bookmarkDict objectForKey:@"id"] inContext:[NSManagedObjectContext MR_defaultContext]];
            if (!bookmark){
                bookmark = [Bookmark MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [bookmark populateFromDict:bookmarkDict];
            [currentUser addBookmark:bookmark];
            [bookmarkSet addObject:bookmark];
        }
        for (Bookmark *bookmark in currentUser.bookmarks){
            if (![bookmarkSet containsObject:bookmark]){
                NSLog(@"Deleting a bookmark that no longer exists: %@",bookmark.story.title);
                [bookmark MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
            }
        }
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            loading = NO;
            [self.tableView beginUpdates];
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView endUpdates];
            [ProgressHUD dismiss];
        }];
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
    if (currentUser.bookmarks.count == 0 && !loading){
        return 1;
    } else {
        return currentUser.bookmarks.count;
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (currentUser.bookmarks.count){
        XXBookmarkCell *cell = (XXBookmarkCell *)[tableView dequeueReusableCellWithIdentifier:@"BookmarkCell"];
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"XXBookmarkCell" owner:nil options:nil] lastObject];
        }
        Bookmark *bookmark = [currentUser.bookmarks objectAtIndex:indexPath.row];
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
        [nothingButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kSourceSansProLight] size:0]];
        [nothingButton setTitleColor:textColor forState:UIControlStateNormal];
        [nothingButton setBackgroundColor:[UIColor clearColor]];
        [cell addSubview:nothingButton];
        [nothingButton setFrame:CGRectMake(20, 0, width-40, height-84)];
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
        self.reloadTheme = NO;
    }
    UIView *selectionView = [[UIView alloc] initWithFrame:cell.frame];
    [selectionView setBackgroundColor:[UIColor colorWithWhite:.9 alpha:.23]];
    cell.selectedBackgroundView = selectionView;
    cell.backgroundColor = [UIColor clearColor];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (currentUser.bookmarks.count && !loading){
        return 80;
    } else {
        return screenHeight()-64;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    Story *story = [currentUser.bookmarks[indexPath.row] story];
    if (story && story.identifier){
        [self performSegueWithIdentifier:@"Read" sender:story];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [super prepareForSegue:segue sender:sender];
    
    if ([segue.identifier isEqualToString:@"Read"] && [sender isKindOfClass:[Story class]]){
        XXStoryViewController *storyVC = [segue destinationViewController];
        [storyVC setStory:(Story*)sender];
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
        Bookmark *bookmark = [currentUser.bookmarks objectAtIndex:indexPathForDeletion.row];
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        if (bookmark.story && bookmark.story.identifier){
            [parameters setObject:bookmark.story.identifier forKey:@"story_id"];
        }
        [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"user_id"];
        [manager DELETE:[NSString stringWithFormat:@"%@/bookmarks/%@",kAPIBaseUrl,bookmark.identifier] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"Success deleting bookmark: %@",responseObject);
            [currentUser removeBookmark:bookmark];
            [bookmark MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
            if (currentUser.bookmarks.count == 0){
                [self.tableView reloadData];
            } else {
                [self.tableView beginUpdates];
                [self.tableView deleteRowsAtIndexPaths:@[indexPathForDeletion] withRowAnimation:UITableViewRowAnimationFade];
                [self.tableView endUpdates];
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
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self saveContext];
}

- (void)saveContext {
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
        NSLog(@"Saving bookmarks: %u",success);
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}
@end

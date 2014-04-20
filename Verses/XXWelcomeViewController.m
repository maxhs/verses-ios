//
//  XXWelcomeViewController.m
//  Verses
//
//  Created by Max Haines-Stiles on 10/11/13.
//  Copyright (c) 2013 Verses. All rights reserved.
//

#import "XXWelcomeViewController.h"
#import "XXStoryCell.h"
#import "XXProgress.h"
#import "XXStory.h"
#import "XXContribution.h"
#import "XXUser.h"
#import "XXPhoto.h"
#import "SWTableViewCell.h"
#import "SWRevealViewController.h"
#import "XXStoryViewController.h"
#import "XXAppDelegate.h"
#import "XXTutorialView.h"
#import "UIImage+ImageEffects.h"
#import <DTCoreText/DTCoreText.h>

@interface XXWelcomeViewController () <UIScrollViewDelegate, SWTableViewCellDelegate>{
    AFHTTPRequestOperationManager *manager;
    XXStory *story1;
    XXStory *story2;
    CGFloat width;
    CGFloat height;
    UIRefreshControl *refreshControl;
    XXTutorialView *tutorial;
    BOOL loading;
    BOOL canLoadMore;
    XXAppDelegate *delegate;
    NSDateFormatter *_formatter;
    UIColor *textColor;
}

@end

@implementation XXWelcomeViewController
@synthesize stories = _stories;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	if (!manager) manager = [AFHTTPRequestOperationManager manager];
    refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(handleRefresh) forControlEvents:UIControlEventValueChanged];
    [refreshControl setTintColor:[UIColor darkGrayColor]];
    [self.tableView addSubview:refreshControl];
    [self.tableView setSeparatorColor:[UIColor clearColor]];
    self.tableView.directionalLockEnabled = YES;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(menuRevealed) name:@"MenuRevealed" object:nil];
    if (![[NSUserDefaults standardUserDefaults] objectForKey:kNoPreview]) {
        [self performSelector:@selector(showPreview) withObject:nil afterDelay:1];
    }
    delegate = (XXAppDelegate*)[UIApplication sharedApplication].delegate;
    canLoadMore = YES;
    self.reloadTheme = NO;
    _formatter= [[NSDateFormatter alloc] init];
    [_formatter setLocale:[NSLocale currentLocale]];
    [_formatter setDateFormat:@"MMM, d - h:mm a"];
}

- (void)viewWillAppear:(BOOL)animated {
    
    [self.navigationController setNavigationBarHidden:YES];
    [delegate.dynamicsDrawerViewController setPaneDragRevealEnabled:NO forDirection:MSDynamicsDrawerDirectionRight];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
        textColor = [UIColor whiteColor];
        [self.view setBackgroundColor:[UIColor clearColor]];
        [refreshControl setTintColor:[UIColor whiteColor]];
    } else {
        textColor = [UIColor blackColor];
        [self.view setBackgroundColor:[UIColor whiteColor]];
        [refreshControl setTintColor:[UIColor darkGrayColor]];
    }
    if (self.reloadTheme){
        [self.tableView reloadData];
    }
    if (self.tableView.alpha == 0.0){
        [UIView animateWithDuration:.25 animations:^{
            [self.tableView setAlpha:1.0];
        }];
    }
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (!_stories || _stories.count == 0){
        [self loadEtherStories];
    } else if (_stories.count <= 5){
        [self loadMore];
    }
}

- (void)handleRefresh{
    [self loadEtherStories];
}

-(UIImage *)blurredSnapshot {
    UIGraphicsBeginImageContextWithOptions([UIScreen mainScreen].bounds.size, NO, self.view.window.screen.scale);
    [self.view drawViewHierarchyInRect:self.view.frame afterScreenUpdates:NO];
    UIImage *snapshotImage = UIGraphicsGetImageFromCurrentImageContext();
    UIImage *blurredSnapshotImage = [snapshotImage applyBlurWithRadius:7 blurType:BOXFILTER tintColor:[UIColor colorWithWhite:1 alpha:.7] saturationDeltaFactor:1.8 maskImage:nil];
    UIGraphicsEndImageContext();
    return blurredSnapshotImage;
}

- (void)showPreview {
    tutorial = [[XXTutorialView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    [tutorial showInView:self.view animateDuration:.5 withBackgroundImage:[self blurredSnapshot]];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kNoPreview];
}

- (void)menuRevealed {
    if (tutorial && tutorial.alpha == 1.0){
        [UIView animateWithDuration:.25 delay:.2 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            [tutorial setAlpha:0.0];
        } completion:^(BOOL finished) {
            [tutorial removeFromSuperview];
        }];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)loadEtherStories {
    [manager GET:[NSString stringWithFormat:@"%@/stories",kAPIBaseUrl] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"story response: %@",responseObject);
        _stories = [[Utilities storiesFromJSONArray:[responseObject objectForKey:@"stories"]] mutableCopy];
        [ProgressHUD dismiss];
        [self.tableView reloadData];
        if (refreshControl.isRefreshing) [refreshControl endRefreshing];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self.tableView reloadData];
        if (refreshControl.isRefreshing) [refreshControl endRefreshing];
        NSLog(@"Failure getting stories from welcome controller: %@",error.description);
        [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Something went wrong while trying to fetch the latest stories. Please pull down to refresh." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    }];
}

- (void)write{
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
        [self performSegueWithIdentifier:@"Write" sender:self];
    } else {
        [self shouldLogin];
    }
}

- (void)shouldLogin {
    [self performSegueWithIdentifier:@"Login" sender:self];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _stories.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    XXStoryCell *cell = (XXStoryCell *)[tableView dequeueReusableCellWithIdentifier:@"StoryCell"];
    if (cell == nil) {
        cell = [[[NSBundle mainBundle] loadNibNamed:@"XXStoryCell" owner:nil options:nil] lastObject];
    }
    XXStory *aStory = [_stories objectAtIndex:indexPath.row];
    [cell configureForStory:aStory textColor:textColor featured:NO cellHeight:170];
    
    if (aStory.minutesToRead == [NSNumber numberWithInt:0]){
        [cell.infoLabel setText:[NSString stringWithFormat:@"%@ words  |  Quick Read  |  %@",aStory.wordCount,[_formatter stringFromDate:aStory.updatedDate]]];
    } else {
        [cell.infoLabel setText:[NSString stringWithFormat:@"%@ words  |  %@ min to read  |  %@",aStory.wordCount,aStory.minutesToRead,[_formatter stringFromDate:aStory.updatedDate]]];
    }
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
        [cell.infoLabel setTextColor:textColor];
        [cell.separatorView setImage:[UIImage imageNamed:@"whiteSeparator"]];
    } else {
        [cell.infoLabel setTextColor:[UIColor lightGrayColor]];
        [cell.separatorView setImage:[UIImage imageNamed:@"blackSeparator"]];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor clearColor];
    UIView *selectedView = [[UIView alloc] initWithFrame:cell.frame];
    [selectedView setBackgroundColor:[UIColor colorWithWhite:.73 alpha:.23]];
    cell.selectedBackgroundView = selectedView;
    
    if([indexPath row] == ((NSIndexPath*)[[tableView indexPathsForVisibleRows] lastObject]).row && tableView == self.tableView){
        //end of loading
        [ProgressHUD dismiss];
        self.reloadTheme = NO;
        [self.tableView setSeparatorColor:[UIColor colorWithWhite:1 alpha:1]];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (IDIOM == IPAD){
        return 256;
    } else {
        return 190;
    }
    
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat actualPosition = scrollView.contentOffset.y;
    CGFloat contentHeight = scrollView.contentSize.height - (screenHeight()*2);
    if (actualPosition >= contentHeight && !loading && canLoadMore) {
        NSLog(@"should be loading more");
        [self loadMore];
    }
}

- (void)loadMore {
    loading = YES;
    XXStory *lastStory = _stories.lastObject;
    if (lastStory){
        [manager GET:[NSString stringWithFormat:@"%@/stories",kAPIBaseUrl] parameters:@{@"before_date":lastStory.epochTime, @"count":@"10"} success:^(AFHTTPRequestOperation *operation, id responseObject) {
            //NSLog(@"more stories response: %@",responseObject);
            NSArray *newStories = [Utilities storiesFromJSONArray:[responseObject objectForKey:@"stories"]];
            [_stories addObjectsFromArray:newStories];
            if (newStories.count < 10) {
                canLoadMore = NO;
                NSLog(@"can't load more, we now have %i stories", _stories.count);
            }
            [delegate.menuViewController setStories:_stories];
            [ProgressHUD dismiss];
            loading = NO;
            [self.tableView reloadData];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            
        }];
    } else {
        [self loadEtherStories];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
    [self performSegueWithIdentifier:@"Story" sender:indexPath];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [super prepareForSegue:segue sender:sender];
    if ([segue.identifier isEqualToString:@"Story"]) {
        if ([sender isKindOfClass:[NSIndexPath class]]) {
            XXStory *story = [_stories objectAtIndex:[(NSIndexPath*)sender row]];
            XXStoryViewController *vc = [segue destinationViewController];
            [vc setStory:story];
            [vc setStories:_stories];
        }
        [UIView animateWithDuration:.25 animations:^{
            [self.tableView setAlpha:0.0];
        }];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}
@end

//
//  XXGuideViewController.m
//  Verses
//
//  Created by Max Haines-Stiles on 6/5/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import "XXGuideViewController.h"
#import "XXSlotCell.h"
#import "XXWriteViewController.h"
#import "XXSearchCell.h"
#import "XXPortfolioViewController.h"
#import "XXAlert.h"
#import "XXLoginController.h"
#import "XXStoryViewController.h"
#import "XXNoRotateNavController.h"
#import "XXGalleryViewController.h"
#import "UIImage+ImageEffects.h"
#import "XXGuideInteractor.h"
#import "XXGuideCollectionCell.h"
#import "XXBookmarksViewController.h"
#import "XXCirclesViewController.h"
#import "XXSettingsViewController.h"
#import "XXFlowLayout.h"

@interface XXGuideViewController () <UISearchBarDelegate> {
    UIButton *dismissButton;
    NSAttributedString *searchPlaceholder;
    BOOL searching;
    BOOL signedIn;
    NSMutableArray *_filteredResults;
    NSMutableArray *_searchResults;
    AFHTTPRequestOperationManager *manager;
    UIView *headerView;
    XXStoriesViewController *stories;
    CGFloat width;
    CGFloat height;
    UIMotionEffectGroup *motion;
    UIButton *downButton;
    User *_currentUser;
}

@end

@implementation XXGuideViewController

@synthesize panTarget = _panTarget;

- (void)viewDidLoad {
    [super viewDidLoad];
    self.automaticallyAdjustsScrollViewInsets = NO;
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
    
    if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)){
        width = screenWidth();
        height = screenHeight();
    } else {
        height = screenWidth();
        width = screenHeight();
    }
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
        signedIn = YES;
        if ([(XXAppDelegate*)[UIApplication sharedApplication].delegate currentUser]){
            _currentUser = [(XXAppDelegate*)[UIApplication sharedApplication].delegate currentUser];
        } else {
            _currentUser = [User MR_findFirstByAttribute:@"identifier" withValue:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]];
        }
    } else {
        signedIn = NO;
    }
    dismissButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.view addSubview:dismissButton];
    [dismissButton setFrame:CGRectMake(width-54, height-54, 54, 54)];
    [dismissButton setImage:[UIImage imageNamed:@"whiteX"] forState:UIControlStateNormal];
    [dismissButton addTarget:self action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view setBackgroundColor:[UIColor blackColor]];
    [self.collectionView setBackgroundColor:[UIColor clearColor]];
    manager = [(XXAppDelegate*)[UIApplication sharedApplication].delegate manager];
    [self.view setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    
    UIImageView *backgroundImageView = [[UIImageView alloc] initWithFrame:self.view.frame];
    backgroundImageView.clipsToBounds = YES;
    [backgroundImageView setContentMode:UIViewContentModeScaleAspectFill];
    if (_currentUser.backgroundImageView){
        [backgroundImageView setImage:[(UIImageView*)[_currentUser backgroundImageView] image]];
    } else {
        [backgroundImageView setImage:[(UIImageView*)[(XXAppDelegate*)[UIApplication sharedApplication].delegate windowBackground] image]];
    }
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
        [backgroundImageView setAlpha:.14];
    } else {
        [backgroundImageView setAlpha:1];
    }
    backgroundImageView.layer.rasterizationScale = [UIScreen mainScreen].scale;
    backgroundImageView.layer.shouldRasterize = YES;
    [self.view addSubview:backgroundImageView];
    [self.view sendSubviewToBack:backgroundImageView];
    _filteredResults = [NSMutableArray array];
    _searchResults = [NSMutableArray array];
    
    if (![[NSUserDefaults standardUserDefaults] boolForKey:kHasSeenGuideView]){
        downButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [downButton setImage:[UIImage imageNamed:@"smallDownWhiteArrow"] forState:UIControlStateNormal];
        [downButton setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
        [downButton setFrame:CGRectMake(width/2-44, height-66, 88, 88)];
        [downButton addTarget:self action:@selector(scrollDown) forControlEvents:UIControlEventTouchUpInside];
        [self.view insertSubview:downButton aboveSubview:self.collectionView];
        [self pulsate:downButton withDelay:.75];
    }
    
    UIInterpolatingMotionEffect *verticalMotionEffect = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.y" type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
    verticalMotionEffect.minimumRelativeValue = @(-14);
    verticalMotionEffect.maximumRelativeValue = @(14);
    UIInterpolatingMotionEffect *horizontalMotionEffect = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.x" type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
    horizontalMotionEffect.minimumRelativeValue = @(-14);
    horizontalMotionEffect.maximumRelativeValue = @(14);
    motion = [UIMotionEffectGroup new];
    motion.motionEffects = @[horizontalMotionEffect, verticalMotionEffect];

    self.searchResultsTableView.rowHeight = 60.f;
    [self.searchResultsTableView setBackgroundColor:[UIColor colorWithWhite:0 alpha:.77]];
    [self.searchResultsTableView setAlpha:0.0];
    [self.searchBar setImage:[UIImage imageNamed:@"whiteSearchIcon"] forSearchBarIcon:UISearchBarIconSearch state:UIControlStateNormal];
    [self.searchBar setBackgroundColor:[UIColor clearColor]];
    searchPlaceholder = [[NSAttributedString alloc] initWithString:@"Search stories" attributes:@{ NSForegroundColorAttributeName : [UIColor whiteColor] }];
    
    headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, height/5)];
    [headerView setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    [headerView addSubview:self.searchBar];
    [self.searchBar setFrame:CGRectMake(0, 0, width, 44)];
    [self.searchBar setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    [self.collectionView addSubview:headerView];
    
    for (id subview in [self.searchBar.subviews.firstObject subviews]){
        [subview setTintColor:[UIColor whiteColor]];
        if ([subview isKindOfClass:[UITextField class]]){
            UITextField *searchTextField = (UITextField*)subview;
            [searchTextField setKeyboardAppearance:UIKeyboardAppearanceDark];
            [searchTextField setBackgroundColor:[UIColor clearColor]];
            searchTextField.layer.borderColor = [UIColor colorWithWhite:1 alpha:.7].CGColor;
            searchTextField.layer.borderWidth = 1.f;
            searchTextField.layer.cornerRadius = 14.f;
            searchTextField.clipsToBounds = YES;
            searchTextField.attributedPlaceholder = searchPlaceholder;
            [searchTextField setFont:[UIFont fontWithName:kSourceSansProRegular size:16]];
            break;
        }
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(willShowKeyboard:)
                                                 name:UIKeyboardWillShowNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
}

- (void)scrollDown {
    [UIView animateWithDuration:.7 delay:0 usingSpringWithDamping:.8 initialSpringVelocity:.0001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [self.collectionView setContentOffset:CGPointMake(0, height/2)];
    } completion:^(BOOL finished) {
        [self removeDownButton];
    }];
}

- (void)removeDownButton {
    [UIView animateWithDuration:.3 animations:^{
        [downButton setAlpha:0.0];
    } completion:^(BOOL finished) {
        [downButton removeFromSuperview];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kHasSeenGuideView];
    }];
}

-(UIImage *)blurredSnapshot:(BOOL)light {
    if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)){
        UIGraphicsBeginImageContextWithOptions([UIScreen mainScreen].bounds.size, NO, self.view.window.screen.scale);
        [self.view drawViewHierarchyInRect:self.view.frame afterScreenUpdates:NO];
    } else {
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(screenHeight(), screenWidth()), NO, self.view.window.screen.scale);
        [self.view drawViewHierarchyInRect:CGRectMake(0, 0, screenHeight(), screenWidth()) afterScreenUpdates:NO];
    }
    
    UIImage *snapshotImage = UIGraphicsGetImageFromCurrentImageContext();
    UIImage *blurredSnapshotImage = [snapshotImage applyBlurWithRadius:50 blurType:BOXFILTER tintColor:[UIColor colorWithWhite:0 alpha:0.53] saturationDeltaFactor:1.8 maskImage:nil];
    
    UIGraphicsEndImageContext();
    return blurredSnapshotImage;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    if (UIInterfaceOrientationIsPortrait(toInterfaceOrientation)){
        width = screenWidth();
        height = screenHeight();
    } else {
        height = screenWidth();
        width = screenHeight();
    }
    [self.collectionView invalidateIntrinsicContentSize];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    searching = YES;
    [self.searchBar setShowsCancelButton:YES animated:YES];
    
    [UIView animateWithDuration:.33 animations:^{
        [self.searchResultsTableView setAlpha:1.0];
    }];
    
    if (!_searchResults.count && !self.searchBar.text.length){
        [manager GET:[NSString stringWithFormat:@"%@/stories/titles",kAPIBaseUrl] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
            //NSLog(@"success fetching titles from guide view: %@",responseObject);
            _searchResults = [self updateLocalStories:[responseObject objectForKey:@"titles"]];
            [_filteredResults removeAllObjects];
            [_filteredResults addObjectsFromArray:_searchResults];
            
            [self.searchResultsTableView beginUpdates];
            [self.searchResultsTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
            [self.searchResultsTableView endUpdates];
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            //NSLog(@"Failure getting search stories titles: %@",error.description);
        }];
        [self.searchResultsTableView reloadData];
    }
}

- (NSMutableArray*)updateLocalStories:(NSArray*)array{
    NSMutableArray *storyArray = [NSMutableArray array];
    for (NSDictionary *dict in array){
        if ([dict objectForKey:@"id"] && [dict objectForKey:@"id"] != [NSNull null]){
            Story *story = [Story MR_findFirstByAttribute:@"identifier" withValue:[dict objectForKey:@"id"]];
            if (!story){
                story = [Story MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [story populateFromDict:dict];
            [storyArray addObject:story];
        }
    }
    [self saveContext];
    return storyArray;
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    searching = NO;
    [self.searchBar setText:@""];
    [self.searchBar setShowsCancelButton:NO animated:YES];
    [self.view endEditing:YES];
    [UIView animateWithDuration:.33 animations:^{
        [self.searchResultsTableView setAlpha:0.0];
    }];
}

- (BOOL)searchBar:(UISearchBar *)searchBar shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    NSString* newText = [searchBar.text stringByReplacingCharactersInRange:range withString:text];
    [self filterContentForSearchText:newText scope:nil];
    return YES;
}

- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope {
    [_filteredResults removeAllObjects]; // First clear the filtered array.
    for (Story *story in _searchResults){
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF contains[cd] %@", searchText];
        if([predicate evaluateWithObject:story.title]) {
            [_filteredResults addObject:story];
        }
    }
    [self.searchResultsTableView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (scrollView == self.tableView && scrollView.contentOffset.y > 60.f && UIInterfaceOrientationIsPortrait(self.interfaceOrientation)){
        [self dismiss];
    }
}*/

-(void)willShowKeyboard:(NSNotification*)notification {
    NSDictionary* keyboardInfo = [notification userInfo];
    NSValue* keyboardFrameBegin = [keyboardInfo valueForKey:UIKeyboardFrameBeginUserInfoKey];
    CGFloat keyboardHeight = [keyboardFrameBegin CGRectValue].size.height;
    self.searchResultsTableView.contentInset = UIEdgeInsetsMake(0, 0, keyboardHeight, 0);
}

#pragma mark – UICollectionViewDelegateFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (IDIOM == IPAD){
        return CGSizeMake(width/3,width/3);
    } else {
        return CGSizeMake(width/2,width/2);
    }
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(0, 0, 0, 0);
}

#pragma mark - UICollectionView Datasource

- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section {
    return 12;
}

- (NSInteger)numberOfSectionsInCollectionView: (UICollectionView *)collectionView {
    return 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    XXGuideCollectionCell *cell = [cv dequeueReusableCellWithReuseIdentifier:@"GuideCell" forIndexPath:indexPath];
    [cell.guideLabel setTextColor:[UIColor whiteColor]];
    [cell.guideLabel setFont:[UIFont fontWithName:kSourceSansProSemibold size:19]];
    cell.guideLabel.numberOfLines = 0;
    
    [cell.imageView addMotionEffect:motion];
    [cell.guideLabel addMotionEffect:motion];
    
    cell.layer.borderColor = [UIColor colorWithWhite:1 alpha:.1].CGColor;
    cell.layer.borderWidth = .5f;
    
    switch (indexPath.item) {
        //left column
        case 0:
            [cell.imageView setImage:[UIImage imageNamed:@"menuHome"]];
            [cell.guideLabel setText:@"Browse"];
            break;
        case 2:
            [cell.imageView setImage:[UIImage imageNamed:@"menuFeatured"]];
            [cell.guideLabel setText:@"Featured"];
            break;
        case 4:
            [cell.imageView setImage:[UIImage imageNamed:@"menuTrending"]];
            [cell.guideLabel setText:@"Trending"];
            break;
        case 6:
            [cell.imageView setImage:[UIImage imageNamed:@"menuCircles"]];
            [cell.guideLabel setText:@"Writing Circles"];
            
            break;
        case 8:
            [cell.imageView setImage:[UIImage imageNamed:@"menuShared"]];
            [cell.guideLabel setText:@"Shared"];
            break;
        case 10:
            [cell.imageView setImage:[UIImage imageNamed:@"menuPhotos"]];
            [cell.guideLabel setText:@"Photo Gallery"];
            break;
            
        case 1:
            [cell.imageView setImage:[UIImage imageNamed:@"menuWrite"]];
            [cell.guideLabel setText:@"Write"];
            break;
        case 3:
            [cell.imageView setImage:[UIImage imageNamed:@"menuSlowReveal"]];
            [cell.guideLabel setText:@"Slow Reveal"];
            break;
        case 5:
            [cell.imageView setImage:[UIImage imageNamed:@"menuDrafts"]];
            [cell.guideLabel setText:@"Drafts"];
            break;
        case 7:
            [cell.imageView setImage:[UIImage imageNamed:@"menuPortfolio"]];
            [cell.guideLabel setText:@"Portfolio"];
            break;
        case 9:
            [cell.imageView setImage:[UIImage imageNamed:@"menuBookmarks"]];
            [cell.guideLabel setText:@"Bookmarks"];

            break;
            
        
        case 11:
            [cell.imageView setImage:[UIImage imageNamed:@"menuSettings"]];
            [cell.guideLabel setText:@"Settings"];
        
            break;
        default:
            break;
    }
    return cell;
}

#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.item) {
        case 0:
            [self goBrowse];
            break;
        case 1:
            if (signedIn){
                [self goWrite];
            } else {
                [self login];
            }
            
            break;
        case 2:
            [self goFeatured];
            break;
        case 3:
            if (signedIn){
                [self goSlowReveal];
            } else {
                [self login];
            }
            
            break;
        case 4:
            [self goTrending];
            break;
        case 5:
            if (signedIn){
                [self goToDrafts];
            } else {
                [self login];
            }
            
            break;
            
        case 6:
            if (signedIn){
                [self goToCircles];
            } else {
                [self login];
            }
            break;
        case 8:
            if (signedIn){
                [self goShared];
            } else {
                [self login];
            }
            break;
        case 7:
            if (signedIn){
                [self goToPortfolio];
            } else {
                [self login];
            }
            break;
            
        case 10:
            [self goGallery];
            break;
        case 9:
            if (signedIn){
                [self goToBookmarks];
            } else {
                [self login];
            }
            
            break;
        case 11:
            if (signedIn){
                [self goToSettings];
            } else {
                [self login];
            }
            break;
            
        default:
            break;
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView.contentOffset.y > 100){
        [self removeDownButton];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {

}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == self.searchResultsTableView && searching){
        if (_filteredResults.count){
            return _filteredResults.count;
        } else if (self.searchBar.text) {
            return 1;
        } else {
            return 0;
        }
    } else {
        return 3;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //if (searching && tableView == self.searchResultsTableView){
        if (_filteredResults.count){
            XXSearchCell *cell = (XXSearchCell *)[tableView dequeueReusableCellWithIdentifier:@"SearchCell"];
            if (cell == nil) {
                cell = [[[NSBundle mainBundle] loadNibNamed:@"XXSearchCell" owner:nil options:nil] lastObject];
            }
            Story *story;
            if (searching){
                story = [_filteredResults objectAtIndex:indexPath.row];
            } else {
                story = [_searchResults objectAtIndex:indexPath.row];
            }
            
            [cell configure:story];
            return cell;
        } else {
            XXSearchCell *cell = (XXSearchCell *)[tableView dequeueReusableCellWithIdentifier:@"SearchCell"];
            if (cell == nil) {
                cell = [[[NSBundle mainBundle] loadNibNamed:@"XXSearchCell" owner:nil options:nil] lastObject];
            }
            [cell.storyTitle setText:@"No results."];
            [cell.authorLabel setText:@""];
            //[cell.authorLabel setText:@"Tap to search again..."];
            [cell.authorLabel setFont:[UIFont fontWithName:kSourceSansProItalic size:15]];
            return cell;
        }
    /*} else {
        XXSlotCell *cell = (XXSlotCell *)[tableView dequeueReusableCellWithIdentifier:@"GuideCell"];
        if (cell == nil) {
            if (IDIOM == IPAD){
                cell = [[[NSBundle mainBundle] loadNibNamed:@"XXSlotCell_ipad" owner:nil options:nil] lastObject];
            } else {
                cell = [[[NSBundle mainBundle] loadNibNamed:@"XXSlotCell" owner:nil options:nil] lastObject];
            }
        }
        if (indexPath.row == 0){
            [cell.topSeparator setHidden:NO];
        } else {
            [cell.topSeparator setHidden:YES];
        }
        [cell configureWidth:screenWidth()];
        cell.scrollView.scrollEnabled = YES;
        CGFloat buttonWidth = cell.firstButton.frame.size.width;
        switch (indexPath.row) {
            case 0:
                
                [cell.firstButton setTitle:@"FEATURED" forState:UIControlStateNormal];
                [cell.firstButton addTarget:self action:@selector(goFeatured) forControlEvents:UIControlEventTouchUpInside];
                [cell.secondButton setTitle:@"BROWSE" forState:UIControlStateNormal];
                [cell.secondButton addTarget:self action:@selector(goBrowse) forControlEvents:UIControlEventTouchUpInside];
                [cell.thirdButton setTitle:@"TRENDING" forState:UIControlStateNormal];
                [cell.thirdButton addTarget:self action:@selector(goTrending) forControlEvents:UIControlEventTouchUpInside];
                
                [cell.scrollView setContentSize:CGSizeMake(buttonWidth*3, 0)];
                [cell.scrollView setContentOffset:CGPointMake(buttonWidth, 0)];
                //[self pulsate:cell.leftButton withDelay:.5];
                //[self pulsate:cell.rightButton withDelay:.5];
                break;
            case 1:
                
                [cell.firstButton setTitle:@"SLOW REVEAL" forState:UIControlStateNormal];
                [cell.firstButton addTarget:self action:@selector(goSlowReveal) forControlEvents:UIControlEventTouchUpInside];
                [cell.secondButton setTitle:@"WRITE" forState:UIControlStateNormal];
                [cell.secondButton addTarget:self action:@selector(goWrite) forControlEvents:UIControlEventTouchUpInside];
                if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
                    [cell.thirdButton setTitle:@"DRAFTS" forState:UIControlStateNormal];
                    [cell.thirdButton addTarget:self action:@selector(goToDrafts) forControlEvents:UIControlEventTouchUpInside];
                    [cell.scrollView setContentSize:CGSizeMake(buttonWidth*3, 0)];
                    [cell.scrollView setContentOffset:CGPointMake(buttonWidth, 0)];
                } else {
                    [cell.scrollView setContentSize:CGSizeMake(buttonWidth*2, 0)];
                }
                //[self pulsate:cell.leftButton withDelay:.6];
                //[self pulsate:cell.rightButton withDelay:.6];
                break;
            case 2:
                if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
                    
                    [cell.firstButton setTitle:@"SHARED WITH ME" forState:UIControlStateNormal];
                    [cell.firstButton addTarget:self action:@selector(goShared) forControlEvents:UIControlEventTouchUpInside];
                    [cell.secondButton setTitle:@"PORTFOLIO" forState:UIControlStateNormal];
                    [cell.secondButton addTarget:self action:@selector(goToPortfolio) forControlEvents:UIControlEventTouchUpInside];
                    [cell.thirdButton setTitle:@"PHOTO GALLERY" forState:UIControlStateNormal];
                    [cell.thirdButton addTarget:self action:@selector(goGallery) forControlEvents:UIControlEventTouchUpInside];
                    cell.scrollView.scrollEnabled = YES;
                    [cell.scrollView setContentSize:CGSizeMake(buttonWidth*3, 0)];
                    [cell.scrollView setContentOffset:CGPointMake(buttonWidth, 0)];
                } else {
                    [cell.firstButton setTitle:@"PORTFOLIO" forState:UIControlStateNormal];
                    [cell.firstButton addTarget:self action:@selector(login) forControlEvents:UIControlEventTouchUpInside];
                    [cell.secondButton setTitle:@"PHOTO GALLERY" forState:UIControlStateNormal];
                    [cell.secondButton addTarget:self action:@selector(goGallery) forControlEvents:UIControlEventTouchUpInside];
                    [cell.scrollView setContentSize:CGSizeMake(buttonWidth*2, 0)];
                }
                //[self pulsate:cell.leftButton withDelay:.7];
                //[self pulsate:cell.rightButton withDelay:.7];
                break;
                
            default:
                break;
        }
        return cell;
    }*/
}

- (void)pulsate:(id)obj withDelay:(CGFloat)delay{
    [UIView animateWithDuration:.5 delay:delay options:UIViewAnimationOptionCurveEaseIn animations:^{
        [obj setAlpha:1.0];
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:1 delay:.23 options:UIViewAnimationOptionCurveEaseOut animations:^{
            [obj setAlpha:0.0];
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:.5 delay:delay options:UIViewAnimationOptionCurveEaseIn animations:^{
                [obj setAlpha:1.0];
            } completion:^(BOOL finished) {
                [UIView animateWithDuration:1 delay:.23 options:UIViewAnimationOptionCurveEaseOut animations:^{
                    [obj setAlpha:0.0];
                } completion:^(BOOL finished) {
                    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kHasSeenGuideView];
                }];
            }];
        }];
    }];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor clearColor];
    UIView *selectionView = [[UIView alloc] initWithFrame:cell.frame];
    [selectionView setBackgroundColor:[UIColor clearColor]];
    cell.selectedBackgroundView = selectionView;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (tableView == self.searchResultsTableView && _filteredResults.count){
        Story *story = [_filteredResults objectAtIndex:indexPath.row];
        XXStoryViewController *storyVC = [[self storyboard] instantiateViewControllerWithIdentifier:@"Story"];
        XXStoriesViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Stories"];
        [vc setEther:YES];
        [storyVC setStoryId:story.identifier];
        UINavigationController *nav = [[UINavigationController alloc] init];
        nav.viewControllers = @[vc,storyVC];
        [[(XXAppDelegate*)[UIApplication sharedApplication].delegate dynamicsDrawerViewController] setPaneViewController:nav];
        [self dismissViewControllerAnimated:YES completion:^{
            
        }];
    }
}

- (void)goBrowse {
    [self setStoriesAsPane];
    stories.ether = YES;
    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)goFeatured {
    [self setStoriesAsPane];
    stories.featured = YES;
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)goTrending {
    [self setStoriesAsPane];
    stories.trending = YES;
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)goShared {
    [self setStoriesAsPane];
    stories.shared = YES;
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)goGallery {
    XXGalleryViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Gallery"];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    [[(XXAppDelegate*)[UIApplication sharedApplication].delegate dynamicsDrawerViewController] setPaneViewController:nav];
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)setStoriesAsPane {
    stories = [[self storyboard] instantiateViewControllerWithIdentifier:@"Stories"];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:stories];
    [[(XXAppDelegate*)[UIApplication sharedApplication].delegate dynamicsDrawerViewController] setPaneViewController:nav];
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
}

- (void)goWrite {
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
        XXWriteViewController *write = [[self storyboard] instantiateViewControllerWithIdentifier:@"Write"];
        write.mystery = NO;
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:write];
        [[(XXAppDelegate*)[UIApplication sharedApplication].delegate dynamicsDrawerViewController] setPaneViewController:nav];
        [self dismissViewControllerAnimated:YES completion:^{
            
        }];
    } else {
        [self login];
    }
    
}
- (void)goSlowReveal {
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
        XXWriteViewController *write = [[self storyboard] instantiateViewControllerWithIdentifier:@"Write"];
        write.mystery = YES;
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:write];
        [[(XXAppDelegate*)[UIApplication sharedApplication].delegate dynamicsDrawerViewController] setPaneViewController:nav];
        [self dismissViewControllerAnimated:YES completion:^{
            [XXAlert show:@"Participants will only see the last 250 characters of each contribution." withTime:3.3f];
        }];
    } else {
        [self login];
    }
}

- (void)login {
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    XXLoginController *login = [[self storyboard] instantiateViewControllerWithIdentifier:@"Login"];
    XXNoRotateNavController *nav = [[XXNoRotateNavController alloc] initWithRootViewController:login];
    [self presentViewController:nav animated:YES completion:^{
        
    }];
}

- (void)goToPortfolio {
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    XXPortfolioViewController *portfolio = [[self storyboard] instantiateViewControllerWithIdentifier:@"Portfolio"];
    [portfolio setDraftMode:NO];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:portfolio];
    [[(XXAppDelegate*)[UIApplication sharedApplication].delegate dynamicsDrawerViewController] setPaneViewController:nav];
    [self dismissViewControllerAnimated:YES completion:^{
    
    }];
}

- (void)goToDrafts {
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    XXPortfolioViewController *portfolio = [[self storyboard] instantiateViewControllerWithIdentifier:@"Portfolio"];
    [portfolio setDraftMode:YES];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:portfolio];
    [[(XXAppDelegate*)[UIApplication sharedApplication].delegate dynamicsDrawerViewController] setPaneViewController:nav];
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)goToBookmarks {
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    XXBookmarksViewController *bookmarks = [[self storyboard] instantiateViewControllerWithIdentifier:@"Bookmarks"];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:bookmarks];
    [[(XXAppDelegate*)[UIApplication sharedApplication].delegate dynamicsDrawerViewController] setPaneViewController:nav];
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)goToCircles {
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    XXCirclesViewController *circles = [[self storyboard] instantiateViewControllerWithIdentifier:@"Circles"];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:circles];
    [[(XXAppDelegate*)[UIApplication sharedApplication].delegate dynamicsDrawerViewController] setPaneViewController:nav];
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)goToSettings {
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    XXSettingsViewController *settings = [[self storyboard] instantiateViewControllerWithIdentifier:@"Settings"];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:settings];
    [[(XXAppDelegate*)[UIApplication sharedApplication].delegate dynamicsDrawerViewController] setPaneViewController:nav];
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    self.transitioningDelegate = nil;
    _filteredResults = nil;
    _searchResults = nil;
    [downButton removeFromSuperview];
}

-(void)saveContext {
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
        NSLog(@"%u success saving stories.",success);
    }];
}

- (void)dismiss {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end

//
//  XXGalleryViewController.m
//  Verses
//
//  Created by Max Haines-Stiles on 6/8/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import "XXGalleryViewController.h"
#import "Photo+helper.h"
#import "XXPhotoCollectionCell.h"
#import "XXGuideTransition.h"
#import "XXGuideViewController.h"

@interface XXGalleryViewController () <UIViewControllerTransitioningDelegate> {
    AFHTTPRequestOperationManager *manager;
    UIButton *menuButton;
    UIButton *cancelButton;
    UIButton *sortButton;
    CGFloat width;
    CGFloat height;
    NSArray *photos;
    CGRect originalPhotoFrame;
    XXPhotoCollectionCell *selectedCell;
    UITapGestureRecognizer *tapGesture;
}

@end

@implementation XXGalleryViewController

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
    if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)){
        width = screenWidth();
        height = screenHeight();
    } else {
        height = screenWidth();
        width = screenHeight();
    }
    [self.navigationController setNavigationBarHidden:YES];
    manager = [(XXAppDelegate*)[UIApplication sharedApplication].delegate manager];
    photos = [Photo MR_findAllSortedBy:@"createdDate" ascending:NO];
    [self loadGallery];
    menuButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [menuButton setImage:[UIImage imageNamed:@"moreWhite"] forState:UIControlStateNormal];
    [menuButton addTarget:self action:@selector(back) forControlEvents:UIControlEventTouchUpInside];
    [menuButton setFrame:CGRectMake(width-44, 0, 44, 44)];
    [self.view addSubview:menuButton];
    
    sortButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [sortButton setTitle:@"Sort" forState:UIControlStateNormal];
    [sortButton.titleLabel setFont:[UIFont fontWithName:kSourceSansProRegular size:16]];
    [sortButton addTarget:self action:@selector(sort) forControlEvents:UIControlEventTouchUpInside];
    [sortButton setFrame:CGRectMake(0, 0, 44, 44)];
    //[self.view addSubview:sortButton];
    
    cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [cancelButton setImage:[UIImage imageNamed:@"whiteX"] forState:UIControlStateNormal];
    [cancelButton addTarget:self action:@selector(unfocus) forControlEvents:UIControlEventTouchUpInside];
    [cancelButton setFrame:CGRectMake(width-44, 0, 44, 44)];
    [cancelButton setHidden:YES];
    [self.view addSubview:cancelButton];
}

- (void)sort {
    NSLog(@"should be sorting");
}

- (void)loadGallery {
    [manager GET:[NSString stringWithFormat:@"%@/photos",kAPIBaseUrl] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Success fetching gallery: %@",responseObject);
        for (NSDictionary *dict in [responseObject objectForKey:@"photos"]){
            if ([dict objectForKey:@"id"] && [dict objectForKey:@"id"] != [NSNull null]){
                Photo *photo = [Photo MR_findFirstByAttribute:@"identifier" withValue:[dict objectForKey:@"id"]];
                if (!photo){
                    photo = [Photo MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                }
                [photo populateFromDict:dict];
            }
        }
        photos = [Photo MR_findAllSortedBy:@"createdDate" ascending:NO];
        [self.collectionView reloadData];
        [self saveContext];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error fetching gallery: %@",error.description);
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UICollectionView Datasource

- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section {
    return [Photo MR_findAll].count;
}

- (NSInteger)numberOfSectionsInCollectionView: (UICollectionView *)collectionView {
    return 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    XXPhotoCollectionCell *cell = [cv dequeueReusableCellWithReuseIdentifier:@"PhotoCell" forIndexPath:indexPath];
    Photo *photo = photos[indexPath.row];
    [cell.photoButton setTag:[photos indexOfObject:photo]];
    [cell configureForPhoto:photo];
    [cell.photoButton setUserInteractionEnabled:NO];
    return cell;
}

#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    selectedCell = (XXPhotoCollectionCell*)[collectionView cellForItemAtIndexPath:indexPath];
    [collectionView bringSubviewToFront:selectedCell];
    [self dimCollectionBackground];
    originalPhotoFrame = selectedCell.frame;
    CGRect photoFrame = originalPhotoFrame;
    photoFrame.origin.x = 0;
    photoFrame.origin.y = (height/2)-(width/2);
    photoFrame.size.width = width;
    photoFrame.size.height = width;
    [UIView animateWithDuration:.77 delay:0 usingSpringWithDamping:.87 initialSpringVelocity:.0001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [selectedCell setFrame:photoFrame];
    } completion:^(BOOL finished) {
    }];
}
- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    [self deselectCell];
    [self unfocus];
}
- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    if (UIInterfaceOrientationIsPortrait(toInterfaceOrientation)){
        width = screenWidth();
        height = screenHeight();
    } else {
        height = screenWidth();
        width = screenHeight();
    }
    [menuButton setFrame:CGRectMake(width-44, 0, 44, 44)];
}

- (void)dimCollectionBackground {
    [UIView animateWithDuration:.33 animations:^{
        for (NSIndexPath *indexPath in _collectionView.indexPathsForVisibleItems){
            XXPhotoCollectionCell *cell = (XXPhotoCollectionCell*)[_collectionView cellForItemAtIndexPath:indexPath];
            if (cell != selectedCell){
                [cell setAlpha:0.23];
            }
        }
    }completion:^(BOOL finished) {
        [menuButton setHidden:YES];
        [cancelButton setHidden:NO];
    }];
}

- (void)deselectCell {
    [UIView animateWithDuration:.4 delay:0 usingSpringWithDamping:.87 initialSpringVelocity:.0001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [selectedCell setFrame:originalPhotoFrame];
    } completion:^(BOOL finished) {

    }];
}

- (void)unfocus {
    [self deselectCell];
    [UIView animateWithDuration:.33 animations:^{
        for (NSIndexPath *indexPath in _collectionView.indexPathsForVisibleItems){
            XXPhotoCollectionCell *cell = (XXPhotoCollectionCell*)[_collectionView cellForItemAtIndexPath:indexPath];
            [cell setAlpha:1.0];
        }
    }completion:^(BOOL finished) {
        [menuButton setHidden:NO];
        [cancelButton setHidden:YES];
    }];
}

#pragma mark – UICollectionViewDelegateFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(screenWidth()/4,screenWidth()/4);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(0, 0, 0, 0);
}

- (void)back{
    XXGuideViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Guide"];
    vc.transitioningDelegate = self;
    vc.modalPresentationStyle = UIModalPresentationCustom;
    [self presentViewController:vc animated:YES completion:nil];
    XXAppDelegate *delegate = (XXAppDelegate*)[UIApplication sharedApplication].delegate;
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
        [UIView animateWithDuration:.3 animations:^{
            [[delegate.dynamicsDrawerViewController paneViewController].view setAlpha:1.0];
        }];
    }
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented
                                                                  presentingController:(UIViewController *)presenting
                                                                      sourceController:(UIViewController *)source {
    
    XXGuideTransition *animator = [XXGuideTransition new];
    animator.presenting = YES;
    return animator;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    XXGuideTransition *animator = [XXGuideTransition new];
    return animator;
}

- (void)saveContext {
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
        
    }];
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

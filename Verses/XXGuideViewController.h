//
//  XXGuideViewController.h
//  Verses
//
//  Created by Max Haines-Stiles on 6/5/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import <UIKit/UIKit.h>

// This protocol is only to silence the compiler since we're using one of two different classes.
@protocol XXGuidePanTarget <NSObject>

-(void)userDidPan:(UIScreenEdgePanGestureRecognizer *)gestureRecognizer;
-(void)setPresenting:(BOOL)presenting;

@end

@interface XXGuideViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UICollectionViewDelegate>
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UITableView *searchResultsTableView;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (nonatomic) id<XXGuidePanTarget> panTarget;

@end


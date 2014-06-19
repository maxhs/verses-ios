//
//  XXCircleDetailViewController.h
//  Verses
//
//  Created by Max Haines-Stiles on 3/30/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Circle+helper.h"
#import "User+helper.h"
#import "Story+helper.h"
#import "XXChat.h"

@class XXCircleDetailViewController;

@interface XXCircleDetailViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, XXChatDelegate>

@property (weak, nonatomic) IBOutlet UITableView *detailsTableView;
@property (weak, nonatomic) IBOutlet UITableView *storiesTableView;
@property (weak, nonatomic) NSNumber *circleId;
@property (strong, nonatomic) Circle *circle;
@property (strong, nonatomic) UICollectionView *collectionView;
@property (strong, nonatomic) XXChat *chatInput;
@property (nonatomic) BOOL needsNavigation;

@end

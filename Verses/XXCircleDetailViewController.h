//
//  XXCircleDetailViewController.h
//  Verses
//
//  Created by Max Haines-Stiles on 3/30/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XXCircle.h"
#import "XXUser.h"
#import "XXStory.h"
#import "XXChat.h"

@class XXCircleDetailViewController;

@interface XXCircleDetailViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, XXChatDelegate>

@property (weak, nonatomic) IBOutlet UITableView *detailsTableView;
@property (weak, nonatomic) IBOutlet UITableView *storiesTableView;
@property (strong, nonatomic) XXCircle *circle;
@property (strong, nonatomic) UICollectionView *collectionView;
@property (strong, nonatomic) XXChat *chatInput;

@end

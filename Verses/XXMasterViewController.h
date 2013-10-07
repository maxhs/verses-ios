//
//  XXMasterViewController.h
//  Verses
//
//  Created by Max Haines-Stiles on 10/6/13.
//  Copyright (c) 2013 Verses. All rights reserved.
//

#import <UIKit/UIKit.h>

@class XXDetailViewController;

#import <CoreData/CoreData.h>

@interface XXMasterViewController : UITableViewController <NSFetchedResultsControllerDelegate>

@property (strong, nonatomic) XXDetailViewController *detailViewController;

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@end

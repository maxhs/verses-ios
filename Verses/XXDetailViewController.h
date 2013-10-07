//
//  XXDetailViewController.h
//  Verses
//
//  Created by Max Haines-Stiles on 10/6/13.
//  Copyright (c) 2013 Verses. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface XXDetailViewController : UIViewController <UISplitViewControllerDelegate>

@property (strong, nonatomic) id detailItem;

@property (weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;
@end

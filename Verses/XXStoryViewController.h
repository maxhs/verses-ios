//
//  XXStoryViewController.h
//  Verses
//
//  Created by Max Haines-Stiles on 11/4/13.
//  Copyright (c) 2013 Verses. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XXStory.h"
#import "XXContribution.h"
#import "XXUser.h"
#import "User.h"
#import <MSDynamicsDrawerViewController/MSDynamicsDrawerViewController.h>
#import "XXPhotoButton.h"

@interface XXStoryViewController : UIViewController <UIScrollViewDelegate, UITableViewDataSource, UITableViewDelegate, UITextViewDelegate>

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) XXStory *story;
@property (strong, nonatomic) NSMutableArray *stories;
@property (weak, nonatomic) MSDynamicsDrawerViewController *dynamicsViewController;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *authorsLabel;
@property (weak, nonatomic) IBOutlet XXPhotoButton *imageButton;
@property (strong, nonatomic) UIImageView *backgroundImageView;

- (void)resetWithStory:(XXStory*)newStory;
@end

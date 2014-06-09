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

@interface XXStoryViewController : UIViewController <UIScrollViewDelegate, UITextViewDelegate>
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) UILabel *titleLabel;
@property (strong, nonatomic) UILabel *authorsLabel;
@property (strong, nonatomic) XXPhotoButton *imageButton;
@property (strong, nonatomic) XXStory *story;
@property (strong, nonatomic) NSNumber *storyId;
@property (strong, nonatomic) NSMutableArray *stories;
@property (weak, nonatomic) MSDynamicsDrawerViewController *dynamicsViewController;
@property (strong, nonatomic) UIImageView *backgroundImageView;
- (void)resetWithStory:(XXStory*)newStory;
@end

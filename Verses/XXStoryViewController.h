//
//  XXStoryViewController.h
//  Verses
//
//  Created by Max Haines-Stiles on 11/4/13.
//  Copyright (c) 2013 Verses. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Story+helper.h"
#import "Contribution+helper.h"
#import "User+helper.h"
#import <MSDynamicsDrawerViewController/MSDynamicsDrawerViewController.h>
#import "XXStoryPhoto.h"

@interface XXStoryViewController : UIViewController <UIScrollViewDelegate, UITextViewDelegate>
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) UILabel *titleLabel;
@property (strong, nonatomic) UILabel *authorsLabel;
@property (strong, nonatomic) XXStoryPhoto *storyPhoto;
@property (strong, nonatomic) Story *story;
@property (strong, nonatomic) NSNumber *storyId;
@property (weak, nonatomic) MSDynamicsDrawerViewController *dynamicsViewController;
@property (strong, nonatomic) UIImageView *backgroundImageView;
- (void)resetWithStory:(Story*)newStory;
@end

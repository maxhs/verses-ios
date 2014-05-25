//
//  XXAppDelegate.h
//  Verses
//
//  Created by Max Haines-Stiles on 10/6/13.
//  Copyright (c) 2013 Verses. All rights reserved.
//

#import <MSDynamicsDrawerViewController/MSDynamicsDrawerViewController.h>
#import "XXStoryInfoViewController.h"
#import "XXMenuViewController.h"
#import <AFNetworking/AFHTTPRequestOperationManager.h>

@interface XXAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) MSDynamicsDrawerViewController *dynamicsDrawerViewController;
@property (strong, nonatomic) XXStoryInfoViewController *storyInfoViewController;
@property (strong, nonatomic) XXMenuViewController *menuViewController;
@property (strong, nonatomic) AFHTTPRequestOperationManager *manager;
@property (nonatomic, strong) UIImageView *windowBackground;
@property (strong, nonatomic) User *currentUser;
@property BOOL offline;
- (void)switchBackgroundTheme;
@end

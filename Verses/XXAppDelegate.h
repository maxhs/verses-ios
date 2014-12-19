//
//  XXAppDelegate.h
//  Verses
//
//  Created by Max Haines-Stiles on 10/6/13.
//  Copyright (c) 2013 Verses. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <MSDynamicsDrawerViewController/MSDynamicsDrawerViewController.h>
#import "XXStoryInfoViewController.h"
#import "XXMenuViewController.h"
#import <MagicalRecord/CoreData+MagicalRecord.h>
#import <AFNetworking/AFHTTPRequestOperationManager.h>
#import "Constants.h"
#import "Utilities.h"
#import "ProgressHUD.h"

@protocol XXLoginDelegate <NSObject>

@optional
- (void)incorrectEmail;
- (void)userAlreadyExists;
- (void)penNameTaken;
- (void)incorrectPassword;
@required
- (void)loginSuccessful;
@end

@interface XXAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) MSDynamicsDrawerViewController *dynamicsDrawerViewController;
@property (strong, nonatomic) XXStoryInfoViewController *storyInfoViewController;
@property (strong, nonatomic) XXMenuViewController *menuViewController;
@property (strong, nonatomic) AFHTTPRequestOperationManager *manager;
@property (nonatomic, strong) UIImageView *windowBackground;
@property (strong, nonatomic) NSURL *backgroundURL;
@property (strong, nonatomic) User *currentUser;
@property (weak, nonatomic) id<XXLoginDelegate> loginDelegate;
@property BOOL loadingBackground;
@property BOOL connected;
- (void)switchBackgroundTheme;
- (void)cleanAndResetupDB;
- (void)connect:(NSDictionary*)parameters withLoginUI:(BOOL)showUI;
- (void)setUserDefaults:(User*)user;
@end

//
//  XXAppDelegate.m
//  Verses
//
//  Created by Max Haines-Stiles on 10/6/13.
//  Copyright (c) 2013 Verses. All rights reserved.
//

#import "XXAppDelegate.h"
#import "XXStoriesViewController.h"
#import "XXStoriesViewController.h"
#import "User+helper.h"
#import <DTCoreText/DTCoreText.h>
#import <Crashlytics/Crashlytics.h>
#import <Mixpanel/Mixpanel.h>
#import "UIImage+ImageEffects.h"
#import "XXCircleDetailViewController.h"
#import "XXStoryViewController.h"
#import "XXProfileViewController.h"
#import <SDWebImage/UIImageView+WebCache.h>
#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)

@interface XXAppDelegate () {
    XXStoriesViewController *welcome;
    NSTimer *timer;
}

@property (nonatomic, strong) UIImageView *defaultBackground;
@end

@implementation XXAppDelegate

@synthesize manager = _manager;
@synthesize backgroundURL = _backgroundURL;
@synthesize currentUser = _currentUser;
@synthesize windowBackground = _windowBackground;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [MagicalRecord setShouldDeleteStoreOnModelMismatch:YES];
    [MagicalRecord setupAutoMigratingCoreDataStack];
    
    [Crashlytics startWithAPIKey:@"5c452a0455dfb4bdd2ee98051181f661006365a4"];
    [Mixpanel sharedInstanceWithToken:MIXPANEL_TOKEN];
    
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
    [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        switch (status) {
            case AFNetworkReachabilityStatusReachableViaWWAN:
            case AFNetworkReachabilityStatusReachableViaWiFi:
                NSLog(@"Connected");
                _connected = YES;
                break;
            case AFNetworkReachabilityStatusNotReachable:
            default:
                NSLog(@"Not online");
                _connected = NO;
                [self offlineNotification];
                break;
        }
    }];
    
    [self customizeAppearance];
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsMobileToken]){
        NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsMobileToken] forKey:@"mobile_token"];
        [self connect:parameters withLoginUI:NO];
        NSLog(@"Auto log in from app delegate");
    } else {
        _currentUser = [User MR_findFirstByAttribute:@"identifier" withValue:[NSNumber numberWithInt:0] inContext:[NSManagedObjectContext MR_defaultContext]];
        
        // if there's still no user, i.e. this is the first time the user has opened the app, create one.
        if (!_currentUser){
            _currentUser = [User MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
        }
    }
    
    self.dynamicsDrawerViewController = (MSDynamicsDrawerViewController *)self.window.rootViewController;
    self.dynamicsDrawerViewController.bounceElasticity = 1.3f;
    self.dynamicsDrawerViewController.gravityMagnitude = 7.f;
    if (IDIOM == IPAD){
        [self.dynamicsDrawerViewController setRevealWidth:384.f forDirection:MSDynamicsDrawerDirectionLeft];
        [self.dynamicsDrawerViewController setRevealWidth:384.f forDirection:MSDynamicsDrawerDirectionRight];
    } else {
        [self.dynamicsDrawerViewController setRevealWidth:280.f forDirection:MSDynamicsDrawerDirectionLeft];
        [self.dynamicsDrawerViewController setRevealWidth:280.f forDirection:MSDynamicsDrawerDirectionRight];
    }
    
    MSDynamicsDrawerScaleStyler *menuScale = [MSDynamicsDrawerScaleStyler styler];
    [menuScale setClosedScale:.23];
    // left drawer
    [self.dynamicsDrawerViewController addStylersFromArray:@[menuScale, [MSDynamicsDrawerFadeStyler styler], [MSDynamicsDrawerParallaxStyler styler]] forDirection:MSDynamicsDrawerDirectionLeft];
    self.menuViewController = [self.window.rootViewController.storyboard instantiateViewControllerWithIdentifier:@"Menu"];
    [self.dynamicsDrawerViewController setDrawerViewController:self.menuViewController forDirection:MSDynamicsDrawerDirectionLeft];
    
    // right drawer
    [self.dynamicsDrawerViewController addStylersFromArray:@[[MSDynamicsDrawerScaleStyler styler],[MSDynamicsDrawerFadeStyler styler], [MSDynamicsDrawerParallaxStyler styler]] forDirection:MSDynamicsDrawerDirectionRight];
    self.storyInfoViewController = [self.window.rootViewController.storyboard instantiateViewControllerWithIdentifier:@"StoryInfo"];
    self.storyInfoViewController.dynamicsDrawerViewController = self.dynamicsDrawerViewController;
    [self.dynamicsDrawerViewController setDrawerViewController:self.storyInfoViewController forDirection:MSDynamicsDrawerDirectionRight];
    
    _manager = [[AFHTTPRequestOperationManager manager] initWithBaseURL:[NSURL URLWithString:kAPIBaseUrl]];
    _manager.requestSerializer = [AFJSONRequestSerializer serializer];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = self.dynamicsDrawerViewController;
    [self.window makeKeyAndVisible];
    
    if (launchOptions != nil && [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey]){
        NSDictionary* dictionary = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
        
        if (dictionary != nil) [self redirect:dictionary];
    
    } else {
        [self.window addSubview:self.defaultBackground];
        [self.window sendSubviewToBack:self.defaultBackground];
        welcome = [self.window.rootViewController.storyboard instantiateViewControllerWithIdentifier:@"Stories"];
        welcome.ether = YES;
        [self transition];
    }
    [self setupWindowBackground];

    return YES;
}

- (void)transition {
    UIImageView *screenshot;
    if (UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation])){
        screenshot = [[UIImageView alloc] initWithFrame:self.window.frame];
    } else {
        screenshot = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, screenHeight(), screenWidth())];
    }
    [screenshot setImage:[self blurredSnapshot]];
    [self.window addSubview:screenshot];
    [_defaultBackground removeFromSuperview];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:welcome];
    [self.dynamicsDrawerViewController setPaneViewController:nav];
    [UIView animateWithDuration:0.5 animations:^{
        [screenshot setAlpha:0.0];
    } completion:^(BOOL finished) {
        [screenshot removeFromSuperview];
    }];
}

#pragma mark - XXAppDelegate

- (UIImageView *)defaultBackground {
    if (!_defaultBackground) {
        if (IDIOM == IPAD){
            if (UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation])){
                _defaultBackground = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"iPadDefault"]];
            } else {
                _defaultBackground = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"iPadDefault-Landscape"]];
                [_defaultBackground setBounds:CGRectMake(0, 0, screenHeight(), screenWidth())];
                CGAffineTransform translation = CGAffineTransformMakeTranslation(-128, 128);
                CGAffineTransform rotate = CGAffineTransformMakeRotation(RADIANS(90));
                _defaultBackground.transform = CGAffineTransformConcat(rotate, translation);
            }
        } else if ([UIScreen mainScreen].bounds.size.height >= 568) {
            _defaultBackground = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Default-568h"]];
        } else {
            _defaultBackground = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Default"]];
        }
    }
    return _defaultBackground;
}

- (void)setupWindowBackground {
    if (!_windowBackground) {
        if (_currentUser.backgroundImageView) {
            _windowBackground = [[UIImageView alloc] initWithFrame:[UIScreen mainScreen].bounds];
            [_windowBackground setImage:[(UIImageView*)_currentUser.backgroundImageView image]];
        } else {
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
                _windowBackground = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"background_ipad"]];
            } else {
                _windowBackground = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"background"]];
            }
        }
    }
    
    [[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground] ? [_windowBackground setAlpha:.14] : [_windowBackground setAlpha:1];
    
    [_windowBackground setContentMode:UIViewContentModeScaleAspectFill];
    [self.window addSubview:_windowBackground];
    [self.window sendSubviewToBack:_windowBackground];
}

- (void)customizeAppearance {
    /*for (NSString* family in [UIFont familyNames]){
        NSLog(@"%@", family);
        for (NSString* name in [UIFont fontNamesForFamilyName: family])
            NSLog(@"  %@", name);
    }*/
    
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setTextColor:[UIColor whiteColor]];
    [[UIButton appearanceWhenContainedIn:[UISearchBar class], nil] setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [[UIButton appearance] setTitleColor:kElectricBlue forState:UIControlStateHighlighted];
    [[UIButton appearance] setTitleColor:kElectricBlue forState:UIControlStateSelected];
    
    UIImage *backImage = [[UIImage imageNamed:@"back"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 23, 0, 10)];
    [[UIBarButtonItem appearanceWhenContainedIn:[UIImagePickerController class], nil] setBackButtonBackgroundImage:[UIImage new] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    [[UIBarButtonItem appearance] setBackButtonBackgroundImage:backImage forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    NSShadow *clearShadow = [[NSShadow alloc] init];
    clearShadow.shadowColor = [UIColor clearColor];
    
    [[UINavigationBar appearanceWhenContainedIn:[XXProfileViewController class], nil] setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    /*[[UINavigationBar appearanceWhenContainedIn:[XXProfileViewController class], nil] setShadowImage:[UIImage new]];
    [[UINavigationBar appearanceWhenContainedIn:[XXProfileViewController class], nil] setTranslucent:YES];*/
    
    [[UIBarButtonItem appearance] setTitleTextAttributes:@{
                                                           NSFontAttributeName : [UIFont fontWithName:kSourceSansProRegular size:17],
                                                           NSShadowAttributeName : clearShadow,
                                                           NSForegroundColorAttributeName : [UIColor blackColor],
                                                           } forState:UIControlStateNormal];
    
    [[UIBarButtonItem appearance] setTitlePositionAdjustment:UIOffsetMake(0, 0) forBarMetrics:UIBarMetricsDefault];

    [[UISwitch appearance] setOnTintColor:kElectricBlue];
    
    [DTCoreTextFontDescriptor setOverrideFontName:@"CrimsonText-Roman" forFontFamily:@"Crimson" bold:NO italic:NO];
    [DTCoreTextFontDescriptor setOverrideFontName:@"CrimsonText-Italic" forFontFamily:@"Crimson" bold:NO italic:YES];
    [DTCoreTextFontDescriptor setOverrideFontName:@"CrimsonText-Semibold" forFontFamily:@"Crimson" bold:YES italic:NO];
    [DTCoreTextFontDescriptor setOverrideFontName:@"Courier" forFontFamily:@"Courier" bold:YES italic:NO];
    [self switchBackgroundTheme];
}

- (void)switchBackgroundTheme {
    [self.window setBackgroundColor:[UIColor blackColor]];
    NSShadow *clearShadow = [[NSShadow alloc] init];
    clearShadow.shadowColor = [UIColor clearColor];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
        [[UINavigationBar appearance] setTitleTextAttributes:@{
                                                               NSForegroundColorAttributeName: [UIColor whiteColor],
                                                               NSFontAttributeName: [UIFont fontWithName:kSourceSansProSemibold size:21],
                                                               NSShadowAttributeName: clearShadow,
                                                               }];
        [[UIBarButtonItem appearance] setTitleTextAttributes:@{
                                                               NSFontAttributeName : [UIFont fontWithName:kSourceSansProRegular size:17],
                                                               NSShadowAttributeName : clearShadow,
                                                               NSForegroundColorAttributeName : [UIColor whiteColor],
                                                               } forState:UIControlStateNormal];
        [UIView animateWithDuration:.23 animations:^{
            [_windowBackground setAlpha:.14];
            [[UIBarButtonItem appearance] setTintColor:[UIColor whiteColor]];
            [[UINavigationBar appearance] setBarStyle:UIBarStyleBlackTranslucent];
        }];
        
    } else {
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
        [[UINavigationBar appearance] setTitleTextAttributes:@{
                                                               NSForegroundColorAttributeName: [UIColor blackColor],
                                                               NSFontAttributeName: [UIFont fontWithName:kSourceSansProSemibold size:21],
                                                               NSShadowAttributeName: clearShadow,
                                                               }];
        [[UIBarButtonItem appearance] setTitleTextAttributes:@{
                                                               NSFontAttributeName : [UIFont fontWithName:kSourceSansProRegular size:17],
                                                               NSShadowAttributeName : clearShadow,
                                                               NSForegroundColorAttributeName : [UIColor blackColor],
                                                               } forState:UIControlStateNormal];
        [UIView animateWithDuration:.23 animations:^{
            [_windowBackground setAlpha:1];
            [[UIBarButtonItem appearance] setTintColor:[UIColor blackColor]];
            [[UINavigationBar appearance] setBarStyle:UIBarStyleDefault];
        }];
        
    }
}

-(void)redirect:(NSDictionary*)dict {
    if ([dict objectForKey:@"circle_id"] && [dict objectForKey:@"circle_id"] != [NSNull null]) {
        XXCircleDetailViewController *vc = [self.window.rootViewController.storyboard instantiateViewControllerWithIdentifier:@"CircleDetail"];
        [vc setCircleId:[dict objectForKey:@"circle_id"]];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        [self.dynamicsDrawerViewController setPaneViewController:nav];
    } else if ([dict objectForKey:@"story_id"] && [dict objectForKey:@"story_id"] != [NSNull null]) {
        XXStoryViewController *vc = [self.window.rootViewController.storyboard instantiateViewControllerWithIdentifier:@"Story"];
        [vc setStoryId:[dict objectForKey:@"story_id"]];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        [self.dynamicsDrawerViewController setPaneViewController:nav];
    } else if ([dict objectForKey:@"target_user_id"] && [dict objectForKey:@"target_user_id"] != [NSNull null]) {
        XXProfileViewController *vc = [self.window.rootViewController.storyboard instantiateViewControllerWithIdentifier:@"Profile"];
        [vc setUserId:[dict objectForKey:@"target_user_id"]];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        [self.dynamicsDrawerViewController setPaneViewController:nav];
    }
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)pushMessage
{
    //[Flurry logEvent:@"Did Receive Remote Notification"];
    [[Mixpanel sharedInstance] track:@"Just received a push message"];
    NSLog(@"Received push: %@",pushMessage);
    [self redirect:pushMessage];
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    NSLog(@"handle open url: %@, %@, %@",url, url.scheme, url.query);
    if ([[url scheme] isEqualToString:kUrlScheme]) {
        if ([[url query] length]) {
            NSDictionary *urlDict = [self parseQueryString:[url query]];
            if ([urlDict objectForKey:@"circle_id"] && [urlDict objectForKey:@"circle_id"] != [NSNull null]) {
                XXCircleDetailViewController *vc = [self.window.rootViewController.storyboard instantiateViewControllerWithIdentifier:@"CircleDetail"];
                [vc setCircleId:[urlDict objectForKey:@"circle_id"]];
                UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
                [self.dynamicsDrawerViewController setPaneViewController:nav];
            } else if ([urlDict objectForKey:@"story_id"] && [urlDict objectForKey:@"story_id"] != [NSNull null]) {
                XXStoryViewController *vc = [self.window.rootViewController.storyboard instantiateViewControllerWithIdentifier:@"Story"];
                [vc setStoryId:[urlDict objectForKey:@"story_id"]];
                UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
                [self.dynamicsDrawerViewController setPaneViewController:nav];
            } else if ([urlDict objectForKey:@"target_user_id"] && [urlDict objectForKey:@"target_user_id"] != [NSNull null]) {
                XXProfileViewController *vc = [self.window.rootViewController.storyboard instantiateViewControllerWithIdentifier:@"Profile"];
                [vc setUserId:[urlDict objectForKey:@"target_user_id"]];
                NSLog(@"go to profile");
                UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
                [self.dynamicsDrawerViewController setPaneViewController:nav];
            }
        }
    }
    return YES;
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
    NSLog(@"open url: %@",url);
    if ([[url scheme] isEqualToString:kUrlScheme]) {
        if ([[url query] length]) {
            NSDictionary *urlDict = [self parseQueryString:[url query]];
            if ([urlDict objectForKey:@"circle_id"]) {
                XXCircleDetailViewController *vc = [self.window.rootViewController.storyboard instantiateViewControllerWithIdentifier:@"CircleDetail"];
                [vc setCircleId:[urlDict objectForKey:@"circle_id"]];
                UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
                [self.dynamicsDrawerViewController setPaneViewController:nav];
            } else if ([urlDict objectForKey:@"story_id"]) {
                XXStoryViewController *vc = [self.window.rootViewController.storyboard instantiateViewControllerWithIdentifier:@"Story"];
                [vc setStoryId:[urlDict objectForKey:@"story_id"]];
                UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
                [self.dynamicsDrawerViewController setPaneViewController:nav];
            } else if ([urlDict objectForKey:@"target_user_id"] && [urlDict objectForKey:@"target_user_id"] != [NSNull null]) {
                XXProfileViewController *vc = [self.window.rootViewController.storyboard instantiateViewControllerWithIdentifier:@"Profile"];
                [vc setUserId:[urlDict objectForKey:@"target_user_id"]];
                UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
                [self.window.rootViewController presentViewController:nav animated:YES completion:nil];
                //[self.dynamicsDrawerViewController setPaneViewController:nav];
            }
        }
    }
    return YES;
}

- (NSDictionary *)parseQueryString:(NSString *)query {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    NSArray *pairs = [query componentsSeparatedByString:@"&"];
    for (NSString *pair in pairs) {
        NSArray *elements = [pair componentsSeparatedByString:@"="];
        NSString *key = [[elements objectAtIndex:0] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSString *val = [[elements objectAtIndex:1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        [dict setObject:val forKey:key];
    }
    //NSLog(@"parsed query dict: %@",dict);
    return dict;
}

- (void)connect:(NSDictionary*)parameters withLoginUI:(BOOL)showUI {
    [_manager POST:[NSString stringWithFormat:@"%@/sessions",kAPIBaseUrl] parameters:@{@"user":parameters} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Success logging in from app delegate: %@",responseObject);
        [self askForPushPermissions];
        
        //NSLog(@"success logging in: %@",responseObject);
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@",[[responseObject objectForKey:@"user"] objectForKey:@"id"]];\
        User *currentUser = [User MR_findFirstWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];
        if (!currentUser) {
            currentUser = [User MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
        }
        [currentUser populateFromDict:[responseObject objectForKey:@"user"]];
        
        //the only purpose of this user was to store the background image. get rid of it now
        User *blankUser = [User MR_findFirstByAttribute:@"identifier" withValue:[NSNumber numberWithInt:0] inContext:[NSManagedObjectContext MR_defaultContext]];
        if (blankUser){
            if (blankUser.backgroundImageView){
                currentUser.backgroundImageView = blankUser.backgroundImageView;
            }
            [blankUser MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
        }
        if (currentUser.backgroundUrl.length){
            [[[SDWebImageManager sharedManager] imageCache] clearDisk];
            [[SDWebImageManager sharedManager] downloadImageWithURL:[NSURL URLWithString:currentUser.backgroundUrl] options:0 progress:^(NSInteger receivedSize, NSInteger expectedSize) {
                
            } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
                
                currentUser.backgroundImageView = [[UIImageView alloc] initWithFrame:[UIScreen mainScreen].bounds];
                [currentUser.backgroundImageView setImage:image];
                [currentUser.backgroundImageView setContentMode:UIViewContentModeScaleAspectFill];
                [(UIImageView*)currentUser.backgroundImageView setClipsToBounds:YES];
                [_windowBackground setImage:image];
            }];
        }
        
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            _currentUser = currentUser;
            [self setUserDefaults:currentUser];
            //not sure if we need this one anymore since we got rid of the slot view in favor of the collectionview
            //[[NSNotificationCenter defaultCenter] postNotificationName:@"ReloadGuide" object:nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ReloadMenu" object:nil];
        }];
        
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        NSLog(@"Failed to log in from appdelegate. Here's the response string: %@",operation.responseString);
        if (showUI) [ProgressHUD dismiss];
        
        if (operation.response.statusCode == 401) {
            if ([operation.responseString isEqualToString:kIncorrectPassword]){
                if (self.loginDelegate && [self.loginDelegate respondsToSelector:@selector(incorrectPassword)]) {
                    [self.loginDelegate incorrectPassword];
                }
            } else if ([operation.responseString isEqualToString:kUserAlreadyExists]) {
                if (self.loginDelegate && [self.loginDelegate respondsToSelector:@selector(userAlreadyExists)]) {
                    [self.loginDelegate userAlreadyExists];
                }
            } else if ([operation.responseString isEqualToString:kNoEmail]) {
                if (self.loginDelegate && [self.loginDelegate respondsToSelector:@selector(incorrectEmail)]) {
                    [self.loginDelegate incorrectEmail];
                }
            } else if ([operation.responseString isEqualToString:kPenNameTaken]) {
                if (self.loginDelegate && [self.loginDelegate respondsToSelector:@selector(penNameTaken)]) {
                    [self.loginDelegate penNameTaken];
                }
            } else {
                [[[UIAlertView alloc] initWithTitle:@"Uh oh" message:@"Something went wrong while trying to log you in." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
            }
        } else {
            [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Something went wrong while trying to log you in." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        }
    }];
}

- (void)askForPushPermissions {
    //only ask for push notifications when a user has successfully logged in
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.f){
        [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge) categories:nil]];
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    } else {
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound)];
    }
}

- (void)setUserDefaults:(User*)user {
    [[NSUserDefaults standardUserDefaults] setObject:user.identifier forKey:kUserDefaultsId];
    [[NSUserDefaults standardUserDefaults] setObject:user.email forKey:kUserDefaultsEmail];
    [[NSUserDefaults standardUserDefaults] setObject:user.mobileToken forKey:kUserDefaultsMobileToken];
    [[NSUserDefaults standardUserDefaults] setObject:user.penName forKey:kUserDefaultsPenName];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken {
    [[NSUserDefaults standardUserDefaults] setObject:deviceToken forKey:kUserDefaultsDeviceToken];
    [[NSUserDefaults standardUserDefaults] synchronize];
    //NSLog(@"device token: %@",[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsDeviceToken]);
}

- (void)application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError*)error {
    //[Flurry logEvent:@"Rejected Remote Notifications"];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    if (!_currentUser && [[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
        _currentUser = [User MR_findFirstByAttribute:@"identifier" withValue:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] inContext:[NSManagedObjectContext MR_defaultContext]];
    }
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

-(UIImage *)blurredSnapshot {
    UIGraphicsBeginImageContextWithOptions([UIScreen mainScreen].bounds.size, NO, self.window.screen.scale);
    [self.window drawViewHierarchyInRect:self.window.frame afterScreenUpdates:NO];
    UIImage *snapshotImage = UIGraphicsGetImageFromCurrentImageContext();
    UIImage *blurredSnapshotImage = [snapshotImage applyBlurWithRadius:20 blurType:BOXFILTER tintColor:[UIColor colorWithWhite:1 alpha:.6] saturationDeltaFactor:1.8 maskImage:nil];
    UIGraphicsEndImageContext();
    return blurredSnapshotImage;
}

- (void)offlineNotification {
    [[[UIAlertView alloc] initWithTitle:@"Offline" message:@"Your device appears to be offline." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
}

- (void)cleanAndResetupDB {
    NSError *error = nil;
    NSURL *storeURL = [NSPersistentStore MR_urlForStoreName:@"Verses"];
    [MagicalRecord cleanUp];
    if([[NSFileManager defaultManager] removeItemAtURL:storeURL error:&error]){
        [MagicalRecord setupCoreDataStackWithAutoMigratingSqliteStoreNamed:@"Verses"];
    } else{
        NSLog(@"Error deleting persistent store description: %@ %@", error.description,storeURL);
    }
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [MagicalRecord cleanUp];
}

@end

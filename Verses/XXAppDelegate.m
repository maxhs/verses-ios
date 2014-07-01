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

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound)];
    [MagicalRecord setupCoreDataStackWithAutoMigratingSqliteStoreNamed:@"Verses"];
    [Crashlytics startWithAPIKey:@"5c452a0455dfb4bdd2ee98051181f661006365a4"];
    [Mixpanel sharedInstanceWithToken:MIXPANEL_TOKEN];
    
    /*for (NSString* family in [UIFont familyNames]){
        NSLog(@"%@", family);
        for (NSString* name in [UIFont fontNamesForFamilyName: family])
            NSLog(@"  %@", name);
    }*/
    
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
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
        _currentUser = [User MR_findFirstByAttribute:@"identifier" withValue:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]];
    } else {
        _currentUser = [User MR_findFirstByAttribute:@"identifier" withValue:[NSNumber numberWithInt:0]];
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
        if (dictionary != nil) {
            //NSLog(@"dictionary: %@",dictionary);
            [self redirect:dictionary];
        }
    } else {
        [self.window addSubview:self.defaultBackground];
        [self.window sendSubviewToBack:self.defaultBackground];
        welcome = [self.window.rootViewController.storyboard instantiateViewControllerWithIdentifier:@"Stories"];
        welcome.ether = YES;
        [self transition];
    }

    [self.window addSubview:self.windowBackground];
    [self.window sendSubviewToBack:self.windowBackground];
    [self customizeAppearance];
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

- (UIImageView *)defaultBackground
{
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

- (UIImageView *)windowBackground
{
    if (!_windowBackground) {
        if (_currentUser.backgroundImageView) {
            _windowBackground = _currentUser.backgroundImageView;
        } else {
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
                _windowBackground = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"background_ipad"]];
            } else {
                _windowBackground = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"background"]];
            }
        }
        [_windowBackground setAlpha:1];
    }
    
    [_windowBackground setContentMode:UIViewContentModeScaleAspectFill];
    return _windowBackground;
}

-(UIImage *)blurredSnapshot {
    UIGraphicsBeginImageContextWithOptions([UIScreen mainScreen].bounds.size, NO, self.window.screen.scale);
    [self.window drawViewHierarchyInRect:self.window.frame afterScreenUpdates:NO];
    UIImage *snapshotImage = UIGraphicsGetImageFromCurrentImageContext();
    UIImage *blurredSnapshotImage = [snapshotImage applyBlurWithRadius:20 blurType:BOXFILTER tintColor:[UIColor colorWithWhite:1 alpha:.6] saturationDeltaFactor:1.8 maskImage:nil];
    UIGraphicsEndImageContext();
    return blurredSnapshotImage;
}

- (void)customizeAppearance {    
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
                                                           NSForegroundColorAttributeName : kElectricBlue,
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
    NSShadow *clearShadow = [[NSShadow alloc] init];
    clearShadow.shadowColor = [UIColor clearColor];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
        [[UINavigationBar appearance] setTitleTextAttributes:@{
                                                               NSForegroundColorAttributeName: [UIColor whiteColor],
                                                               NSFontAttributeName: [UIFont fontWithName:kSourceSansProSemibold size:21],
                                                               NSShadowAttributeName: clearShadow,
                                                               }];
        [UIView animateWithDuration:.23 animations:^{
            [_windowBackground setAlpha:.14];
            [[UIBarButtonItem appearance] setTintColor:[UIColor whiteColor]];
            [self.window setBackgroundColor:[UIColor blackColor]];
            [[UINavigationBar appearance] setBarStyle:UIBarStyleBlackTranslucent];
        }];
        
    } else {
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
        [[UINavigationBar appearance] setTitleTextAttributes:@{
                                                               NSForegroundColorAttributeName: [UIColor blackColor],
                                                               NSFontAttributeName: [UIFont fontWithName:kSourceSansProSemibold size:21],
                                                               NSShadowAttributeName: clearShadow,
                                                               }];
        [UIView animateWithDuration:.23 animations:^{
            [_windowBackground setAlpha:1];
            [[UIBarButtonItem appearance] setTintColor:[UIColor blackColor]];
            [self.window setBackgroundColor:[UIColor blackColor]];
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
    //NSLog(@"Received push: %@",pushMessage);
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
         annotation:(id)annotation
{
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

- (void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken
{
    //[Flurry logEvent:@"Registered For Remote Notifications"];
    [[NSUserDefaults standardUserDefaults] setObject:deviceToken forKey:kUserDefaultsDeviceToken];
    [[NSUserDefaults standardUserDefaults] synchronize];
    //NSLog(@"device token: %@",[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsDeviceToken]);
}

- (void)application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError*)error
{
    //[Flurry logEvent:@"Rejected Remote Notifications"];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    if (!_currentUser && [[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
        _currentUser = [User MR_findFirstByAttribute:@"identifier" withValue:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]];
    }
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
    //refresh user data by signing them in again
    /*if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsEmail] forKey:@"email"];
        if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsDeviceToken]){
            [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsDeviceToken] forKey:@"device_token"];
        }
        
        if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsPassword]) {
            [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsPassword] forKey:@"password"];
            [[AFHTTPRequestOperationManager manager] POST:[NSString stringWithFormat:@"%@/sessions", kAPIBaseUrl] parameters:@{@"user":parameters} success:^(AFHTTPRequestOperation *operation, id responseObject) {
                //NSLog(@"success logging in from app delegate: %@",responseObject);
                
                NSManagedObjectContext *defaultContext = [NSManagedObjectContext MR_defaultContext];
                NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [[responseObject objectForKey:@"user"] objectForKey:@"id"]];
                _currentUser = [User MR_findFirstWithPredicate:predicate inContext:defaultContext];
                if (!_currentUser) {
                    _currentUser = [User MR_createInContext:defaultContext];
                }
                [_currentUser populateFromDict:[responseObject objectForKey:@"user"]];
                
                [[NSUserDefaults standardUserDefaults] setObject:_currentUser.identifier forKey:kUserDefaultsId];
                [[NSUserDefaults standardUserDefaults] setObject:_currentUser.authToken forKey:kUserDefaultsAuthToken];
                [[NSUserDefaults standardUserDefaults] setObject:_currentUser.penName forKey:kUserDefaultsPenName];
                [[NSUserDefaults standardUserDefaults] setObject:_currentUser.picSmall forKey:kUserDefaultsPicSmall];
                [[NSUserDefaults standardUserDefaults] setObject:_currentUser.picLarge forKey:kUserDefaultsPicLarge];
                [[NSUserDefaults standardUserDefaults] synchronize];
                
                [defaultContext MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                    NSLog(@"Saving user to persistent store: %u",success);
                }];
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                //NSLog(@"Failure logging in from app delegate: %@",error.description);
            }];
        }
    }*/
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

- (void)applicationWillTerminate:(UIApplication *)application
{
    [MagicalRecord cleanUp];
}

@end

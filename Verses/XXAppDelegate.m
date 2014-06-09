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
@synthesize stories = _stories;
@synthesize backgroundURL = _backgroundURL;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound)];
    [MagicalRecord setupCoreDataStackWithAutoMigratingSqliteStoreNamed:@"Verses"];
    [Crashlytics startWithAPIKey:@"5c452a0455dfb4bdd2ee98051181f661006365a4"];
    [Mixpanel sharedInstanceWithToken:MIXPANEL_TOKEN];
    
    /*for (NSString* family in [UIFont familyNames]){
        NSLog(@"%@", family);
        for (NSString* name in [UIFont fontNamesForFamilyName: family])
        {
            NSLog(@"  %@", name);
        }
    }*/
    
    self.dynamicsDrawerViewController = (MSDynamicsDrawerViewController *)self.window.rootViewController;
    self.dynamicsDrawerViewController.bounceElasticity = 2;
    self.dynamicsDrawerViewController.gravityMagnitude = 3;
    if (IDIOM == IPAD){
        [self.dynamicsDrawerViewController setRevealWidth:672.f forDirection:MSDynamicsDrawerDirectionLeft];
        [self.dynamicsDrawerViewController setRevealWidth:672.f forDirection:MSDynamicsDrawerDirectionRight];
    } else {
        [self.dynamicsDrawerViewController setRevealWidth:280.f forDirection:MSDynamicsDrawerDirectionLeft];
        [self.dynamicsDrawerViewController setRevealWidth:280.f forDirection:MSDynamicsDrawerDirectionRight];
    }
    
    MSDynamicsDrawerScaleStyler *menuScale = [MSDynamicsDrawerScaleStyler styler];
    [menuScale setClosedScale:.13];
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
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
            _windowBackground = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"background_ipad"]];
        } else {
            _windowBackground = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"background"]];
        }
        [_windowBackground setAlpha:1];
    }
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
    
    NSShadow *clearShadow = [[NSShadow alloc] init];
    clearShadow.shadowColor = [UIColor clearColor];
    
    [[UIBarButtonItem appearance] setTitleTextAttributes:@{
                                                           NSFontAttributeName : [UIFont fontWithName:kSourceSansProRegular size:15],
                                                           NSShadowAttributeName : clearShadow,
                                                           NSForegroundColorAttributeName : kElectricBlue,
                                                           } forState:UIControlStateNormal];
    
    [[UIBarButtonItem appearance] setTitlePositionAdjustment:UIOffsetMake(0, 0) forBarMetrics:UIBarMetricsDefault];

    [[UISwitch appearance] setOnTintColor:kElectricBlue];
    [DTCoreTextFontDescriptor setOverrideFontName:@"CrimsonText-Roman" forFontFamily:@"Crimson" bold:NO italic:NO];
    [DTCoreTextFontDescriptor setOverrideFontName:@"CrimsonText-Italic" forFontFamily:@"Crimson" bold:NO italic:YES];
    [DTCoreTextFontDescriptor setOverrideFontName:@"CrimsonText-Semibold" forFontFamily:@"Crimson" bold:YES italic:NO];

    [self switchBackgroundTheme];
}

- (void)switchBackgroundTheme {
    NSShadow *clearShadow = [[NSShadow alloc] init];
    clearShadow.shadowColor = [UIColor clearColor];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
        
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
        UIImage *backImage = [[UIImage imageNamed:@"whiteBack"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 23, 0, 10)];
        [[UIBarButtonItem appearance] setBackButtonBackgroundImage:backImage forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
        [[UINavigationBar appearance] setTitleTextAttributes:@{
                                                               NSForegroundColorAttributeName: [UIColor whiteColor],
                                                               NSFontAttributeName: [UIFont fontWithName:kSourceSansProSemibold size:21],
                                                               NSShadowAttributeName: clearShadow,
                                                               }];
        [UIView animateWithDuration:.23 animations:^{
            [_windowBackground setAlpha:.23];
            [[UIBarButtonItem appearance] setTintColor:[UIColor whiteColor]];
            [self.window setBackgroundColor:[UIColor blackColor]];
            [[UINavigationBar appearance] setBarStyle:UIBarStyleBlackTranslucent];
        }];
        
    } else {
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
        UIImage *backImage = [[UIImage imageNamed:@"back"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 23, 0, 10)];
        [[UIBarButtonItem appearance] setBackButtonBackgroundImage:backImage forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
        [[UINavigationBar appearance] setTitleTextAttributes:@{
                                                               NSForegroundColorAttributeName: [UIColor blackColor],
                                                               NSFontAttributeName: [UIFont fontWithName:kSourceSansProSemibold size:21],
                                                               NSShadowAttributeName: clearShadow,
                                                               }];
        [UIView animateWithDuration:.23 animations:^{
            [_windowBackground setAlpha:1];
            [[UIBarButtonItem appearance] setTintColor:[UIColor blackColor]];
            [self.window setBackgroundColor:[UIColor whiteColor]];
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
    NSLog(@"handle open url: %@",url);
    if ([[url scheme] isEqualToString:kUrlScheme]) {
        if ([[url query] length]) {
            NSDictionary *urlDict = [self parseQueryString:[url query]];
            if ([urlDict objectForKey:@"circle_id"] && [urlDict objectForKey:@"circle_id"] != [NSNull null]) {
                XXCircleDetailViewController *vc = [self.window.rootViewController.storyboard instantiateViewControllerWithIdentifier:@"CircleDetail"];
                [vc setCircleId:[urlDict objectForKey:@"circle_id"]];
                UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
                [self.dynamicsDrawerViewController setPaneViewController:nav];
            } else if ([urlDict objectForKey:@"story_id"]) {
                XXStoryViewController *vc = [self.window.rootViewController.storyboard instantiateViewControllerWithIdentifier:@"Story"];
                [vc setStoryId:[urlDict objectForKey:@"story_id"]];
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
    NSLog(@"url: %@",url);
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
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
    //refresh user data by signing them in again
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsEmail] forKey:@"email"];
        if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsDeviceToken]){
            [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsDeviceToken] forKey:@"device_token"];
        }
        
        if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsPassword]) {
            [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsPassword] forKey:@"password"];
            [[AFHTTPRequestOperationManager manager] POST:[NSString stringWithFormat:@"%@/sessions", kAPIBaseUrl] parameters:@{@"user":parameters} success:^(AFHTTPRequestOperation *operation, id responseObject) {
                //NSLog(@"success logging in from app delegate: %@",responseObject);
                XXUser *user = [[XXUser alloc] initWithDictionary:[responseObject objectForKey:@"user"]];
                [[NSUserDefaults standardUserDefaults] setObject:user.identifier forKey:kUserDefaultsId];
                [[NSUserDefaults standardUserDefaults] setObject:user.authToken forKey:kUserDefaultsAuthToken];
                [[NSUserDefaults standardUserDefaults] setObject:user.penName forKey:kUserDefaultsPenName];
                [[NSUserDefaults standardUserDefaults] setObject:user.picLargeUrl forKey:kUserDefaultsPicLarge];
                [[NSUserDefaults standardUserDefaults] synchronize];
                
                NSManagedObjectContext *defaultContext = [NSManagedObjectContext MR_defaultContext];
                NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", user.identifier];
                _currentUser = [User MR_findFirstWithPredicate:predicate inContext:defaultContext];
                if (!_currentUser) {
                    _currentUser = [User MR_createInContext:defaultContext];
                }
                [_currentUser populateFromDict:[responseObject objectForKey:@"user"]];
                [defaultContext MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                    NSLog(@"Saving user to persistent store: %u %@",success, error);
                }];
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                NSLog(@"Failure logging in from app delegate: %@",error.localizedRecoverySuggestion);
            }];
        }
    }
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [MagicalRecord cleanUp];
}

@end

//
//  XXLoginController.m
//  Verses
//
//  Created by Max Haines-Stiles on 10/7/13.
//  Copyright (c) 2013 Verses. All rights reserved.
//

#import "XXLoginController.h"
#import <SVProgressHUD/SVProgressHUD.h>
#import "Constants.h"
#import "XXAppDelegate.h"
#import <SIAlertView/SIAlertView.h>

@interface XXLoginController () {
    AFHTTPRequestOperationManager *manager;
}

@end

@implementation XXLoginController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	if (!manager) manager = [AFHTTPRequestOperationManager manager];
}

- (IBAction)login{
    [SVProgressHUD showWithStatus:@"Logging in..."];
    // POST to create
    NSDictionary *parameters = @{@"email":self.emailTextField.text, @"password":self.passwordTextField.text};
    [manager POST:[NSString stringWithFormat:@"%@/login", kAPIBaseUrl] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        XXUser *user = [[XXUser alloc] initWithDictionary:[responseObject objectForKey:@"user"]];
        [[NSUserDefaults standardUserDefaults] setObject:user.identifier forKey:kUserDefaultsId];
        [[NSUserDefaults standardUserDefaults] setObject:user.email forKey:kUserDefaultsEmail];
        [[NSUserDefaults standardUserDefaults] setObject:user.authToken forKey:kUserDefaultsAuthToken];
        [[NSUserDefaults standardUserDefaults] setObject:user.password forKey:kUserDefaultsPassword];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [SVProgressHUD dismiss];
        [self performSegueWithIdentifier:@"LoginSuccessful" sender:self];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [SVProgressHUD dismiss];
        NSLog(@"Failure logging in: %@",error.localizedRecoverySuggestion);
        SIAlertView *trouble = [[SIAlertView alloc] initWithTitle:@"Hold on..." andMessage:@"Something went wrong while trying to log you in"];
        [trouble addButtonWithTitle:@"Well shucks" type:SIAlertViewButtonTypeDefault handler:^(SIAlertView *alertView) {}];
        trouble.transitionStyle = SIAlertViewTransitionStyleBounce;
        [trouble show];
    }];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

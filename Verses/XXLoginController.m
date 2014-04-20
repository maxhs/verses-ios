//
//  XXLoginController.m
//  Verses
//
//  Created by Max Haines-Stiles on 10/7/13.
//  Copyright (c) 2013 Verses. All rights reserved.
//

#import "XXLoginController.h"
#import "Constants.h"
#import "XXAppDelegate.h"
#import "XXProgress.h"
#import "User.h"
#import "XXMenuViewController.h"
#import "SWRevealViewController/SWRevealViewController.h"

@interface XXLoginController () <UITextFieldDelegate, UIAlertViewDelegate> {
    AFHTTPRequestOperationManager *manager;
    XXAppDelegate *delegate;
    CGRect screen;
    BOOL smallFormFactor;
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
    screen = [UIScreen mainScreen].bounds;
	manager = [AFHTTPRequestOperationManager manager];
    delegate = (XXAppDelegate *)[[UIApplication sharedApplication] delegate];
    [self.emailTextField setFont:[UIFont fontWithName:kSourceSansProLight size:19]];
    [self.passwordTextField setFont:[UIFont fontWithName:kSourceSansProLight size:19]];
    [self.registerEmailTextField setFont:[UIFont fontWithName:kSourceSansProLight size:19]];
    [self.registerPasswordTextField setFont:[UIFont fontWithName:kSourceSansProLight size:19]];
    [self.registerPenNameTextField setFont:[UIFont fontWithName:kSourceSansProLight size:19]];
    
    [self textFieldTreatment:self.emailTextField];
    [self textFieldTreatment:self.passwordTextField];
    [self textFieldTreatment:self.registerPasswordTextField];
    [self textFieldTreatment:self.registerEmailTextField];
    [self textFieldTreatment:self.registerPenNameTextField];
    
    [self.loginButton.titleLabel setFont:[UIFont fontWithName:kSourceSansProLight size:21]];
    [self.loginButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    self.loginButton.layer.borderColor = [UIColor darkGrayColor].CGColor;
    self.loginButton.layer.borderWidth = .5f;
    self.loginButton.layer.cornerRadius = 14.f;
    self.loginButton.layer.backgroundColor = [UIColor clearColor].CGColor;
    [self.loginButton setBackgroundColor:[UIColor whiteColor]];
    self.loginButton.layer.rasterizationScale = [UIScreen mainScreen].scale;
    self.loginButton.layer.shouldRasterize = YES;
    
    [self.signupButton.titleLabel setFont:[UIFont fontWithName:kSourceSansProLight size:21]];
    [self.signupButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    self.signupButton.layer.borderColor = [UIColor darkGrayColor].CGColor;
    self.signupButton.layer.borderWidth = .5f;
    self.signupButton.layer.cornerRadius = 14.f;
    self.signupButton.layer.backgroundColor = [UIColor clearColor].CGColor;
    [self.signupButton setBackgroundColor:[UIColor whiteColor]];
    self.signupButton.layer.rasterizationScale = [UIScreen mainScreen].scale;
    self.signupButton.layer.shouldRasterize = YES;
    
    if (screen.size.height != 568 && IDIOM != IPAD){
        CGRect loginFrame = self.loginContainer.frame;
        loginFrame.origin.y -= 40;
        [self.loginContainer setFrame:loginFrame];
        CGRect signupFrame = self.signupContainer.frame;
        signupFrame.origin.y -= 40;
        [self.signupContainer setFrame:signupFrame];
        smallFormFactor = YES;
    }
    
    self.loginContainer.transform = CGAffineTransformMakeTranslation(2*screen.size.width, 0);
    self.signupContainer.transform = CGAffineTransformMakeTranslation(-2*screen.size.width, 0);
    
    [self.forgotPasswordButton.titleLabel setFont:[UIFont fontWithName:kSourceSansProLight size:18]];
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doneEditing)];
    tapGesture.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:tapGesture];
}

- (void)textFieldTreatment:(UITextField*)textField {
    textField.layer.borderColor = [UIColor colorWithWhite:0 alpha:.2].CGColor;
    textField.layer.borderWidth = .5f;
    textField.layer.cornerRadius = 2.f;
    UIView *paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 7, 20)];
    textField.leftView = paddingView;
    textField.leftViewMode = UITextFieldViewModeAlways;
}

- (void)loginTapped{
    [self.loginButton setUserInteractionEnabled:NO];
    [self.signupButton setUserInteractionEnabled:YES];
    [UIView animateWithDuration:.75 delay:0 usingSpringWithDamping:.5 initialSpringVelocity:.0001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.loginContainer.transform = CGAffineTransformIdentity;
        self.signupContainer.transform = CGAffineTransformMakeTranslation(-2*screen.size.width, 0);
        self.signupButton.transform = CGAffineTransformMakeTranslation(-screen.size.width, 0);
        
        if (IDIOM == IPAD){
            self.loginButton.transform = CGAffineTransformMakeTranslation(-60, -57);
        } else {
            self.logo.transform = CGAffineTransformMakeTranslation(0, -(self.emailTextField.frame.origin.y+87));
            self.loginButton.transform = CGAffineTransformMakeTranslation(-(screen.size.width/2-self.loginButton.frame.size.width), -38);
        }
    } completion:^(BOOL finished) {
        [self.signupButton removeTarget:nil
                                 action:NULL
                       forControlEvents:UIControlEventAllEvents];
        [self.signupButton addTarget:self action:@selector(signupTapped) forControlEvents:UIControlEventTouchUpInside];
        [self.loginButton removeTarget:nil
                                 action:NULL
                       forControlEvents:UIControlEventAllEvents];
        [self.loginButton addTarget:self action:@selector(login) forControlEvents:UIControlEventTouchUpInside];
        [self.emailTextField becomeFirstResponder];
        
    }];
}

- (IBAction)signupTapped{
    [self.loginButton setUserInteractionEnabled:YES];
    [self.signupButton setUserInteractionEnabled:NO];
    [UIView animateWithDuration:.75 delay:0 usingSpringWithDamping:.5 initialSpringVelocity:.0001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.signupContainer.transform = CGAffineTransformIdentity;
        self.loginContainer.transform = CGAffineTransformMakeTranslation(2*screen.size.width, 0);
        self.loginButton.transform = CGAffineTransformMakeTranslation(screen.size.width, 0);
        
        if (IDIOM == IPAD){
            self.signupButton.transform = CGAffineTransformMakeTranslation(60, -48);
        } else {
            self.logo.transform = CGAffineTransformMakeTranslation(0, -(self.registerEmailTextField.frame.origin.y+83));
             self.signupButton.transform = CGAffineTransformMakeTranslation(screen.size.width/2-self.signupButton.frame.size.width, -30);
        }
        
        [self.loginButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    } completion:^(BOOL finished) {
        [self.loginButton removeTarget:nil
                                action:NULL
                      forControlEvents:UIControlEventAllEvents];
        [self.loginButton addTarget:self action:@selector(loginTapped) forControlEvents:UIControlEventTouchUpInside];
        [self.signupButton removeTarget:nil
                                action:NULL
                      forControlEvents:UIControlEventAllEvents];
        [self.signupButton addTarget:self action:@selector(signup) forControlEvents:UIControlEventTouchUpInside];
        [self.registerPenNameTextField becomeFirstResponder];
        
    }];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    /*if (toInterfaceOrientation == UIInterfaceOrientationPortrait){
        [UIView animateWithDuration:duration delay:0 usingSpringWithDamping:.5 initialSpringVelocity:.0001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self.logo.transform = CGAffineTransformIdentity;
        } completion:^(BOOL finished) {
            
        }];
    } else {
        [UIView animateWithDuration:duration delay:0 usingSpringWithDamping:.5 initialSpringVelocity:.0001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self.logo.transform = CGAffineTransformMakeTranslation(120, 0);
        } completion:^(BOOL finished) {
            
        }];
    }*/
}

- (void)resetButtons {
    [UIView animateWithDuration:.75 delay:0 usingSpringWithDamping:.5 initialSpringVelocity:.0001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.loginButton.transform = CGAffineTransformIdentity;
        self.signupButton.transform = CGAffineTransformIdentity;
        self.loginContainer.transform = CGAffineTransformMakeTranslation(2*screen.size.width, 0);
        self.signupContainer.transform = CGAffineTransformMakeTranslation(-2*screen.size.width, 0);
        [self.signupButton setBackgroundColor:[UIColor whiteColor]];
        self.signupButton.layer.borderColor = [UIColor blackColor].CGColor;
        [self.signupButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [self.loginButton setBackgroundColor:[UIColor whiteColor]];
        self.loginButton.layer.borderColor = [UIColor blackColor].CGColor;
        [self.loginButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        self.logo.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        [self.signupButton removeTarget:nil
                                 action:NULL
                       forControlEvents:UIControlEventAllEvents];
        [self.signupButton addTarget:self action:@selector(signupTapped) forControlEvents:UIControlEventTouchUpInside];
        [self.loginButton removeTarget:nil
                                 action:NULL
                       forControlEvents:UIControlEventAllEvents];
        [self.loginButton addTarget:self action:@selector(loginTapped) forControlEvents:UIControlEventTouchUpInside];
        [self.view endEditing:YES];
        [self.loginButton setUserInteractionEnabled:YES];
        [self.signupButton setUserInteractionEnabled:YES];
        self.emailTextField.text = @"";
        self.passwordTextField.text = @"";
        self.registerEmailTextField.text = @"";
        self.registerPasswordTextField.text = @"";
        self.registerPenNameTextField.text = @"";
    }];
}

- (void)login{
    [ProgressHUD show:@"Logging in..."];
    [self connect:NO withLoginUI:YES];
}

- (void)signup{
    [ProgressHUD show:@"Signing up..."];
    [self connect:YES withLoginUI:YES];
}

- (IBAction)forgotPassword{
    UIAlertView *forgotAlert = [[UIAlertView alloc] initWithTitle:nil message:@"Enter your email:" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Submit", nil];
    forgotAlert.alertViewStyle = UIAlertViewStylePlainTextInput;
    [forgotAlert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Submit"]){
        [self forgotMethod:[alertView textFieldAtIndex:0].text];
    } else if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Sign Up"]){
        [self signupTapped];
    } else if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Log in"]){
        [self loginTapped];
    }
}

- (void)forgotMethod:(NSString*)email {
    [manager POST:[NSString stringWithFormat:@"%@/sessions/forgot_password",kAPIBaseUrl] parameters:@{@"email":email} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"success with forgot password method: %@",responseObject);
        NSNumber *response = (NSNumber *)[responseObject objectForKey: @"success"];
        if([response boolValue] == YES){
           [[[UIAlertView alloc] initWithTitle:@"Success" message:@"You'll soon receive an email with your freshly reset password." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:@"Log In", nil] show];
        } else {
            [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"We couldn't find an account associated with that email address." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Sign Up", nil] show];
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [[[UIAlertView alloc] initWithTitle:@"Shoot" message:@"Something went wrong. Please try again soon." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        NSLog(@"Failed to do the forgot password thing: %@",error.description); 
    }];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    textField.layer.borderColor = [UIColor colorWithWhite:0 alpha:.35].CGColor;
    [textField setTintColor:kElectricBlue];
    //[textField setFont:[UIFont fontWithName:kSourceSansProRegular size:18]];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    textField.layer.borderColor = [UIColor colorWithWhite:0 alpha:.2].CGColor;
    //[textField setFont:[UIFont fontWithName:kSourceSansProRegular size:18]];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (self.emailTextField.text.length && self.passwordTextField.text.length){
        [self.loginButton setBackgroundColor:kElectricBlue];
        self.loginButton.layer.borderColor = kElectricBlue.CGColor;
        [self.loginButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        self.loginButton.userInteractionEnabled = YES;
    } else if (self.registerEmailTextField.text.length && self.registerPasswordTextField.text.length && self.registerPenNameTextField.text.length) {
        [self.signupButton setBackgroundColor:kElectricBlue];
        self.signupButton.layer.borderColor = kElectricBlue.CGColor;
        [self.signupButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        self.signupButton.userInteractionEnabled = YES;
    } else {
        [self.loginButton setBackgroundColor:[UIColor whiteColor]];
        self.loginButton.layer.borderColor = [UIColor darkGrayColor].CGColor;
        [self.loginButton setUserInteractionEnabled:NO];
        [self.loginButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [self.signupButton setBackgroundColor:[UIColor whiteColor]];
        self.signupButton.layer.borderColor = [UIColor darkGrayColor].CGColor;
        [self.signupButton setUserInteractionEnabled:NO];
        [self.signupButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    }
    return YES;
}

- (void)doneEditing {
    [self resetButtons];
    [self.view endEditing:YES];
}

- (void)connect:(BOOL)signup withLoginUI:(BOOL)ui{
    if ([self.emailTextField.text rangeOfString:@"@"].location == NSNotFound && [self.registerEmailTextField.text rangeOfString:@"@"].location == NSNotFound) {
        [ProgressHUD dismiss];
        [[[UIAlertView alloc] initWithTitle:@"Uh-oh" message:@"Please make sure you've entered a valid email address before continuing." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    } else {
        [self doneEditing];
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        if (signup) {
            [parameters setObject:self.registerEmailTextField.text forKey:@"user[email]"];
            [parameters setObject:self.registerPasswordTextField.text forKey:@"user[password]"];
            [parameters setObject:self.registerPenNameTextField.text forKey:@"user[pen_name]"];
            [parameters setObject:[NSNumber numberWithBool:YES] forKey:@"user[signup]"];
        } else {
            [parameters setObject:self.emailTextField.text forKey:@"user[email]"];
            [parameters setObject:self.passwordTextField.text forKey:@"user[password]"];
        }
        if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsDeviceToken]) {
            [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsDeviceToken] forKey:@"user[device_token]"];
        }

        [manager POST:[NSString stringWithFormat:@"%@/sessions", kAPIBaseUrl] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"success logging in: %@",responseObject);
            XXUser *user = [[XXUser alloc] initWithDictionary:[responseObject objectForKey:@"user"]];
            [[NSUserDefaults standardUserDefaults] setObject:user.identifier forKey:kUserDefaultsId];
            [[NSUserDefaults standardUserDefaults] setObject:user.email forKey:kUserDefaultsEmail];
            [[NSUserDefaults standardUserDefaults] setObject:[parameters objectForKey:@"user[password]"] forKey:kUserDefaultsPassword];
            [[NSUserDefaults standardUserDefaults] setObject:user.authToken forKey:kUserDefaultsAuthToken];
            [[NSUserDefaults standardUserDefaults] setObject:user.penName forKey:kUserDefaultsPenName];
            [[NSUserDefaults standardUserDefaults] setObject:user.picSmallUrl forKey:kUserDefaultsPicSmall];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            [delegate.dynamicsDrawerViewController setPaneState:MSDynamicsDrawerPaneStateClosed animated:YES allowUserInterruption:YES completion:^{
            
            }];
            [UIView animateWithDuration:.23 animations:^{
                [self.logo setAlpha:0.0];
            }];
            
            NSManagedObjectContext *localContext = [NSManagedObjectContext MR_contextForCurrentThread];
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier ==[c] %@", user.identifier];
            User *savedUser = [User MR_findFirstWithPredicate:predicate inContext:localContext];
            if (savedUser) {
                savedUser.picSmall = user.picSmallUrl;
                savedUser.email = user.email;
                savedUser.penName = user.penName;
                savedUser.identifier = user.identifier;
                savedUser.contactCount = user.contactCount;
                savedUser.storyCount = user.storyCount;
                NSLog(@"found existing MR user from Login vc");
                [localContext MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                    [self dismissViewControllerAnimated:YES completion:^{
                        [ProgressHUD dismiss];
                    }];
                }];
            } else {
                NSLog(@"had to create new MR user");
                User *newUser = [User MR_createInContext:localContext];
                newUser.picSmall = user.picSmallUrl;
                newUser.email = user.email;
                newUser.penName = user.penName;
                newUser.identifier = user.identifier;
                newUser.contactCount = user.contactCount;
                newUser.storyCount = user.storyCount;
                [localContext MR_saveOnlySelfWithCompletion:^(BOOL success, NSError *error) {
                    if (success) NSLog(@"done saving user through Magical Record");
                    else NSLog(@"error saving through MR: %@",error.description);
                    [self dismissViewControllerAnimated:YES completion:^{
                        [ProgressHUD dismiss];
                    }];
                }];
            }
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            [ProgressHUD dismiss];
            NSLog(@"Failure logging in: %@",error.localizedRecoverySuggestion);
            NSLog(@"Failure logging in: %@",error.localizedFailureReason);
            NSLog(@"Failure logging in: %@",error.description);
            NSLog(@"Failure logging in: %@",error.debugDescription);
            UIAlertView *trouble = [[UIAlertView alloc] initWithTitle:@"Uh oh" message:@"Something went wrong while trying to log you in" delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil];
            [trouble show];
        }];
    }
}

- (IBAction)cancel{
    [UIView animateWithDuration:.13 animations:^{
        [self.logo setAlpha:0.0];
    }];
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [ProgressHUD dismiss];
    //[XXProgress dismiss];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
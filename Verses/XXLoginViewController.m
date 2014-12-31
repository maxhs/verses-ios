//
//  XXLoginViewController.m
//  Verses
//
//  Created by Max Haines-Stiles on 10/7/13.
//  Copyright (c) 2013 Verses. All rights reserved.
//

#import "XXLoginViewController.h"
#import "Constants.h"
#import "XXAppDelegate.h"
#import "XXProgress.h"
#import "User+helper.h"
#import "XXMenuViewController.h"
#import "XXWebViewController.h"
#import "XXAlert.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "XXGuideAnimator.h"
#import "XXStoriesViewController.h"
#import "XXGuideViewController.h"

static NSString * const kShakeAnimationKey = @"XXShakeItNow";

@interface XXLoginViewController () <UITextFieldDelegate, UIAlertViewDelegate,UIViewControllerTransitioningDelegate,XXLoginDelegate> {
    AFHTTPRequestOperationManager *manager;
    XXAppDelegate *delegate;
    CGRect screen;
    CGRect originalLoginButtonFrame;
    CGRect originalSignupButtonFrame;
    CGRect originalLogoFrame;
    CGFloat keyboardHeight;
    BOOL smallFormFactor;
    UIColor *textColor;
    NSArray *views;
    NSUInteger completedAnimations;
    void (^completionBlock)();
}

@end

@implementation XXLoginViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    screen = [UIScreen mainScreen].bounds;
    delegate = (XXAppDelegate *)[[UIApplication sharedApplication] delegate];
    delegate.loginDelegate = self;
    manager = delegate.manager;
    [self.emailTextField setFont:[UIFont fontWithName:kSourceSansProLight size:18]];
    [self.passwordTextField setFont:[UIFont fontWithName:kSourceSansProLight size:18]];
    [self.registerEmailTextField setFont:[UIFont fontWithName:kSourceSansProLight size:18]];
    [self.registerPasswordTextField setFont:[UIFont fontWithName:kSourceSansProLight size:18]];
    [self.registerPenNameTextField setFont:[UIFont fontWithName:kSourceSansProLight size:18]];
    
    [self.loginButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleSubheadline forFont:kSourceSansProLight] size:0]];
    [self.loginButton setBackgroundColor:[UIColor clearColor]];
    originalLoginButtonFrame = self.loginButton.frame;
    
    [self.signupButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleSubheadline forFont:kSourceSansProLight] size:0]];
    [self.signupButton setBackgroundColor:[UIColor clearColor]];
    
    originalSignupButtonFrame = self.signupButton.frame;
    
    originalLogoFrame = self.logo.frame;
    
    if (IDIOM == IPAD){
        self.signupButton.layer.cornerRadius = 14.f;
        self.signupButton.layer.backgroundColor = [UIColor clearColor].CGColor;
        self.signupButton.layer.rasterizationScale = [UIScreen mainScreen].scale;
        self.signupButton.layer.shouldRasterize = YES;
        self.loginButton.layer.cornerRadius = 14.f;
        self.loginButton.layer.backgroundColor = [UIColor clearColor].CGColor;
        self.loginButton.layer.rasterizationScale = [UIScreen mainScreen].scale;
        self.loginButton.layer.shouldRasterize = YES;
    } else if (screen.size.height != 568){
        CGRect loginFrame = self.loginContainer.frame;
        loginFrame.origin.y -= 90;
        [self.loginContainer setFrame:loginFrame];
        CGRect signupFrame = self.signupContainer.frame;
        signupFrame.origin.y -= 80;
        [self.signupContainer setFrame:signupFrame];
        smallFormFactor = YES;
    }
    
    self.loginContainer.transform = CGAffineTransformMakeTranslation(2*screen.size.width, 0);
    self.signupContainer.transform = CGAffineTransformMakeTranslation(-2*screen.size.width, 0);
    
    [self.forgotPasswordButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kSourceSansProLight] size:0]];
    [self.termsButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kSourceSansProLight] size:0]];
    
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
        textColor = [UIColor whiteColor];
    } else {
        textColor = [UIColor blackColor];
    }
    
    NSMutableAttributedString *termsString = [[NSMutableAttributedString alloc] initWithString:@"By continuing, you agree to our " attributes:@{NSForegroundColorAttributeName:textColor}];
    NSMutableAttributedString *linkString = [[NSMutableAttributedString alloc] initWithString:@"Terms of Service" attributes:@{NSUnderlineStyleAttributeName:[NSNumber numberWithInt:NSUnderlineStyleSingle],NSForegroundColorAttributeName:textColor}];
    [termsString appendAttributedString:linkString];
    self.termsButton.titleLabel.numberOfLines = 0;
    self.termsButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.termsButton setAttributedTitle:termsString forState:UIControlStateNormal];
    [self.termsButton addTarget:self action:@selector(termsWebView) forControlEvents:UIControlEventTouchUpInside];
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(resetButtons)];
    tapGesture.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:tapGesture];
    
    keyboardHeight = 216;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
        [self.view setBackgroundColor:[UIColor clearColor]];
        [self textFieldTreatment:self.emailTextField withDarkBackground:YES];
        [self textFieldTreatment:self.passwordTextField withDarkBackground:YES];
        [self textFieldTreatment:self.registerEmailTextField withDarkBackground:YES];
        [self textFieldTreatment:self.registerPenNameTextField withDarkBackground:YES];
        [self textFieldTreatment:self.registerPasswordTextField withDarkBackground:YES];
        [self.signupButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self.loginButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self.forgotPasswordButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self.logo setImage:[UIImage imageNamed:@"logoWhite"]];
        [self.cancelButton setImage:[UIImage imageNamed:@"whiteX"] forState:UIControlStateNormal];
    } else {
        [self.view setBackgroundColor:[UIColor whiteColor]];
        [self textFieldTreatment:self.emailTextField withDarkBackground:NO];
        [self textFieldTreatment:self.passwordTextField withDarkBackground:NO];
        [self textFieldTreatment:self.registerEmailTextField withDarkBackground:NO];
        [self textFieldTreatment:self.registerPenNameTextField withDarkBackground:NO];
        [self textFieldTreatment:self.registerPasswordTextField withDarkBackground:NO];
        [self.signupButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [self.loginButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [self.forgotPasswordButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [self.logo setImage:[UIImage imageNamed:@"logo"]];
        [self.cancelButton setImage:[UIImage imageNamed:@"blackX"] forState:UIControlStateNormal];
    }
}

- (void)termsWebView {
    XXWebViewController *webViewVC = [[self storyboard] instantiateViewControllerWithIdentifier:@"WebView"];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:webViewVC];
    [webViewVC setUrlString:[NSString stringWithFormat:@"%@/terms",kBaseUrl]];
    [webViewVC setTitle:@"Terms of Service"];
    [self presentViewController:nav animated:YES completion:^{
        
    }];
}

- (void)keyboardWillShow:(NSNotification *)notification {
    NSDictionary *info = [notification userInfo];
    NSValue *kbFrame = [info objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardFrame = [kbFrame CGRectValue];
    keyboardHeight = keyboardFrame.size.height;
}

- (void)textFieldTreatment:(UITextField*)textField withDarkBackground:(BOOL)dark {
    if (dark){
        textField.layer.borderColor = [UIColor colorWithWhite:1 alpha:.07].CGColor;
        [textField setTextColor:[UIColor whiteColor]];
        [textField setKeyboardAppearance:UIKeyboardAppearanceDark];
        [textField setTintColor:[UIColor whiteColor]];
        [textField setBackgroundColor:[UIColor colorWithWhite:1 alpha:.1]];
    } else {
        textField.layer.borderColor = [UIColor colorWithWhite:0 alpha:.07].CGColor;
        [textField setTextColor:[UIColor blackColor]];
        [textField setKeyboardAppearance:UIKeyboardAppearanceDefault];
        [textField setTintColor:kElectricBlue];
        [textField setBackgroundColor:[UIColor clearColor]];
    }
    
    textField.layer.borderWidth = .25f;
    textField.layer.cornerRadius = 4.f;
    UIView *paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 7, 20)];
    textField.leftView = paddingView;
    textField.leftViewMode = UITextFieldViewModeAlways;
}

- (void)loginTapped{
    [self.emailTextField becomeFirstResponder];
    [UIView animateWithDuration:.75 delay:0 usingSpringWithDamping:.5 initialSpringVelocity:.0001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.loginContainer.transform = CGAffineTransformIdentity;
        self.signupContainer.transform = CGAffineTransformMakeTranslation(-2*screen.size.width, 0);
        [self.signupButton setFrame:CGRectMake(-screenWidth(), self.signupButton.frame.origin.y, self.signupButton.frame.size.width, self.signupButton.frame.size.height)];
        self.forgotPasswordButton.transform = CGAffineTransformMakeTranslation(0, screenHeight()/2);
        if (IDIOM == IPAD){
            CGRect logoFrame = originalLogoFrame;
            logoFrame.origin.y = 110;
            [self.logo setFrame:logoFrame];
            [self.loginButton setFrame:CGRectMake(screenWidth()/2-self.emailTextField.frame.size.width/2, screenHeight()/2-33, self.emailTextField.frame.size.width, 66)];
        } else {
            if (smallFormFactor) {
                self.logo.transform = CGAffineTransformMakeTranslation(0, -(self.emailTextField.frame.origin.y+100));
            } else {
                self.logo.transform = CGAffineTransformMakeTranslation(0, -(self.emailTextField.frame.origin.y+77));
            }
            
            [self.loginButton setFrame:CGRectMake(0, screenHeight()-keyboardHeight-66, screenWidth(), 66)];
        }
        [self.cancelButton setAlpha:0.0];
    } completion:^(BOOL finished) {
        [self.signupButton removeTarget:nil
                                 action:NULL
                       forControlEvents:UIControlEventAllEvents];
        [self.signupButton addTarget:self action:@selector(signupTapped) forControlEvents:UIControlEventTouchUpInside];
        [self.loginButton removeTarget:nil
                                 action:NULL
                       forControlEvents:UIControlEventAllEvents];
        [self.loginButton addTarget:self action:@selector(login) forControlEvents:UIControlEventTouchUpInside];
    }];
}

- (IBAction)signupTapped{
    [self.registerPenNameTextField becomeFirstResponder];
    [UIView animateWithDuration:.75 delay:0 usingSpringWithDamping:.5 initialSpringVelocity:.0001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.signupContainer.transform = CGAffineTransformIdentity;
        self.loginContainer.transform = CGAffineTransformMakeTranslation(2*screen.size.width, 0);
        [self.loginButton setFrame:CGRectMake(screenWidth(), self.loginButton.frame.origin.y, self.loginButton.frame.size.width, self.loginButton.frame.size.height)];
        self.forgotPasswordButton.transform = CGAffineTransformMakeTranslation(0, screenHeight()/2);
        
        if (IDIOM == IPAD){
            [self.signupButton setFrame:CGRectMake(screenWidth()/2-self.registerEmailTextField.frame.size.width/2, screenHeight()/2-33, self.registerEmailTextField.frame.size.width, 66)];
            CGRect logoFrame = originalLogoFrame;
            logoFrame.origin.y = 110;
            [self.logo setFrame:logoFrame];
        } else {
            if (smallFormFactor){
                self.logo.transform = CGAffineTransformMakeTranslation(0, -(self.registerEmailTextField.frame.origin.y+70));
            } else {
                self.logo.transform = CGAffineTransformMakeTranslation(0, -(self.registerEmailTextField.frame.origin.y+67));
            }
            
            [self.signupButton setFrame:CGRectMake(0, screenHeight()-keyboardHeight-66, screenWidth(), 66)];
        }
        [self.cancelButton setAlpha:0.0];
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
    }];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    if (toInterfaceOrientation == UIInterfaceOrientationPortrait){

    } else {

    }
}

- (void)resetButtons {
    [self.view endEditing:YES];
    [UIView animateWithDuration:.75 delay:0 usingSpringWithDamping:.5 initialSpringVelocity:.0001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [self.loginButton setFrame:originalLoginButtonFrame];
        [self.signupButton setFrame:originalSignupButtonFrame];
        self.loginContainer.transform = CGAffineTransformMakeTranslation(2*screen.size.width, 0);
        self.signupContainer.transform = CGAffineTransformMakeTranslation(-2*screen.size.width, 0);
        
        self.signupButton.layer.borderColor = [UIColor blackColor].CGColor;
        [self.signupButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
            [self.loginButton setBackgroundColor:[UIColor clearColor]];
            [self.signupButton setBackgroundColor:[UIColor clearColor]];
            self.loginButton.layer.borderColor = [UIColor whiteColor].CGColor;
            [self.loginButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            self.signupButton.layer.borderColor = [UIColor whiteColor].CGColor;
            [self.signupButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        } else {
            [self.loginButton setBackgroundColor:[UIColor whiteColor]];
            [self.signupButton setBackgroundColor:[UIColor whiteColor]];
            self.loginButton.layer.borderColor = [UIColor blackColor].CGColor;
            [self.loginButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            self.signupButton.layer.borderColor = [UIColor blackColor].CGColor;
            [self.signupButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        }
        
        
        self.logo.transform = CGAffineTransformIdentity;
        self.forgotPasswordButton.transform = CGAffineTransformIdentity;
        [_cancelButton setAlpha:1.0];
        if (IDIOM == IPAD){
            [self.logo setFrame:originalLogoFrame];
        }
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
    //[ProgressHUD show:@"Logging in..."];
    [self connect:NO withLoginUI:YES];
}

- (void)signup{
    //[ProgressHUD show:@"Signing up..."];
    [self connect:YES withLoginUI:YES];
}

- (IBAction)forgotPassword{
    UIAlertView *forgotAlert = [[UIAlertView alloc] initWithTitle:nil message:@"Enter your email:" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Submit", nil];
    forgotAlert.alertViewStyle = UIAlertViewStylePlainTextInput;
    [[forgotAlert textFieldAtIndex:0] setKeyboardType:UIKeyboardTypeEmailAddress];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
        [[forgotAlert textFieldAtIndex:0] setKeyboardAppearance:UIKeyboardAppearanceDark];
    }
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
        //NSLog(@"success with forgot password method: %@",responseObject);
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

#pragma mark - Shake Animation

- (void)addShakeAnimationForView:(UIView *)view withDuration:(NSTimeInterval)duration {
    CAKeyframeAnimation * animation = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.x"];
    animation.delegate = self;
    animation.duration = duration;
    animation.values = @[ @(0), @(10), @(-8), @(8), @(-5), @(5), @(0) ];
    animation.keyTimes = @[ @(0), @(0.225), @(0.425), @(0.6), @(0.75), @(0.875), @(1) ];
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [view.layer addAnimation:animation forKey:kShakeAnimationKey];
}


#pragma mark - CAAnimation Delegate

- (void)animationDidStop:(CAAnimation *)animation finished:(BOOL)flag {
    completedAnimations += 1;
    if ( completedAnimations >= views.count ) {
        completedAnimations = 0;
        if ( completionBlock ) {
            completionBlock();
        }
    }
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    textField.layer.borderColor = [UIColor colorWithWhite:0 alpha:.25].CGColor;
    [textField setTintColor:kElectricBlue];
    [self checkTextFields];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    textField.layer.borderColor = [UIColor colorWithWhite:0 alpha:.03].CGColor;
    [self checkTextFields];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    [self checkTextFields];
    if ([string isEqualToString:@"\n"]) {
        if (textField == _registerPenNameTextField){
            [_registerEmailTextField becomeFirstResponder];
        } else if (textField == _registerEmailTextField) {
            [_registerPasswordTextField becomeFirstResponder];
        } else if (textField == _registerPasswordTextField && _registerPasswordTextField.text.length) {
            [self signup];
        } else if (textField == _emailTextField) {
            [_passwordTextField becomeFirstResponder];
        } else if (textField == _passwordTextField && _passwordTextField.text.length) {
            [self login];
        }
        return NO;
    }
    return YES;
}

- (void)checkTextFields {
    if (self.emailTextField.text.length && self.passwordTextField.text.length){
        [self.loginButton setBackgroundColor:kElectricBlue];
        self.loginButton.layer.borderColor = kElectricBlue.CGColor;
        [self.loginButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self.loginButton addTarget:self action:@selector(login) forControlEvents:UIControlEventTouchUpInside];
    } else if (self.registerEmailTextField.text.length && self.registerPasswordTextField.text.length && self.registerPenNameTextField.text.length) {
        [self.signupButton setBackgroundColor:kElectricBlue];
        self.signupButton.layer.borderColor = kElectricBlue.CGColor;
        [self.signupButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self.signupButton addTarget:self action:@selector(signup) forControlEvents:UIControlEventTouchUpInside];
    } else {
        if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
            [self.loginButton setBackgroundColor:[UIColor clearColor]];
            [self.signupButton setBackgroundColor:[UIColor clearColor]];
        } else {
            [self.loginButton setBackgroundColor:[UIColor whiteColor]];
            [self.signupButton setBackgroundColor:[UIColor whiteColor]];
        }
        
        self.loginButton.layer.borderColor = [UIColor darkGrayColor].CGColor;
        [self.loginButton removeTarget:nil
                                 action:NULL
                       forControlEvents:UIControlEventAllEvents];
        [self.loginButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        
        self.signupButton.layer.borderColor = [UIColor darkGrayColor].CGColor;
        [self.signupButton removeTarget:nil
                                 action:NULL
                       forControlEvents:UIControlEventAllEvents];
        [self.signupButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    }
}

- (void)doneEditing {
    [UIView animateWithDuration:.23 animations:^{
        [self.cancelButton setAlpha:1.0];
    }completion:^(BOOL finished) {
        
    }];
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
            [parameters setObject:self.registerEmailTextField.text forKey:@"email"];
            [parameters setObject:self.registerPasswordTextField.text forKey:@"password"];
            [parameters setObject:self.registerPenNameTextField.text forKey:@"pen_name"];
            [parameters setObject:@YES forKey:@"signup"];
        } else {
            [parameters setObject:self.emailTextField.text forKey:@"email"];
            [parameters setObject:self.passwordTextField.text forKey:@"password"];
        }
        if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsDeviceToken]) {
            [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsDeviceToken] forKey:@"device_token"];
        }

        [delegate connect:parameters withLoginUI:YES];
    }
}

- (void)incorrectEmail {
    [self addShakeAnimationForView:self.emailTextField withDuration:.77];
}

- (void)incorrectPassword {
    [self addShakeAnimationForView:self.passwordTextField withDuration:.77];
    [self addShakeAnimationForView:self.registerPasswordTextField withDuration:.77];
}

- (void)penNameTaken {
    [self alert:@"Sorry, but that pen name has already been taken."];
    [self addShakeAnimationForView:self.registerPenNameTextField withDuration:.77];
}

- (void)userAlreadyExists {
    [self addShakeAnimationForView:self.registerEmailTextField withDuration:.77];
    [self alert:@"An account with that email address already exists."];
}

- (void)alert:(NSString*)alert {
    double delayInSeconds = .87;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [XXAlert show:alert withTime:2.f];
    });
}

- (void)loginSuccessful {
    [self cancel];
}

- (IBAction)cancel{
    [ProgressHUD dismiss];
    if (self.presentingViewController){
        [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
            
        }];
    } else {
        [self showGuide];
    }
}

- (void)showGuide {
    XXGuideViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Guide"];
    vc.transitioningDelegate = self;
    vc.modalPresentationStyle = UIModalPresentationCustom;
    [self presentViewController:vc animated:YES completion:^{
        
    }];
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented
                                                                  presentingController:(UIViewController *)presenting
                                                                      sourceController:(UIViewController *)source {
    XXGuideAnimator *animator = [XXGuideAnimator new];
    animator.presenting = YES;
    return animator;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    XXGuideAnimator *animator = [XXGuideAnimator new];
    return animator;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [ProgressHUD dismiss];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

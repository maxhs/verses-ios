//
//  XXLoginController.h
//  Verses
//
//  Created by Max Haines-Stiles on 10/7/13.
//  Copyright (c) 2013 Verses. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XXUser.h"

@interface XXLoginController : UIViewController
@property (strong, nonatomic) IBOutlet UITextField *emailTextField;
@property (strong, nonatomic) IBOutlet UITextField *passwordTextField;
@property (strong, nonatomic) IBOutlet UITextField *registerEmailTextField;
@property (strong, nonatomic) IBOutlet UITextField *registerPasswordTextField;
@property (strong, nonatomic) IBOutlet UITextField *registerPenNameTextField;
@property (weak, nonatomic) IBOutlet UIView *loginContainer;
@property (weak, nonatomic) IBOutlet UIView *signupContainer;
@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (weak, nonatomic) IBOutlet UIButton *signupButton;
@property (weak, nonatomic) IBOutlet UIButton *forgotPasswordButton;
@property (weak, nonatomic) IBOutlet UIButton *termsButton;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIImageView *logo;
-(IBAction)cancel;
-(IBAction)forgotPassword;
@end

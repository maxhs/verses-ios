//
//  XXNoRotateNavController.m
//  Verses
//
//  Created by Max Haines-Stiles on 4/24/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import "XXNoRotateNavController.h"
#import "XXLoginController.h"
#import "XXNewUserWalkthroughViewController.h"

@interface XXNoRotateNavController ()

@end

@implementation XXNoRotateNavController

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
    [self setNavigationBarHidden:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)shouldAutorotate {
    id currentViewController = self.topViewController;
    if ([currentViewController isKindOfClass:[XXLoginController class]] || [currentViewController isKindOfClass:[XXNewUserWalkthroughViewController class]]){
        return NO;
    } else {
        return YES;
    }
}

@end

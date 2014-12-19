//
//  XXWebViewController.m
//  Verses
//
//  Created by Max Haines-Stiles on 5/30/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import "XXWebViewController.h"
#import "Utilities.h"
#import "ProgressHUD.h"

@interface XXWebViewController () {
    UIBarButtonItem *backButton;
    UIImageView *navBarShadowView;
}

@end

@implementation XXWebViewController

@synthesize urlString = _urlString;

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
    backButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"blackX"] style:UIBarButtonItemStylePlain target:self action:@selector(back)];
    self.navigationItem.leftBarButtonItem = backButton;
    NSURL *url = [NSURL URLWithString:_urlString];
    NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
    [self.webView loadRequest:requestObj];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    navBarShadowView = [Utilities findNavShadow:self.navigationController.navigationBar];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    navBarShadowView.hidden = YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    [ProgressHUD show:@"Loading..."];
}

-(void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    //NSLog(@"error? %@",error.description);
    [ProgressHUD dismiss];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [ProgressHUD dismiss];
}

- (void)back {
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end

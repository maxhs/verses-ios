//
//  XXWriteViewController.m
//  Verses
//
//  Created by Max Haines-Stiles on 10/11/13.
//  Copyright (c) 2013 Verses. All rights reserved.
//

#import "XXWriteViewController.h"
#import "XXStoriesViewController.h"
#import "XXWritingCell.h"
#import "XXTextView.h"
#import "XXContribution.h"
#import "XXWelcomeViewController.h"
#import "UIImage+ImageEffects.h"
#import <Mixpanel/Mixpanel.h>
#import "XXDraftsViewController.h"
#import "XXCollaborateViewController.h"
#import "XXStoryViewController.h"
#import "XXMyStoriesViewController.h"
#import "XXCircle.h"
#import <DTCoreText/DTCoreText.h>

@interface XXWriteViewController () <UITextFieldDelegate, UITextViewDelegate, UIGestureRecognizerDelegate, UIAlertViewDelegate> {
    NSArray *sidebarImageArray;
    UITextField *titleTextField;
    UITextView *bodyTextView;
    CGRect screen;
    CGFloat width;
    CGFloat height;
    AFHTTPRequestOperationManager *manager;
    BOOL joinable;
    BOOL mystery;
    BOOL private;
    BOOL saving;
    UIBarButtonItem *doneButton;
    UIBarButtonItem *saveButton;
    UIBarButtonItem *publishButton;
    UIBarButtonItem *optionsButton;
    UITapGestureRecognizer *optionsTap;
    UIImage *blurredSnapshotImage;
    UIImageView *blurredImageView;
    UIStoryboard *storyboard;
    NSMutableArray *_collaborators;
    NSMutableArray *_circleCollaborators;
    UIColor *textColor;
    UIInterfaceOrientation currentOrientation;
    UIImageView *navBarShadowView;
}

@end

@implementation XXWriteViewController
@synthesize story = _story;
@synthesize welcomeViewController;

- (void)viewDidLoad
{
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)]){
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
    
    [super viewDidLoad];
    manager = [AFHTTPRequestOperationManager manager];
    screen = [UIScreen mainScreen].bounds;
    width = screen.size.width;
    height = screen.size.height;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(willShowKeyboard:)
                                                 name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(willHideKeyboard)
                                                 name:UIKeyboardWillHideNotification object:nil];
    self.tableView.pagingEnabled = YES;
    publishButton = [[UIBarButtonItem alloc] initWithTitle:@"   PUBLISH   " style:UIBarButtonItemStylePlain target:self action:@selector(confirmPublish)];
    doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneEditing)];
    optionsButton = [[UIBarButtonItem alloc] initWithTitle:@"   OPTIONS   " style:UIBarButtonItemStylePlain target:self action:@selector(showOptions)];

    [self setupControls];
    [self offsetOptions];
    [self.draftLabel setFont:[UIFont fontWithName:kSourceSansProLight size:18]];
    [self.privateLabel setFont:[UIFont fontWithName:kSourceSansProLight size:18]];
    [self.feedbackLabel setFont:[UIFont fontWithName:kSourceSansProLight size:18]];
    [self.joinableLabel setFont:[UIFont fontWithName:kSourceSansProLight size:18]];
    [self.slowRevealLabel setFont:[UIFont fontWithName:kSourceSansProLight size:18]];
    
    [self.doneOptionsButton.titleLabel setFont:[UIFont fontWithName:kSourceSansProLight size:18]];
    self.doneOptionsButton.layer.borderColor = [UIColor darkGrayColor].CGColor;
    self.doneOptionsButton.layer.borderWidth = .5f;
    self.doneOptionsButton.layer.cornerRadius = 14.f;
    [self.doneOptionsButton.layer setBackgroundColor:[UIColor clearColor].CGColor];
    [self.doneOptionsButton setBackgroundColor:[UIColor clearColor]];
    self.doneOptionsButton.layer.rasterizationScale = [UIScreen mainScreen].scale;
    self.doneOptionsButton.layer.shouldRasterize = YES;
    
    [self.deleteButton.titleLabel setFont:[UIFont fontWithName:kSourceSansProLight size:18]];
    [self.deleteButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    self.deleteButton.layer.borderColor = [UIColor redColor].CGColor;
    self.deleteButton.layer.borderWidth = .5f;
    self.deleteButton.layer.cornerRadius = 14.f;
    [self.deleteButton.layer setBackgroundColor:[UIColor clearColor].CGColor];
    [self.deleteButton setBackgroundColor:[UIColor clearColor]];
    self.deleteButton.layer.rasterizationScale = [UIScreen mainScreen].scale;
    self.deleteButton.layer.shouldRasterize = YES;
    
    [self.collaborateButton.titleLabel setFont:[UIFont fontWithName:kSourceSansProLight size:18]];
    self.collaborateButton.layer.borderColor = [UIColor darkGrayColor].CGColor;
    self.collaborateButton.layer.borderWidth = 0.5f;
    self.collaborateButton.layer.cornerRadius = 14.f;
    [self.collaborateButton.layer setBackgroundColor:[UIColor clearColor].CGColor];
    [self.collaborateButton setBackgroundColor:[UIColor clearColor]];
    self.collaborateButton.layer.rasterizationScale = [UIScreen mainScreen].scale;
    self.collaborateButton.layer.shouldRasterize = YES;
    
    optionsTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showOptions)];
    optionsTap.numberOfTapsRequired = 1;
    optionsTap.delegate = self;
    [self.optionsContainerView addGestureRecognizer:optionsTap];
    if (self.navigationController.viewControllers.firstObject == self){
        UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"blackX"] style:UIBarButtonItemStylePlain target:self action:@selector(back)];
        self.navigationItem.leftBarButtonItem = cancelButton;
    } else {
        UIBarButtonItem *backButton;
        if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
            backButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"whiteBack"] style:UIBarButtonItemStylePlain target:self action:@selector(pop)];
        } else {
            backButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"back"] style:UIBarButtonItemStylePlain target:self action:@selector(pop)];
        }
        self.navigationItem.leftBarButtonItem = backButton;
    }

    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone){
        storyboard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle:nil];
    } else {
        storyboard = [UIStoryboard storyboardWithName:@"Main_iPad" bundle:nil];
    }
    
    _collaborators = [NSMutableArray array];
    if (_story.collaborators.count){
        for (XXUser *user in _story.collaborators){
            [_collaborators addObject:user.identifier];
        }
    }
    _circleCollaborators = [NSMutableArray array];
    if (_story.circles.count){
        for (XXCircle *circle in _story.circles){
            [_circleCollaborators addObject:circle.identifier];
        }
    }
    navBarShadowView = [Utilities findNavShadow:self.navigationController.navigationBar];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addCollaborators:) name:@"Collaborators" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addCircleCollaborators:) name:@"CircleCollaborators" object:nil];
}

- (void)pop{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)setupControls {
    if (_story.identifier){
        saveButton = [[UIBarButtonItem alloc] initWithTitle:@"   SAVE   " style:UIBarButtonItemStylePlain target:self action:@selector(save)];
        self.navigationItem.rightBarButtonItems = @[saveButton,optionsButton];
        if ([_story.owner.identifier isEqualToNumber:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]]){
            [self.deleteButton setHidden:NO];
        } else {
            CGRect doneRect = self.doneOptionsButton.frame;
            doneRect.origin.x = width/2-doneRect.size.width/2;
            [self.doneOptionsButton setFrame:doneRect];
            [self.deleteButton setHidden:YES];
        }
        [self setupStoryBooleans];
    } else {
        _story = [[XXStory alloc] init];
        _story.saved = YES;
        _story.privateStory = YES;
        XXContribution *firstContribution = [[XXContribution alloc] init];
        [firstContribution setAllowFeedback:NO];
        _story.contributions = [NSMutableArray arrayWithObject:firstContribution];
        saveButton = [[UIBarButtonItem alloc] initWithTitle:@"   SAVE   " style:UIBarButtonItemStylePlain target:self action:@selector(save)];
        self.navigationItem.rightBarButtonItems = @[saveButton,publishButton,optionsButton];
        CGRect doneRect = self.doneOptionsButton.frame;
        doneRect.origin.x = self.optionsContainerView.frame.size.width/2-doneRect.size.width/2;
        [self.doneOptionsButton setFrame:doneRect];
        [self.deleteButton setHidden:YES];
    }
}

- (void)offsetOptions {
    self.feedbackSwitch.transform = CGAffineTransformMakeTranslation(width, 0);
    [self.feedbackSwitch addTarget:self action:@selector(shareButton) forControlEvents:UIControlEventValueChanged];
    self.feedbackLabel.transform = CGAffineTransformMakeTranslation(width, 0);
    
    self.joinableSwitch.transform = CGAffineTransformMakeTranslation(width, 0);
    [self.joinableSwitch addTarget:self action:@selector(shareButton) forControlEvents:UIControlEventValueChanged];
    self.joinableLabel.transform = CGAffineTransformMakeTranslation(width, 0);
    
    self.slowRevealLabel.transform = CGAffineTransformMakeTranslation(width, 0);
    self.slowRevealSwitch.transform = CGAffineTransformMakeTranslation(width, 0);
    [self.slowRevealSwitch addTarget:self action:@selector(shareButton) forControlEvents:UIControlEventValueChanged];
    
    self.privateSwitch.transform = CGAffineTransformMakeTranslation(width, 0);
    self.privateLabel.transform = CGAffineTransformMakeTranslation(width, 0);
    [self.privateSwitch addTarget:self action:@selector(shareButton) forControlEvents:UIControlEventValueChanged];
    
    self.draftLabel.transform = CGAffineTransformMakeTranslation(width, 0);
    self.draftSwitch.transform = CGAffineTransformMakeTranslation(width, 0);
    [self.draftSwitch addTarget:self action:@selector(shareButton) forControlEvents:UIControlEventValueChanged];
    
    self.doneOptionsButton.transform = CGAffineTransformMakeTranslation(width, 0);
    self.deleteButton.transform = CGAffineTransformMakeTranslation(-width, 0);
    self.collaborateButton.transform = CGAffineTransformMakeTranslation(0, height/2);
}

-(void)blurredSnapshot {
    UIGraphicsBeginImageContextWithOptions(self.tableView.frame.size, NO, self.view.window.screen.scale);
    [self.view drawViewHierarchyInRect:self.view.frame afterScreenUpdates:NO];
    UIImage *snapshotImage = UIGraphicsGetImageFromCurrentImageContext();
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
        blurredSnapshotImage = [snapshotImage applyBlurWithRadius:20 blurType:BOXFILTER tintColor:[UIColor colorWithWhite:0 alpha:.90] saturationDeltaFactor:1.8 maskImage:nil];
    } else {
        blurredSnapshotImage = [snapshotImage applyBlurWithRadius:10 blurType:BOXFILTER tintColor:[UIColor colorWithWhite:1 alpha:.25] saturationDeltaFactor:1.8 maskImage:nil];
    }
    
    UIGraphicsEndImageContext();
    blurredImageView = [[UIImageView alloc] initWithImage:blurredSnapshotImage];
    [blurredImageView setAlpha:0.0];
}

- (void)setupStoryBooleans {
    if (_story.saved){
        [self.draftSwitch setOn:YES animated:NO];
    } else {
        [self.draftSwitch setOn:NO animated:NO];
    }
    
    if (_story.joinable){
        [self.joinableSwitch setOn:YES animated:NO];
    } else {
        [self.joinableSwitch setOn:NO animated:NO];
    }
    if (_story.mystery){
        [self.slowRevealSwitch setOn:YES animated:NO];
    } else {
        [self.slowRevealSwitch setOn:NO animated:NO];
    }
    if (_story.privateStory){
        [self.privateSwitch setOn:YES animated:NO];
    } else {
        [self.privateSwitch setOn:NO animated:NO];
    }
    if (_story.lastContribution.allowFeedback){
        [self.feedbackSwitch setOn:YES animated:NO];
    } else {
        [self.feedbackSwitch setOn:NO animated:NO];
    }
}

- (void)showOptions {
    if (self.optionsContainerView.hidden == YES){
        [self.optionsContainerView setHidden:NO];
        [self blurredSnapshot];
        [blurredImageView setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
        [self.view insertSubview:blurredImageView belowSubview:self.optionsContainerView];
        [self setupStoryBooleans];
        
        [UIView animateWithDuration:.5 animations:^{
            [blurredImageView setAlpha:1.0];
        }];
        [self animateWiggle:self.draftLabel withSwitch:self.draftSwitch orButton:nil withDelay:0];
        [self animateWiggle:self.privateLabel withSwitch:self.privateSwitch orButton:nil withDelay:0.025];
        [self animateWiggle:self.feedbackLabel withSwitch:self.feedbackSwitch orButton:nil withDelay:.05];
        [self animateWiggle:self.joinableLabel withSwitch:self.joinableSwitch orButton:nil withDelay:.075];
        [self animateWiggle:self.slowRevealLabel withSwitch:self.slowRevealSwitch orButton:nil withDelay:.1];
        [self animateWiggle:nil withSwitch:nil orButton:self.doneOptionsButton withDelay:.125];
        [self animateWiggle:nil withSwitch:nil orButton:self.deleteButton withDelay:.15];
        [self animateWiggle:nil withSwitch:nil orButton:self.collaborateButton withDelay:.175];
    } else {
        [UIView animateWithDuration:.6 animations:^{
            [blurredImageView setAlpha:0.0];
        } completion:^(BOOL finished) {
            [self.optionsContainerView setHidden:YES];
            blurredSnapshotImage = nil;
            blurredImageView = nil;
        }];
        [self animateWiggleOff:self.draftLabel withSwitch:self.draftSwitch orButton:nil withDelay:0];
        [self animateWiggleOff:self.privateLabel withSwitch:self.privateSwitch orButton:nil withDelay:.025];
        [self animateWiggleOff:self.feedbackLabel withSwitch:self.feedbackSwitch orButton:nil withDelay:.05];
        [self animateWiggleOff:self.joinableLabel withSwitch:self.joinableSwitch orButton:nil withDelay:.075];
        [self animateWiggleOff:self.slowRevealLabel withSwitch:self.slowRevealSwitch orButton:nil withDelay:.1];
        [self animateWiggleOff:nil withSwitch:nil orButton:self.doneOptionsButton withDelay:.125];
        [self animateWiggleOff:nil withSwitch:nil orButton:self.deleteButton withDelay:.15];
        [self animateWiggleOff:nil withSwitch:nil orButton:self.collaborateButton withDelay:.175];
    }
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    currentOrientation = toInterfaceOrientation;
    [self.tableView reloadData];
}

- (IBAction)deleteStory{
    [[[UIAlertView alloc] initWithTitle:@"Confirmation Needed" message:@"Are you sure you want to delete your story? This can not be undone." delegate:self cancelButtonTitle:@"No!" otherButtonTitles:@"Yes", nil] show];
}
- (void)doubleConfirmation{
    [[[UIAlertView alloc] initWithTitle:@"Double Checking..." message:@"Are you really sure you want to delete your story?" delegate:self cancelButtonTitle:@"No!" otherButtonTitles:@"Really Sure", nil] show];
}

- (IBAction)doneOptions{
    [UIView animateWithDuration:.6 animations:^{
        [blurredImageView setAlpha:0.0];
    } completion:^(BOOL finished) {
        [self.optionsContainerView setHidden:YES];
        blurredSnapshotImage = nil;
        blurredImageView = nil;
    }];
    [self animateWiggleOff:self.draftLabel withSwitch:self.draftSwitch orButton:nil withDelay:0];
    [self animateWiggleOff:self.privateLabel withSwitch:self.privateSwitch orButton:nil withDelay:.025];
    [self animateWiggleOff:self.feedbackLabel withSwitch:self.feedbackSwitch orButton:nil withDelay:.05];
    [self animateWiggleOff:self.joinableLabel withSwitch:self.joinableSwitch orButton:nil withDelay:.075];
    [self animateWiggleOff:self.slowRevealLabel withSwitch:self.slowRevealSwitch orButton:nil withDelay:.1];
    [self animateWiggleOff:nil withSwitch:nil orButton:self.doneOptionsButton withDelay:.125];
    [self animateWiggleOff:nil withSwitch:nil orButton:self.deleteButton withDelay:.15];
    [self animateWiggleOff:nil withSwitch:nil orButton:self.collaborateButton withDelay:.175];
}

- (void)animateWiggle:(UILabel*)theLabel withSwitch:(UISwitch*)theSwitch orButton:(UIButton*)button withDelay:(NSTimeInterval)delay {
    [UIView animateWithDuration:.75 delay:delay usingSpringWithDamping:.5 initialSpringVelocity:.001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        theLabel.transform = CGAffineTransformIdentity;
        theSwitch.transform = CGAffineTransformIdentity;
        button.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        
    }];
}

- (void)animateWiggleOff:(UILabel*)theLabel withSwitch:(UISwitch*)theSwitch orButton:(UIButton*)button withDelay:(NSTimeInterval)delay {
    [UIView animateWithDuration:.6 delay:delay usingSpringWithDamping:.5 initialSpringVelocity:.0001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        theSwitch.transform = CGAffineTransformMakeTranslation(width, 0);
        theLabel.transform = CGAffineTransformMakeTranslation(width, 0);
        if (button == self.deleteButton){
            button.transform = CGAffineTransformMakeTranslation(-width, 0);
        } else if (button == self.collaborateButton) {
            button.transform = CGAffineTransformMakeTranslation(0, height/2);
        } else {
            button.transform = CGAffineTransformMakeTranslation(width, 0);
        }
    } completion:^(BOOL finished) {
        
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
        [self.view setBackgroundColor:[UIColor clearColor]];
        textColor = [UIColor whiteColor];
        [self.collaborateButton.layer setBorderColor:textColor.CGColor];
        [self.collaborateButton setTitleColor:textColor forState:UIControlStateNormal];
        [self.doneOptionsButton.layer setBorderColor:textColor.CGColor];
        [self.doneOptionsButton setTitleColor:textColor forState:UIControlStateNormal];
    } else {
        [self.view setBackgroundColor:[UIColor whiteColor]];
        textColor = [UIColor blackColor];
        [self.collaborateButton.layer setBorderColor:[UIColor darkGrayColor].CGColor];
        [self.collaborateButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
        [self.doneOptionsButton.layer setBorderColor:[UIColor darkGrayColor].CGColor];
        [self.doneOptionsButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    }
    [self.draftLabel setTextColor:textColor];
    [self.privateLabel setTextColor:textColor];
    [self.feedbackLabel setTextColor:textColor];
    [self.joinableLabel setTextColor:textColor];
    [self.slowRevealLabel setTextColor:textColor];
    if (_story.collaborators.count) {
        [publishButton setTitle:@"   SHARE   "];
    }
    navBarShadowView.hidden = YES;
    if (self.view.alpha != 1.f){
        [UIView animateWithDuration:.23 animations:^{
            [self.view setAlpha:1.0];
            self.view.transform = CGAffineTransformIdentity;
        }];
    }
}

- (void)prepareStory{
    [self setupControls];
    [self.tableView reloadData];
}

- (void)confirmPublish {
    if (self.draftSwitch.isOn){
        [[[UIAlertView alloc] initWithTitle:@"Ready to Publish?" message:@"This story is still in draft mode. Are you sure you want to publish?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Publish", nil] show];
    } else if (self.privateSwitch.isOn) {
        [[[UIAlertView alloc] initWithTitle:@"Ready to Publish?" message:@"This story is in private mode. Publishing will only make it visible to your collaborators." delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Publish", nil] show];
    } else {
        [[[UIAlertView alloc] initWithTitle:@"Ready to Publish?" message:@"This will make the story visible to the public." delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Publish", nil] show];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Publish"]){
        [self send];
    } else if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Yes"]) {
        [self doubleConfirmation];
    } else if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Really Sure"]) {
        [self actuallyDelete];
    }
}

- (void)actuallyDelete {
    [ProgressHUD show:@"Deleting story..."];
    [manager DELETE:[NSString stringWithFormat:@"%@/stories/%@",kAPIBaseUrl,_story.identifier] parameters:@{@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"success deleting story: %@",responseObject);
        if ([self.navigationController.viewControllers.firstObject isKindOfClass:[XXDraftsViewController class]] || [self.navigationController.viewControllers.firstObject isKindOfClass:[XXMyStoriesViewController class]]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"RemoveStory" object:nil userInfo:@{@"story_id":_story.identifier}];
            [self.navigationController popViewControllerAnimated:YES];
        } else {
            _story = nil;
            [self prepareStory];
            [self doneOptions];
        }
        [ProgressHUD dismiss];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failed to delete story: %@",error.description);
        [ProgressHUD dismiss];
    }];
}

- (void)addCollaborators:(NSNotification*)notification{
    _collaborators = [notification.userInfo objectForKey:@"collaborators"];
}
- (void)addCircleCollaborators:(NSNotification*)notification{
    _circleCollaborators = [notification.userInfo objectForKey:@"circleCollaborators"];
    NSLog(@"should be adding circle collaborators: %@",notification.userInfo);
}

- (void)save{
    saving = YES;
    [self send];
}

- (void)send{
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"story[owner_id]"];
    [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"contribution[user_id]"];
    
    if (bodyTextView.text.length && ![bodyTextView.text isEqualToString:kStoryPlaceholder]){
        [parameters setObject:[bodyTextView.attributedText htmlFragment] forKey:@"contribution[body]"];
        NSLog(@"html fragment: %@",[bodyTextView.attributedText htmlFragment]);
        //NSLog(@"html string: %@",[bodyTextView.attributedText htmlString]);
    }
    if (titleTextField.text.length && ![titleTextField.text isEqualToString:kTitlePlaceholder]) {
        [parameters setObject:titleTextField.text forKey:@"story[title]"];
    }
    
    if (self.draftSwitch.isOn){
        [parameters setObject:[NSNumber numberWithBool:YES] forKey:@"contribution[saved]"];
        [parameters setObject:[NSNumber numberWithBool:YES] forKey:@"story[saved]"];
    } else {
        [parameters setObject:[NSNumber numberWithBool:NO] forKey:@"contribution[saved]"];
        [parameters setObject:[NSNumber numberWithBool:NO] forKey:@"story[saved]"];
    }
    
    if (self.joinableSwitch.isOn){
        [parameters setObject:[NSNumber numberWithBool:YES] forKey:@"story[joinable]"];
    } else {
        [parameters setObject:[NSNumber numberWithBool:NO] forKey:@"story[joinable]"];
    }
    
    if (self.feedbackSwitch.isOn){
        [parameters setObject:[NSNumber numberWithBool:YES] forKey:@"contribution[allow_feedback]"];
    } else {
        [parameters setObject:[NSNumber numberWithBool:NO] forKey:@"contribution[allow_feedback]"];
    }
    if (self.privateSwitch.isOn){
        [parameters setObject:[NSNumber numberWithBool:YES] forKey:@"contribution[is_private]"];
        [parameters setObject:[NSNumber numberWithBool:YES] forKey:@"story[is_private]"];
    } else {
        [parameters setObject:[NSNumber numberWithBool:NO] forKey:@"contribution[is_private]"];
        [parameters setObject:[NSNumber numberWithBool:NO] forKey:@"story[is_private]"];
    }
    if (self.slowRevealSwitch.isOn){
        [parameters setObject:[NSNumber numberWithBool:YES] forKey:@"story[mystery]"];
    } else {
        [parameters setObject:[NSNumber numberWithBool:NO] forKey:@"story[mystery]"];
    }
    if (_collaborators.count){
        [parameters setObject:[_collaborators componentsJoinedByString:@","] forKey:@"story[user_ids]"];
    }
    if (_circleCollaborators.count){
        [parameters setObject:[_circleCollaborators componentsJoinedByString:@","] forKey:@"story[circle_ids]"];
    }
    
    if (saving && _story.identifier){
        [ProgressHUD show:@"Saving..."];
        [manager PUT:[NSString stringWithFormat:@"%@/stories/%@",kAPIBaseUrl,_story.identifier] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"Success saving your story: %@",responseObject);
            _story = [[XXStory alloc] initWithDictionary:[responseObject objectForKey:@"story"]];
            [self doneOptions];
            [[[UIAlertView alloc] initWithTitle:@"Story saved" message:nil delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
            //[self.tableView reloadData];
            [ProgressHUD dismiss];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            [ProgressHUD dismiss];
            [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Something went wrong while trying to save your story. Please try again soon." delegate:nil cancelButtonTitle:@"Shucks" otherButtonTitles:nil] show];
            NSLog(@"Failed to update a story: %@",error.description);
        }];
        saving = NO;
    } else if (saving) {
        [ProgressHUD show:@"Saving..."];
        [manager POST:[NSString stringWithFormat:@"%@/stories",kAPIBaseUrl] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"Success creating and then savign your story: %@",responseObject);
            [[[UIAlertView alloc] initWithTitle:@"Story saved" message:nil delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
            [ProgressHUD dismiss];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Failed to create and then save a story: %@",error.description);
            [ProgressHUD dismiss];
        }];
    } else {
        [ProgressHUD show:@"Publishing..."];
        [manager POST:[NSString stringWithFormat:@"%@/stories",kAPIBaseUrl] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"Success creating your story: %@",responseObject);
            _story = [[XXStory alloc] initWithDictionary:[responseObject objectForKey:@"story"]];
            [self showStory];
            [ProgressHUD dismiss];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Failed to create a story: %@",error.description);
            [ProgressHUD dismiss];
        }];
    }
}

- (void)showStory {
    XXStoryViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"Story"];
    [vc setStory:_story];
    XXAppDelegate *delegate = [UIApplication sharedApplication].delegate;
    [vc setStories:delegate.menuViewController.stories];
    [vc setTitle:_story.title];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    [delegate.dynamicsDrawerViewController setPaneState:MSDynamicsDrawerPaneStateClosed];
    [delegate.dynamicsDrawerViewController setPaneViewController:nav animated:NO completion:^{
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
}

- (void)shareButton {
    if (_story.collaborators.count || self.joinableSwitch.isOn){
        [publishButton setTitle:@"   SHARE   "];
    } else {
        [publishButton setTitle:@"   PUBLISH   "];
    }
    
    if (self.draftSwitch.isOn){
        _story.saved = YES;
    } else {
        _story.saved = NO;
    }
    
    if (self.privateSwitch.isOn){
        _story.privateStory = YES;
    } else {
        _story.privateStory = NO;
    }
    
    if (self.joinableSwitch.isOn){
        _story.joinable = YES;
    } else {
        _story.joinable = NO;
    }
    
    if (self.slowRevealSwitch.isOn){
        _story.mystery = YES;
    } else {
        _story.mystery = NO;
    }
    if (self.feedbackSwitch.isOn){
        _story.lastContribution.allowFeedback = YES;
    } else {
        _story.lastContribution.allowFeedback = NO;
    }
}

- (IBAction)collaborate {
    XXCollaborateViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"Collaborate"];
    [vc setModal:YES];
    [vc setTitle:@"Collaborate"];
    [vc setCollaborators:_collaborators];
    [vc setCollaborators:_circleCollaborators];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
        [UIView animateWithDuration:.23 animations:^{
            [self.view setAlpha:0.0];
            self.view.transform = CGAffineTransformMakeScale(.8, .8);
        }];
    }
    [self presentViewController:nav animated:YES completion:^{
        
    }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) return 1;
    else return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        XXWritingCell *cell = (XXWritingCell *)[tableView dequeueReusableCellWithIdentifier:@"WritingCell"];
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"XXWritingCell" owner:nil options:nil] lastObject];
        }
        if (_story){
            [cell configure:_story withOrientation:self.interfaceOrientation];
        }
        
        if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground] && !_story.title.length){
            [cell.titleTextField setText:kTitlePlaceholder];
            cell.titleTextField.keyboardAppearance = UIKeyboardAppearanceDark;
            cell.textView.keyboardAppearance = UIKeyboardAppearanceDark;
        } else {
            cell.titleTextField.keyboardAppearance = UIKeyboardAppearanceDefault;
            cell.textView.keyboardAppearance = UIKeyboardAppearanceDefault;
        }
        titleTextField = cell.titleTextField;
        [titleTextField setDelegate:self];
        [titleTextField setTextColor:textColor];
        
        bodyTextView = cell.textView;
        bodyTextView.delegate = self;
        if (bodyTextView.text.length && ![bodyTextView.text isEqualToString:kStoryPlaceholder]){
            [bodyTextView setTextColor:textColor];
        }
        
        return cell;
    } else {
        return nil;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 0:
            return screen.size.height;
            break;
            
        default:
            return 0;
            break;
    }
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if([indexPath row] == ((NSIndexPath*)[[tableView indexPathsForVisibleRows] lastObject]).row && tableView == self.tableView){
        //end of loading
        [ProgressHUD dismiss];
    }
    cell.backgroundColor = [UIColor clearColor];
}

#pragma mark - UITextViewDelegate Methods

- (void)willShowKeyboard:(NSNotification *)notification {
    self.tableView.pagingEnabled = NO;
    /*CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(44.0, 0.0, keyboardSize.height, 0.0);
    self.tableView.contentInset = contentInsets;
    self.tableView.scrollIndicatorInsets = contentInsets;
    CGRect aRect = self.view.frame;
    aRect.size.height -= keyboardSize.height;
    if (!CGRectContainsPoint(aRect, addCommentTextView.frame.origin) ) {
        CGPoint scrollPoint = CGPointMake(0.0, addCommentTextView.frame.origin.y - (keyboardSize.height-45));
        [self.tableView setContentOffset:scrollPoint animated:YES];
    }*/
}

-(void)doneEditing {
    [self.view endEditing:YES];
    if (_story.identifier){
        self.navigationItem.rightBarButtonItems = @[saveButton,optionsButton];
    } else {
        self.navigationItem.rightBarButtonItems = @[saveButton,publishButton,optionsButton];
    }
    self.tableView.pagingEnabled = YES;
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
    self.navigationItem.rightBarButtonItems = nil;
    self.navigationItem.rightBarButtonItem = doneButton;
    if ([textView.text isEqualToString:kStoryPlaceholder]) {
        textView.text = @"";
        textView.textColor = textColor;
        Mixpanel *mixpanel = [Mixpanel sharedInstance];
        [mixpanel track:@"Started Writing" properties:@{
                                                        @"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId],
                                                        @"pen_name":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsPenName]
                                                        }];
    }
}

- (void)textViewDidEndEditing:(UITextView *)textView{
    if ([textView.text isEqualToString:@""]) {
        textView.text = kStoryPlaceholder;
        textView.textColor = [UIColor lightGrayColor];
    }
}
- (void)willHideKeyboard {
    self.tableView.scrollEnabled = YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    if ([string isEqualToString:@"\n"]) {
        if (textField.text.length) {
            [self doneEditing];
        }
        [textField resignFirstResponder];
        return NO;
    }
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    self.navigationItem.rightBarButtonItems = nil;
    self.navigationItem.rightBarButtonItem = doneButton;
    if ([textField.text isEqual:kTitlePlaceholder]){
        textField.text = @"";
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if ([textField.text isEqual:@""]){
        textField.text = kTitlePlaceholder;
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)back{
    XXAppDelegate *delegate = (XXAppDelegate*)[UIApplication sharedApplication].delegate;
    [self dismissViewControllerAnimated:YES completion:nil];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
        [UIView animateWithDuration:.3 animations:^{
            [[delegate.dynamicsDrawerViewController paneViewController].view setAlpha:1.0];
        }];
    }
}

@end

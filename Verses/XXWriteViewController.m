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
#import "XXWritingTitleCell.h"
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
#import "UIFontDescriptor+CrimsonText.h"
#import "UIFontDescriptor+SourceSansPro.h"

@interface XXWriteViewController () <UITextFieldDelegate, UITextViewDelegate, UIGestureRecognizerDelegate, UIAlertViewDelegate, TextViewDelegate, UITextInputDelegate> {
    NSArray *sidebarImageArray;
    UITextField *titleTextField;
    XXTextView *bodyTextView;
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
    NSMutableArray *_collaborators;
    NSMutableArray *_circleCollaborators;
    UIColor *textColor;
    UIInterfaceOrientation currentOrientation;
    UIImageView *navBarShadowView;
    NSString *_selectedText;
    UITextRange *_selectedRange;
    UIBarButtonItem *leftBarButtonItem;
    XXTextStorage *_textStorage;
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
    manager = [(XXAppDelegate*)[UIApplication sharedApplication].delegate manager];
    width = screenWidth();
    height = screenHeight();
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(willHideKeyboard)
                                                 name:UIKeyboardWillHideNotification object:nil];
    publishButton = [[UIBarButtonItem alloc] initWithTitle:@"   PUBLISH   " style:UIBarButtonItemStylePlain target:self action:@selector(confirmPublish)];
    doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneEditing)];
    optionsButton = [[UIBarButtonItem alloc] initWithTitle:@"   OPTIONS   " style:UIBarButtonItemStylePlain target:self action:@selector(showOptions)];

    //setup controls has lots of story logic in it
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
    
    //set left bar button item
    if (self.navigationController.viewControllers.firstObject == self){
        leftBarButtonItem = [[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"blackX"] style:UIBarButtonItemStylePlain target:self action:@selector(back)];
    } else {
        if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
            leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"whiteBack"] style:UIBarButtonItemStylePlain target:self action:@selector(pop)];
        } else {
            leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"back"] style:UIBarButtonItemStylePlain target:self action:@selector(pop)];
        }
    }
    self.navigationItem.leftBarButtonItem = leftBarButtonItem;
    
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
    
    [self.tableView setContentInset:UIEdgeInsetsMake(56, 0, 0, 0)];
}

- (void)pop{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)setupControls {
    
    if (_story.contributions.count){
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
    if (UIInterfaceOrientationIsPortrait(toInterfaceOrientation)){
        width = screenWidth();
        height = screenHeight();
    } else {
        width = screenHeight();
        height = screenWidth();
    }
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
        bodyTextView.keyboardAppearance = UIKeyboardAppearanceDark;
    } else {
        [self.view setBackgroundColor:[UIColor whiteColor]];
        textColor = [UIColor blackColor];
        [self.collaborateButton.layer setBorderColor:[UIColor darkGrayColor].CGColor];
        [self.collaborateButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
        [self.doneOptionsButton.layer setBorderColor:[UIColor darkGrayColor].CGColor];
        [self.doneOptionsButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
        bodyTextView.keyboardAppearance = UIKeyboardAppearanceDefault;
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
    [self createTextViewWithOrientation:self.interfaceOrientation];
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
    XXStoryViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Story"];
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
    XXCollaborateViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Collaborate"];
    [vc setModal:YES];
    [vc setTitle:@"Collaborate"];
    [vc setCollaborators:_collaborators];
    [vc setCircleCollaborators:_circleCollaborators];
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
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        XXWritingTitleCell *cell = (XXWritingTitleCell *)[tableView dequeueReusableCellWithIdentifier:@"WritingTitleCell"];
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"XXWritingTitleCell" owner:nil options:nil] lastObject];
        }
        [cell configure:_story withOrientation:self.interfaceOrientation];
        
        if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground] && !_story.title.length){
            [cell.titleTextField setText:kTitlePlaceholder];
            cell.titleTextField.keyboardAppearance = UIKeyboardAppearanceDark;
        } else {
            cell.titleTextField.keyboardAppearance = UIKeyboardAppearanceDefault;
        }
        
        
        titleTextField = cell.titleTextField;
        [titleTextField setDelegate:self];
        [titleTextField setTextColor:textColor];
        
        return cell;
    } else {
        XXWritingCell *cell = (XXWritingCell *)[tableView dequeueReusableCellWithIdentifier:@"WritingCell"];
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"XXWritingCell" owner:nil options:nil] lastObject];
        }
        
        if (bodyTextView){
            if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground] && !_story.title.length){
                bodyTextView.keyboardAppearance = UIKeyboardAppearanceDark;
            } else {
                bodyTextView.keyboardAppearance = UIKeyboardAppearanceDefault;
            }
            if ([bodyTextView.text isEqualToString:kStoryPlaceholder]){
                [bodyTextView setTextColor:[UIColor lightGrayColor]];
            } else {
                
            }
            [cell addSubview:bodyTextView];
            NSLog(@"body text view? %@",bodyTextView);
            [bodyTextView.boldButton addTarget:self action:@selector(boldText) forControlEvents:UIControlEventTouchUpInside];
            [bodyTextView.italicsButton addTarget:self action:@selector(italicText) forControlEvents:UIControlEventTouchUpInside];
            [bodyTextView.underlineButton addTarget:self action:@selector(underlineText) forControlEvents:UIControlEventTouchUpInside];
            [bodyTextView.headerButton addTarget:self action:@selector(headline) forControlEvents:UIControlEventTouchUpInside];
            [bodyTextView.footnoteButton addTarget:self action:@selector(footnote) forControlEvents:UIControlEventTouchUpInside];
            bodyTextView.keyboardEnabled = NO;
            bodyTextView.selectable = YES;
            bodyTextView.delegate = self;
        }
        return cell;
    }
}

- (void)createTextViewWithOrientation:(UIInterfaceOrientation)orientation {
    NSString *storyBody = @"";
    if (_story && _story.contributions.count){
        for (XXContribution *contribution in _story.contributions) {
            if (contribution.body.length) storyBody = [storyBody stringByAppendingString:contribution.body];
        }
        
        NSDictionary* attributes = @{NSFontAttributeName:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCrimsonTextFontDescriptorWithTextStyle:UIFontTextStyleBody] size:0],
                                     /*NSParagraphStyleAttributeName:paragraphStyle,
                                     NSForegroundColorAttributeName:textColor,*/
                                     NSDocumentTypeDocumentAttribute:NSHTMLTextDocumentType,
                                     };
        NSMutableAttributedString* attrString = [[NSMutableAttributedString alloc] initWithData:[storyBody dataUsingEncoding:NSUTF32StringEncoding] options:attributes documentAttributes:nil error:nil];
        [attrString beginEditing];
        [attrString addAttributes:attributes range:NSMakeRange(0, attrString.length)];
        [attrString endEditing];
        _textStorage = [XXTextStorage new];
        [_textStorage appendAttributedString:attrString];
        
        NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];
        
        CGRect bodyRect = [attrString boundingRectWithSize:CGSizeMake(screenWidth()-10, CGFLOAT_MAX)
                                                   options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading)
                                                   context:nil];
        NSLog(@"height of bodyrect: %f",bodyRect.size.height);
        CGSize containerSize = CGSizeMake(bodyRect.size.width,  CGFLOAT_MAX);
        NSTextContainer *container = [[NSTextContainer alloc] initWithSize:containerSize];
        container.widthTracksTextView = YES;
        [layoutManager addTextContainer:container];
        [_textStorage addLayoutManager:layoutManager];
        
        bodyTextView = [[XXTextView alloc] initWithFrame:bodyRect textContainer:container];
        bodyTextView.keyboardEnabled = YES;
        bodyTextView.selectable = YES;
        bodyTextView.userInteractionEnabled = YES;
        
        [bodyTextView setupButtons];
        [bodyTextView setScrollEnabled:NO];
    } else {
        storyBody = kStoryPlaceholder;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 0:
            return 56;
            break;
        case 1:
        {
            return bodyTextView.frame.size.height;
        }
            break;
        default:
            return 0;
            break;
    }
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.section == tableView.numberOfSections && indexPath.row == ((NSIndexPath*)[[tableView indexPathsForVisibleRows] lastObject]).row){
        //end of loading
        [ProgressHUD dismiss];
    }
    cell.backgroundColor = [UIColor clearColor];
}

#pragma mark - UITextViewDelegate Methods

-(void)doneEditing {
    [self.view endEditing:YES];
    if (_story.identifier){
        self.navigationItem.rightBarButtonItems = @[saveButton,optionsButton];
    } else {
        self.navigationItem.rightBarButtonItems = @[saveButton,publishButton,optionsButton];
    }
}

- (void)willHideKeyboard {
}

/*- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    if ([string isEqualToString:@"\n"]) {
        if (textField.text.length) {
            [self doneEditing];
        }
        [textField resignFirstResponder];
        return NO;
    }
    return YES;
}*/

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    self.navigationItem.rightBarButtonItems = nil;
    self.navigationItem.rightBarButtonItem = doneButton;
    if ([textField.text isEqual:kTitlePlaceholder]){
        textField.text = @"";
    }
    self.navigationItem.leftBarButtonItem = nil;
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
        textField.keyboardAppearance = UIKeyboardAppearanceDark;
        [textField setTextColor:textColor];
    } else {
        textField.keyboardAppearance = UIKeyboardAppearanceDefault;
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if (![textField.text isEqual:kTitlePlaceholder] && textField.text.length > 0){
        NSLog(@"textfield text should be reset");
        _story.title = textField.text;
    }
    self.navigationItem.leftBarButtonItem = leftBarButtonItem;
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
    self.navigationItem.leftBarButtonItem = nil;
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
        textView.keyboardAppearance = UIKeyboardAppearanceDark;
    } else {
        textView.keyboardAppearance = UIKeyboardAppearanceDefault;
    }
}

- (void)textViewDidEndEditing:(UITextView *)textView{
    if ([textView.text isEqualToString:@""]) {
        textView.text = kStoryPlaceholder;
        textView.textColor = [UIColor lightGrayColor];
    }
    self.navigationItem.leftBarButtonItem = leftBarButtonItem;
}

- (void)boldText {
    [bodyTextView toggleBoldface:nil];
}

- (void)italicText {
    [bodyTextView toggleItalics:nil];
}

- (void)underlineText {
    [bodyTextView toggleUnderline:nil];
}

- (void)headline {
    if (_selectedText.length){
        NSRange selectionRange = [self selectedRangeForText:_selectedRange];
        NSMutableAttributedString *attrString = [bodyTextView.textStorage attributedSubstringFromRange:[self selectedRangeForText:_selectedRange]].mutableCopy;
        UIFontDescriptor *currentFontDescriptor = [[bodyTextView.textStorage attributesAtIndex:selectionRange.location effectiveRange:NULL][NSFontAttributeName] fontDescriptor];
        CGFloat fontSize = [currentFontDescriptor.fontAttributes[UIFontDescriptorSizeAttribute] floatValue];
        
        [attrString beginEditing];
        if (fontSize < 25.f){
            [attrString addAttribute:NSFontAttributeName value:[UIFont fontWithDescriptor:[[UIFontDescriptor preferredSourceSansProFontDescriptorWithTextStyle:UIFontTextStyleSubheadline] fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold] size:0] range:NSMakeRange((0), attrString.length)];
            [bodyTextView.textStorage replaceCharactersInRange:selectionRange withAttributedString:attrString];
        } else if (fontSize > 25.f && fontSize < 30.f){
            [attrString addAttribute:NSFontAttributeName value:[UIFont fontWithDescriptor:[[UIFontDescriptor preferredSourceSansProFontDescriptorWithTextStyle:UIFontTextStyleHeadline] fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold] size:0] range:NSMakeRange((0), attrString.length)];
            [bodyTextView.textStorage replaceCharactersInRange:selectionRange withAttributedString:attrString];
        } else {
            [attrString addAttribute:NSFontAttributeName value:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCrimsonTextFontDescriptorWithTextStyle:UIFontTextStyleBody] size:0] range:NSMakeRange((0), attrString.length)];
            [bodyTextView.textStorage replaceCharactersInRange:selectionRange withAttributedString:attrString];
        }
        
        [attrString endEditing];
    }
}

- (void)footnote {
    if (_selectedText.length){
        NSRange selectionRange = [self selectedRangeForText:_selectedRange];
        NSMutableAttributedString *attrString = [bodyTextView.textStorage attributedSubstringFromRange:[self selectedRangeForText:_selectedRange]].mutableCopy;
        
        [attrString beginEditing];
        [attrString addAttribute:NSFontAttributeName value:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCrimsonTextFontDescriptorWithTextStyle:UIFontTextStyleFootnote] size:0] range:NSMakeRange((0), attrString.length)];
        [bodyTextView.textStorage replaceCharactersInRange:selectionRange withAttributedString:attrString];
        
        [attrString endEditing];
    }
}

- (NSRange) selectedRangeForText:(UITextRange*)selectedRange
{
    UITextPosition* beginning = bodyTextView.beginningOfDocument;
    UITextPosition* selectionStart = selectedRange.start;
    UITextPosition* selectionEnd = selectedRange.end;
    const NSInteger location = [bodyTextView offsetFromPosition:beginning toPosition:selectionStart];
    const NSInteger length = [bodyTextView offsetFromPosition:selectionStart toPosition:selectionEnd];
    return NSMakeRange(location, length);
}

- (void)textViewDidChangeSelection:(UITextView *)textView {
    _selectedRange = [textView selectedTextRange];
    _selectedText = [textView textInRange:_selectedRange];
    //NSLog(@"selected text from write view: %@",_selectedText);
    if (!_selectedText.length) {
        [self resignFirstResponder];
        _selectedText = nil;
        _selectedRange = nil;
    }
}

- (void)textWillChange:(id<UITextInput>)textInput {
    NSLog(@"text will change: %@",textInput);
}

- (void)textDidChange:(id<UITextInput>)textInput {
    NSLog(@"text did change: %@",textInput);
}

- (void)selectionDidChange:(id<UITextInput>)textInput {
    NSLog(@"selection did change: %@",textInput);
}

- (void)selectionWillChange:(id<UITextInput>)textInput {
    NSLog(@"selection will change: %@",textInput);
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

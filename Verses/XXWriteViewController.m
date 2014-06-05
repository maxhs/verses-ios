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
#import "XXAlert.h"

@interface XXWriteViewController () <UITextFieldDelegate, UITextViewDelegate, UIGestureRecognizerDelegate, UIAlertViewDelegate, UITextInputDelegate> {
    CGFloat width;
    CGFloat height;
    AFHTTPRequestOperationManager *manager;
    BOOL joinable;
    BOOL mystery;
    BOOL private;
    BOOL saving;
    BOOL keyboardIsVisible;
    CGRect keyboardRect;
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
    XXTextView *_bodyTextView;
    CGFloat widthSpacer;
    CGFloat offset;
    UIButton *loadPreviousButton;
    UIButton *loadMoreButton;
    NSMutableArray *sections;
    
    BOOL boldSelected;
    BOOL underlineSelected;
    BOOL italicsSelected;
}

@end

@implementation XXWriteViewController
@synthesize story = _story;
@synthesize welcomeViewController;

- (void)viewDidLoad {
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)]){
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
    
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
    
    manager = [(XXAppDelegate*)[UIApplication sharedApplication].delegate manager];
    width = screenWidth();
    height = screenHeight();
    publishButton = [[UIBarButtonItem alloc] initWithTitle:@"   PUBLISH   " style:UIBarButtonItemStylePlain target:self action:@selector(confirmPublish)];
    doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneEditing)];
    optionsButton = [[UIBarButtonItem alloc] initWithTitle:@"   OPTIONS   " style:UIBarButtonItemStylePlain target:self action:@selector(showOptions)];

    //setup controls has lots of story logic in it
    [self offsetOptions];
    [self setupView];
    [self setupControls];
    
    [super viewDidLoad];
    
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
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(willShowKeyboard:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(willHideKeyboard:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
        [self.view setBackgroundColor:[UIColor clearColor]];
        textColor = [UIColor whiteColor];
        [self.collaborateButton.layer setBorderColor:textColor.CGColor];
        [self.collaborateButton setTitleColor:textColor forState:UIControlStateNormal];
        [self.doneOptionsButton.layer setBorderColor:textColor.CGColor];
        [self.doneOptionsButton setTitleColor:textColor forState:UIControlStateNormal];
        _bodyTextView.keyboardAppearance = UIKeyboardAppearanceDark;
    } else {
        [self.view setBackgroundColor:[UIColor whiteColor]];
        textColor = [UIColor blackColor];
        [self.collaborateButton.layer setBorderColor:[UIColor darkGrayColor].CGColor];
        [self.collaborateButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
        [self.doneOptionsButton.layer setBorderColor:[UIColor darkGrayColor].CGColor];
        [self.doneOptionsButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
        _bodyTextView.keyboardAppearance = UIKeyboardAppearanceDefault;
    }
    [self.draftLabel setTextColor:textColor];
    [self.privateLabel setTextColor:textColor];
    [self.feedbackLabel setTextColor:textColor];
    [self.joinableLabel setTextColor:textColor];
    [self.slowRevealLabel setTextColor:textColor];

    [_titleTextField setTextColor:textColor];
    [_titleTextField setFont:[UIFont fontWithName:kSourceSansProSemibold size:33]];
    [_titleTextField setAutocapitalizationType:UITextAutocapitalizationTypeWords];
    
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
    [self drawStory];
}

- (void)prepareStory{
    [self setupControls];
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
        [_titleTextField setPlaceholder:kTitlePlaceholder];
        
        XXContribution *firstContribution = [[XXContribution alloc] init];
        [firstContribution setAllowFeedback:NO];
        _story.contributions = [NSMutableArray arrayWithObject:firstContribution];
        saveButton = [[UIBarButtonItem alloc] initWithTitle:@"   SAVE   " style:UIBarButtonItemStylePlain target:self action:@selector(save)];
        self.navigationItem.rightBarButtonItems = @[saveButton,publishButton,optionsButton];
        CGRect doneRect = _doneOptionsButton.frame;
        doneRect.origin.x = (self.optionsContainerView.frame.size.width/2-doneRect.size.width/2) + width;
        [_doneOptionsButton setFrame:doneRect];
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
    UIGraphicsBeginImageContextWithOptions(self.scrollView.frame.size, NO, self.view.window.screen.scale);
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
    CGRect bodyRect = _bodyTextView.frame;
    bodyRect.size.width = width-widthSpacer;
    [_bodyTextView setFrame:bodyRect];
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
        [[NSNotificationCenter defaultCenter] postNotificationName:@"RemoveStory" object:nil userInfo:@{@"story_id":_story.identifier}];
        if ([self.navigationController.viewControllers.firstObject isKindOfClass:[XXDraftsViewController class]] || [self.navigationController.viewControllers.firstObject isKindOfClass:[XXMyStoriesViewController class]]) {
            [self.navigationController popViewControllerAnimated:YES];
        } else {
            _story = nil;
            [self dismissViewControllerAnimated:YES completion:^{
                [ProgressHUD dismiss];
            }];
        }
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
    NSMutableDictionary *storyParameters = [NSMutableDictionary dictionary];
    NSMutableDictionary *contributionParameters = [NSMutableDictionary dictionary];
    [storyParameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"owner_id"];
    [contributionParameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"user_id"];
    
    if (_bodyTextView.text.length && ![_bodyTextView.text isEqualToString:kStoryPlaceholder]){
        [contributionParameters setObject:[_bodyTextView.attributedText htmlFragment] forKey:@"body"];
    } else {
        [contributionParameters setObject:@"" forKey:@"body"];
    }
    if (_titleTextField.text.length && ![_titleTextField.text isEqualToString:kTitlePlaceholder]) {
        [storyParameters setObject:_titleTextField.text forKey:@"title"];
    } else {
        [storyParameters setObject:@"" forKey:@"title"];
    }
    
    if (self.draftSwitch.isOn){
        [contributionParameters setObject:[NSNumber numberWithBool:YES] forKey:@"saved"];
        [storyParameters setObject:[NSNumber numberWithBool:YES] forKey:@"saved"];
    } else {
        [contributionParameters setObject:[NSNumber numberWithBool:NO] forKey:@"saved"];
        [storyParameters setObject:[NSNumber numberWithBool:NO] forKey:@"saved"];
    }
    
    if (self.joinableSwitch.isOn){
        [storyParameters setObject:[NSNumber numberWithBool:YES] forKey:@"joinable"];
    } else {
        [storyParameters setObject:[NSNumber numberWithBool:NO] forKey:@"joinable"];
    }
    
    if (self.feedbackSwitch.isOn){
        [contributionParameters setObject:[NSNumber numberWithBool:YES] forKey:@"allow_feedback"];
    } else {
        [contributionParameters setObject:[NSNumber numberWithBool:NO] forKey:@"allow_feedback"];
    }
    if (self.privateSwitch.isOn){
        [contributionParameters setObject:[NSNumber numberWithBool:YES] forKey:@"is_private"];
        [storyParameters setObject:[NSNumber numberWithBool:YES] forKey:@"is_private"];
    } else {
        [contributionParameters setObject:[NSNumber numberWithBool:NO] forKey:@"is_private"];
        [storyParameters setObject:[NSNumber numberWithBool:NO] forKey:@"is_private"];
    }
    if (self.slowRevealSwitch.isOn){
        [storyParameters setObject:[NSNumber numberWithBool:YES] forKey:@"mystery"];
    } else {
        [storyParameters setObject:[NSNumber numberWithBool:NO] forKey:@"mystery"];
    }
    if (_collaborators.count){
        [storyParameters setObject:[_collaborators componentsJoinedByString:@","] forKey:@"user_ids"];
    }
    if (_circleCollaborators.count){
        [storyParameters setObject:[_circleCollaborators componentsJoinedByString:@","] forKey:@"circle_ids"];
    }
    
    if (saving && _story.identifier){
        [ProgressHUD show:@"Saving..."];
        [manager PUT:[NSString stringWithFormat:@"%@/stories/%@",kAPIBaseUrl,_story.identifier] parameters:@{@"story":storyParameters,@"contribution":contributionParameters} success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"Success saving your story: %@",responseObject);
            _story = [[XXStory alloc] initWithDictionary:[responseObject objectForKey:@"story"]];
            [self doneOptions];
            
            [XXAlert show:@"Story saved"];
            //[[[UIAlertView alloc] initWithTitle:@"Story saved" message:nil delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
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
        [manager POST:[NSString stringWithFormat:@"%@/stories",kAPIBaseUrl] parameters:@{@"story":storyParameters,@"contribution":contributionParameters} success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"Success creating and then savign your story: %@",responseObject);
            [XXAlert show:@"Story saved"];
            //[[[UIAlertView alloc] initWithTitle:@"Story saved" message:nil delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
            [ProgressHUD dismiss];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Failed to create and then save a story: %@",error.description);
            [ProgressHUD dismiss];
        }];
    } else {
        [ProgressHUD show:@"Publishing..."];
        [manager POST:[NSString stringWithFormat:@"%@/stories",kAPIBaseUrl] parameters:@{@"story":storyParameters,@"contribution":contributionParameters} success:^(AFHTTPRequestOperation *operation, id responseObject) {
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
    [vc setStories:delegate.stories];
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
    [vc setManageContacts:NO];
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

- (void)resetStoryBody {
    for (id obj in self.scrollView.subviews) {
        if ([obj isKindOfClass:[XXTextView class]] || [(UIView*)obj tag] == kSeparatorTag) {
            [obj removeFromSuperview];
        }
    }
}

- (void)drawStory {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
        _titleTextField.keyboardAppearance = UIKeyboardAppearanceDark;
    } else {
        _titleTextField.keyboardAppearance = UIKeyboardAppearanceDefault;
    }
    if (_story.title.length) {
        [_titleTextField setText:_story.title];
    } else {
         [_titleTextField setPlaceholder:kTitlePlaceholder];
    }

    [_titleTextField setDelegate:self];
    [_titleTextField setTextColor:textColor];
    
    offset = _titleTextField.frame.origin.y + _titleTextField.frame.size.height;
    
    [self drawTextView];
    
    [_bodyTextView setupButtons];
    [_bodyTextView setTextColor:textColor];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground] && !_story.title.length){
        _bodyTextView.keyboardAppearance = UIKeyboardAppearanceDark;
    } else {
        _bodyTextView.keyboardAppearance = UIKeyboardAppearanceDefault;
    }
    
    [_bodyTextView.boldButton addTarget:self action:@selector(boldText:) forControlEvents:UIControlEventTouchUpInside];
    [_bodyTextView.italicsButton addTarget:self action:@selector(italicText:) forControlEvents:UIControlEventTouchUpInside];
    [_bodyTextView.underlineButton addTarget:self action:@selector(underlineText:) forControlEvents:UIControlEventTouchUpInside];
    [_bodyTextView.headerButton addTarget:self action:@selector(headline:) forControlEvents:UIControlEventTouchUpInside];
    [_bodyTextView.footnoteButton addTarget:self action:@selector(footnote) forControlEvents:UIControlEventTouchUpInside];
}

- (void)drawTextView {
    widthSpacer = 10;
    if (_story && _story.contributions.count && !_bodyTextView){
        NSString *storyBody = @"";
        for (XXContribution *contribution in _story.contributions) {
            if (contribution.body.length) storyBody = [storyBody stringByAppendingString:contribution.body];
        }
        if (!storyBody.length) storyBody = kStoryPlaceholder;
        
        NSDictionary* attributes = @{NSFontAttributeName:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCrimsonTextFontDescriptorWithTextStyle:UIFontTextStyleBody] size:0],
                                     NSForegroundColorAttributeName : textColor,
                                     NSDocumentTypeDocumentAttribute:NSHTMLTextDocumentType,
                                     };
        NSMutableAttributedString* attrString = [[NSMutableAttributedString alloc] initWithData:[storyBody dataUsingEncoding:NSUnicodeStringEncoding] options:attributes documentAttributes:nil error:nil];
        [attrString beginEditing];
        [attrString addAttributes:attributes range:NSMakeRange(0, attrString.length)];
        [attrString endEditing];
        /*_textStorage = [XXTextStorage new];
        [_textStorage appendAttributedString:attrString];
        NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];
        CGSize containerSize = CGSizeMake(bodyRect.size.width,  CGFLOAT_MAX);
        NSTextContainer *container = [[NSTextContainer alloc] initWithSize:containerSize];
        container.widthTracksTextView = YES;
        [layoutManager addTextContainer:container];
        [_textStorage addLayoutManager:layoutManager];*/
        
        //readjust the body text view so that it doesn't look stupid
        CGRect bodyRect = [attrString boundingRectWithSize:CGSizeMake(screenWidth()-widthSpacer, CGFLOAT_MAX)
                                                   options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading)
                                                   context:nil];
        bodyRect.origin.y = offset;
        bodyRect.origin.x = widthSpacer/2;
        bodyRect.size.width = screenWidth() - widthSpacer;
        sections = [NSMutableArray array];
        int start = 0;
        int distance = 7000;
        BOOL moreText = YES;
        while (moreText){
            if (start + distance < attrString.length){
                NSMutableAttributedString *attrSubstring = [attrString attributedSubstringFromRange:NSMakeRange(start, distance)].mutableCopy;
                [attrSubstring appendString:@"..."];
                start += distance;
                [sections addObject:attrSubstring];
            } else {
                NSAttributedString *attrSubstring = [attrString attributedSubstringFromRange:NSMakeRange(start, attrString.length-start)];
                [sections addObject:attrSubstring];
                moreText = NO;
            }
        }
        
        _bodyTextView = [[XXTextView alloc] initWithFrame:bodyRect /*textContainer:container*/];
        [_bodyTextView setAttributedText:sections.firstObject];
        bodyRect.size.height = [_bodyTextView sizeThatFits:CGSizeMake(width-widthSpacer, CGFLOAT_MAX)].height;
        [_bodyTextView setFrame:bodyRect];
        offset += bodyRect.size.height;
        
        _bodyTextView.keyboardEnabled = YES;
        _bodyTextView.selectable = YES;
        _bodyTextView.userInteractionEnabled = YES;
        _bodyTextView.delegate = self;
        _bodyTextView.clipsToBounds = NO;
        _bodyTextView.scrollEnabled = NO;
        
        if ([_bodyTextView.text isEqualToString:kStoryPlaceholder]){
            if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
                [_bodyTextView setTextColor:textColor];
            } else {
                [_bodyTextView setTextColor:[UIColor lightGrayColor]];
            }
        }
        
        [_scrollView addSubview:_bodyTextView];
        
        if ([_bodyTextView.text isEqualToString:kStoryPlaceholder]) {
            [_bodyTextView becomeFirstResponder];
        }
        
        if (sections.count > 1){
            loadMoreButton = [UIButton buttonWithType:UIButtonTypeCustom];
            [loadMoreButton setTag:1];
            [loadMoreButton setFrame:CGRectMake(0, offset, width, 88)];
            [loadMoreButton setTitle:@"Load more..." forState:UIControlStateNormal];
            [loadMoreButton.titleLabel setFont:[UIFont fontWithName:kSourceSansProRegular size:20]];
            [loadMoreButton addTarget:self action:@selector(reload:) forControlEvents:UIControlEventTouchUpInside];
            [loadMoreButton setTitleColor:textColor forState:UIControlStateNormal];
            [_scrollView addSubview:loadMoreButton];
            offset += 88;
        }
        
        [_scrollView setContentSize:CGSizeMake(_bodyTextView.frame.size.width, offset)];
    } else {
        NSLog(@"already had a bodytextview");
    }
}

- (void)reload:(UIButton*)button {
    NSLog(@"should be reloading story with section at index: %d",button.tag);
    //[self resetStoryBody];
    
    if (button.tag > 0){
        loadPreviousButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [loadPreviousButton setFrame:CGRectMake(0, 0, screenWidth(), 88)];
        [loadPreviousButton setTitle:@"Load previous..." forState:UIControlStateNormal];
        [loadPreviousButton.titleLabel setFont:[UIFont fontWithName:kSourceSansProRegular size:20]];
        [loadPreviousButton setTag:button.tag-1];
        [loadPreviousButton addTarget:self action:@selector(reload:) forControlEvents:UIControlEventTouchUpInside];
        [loadPreviousButton setTitleColor:textColor forState:UIControlStateNormal];
        [_scrollView addSubview:loadPreviousButton];
        [_titleTextField setHidden:YES];
    } else {
        [_titleTextField setHidden:NO];
        [loadPreviousButton removeFromSuperview];
    }

    [_bodyTextView setAttributedText:[sections objectAtIndex:button.tag]];
    //need to reset height because boundingRectWithSize doesn't really work for attributedStrings
    CGRect bodyRect = _bodyTextView.frame;
    bodyRect.size.height = [_bodyTextView sizeThatFits:CGSizeMake(width-widthSpacer, CGFLOAT_MAX)].height;
    [_bodyTextView setFrame:bodyRect];
    [_bodyTextView setBackgroundColor:[UIColor clearColor]];
    _bodyTextView.scrollEnabled = NO;
    _bodyTextView.keyboardEnabled = NO;
    [_bodyTextView setTextColor:textColor];
    
    //[_scrollView addSubview:_bodyTextView];
    
    if (sections.count){
        //[loadMoreButton setFrame:CGRectMake(0, 0, screenWidth(), 88)];
        [loadMoreButton setTag:button.tag+1];
        [loadMoreButton setTitleColor:textColor forState:UIControlStateNormal];
        //[_scrollView addSubview:loadMoreButton];
    }
    [_scrollView setContentOffset:CGPointZero animated:YES];
    [_scrollView setContentSize:CGSizeMake(screenWidth()-widthSpacer, _bodyTextView.frame.size.height)];
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

- (void)willShowKeyboard:(NSNotification*)notification {
    keyboardIsVisible = YES;
    keyboardRect = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    keyboardRect = [self.view convertRect:keyboardRect fromView:nil];
    
    /*UIEdgeInsets inset = _bodyTextView.contentInset;
    inset.bottom = keyboardRect.size.height;
    _bodyTextView.contentInset = inset;
    _bodyTextView.scrollIndicatorInsets = inset;*/
    //[self scrollToCaret:YES];
}

- (void)willHideKeyboard:(NSNotification*)notification {
    keyboardIsVisible = NO;
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
        _story.title = textField.text;
    } else if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]) {
        [textField setTextColor:[UIColor whiteColor]];
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

- (void)textViewDidChange:(UITextView *)textView {
    //54 is the extra height for the keyboard toolbar
    CGRect bodyRect = textView.frame;
    bodyRect.size.height = [textView sizeThatFits:CGSizeMake(textView.frame.size.width, CGFLOAT_MAX)].height;
    [textView setFrame:bodyRect];
    [self.scrollView setContentSize:CGSizeMake(screenWidth(),bodyRect.size.height + _titleTextField.frame.size.height+keyboardRect.size.height+54)];
    /*if ([textView.text hasSuffix:@"\n"]) {
        [CATransaction setCompletionBlock:^{
            [self scrollToCaret:NO];
        }];
    } else {
        [self scrollToCaret:NO];
    }*/
}

- (void)scrollToCaret:(BOOL)animated
{
    CGRect rect = [_bodyTextView caretRectForPosition:_bodyTextView.selectedTextRange.end];
    rect.size.height += _bodyTextView.textContainerInset.bottom;
    [_bodyTextView scrollRectToVisible:rect animated:animated];
}

- (void)boldText:(UIButton*)button {
    [_bodyTextView toggleBoldface:nil];
    boldSelected = !boldSelected;
    if (boldSelected) {
        [_bodyTextView.boldButton setBackgroundColor:[UIColor whiteColor]];
    } else {
        [_bodyTextView.boldButton setBackgroundColor:[UIColor clearColor]];
    }
    
    if (italicsSelected) {
        NSMutableAttributedString *attrString = [_bodyTextView.textStorage attributedSubstringFromRange:[self selectedRangeForText:_selectedRange]].mutableCopy;
        [attrString addAttribute:NSFontAttributeName value:[UIFont fontWithDescriptor:[[UIFontDescriptor preferredSourceSansProFontDescriptorWithTextStyle:UIFontTextStyleBody] fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitItalic] size:0] range:NSMakeRange((0), attrString.length)];
    }
}

- (void)italicText:(UIButton*)button {
    [_bodyTextView toggleItalics:nil];
    italicsSelected = !italicsSelected;
    if (italicsSelected) {
        [_bodyTextView.italicsButton setBackgroundColor:[UIColor whiteColor]];
    } else {
        [_bodyTextView.italicsButton setBackgroundColor:[UIColor clearColor]];
    }
    
    if (boldSelected){
        NSMutableAttributedString *attrString = [_bodyTextView.textStorage attributedSubstringFromRange:[self selectedRangeForText:_selectedRange]].mutableCopy;
        [attrString addAttribute:NSFontAttributeName value:[UIFont fontWithDescriptor:[[UIFontDescriptor preferredSourceSansProFontDescriptorWithTextStyle:UIFontTextStyleBody] fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold] size:0] range:NSMakeRange((0), attrString.length)];
    }
}

- (void)underlineText:(UIButton*)button {
    [_bodyTextView toggleUnderline:nil];
    underlineSelected = !underlineSelected;
    if (underlineSelected) {
        [_bodyTextView.underlineButton setBackgroundColor:[UIColor whiteColor]];
    } else {
        [_bodyTextView.underlineButton setBackgroundColor:[UIColor clearColor]];
    }

}

- (void)headline:(UIButton*)button {
    if (_selectedText.length){
        NSRange selectionRange = [self selectedRangeForText:_selectedRange];
        NSMutableAttributedString *attrString = [_bodyTextView.textStorage attributedSubstringFromRange:[self selectedRangeForText:_selectedRange]].mutableCopy;
        UIFontDescriptor *currentFontDescriptor = [[_bodyTextView.textStorage attributesAtIndex:selectionRange.location effectiveRange:NULL][NSFontAttributeName] fontDescriptor];
        CGFloat fontSize = [currentFontDescriptor.fontAttributes[UIFontDescriptorSizeAttribute] floatValue];
        
        [attrString beginEditing];
        if (fontSize < 25.f){
            [attrString addAttribute:NSFontAttributeName value:[UIFont fontWithDescriptor:[[UIFontDescriptor preferredSourceSansProFontDescriptorWithTextStyle:UIFontTextStyleSubheadline] fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold] size:0] range:NSMakeRange((0), attrString.length)];
            [_bodyTextView.textStorage replaceCharactersInRange:selectionRange withAttributedString:attrString];
        } else if (fontSize > 25.f && fontSize < 30.f){
            [attrString addAttribute:NSFontAttributeName value:[UIFont fontWithDescriptor:[[UIFontDescriptor preferredSourceSansProFontDescriptorWithTextStyle:UIFontTextStyleHeadline] fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold] size:0] range:NSMakeRange((0), attrString.length)];
            [_bodyTextView.textStorage replaceCharactersInRange:selectionRange withAttributedString:attrString];
        } else {
            [attrString addAttribute:NSFontAttributeName value:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCrimsonTextFontDescriptorWithTextStyle:UIFontTextStyleBody] size:0] range:NSMakeRange((0), attrString.length)];
            [_bodyTextView.textStorage replaceCharactersInRange:selectionRange withAttributedString:attrString];
        }
        
        [attrString endEditing];
    }
}

- (void)footnote {
    if (_selectedText.length){
        NSRange selectionRange = [self selectedRangeForText:_selectedRange];
        NSMutableAttributedString *attrString = [_bodyTextView.textStorage attributedSubstringFromRange:[self selectedRangeForText:_selectedRange]].mutableCopy;
        
        [attrString beginEditing];
        [attrString addAttribute:NSFontAttributeName value:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCrimsonTextFontDescriptorWithTextStyle:UIFontTextStyleFootnote] size:0] range:NSMakeRange((0), attrString.length)];
        [_bodyTextView.textStorage replaceCharactersInRange:selectionRange withAttributedString:attrString];
        
        [attrString endEditing];
    }
}

- (NSRange) selectedRangeForText:(UITextRange*)selectedRange
{
    UITextPosition* beginning = _bodyTextView.beginningOfDocument;
    UITextPosition* selectionStart = selectedRange.start;
    UITextPosition* selectionEnd = selectedRange.end;
    const NSInteger location = [_bodyTextView offsetFromPosition:beginning toPosition:selectionStart];
    const NSInteger length = [_bodyTextView offsetFromPosition:selectionStart toPosition:selectionEnd];
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
    } else {
        [self determineButtonState];
    }
}

- (void)determineButtonState {
    NSRange selectionRange = [self selectedRangeForText:_selectedRange];
    NSMutableAttributedString *attrString = [_bodyTextView.textStorage attributedSubstringFromRange:[self selectedRangeForText:_selectedRange]].mutableCopy;
    UIFontDescriptor *currentFontDescriptor = [[_bodyTextView.textStorage attributesAtIndex:selectionRange.location effectiveRange:NULL][NSFontAttributeName] fontDescriptor];
   
    if ([self isBold:currentFontDescriptor]){
        NSLog(@"it's bold");
        [_bodyTextView.boldButton setBackgroundColor:[UIColor whiteColor]];
        boldSelected = YES;
    } else {
        [_bodyTextView.boldButton setBackgroundColor:[UIColor clearColor]];
        boldSelected = NO;
    }
    if ([self isItalic:currentFontDescriptor]) {
        NSLog(@"it's italic");
        [_bodyTextView.italicsButton setBackgroundColor:[UIColor whiteColor]];
        italicsSelected = YES;
    } else {
        [_bodyTextView.italicsButton setBackgroundColor:[UIColor clearColor]];
        italicsSelected = NO;
    }

    NSRange effectiveRange = NSMakeRange(0, 0);
    id underlineAttribute = [attrString attribute:NSUnderlineStyleAttributeName atIndex:NSMaxRange(effectiveRange) effectiveRange:&effectiveRange];
    if (underlineAttribute != 0 && underlineAttribute != nil) {
        NSLog(@"it's underline");
        [_bodyTextView.underlineButton setBackgroundColor:[UIColor whiteColor]];
        underlineSelected = YES;
    } else {
        [_bodyTextView.underlineButton setBackgroundColor:[UIColor clearColor]];
        underlineSelected = NO;
    }
    
}

- (BOOL)isBold:(UIFontDescriptor*)fontDescriptor
{
    return (fontDescriptor.symbolicTraits & UIFontDescriptorTraitBold) != 0;
}
- (BOOL)isItalic:(UIFontDescriptor*)fontDescriptor
{
    return (fontDescriptor.symbolicTraits & UIFontDescriptorTraitItalic) != 0;
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

#pragma mark - Setup the Controls

- (void)setupView {
    [_doneOptionsButton.titleLabel setFont:[UIFont fontWithName:kSourceSansProLight size:18]];
    _doneOptionsButton.layer.borderColor = [UIColor darkGrayColor].CGColor;
    _doneOptionsButton.layer.borderWidth = .5f;
    _doneOptionsButton.layer.cornerRadius = 14.f;
    [_doneOptionsButton.layer setBackgroundColor:[UIColor clearColor].CGColor];
    [_doneOptionsButton setBackgroundColor:[UIColor clearColor]];
    _doneOptionsButton.layer.rasterizationScale = [UIScreen mainScreen].scale;
    _doneOptionsButton.layer.shouldRasterize = YES;
    
    [_deleteButton.titleLabel setFont:[UIFont fontWithName:kSourceSansProLight size:18]];
    [_deleteButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    _deleteButton.layer.borderColor = [UIColor redColor].CGColor;
    _deleteButton.layer.borderWidth = .5f;
    _deleteButton.layer.cornerRadius = 14.f;
    [_deleteButton.layer setBackgroundColor:[UIColor clearColor].CGColor];
    [_deleteButton setBackgroundColor:[UIColor clearColor]];
    _deleteButton.layer.rasterizationScale = [UIScreen mainScreen].scale;
    _deleteButton.layer.shouldRasterize = YES;
    
    [_collaborateButton.titleLabel setFont:[UIFont fontWithName:kSourceSansProLight size:18]];
    _collaborateButton.layer.borderColor = [UIColor darkGrayColor].CGColor;
    _collaborateButton.layer.borderWidth = 0.5f;
    _collaborateButton.layer.cornerRadius = 14.f;
    [_collaborateButton.layer setBackgroundColor:[UIColor clearColor].CGColor];
    [_collaborateButton setBackgroundColor:[UIColor clearColor]];
    _collaborateButton.layer.rasterizationScale = [UIScreen mainScreen].scale;
    _collaborateButton.layer.shouldRasterize = YES;
    
    [_draftLabel setFont:[UIFont fontWithName:kSourceSansProLight size:18]];
    [_privateLabel setFont:[UIFont fontWithName:kSourceSansProLight size:18]];
    [_feedbackLabel setFont:[UIFont fontWithName:kSourceSansProLight size:18]];
    [_joinableLabel setFont:[UIFont fontWithName:kSourceSansProLight size:18]];
    [_slowRevealLabel setFont:[UIFont fontWithName:kSourceSansProLight size:18]];
    
    optionsTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showOptions)];
    optionsTap.numberOfTapsRequired = 1;
    optionsTap.delegate = self;
    [self.optionsContainerView addGestureRecognizer:optionsTap];
}

- (void)pop{
    [self.navigationController popViewControllerAnimated:YES];
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

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self doneOptions];
}

@end

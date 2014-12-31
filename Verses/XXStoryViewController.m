//
//  XXStoryViewController.m
//  Verses
//
//  Created by Max Haines-Stiles on 11/4/13.
//  Copyright (c) 2013 Verses. All rights reserved.
//

#import "XXAppDelegate.h"
#import "XXStoryViewController.h"
#import "XXStoryInfoViewController.h"
#import "XXStoryCell.h"
#import "XXStoryBodyCell.h"
#import "Photo.h"
#import "UIImage+ImageEffects.h"
#import <SDWebImage/UIButton+WebCache.h>
#import "XXBookmarksViewController.h"
#import "XXStoriesViewController.h"
#import "XXWriteViewController.h"
#import "Feedback+helper.h"
#import "UIFontDescriptor+Custom.h"
#import "UIFontDescriptor+Custom.h"
#import "XXTextView.h"
#import "XXAddFeedbackViewController.h"
#import "XXFeedbackTransition.h"
#import <DTCoreText/DTCoreText.h>
#import "XXProfileViewController.h"
#import "XXFlagContentViewController.h"
#import "XXNoRotateNavController.h"
#import "XXLoginViewController.h"
#import <Mixpanel/Mixpanel.h>
#import "XXAlert.h"

@interface XXStoryViewController () <UIViewControllerTransitioningDelegate, UIAlertViewDelegate> {
    AFHTTPRequestOperationManager *manager;
    MSDynamicsDrawerViewController *dynamicsViewController;
    XXAppDelegate *delegate;
    CGFloat width;
    CGFloat height;
    UIButton *dismissButton;
    UITapGestureRecognizer *tapGesture;
    UIImage *backgroundImage;
    NSTimer *readingTimer;
    XXStoryInfoViewController *storyInfoVc;
    XXStoriesViewController *welcomeVc;
    XXBookmarksViewController *bookmarkVc;
    UIInterfaceOrientation orientation;
    CGFloat rowHeight;
    UIBarButtonItem *backButton;
    UIBarButtonItem *themeButton;
    UIBarButtonItem *editButton;
    NSDateFormatter *_formatter;
    UIImageView *navBarShadowView;
    UIColor *textColor;
    BOOL canLoadMore;
    BOOL loading;
    BOOL signedIn;
    CGFloat textSize;
    CGRect titleFrame;
    CGRect authorsFrame;
    CGFloat imageHeight;
    CGFloat spacer;
    CGFloat contributionOffset;
    
    UIButton *shouldShareButton;
    UIButton *flagButton;
    UIButton *addSlowRevealButton;
    XXTextView *newContributionTextView;
    NSString *_selectedText;
    UITextRange *_selectedRange;
    User *_currentUser;
    CGFloat keyboardHeight;
    UIButton *publishButton;
    UIButton *cancelButton;
    
    BOOL multiPage;
    int pages;
    NSLayoutManager *layoutManager;
    XXTextStorage *_textStorage;
    NSMutableArray *_attributedPages;
    NSMutableSet *visiblePages;
    NSInteger page;
    CGFloat header1spacing,header2spacing;
}

@end

@implementation XXStoryViewController

@synthesize story = _story;
@synthesize storyId = _storyId;

- (void)viewDidLoad
{
    self.automaticallyAdjustsScrollViewInsets = NO;
    orientation = self.interfaceOrientation;
    
    if (UIInterfaceOrientationIsPortrait(orientation) || [[[UIDevice currentDevice] systemVersion] floatValue] >= 8.f){
        width = screenWidth();
        height = screenHeight();
    } else {
        width = screenHeight();
        height = screenWidth();
    }
    if (IDIOM == IPAD){
        rowHeight = height/3;
    } else {
        rowHeight = height/2;
    }
    
    delegate = (XXAppDelegate*)[UIApplication sharedApplication].delegate;
    [delegate.dynamicsDrawerViewController setPaneDragRevealEnabled:YES forDirection:MSDynamicsDrawerDirectionRight];
    manager = delegate.manager;
    dynamicsViewController = delegate.dynamicsDrawerViewController;
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
        signedIn = YES;
        if (delegate.currentUser){
            _currentUser = delegate.currentUser;
        } else {
            _currentUser = [User MR_findFirstByAttribute:@"identifier" withValue:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] inContext:[NSManagedObjectContext MR_defaultContext]];
        }
    } else {
        signedIn = NO;
    }
    tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleNavBar:)];
    [self.view addGestureRecognizer:tapGesture];
    canLoadMore = YES;
    
    if (self.navigationController.viewControllers.firstObject == self){
        backButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"back"] style:UIBarButtonItemStylePlain target:self action:@selector(back)];
        self.navigationItem.leftBarButtonItem = backButton;
    } else if (self.navigationController.viewControllers.count > 1) {
        NSUInteger count = self.navigationController.viewControllers.count;
        backButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"back"] style:UIBarButtonItemStylePlain target:self action:@selector(pop)];
        self.navigationItem.leftBarButtonItem = backButton;
        if ([[self.navigationController.viewControllers objectAtIndex:count-2] isKindOfClass:[XXStoriesViewController class]]) {
            welcomeVc = [self.navigationController.viewControllers objectAtIndex:count-2];
        } else if ([self.navigationController.viewControllers.firstObject isKindOfClass:[XXBookmarksViewController class]]){
            bookmarkVc = self.navigationController.viewControllers.firstObject;
        }
    }
    readingTimer = [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(hideControls) userInfo:nil repeats:NO];
    
    _attributedPages = [NSMutableArray array];
    storyInfoVc = (XXStoryInfoViewController*)[delegate.dynamicsDrawerViewController drawerViewControllerForDirection:MSDynamicsDrawerDirectionRight];

    _formatter= [[NSDateFormatter alloc] init];
    [_formatter setLocale:[NSLocale currentLocale]];
    [_formatter setDateFormat:@"MMM, d - h:mm a"];
    navBarShadowView = [Utilities findNavShadow:self.navigationController.navigationBar];
    
    [self showControls];
    
    [self registerForKeyboardNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(addFeedback:)
                                                 name:@"AddFeedback" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(flagContent)
                                                 name:@"CreateFlag" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resetStory:) name:@"ResetStory" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(storyFlagged) name:@"StoryFlagged" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeStory:) name:@"RemoveStory" object:nil];
    [super viewDidLoad];
    
    if (_storyId){
        NSLog(@"story id: %@",_storyId);
        [self loadStory:_storyId];
        [ProgressHUD show:@"Loading story..."];
    } else if (_story.contributions.count){
        pages = 0;
        contributionOffset = 0;
        [self resetStoryBody];
        [self drawStoryBody];
        [storyInfoVc setStory:_story];
        [self loadFeedbacks];
    } else if (_story) {
        [self loadStory:_story.identifier];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    navBarShadowView.hidden = YES;
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
        [self.view setBackgroundColor:[UIColor clearColor]];
        textColor = [UIColor whiteColor];
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
        [_scrollView setIndicatorStyle:UIScrollViewIndicatorStyleWhite];
    } else {
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
        [self.view setBackgroundColor:[UIColor whiteColor]];
        textColor = [UIColor blackColor];
        [_scrollView setIndicatorStyle:UIScrollViewIndicatorStyleBlack];
    }
    if (_scrollView.alpha == 0.0){
        [UIView animateWithDuration:.23 animations:^{
            [_scrollView setAlpha:1.0];
            _scrollView.transform = CGAffineTransformIdentity;
        }];
    }
}

- (void)loadStory:(NSNumber*)identifier {
    [self resetStoryBody];
    NSDictionary *parameters;
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
        parameters = @{@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]};
    }
    
    [manager GET:[NSString stringWithFormat:@"%@/stories/%@",kAPIBaseUrl,identifier] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"load story response: %@",responseObject);
        _story = [Story MR_findFirstByAttribute:@"identifier" withValue:identifier inContext:[NSManagedObjectContext MR_defaultContext]];
        if (!_story) {
            _story = [Story MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
        }
        [_story populateFromDict:[responseObject objectForKey:@"story"]];
        [self drawStoryBody];
        [self loadFeedbacks];
        storyInfoVc.story = _story;
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error loading story: %@",error.description);
    }];
}

- (void)removeStory:(NSNotification*)notificaiton {
    //the story is gone, so pop the vc. it was too hard to figure out the proper view hierarchy
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)confirmLoginPrompt {
    [[[UIAlertView alloc] initWithTitle:@"Easy does it!" message:@"You'll need to log in if you want to leave feedback." delegate:self cancelButtonTitle:@"No Thanks" otherButtonTitles:@"Login", nil] show];
}
- (void)confirmLoginPromptBookmark {
    [[[UIAlertView alloc] initWithTitle:@"Slow those horses!" message:@"You'll need to log in if you want to create bookmarks." delegate:self cancelButtonTitle:@"No Thanks" otherButtonTitles:@"Login", nil] show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Login"]){
        XXLoginViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Login"];
        XXNoRotateNavController *nav = [[XXNoRotateNavController alloc] initWithRootViewController:vc];
        [self presentViewController:nav animated:YES completion:nil];
    }
}

- (void)edit {
    XXWriteViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Write"];
    [vc setStory:_story];
    [vc setEditMode:YES];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
        [UIView animateWithDuration:.23 animations:^{
            [_scrollView setAlpha:0.0];
            _scrollView.transform = CGAffineTransformMakeScale(.8, .8);
        }];
    }
    
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)createBookmark {
    if (signedIn && ![_story.identifier isEqualToNumber:[NSNumber numberWithInt:0]]){
        Bookmark *bookmark = [Bookmark MR_findFirstByAttribute:@"story.identifier" withValue:_story.identifier inContext:[NSManagedObjectContext MR_defaultContext]];
        if (!bookmark) {
            bookmark = [Bookmark MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
        }
        bookmark.user = _currentUser;
        bookmark.story = _story;
        bookmark.createdDate = [NSDate date];
        [_story setBookmarked:@YES];
        [self setupNavButtons];
        
        [manager POST:[NSString stringWithFormat:@"%@/bookmarks",kAPIBaseUrl] parameters:@{@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId],@"story_id":_story.identifier} success:^(AFHTTPRequestOperation *operation, id responseObject) {
            //NSLog(@"Success creating a bookmark: %@",responseObject);
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Error creating a bookmark: %@",error.description);
        }];
    }
}

- (void)destroyBookmark {
    if (![_story.identifier isEqualToNumber:[NSNumber numberWithInt:0]]){
        [_story setBookmarked:@NO];
        [self setupNavButtons];
        __block NSNumber *bookmarkId;
        [_currentUser.bookmarks enumerateObjectsUsingBlock:^(Bookmark *bookmark, NSUInteger idx, BOOL *stop) {
            if ([bookmark.story.identifier isEqualToNumber:_story.identifier] || [bookmark.contribution.story.identifier isEqualToNumber:_story.identifier]){
                bookmarkId = bookmark.identifier;
                [manager DELETE:[NSString stringWithFormat:@"%@/bookmarks/%@",kAPIBaseUrl,bookmarkId] parameters:@{@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
                    //NSLog(@"success deleting a bookmark: %@",responseObject);
                } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                    NSLog(@"Failed to delete the bookmark: %@",error.description);
                }];
                [bookmark MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
                *stop = YES;
            }
        }];
    }
}

- (void)pop {
    [self.navigationController popViewControllerAnimated:YES];
}
- (void)back {
    [[(XXAppDelegate*)[UIApplication sharedApplication].delegate dynamicsDrawerViewController] setPaneState:MSDynamicsDrawerPaneStateOpen inDirection:MSDynamicsDrawerDirectionLeft animated:YES allowUserInterruption:YES completion:^{
        
    }];
}
- (void)toggleNavBar:(UITapGestureRecognizer *)gesture {
    [readingTimer invalidate];
    readingTimer = nil;
    if (self.navigationController.navigationBarHidden) {
        [self showControls];
    } else {
        [self hideControls];
    }
}

- (void)loadFeedbacks {
    if (signedIn){
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"user_id"];
        [manager GET:[NSString stringWithFormat:@"%@/feedbacks/%@",kAPIBaseUrl,_story.identifier] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
            //NSLog(@"success getting feedbacks for story %@, %@",_story.title,responseObject);
            [self updateStoryFeedback:[responseObject objectForKey:@"feedbacks"]];
            if ([responseObject objectForKey:@"bookmarked"]){
                [_story setBookmarked:@YES];
                [self setupNavButtons];
            } else {
                [_currentUser.bookmarks.array enumerateObjectsUsingBlock:^(Bookmark *bookmark, NSUInteger idx, BOOL *stop) {
                    
                    if (bookmark.story && [_story.identifier isEqualToNumber:bookmark.story.identifier]){
                        [_story setBookmarked:@YES];
                        [self setupNavButtons];
                        *stop = YES;
                    }
                }];
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Failed to get feedbacks for %@, %@",_story.title,error.description);
        }];
    }
}

- (void)updateStoryFeedback:(NSArray*)array{
    NSMutableOrderedSet *feedbacks = [NSMutableOrderedSet orderedSet];
    for (NSDictionary *dict in array){
        Feedback *feedback = [Feedback MR_findFirstByAttribute:@"identifier" withValue:[dict objectForKey:@"id"] inContext:[NSManagedObjectContext MR_defaultContext]];
        if (feedback){
            [feedback update:dict];
        } else {
            feedback = [Feedback MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            [feedback populateFromDict:dict];
        }
        
        [feedbacks addObject:feedback];
    }
    for (Feedback *feedback in _story.feedbacks){
        if (![feedbacks containsObject:feedback]){
            NSLog(@"Deleting feedback that no longer exists.");
            [feedback MR_inContext:[NSManagedObjectContext MR_defaultContext]];
        }
    }
    _story.feedbacks = feedbacks;
    storyInfoVc.story = _story;
}

- (void)setupNavButtons {
    if (signedIn && [_story.owner.identifier isEqualToNumber:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]] && _story.contributions.count <= 1){
        editButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"whitePencil"] style:UIBarButtonItemStylePlain target:self action:@selector(edit)];
    } else if (signedIn && [_story.bookmarked isEqualToNumber:@YES]){
        editButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"bookmarked"] style:UIBarButtonItemStylePlain target:self action:@selector(destroyBookmark)];
    } else if (signedIn){
        editButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"bookmark"] style:UIBarButtonItemStylePlain target:self action:@selector(createBookmark)];
    } else {
        editButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"bookmark"] style:UIBarButtonItemStylePlain target:self action:@selector(confirmLoginPromptBookmark)];
    }
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
        themeButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"moon"] style:UIBarButtonItemStylePlain target:self action:@selector(themeSwitch)];
        self.navigationItem.rightBarButtonItems = @[editButton,themeButton];
        [self.view setBackgroundColor:[UIColor clearColor]];
        textColor = [UIColor whiteColor];
    } else {
        themeButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"sun"] style:UIBarButtonItemStylePlain target:self action:@selector(themeSwitch)];
        
        self.navigationItem.rightBarButtonItems = @[editButton,themeButton];
        [self.view setBackgroundColor:[UIColor whiteColor]];
        textColor = [UIColor blackColor];
    }
    themeButton.imageInsets = UIEdgeInsetsMake(0, 0, 0, -10);
}

- (void)themeSwitch {
    NSShadow *clearShadow = [[NSShadow alloc] init];
    clearShadow.shadowColor = [UIColor clearColor];

    if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kDarkBackground];
        [_scrollView setIndicatorStyle:UIScrollViewIndicatorStyleBlack];
        textColor = [UIColor blackColor];
        [backButton setTintColor:textColor];
        [themeButton setTintColor:textColor];
        [_titleLabel setTextColor:textColor];
        [_authorsLabel setTextColor:textColor];
        [UIView animateWithDuration:.23 animations:^{
            [self.view setBackgroundColor:[UIColor whiteColor]];
            for (id obj in _scrollView.subviews){
                if ([obj isKindOfClass:[XXTextView class]] || [obj isKindOfClass:[UILabel class]]){
                    [obj setTextColor:textColor];
                } else if ([obj isKindOfClass:[UIButton class]]){
                    [(UIButton*)obj setTitleColor:textColor forState:UIControlStateNormal];
                }
            }
        }];
        
        [self.navigationController.navigationBar setBarStyle:UIBarStyleDefault];
        [self.navigationController.navigationBar setTitleTextAttributes:@{
                                                                          NSForegroundColorAttributeName: [UIColor blackColor],
                                                                          NSFontAttributeName: [UIFont fontWithName:kSourceSansProSemibold size:23],
                                                                          NSShadowAttributeName: clearShadow,
                                                                          }];
        
    } else {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kDarkBackground];
        [_scrollView setIndicatorStyle:UIScrollViewIndicatorStyleWhite];
        [backButton setTintColor:[UIColor whiteColor]];
        [themeButton setTintColor:[UIColor whiteColor]];
        textColor = [UIColor whiteColor];
        [_titleLabel setTextColor:textColor];
        [_authorsLabel setTextColor:textColor];
        
        [UIView animateWithDuration:.23 animations:^{
            [self.view setBackgroundColor:[UIColor clearColor]];
            for (id obj in _scrollView.subviews){
                if ([obj isKindOfClass:[XXTextView class]]){
                    [obj setTextColor:textColor];
                } else if ([obj isKindOfClass:[UIButton class]]){
                    [(UIButton*)obj setTitleColor:textColor forState:UIControlStateNormal];
                }
            }
        }];
        
        [self.navigationController.navigationBar setBarStyle:UIBarStyleBlackTranslucent];
        [self.navigationController.navigationBar setTitleTextAttributes:@{
                                                                          NSForegroundColorAttributeName: [UIColor whiteColor],
                                                                          NSFontAttributeName: [UIFont fontWithName:kSourceSansProSemibold size:23],
                                                                          NSShadowAttributeName: clearShadow,
                                                                          }];
    }
    [(XXAppDelegate*)[UIApplication sharedApplication].delegate switchBackgroundTheme];
    [self setupNavButtons];
    if (welcomeVc) {
        welcomeVc.reloadTheme = YES;
    } else if (bookmarkVc) {
        bookmarkVc.reloadTheme = YES;
    }
}

- (void)showControls {
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    for (UIView *view in _scrollView.subviews){
        if (view.tag == kContributorViewTag){
            [view setHidden:NO];
            [UIView animateWithDuration:.23 animations:^{
                [view setAlpha:1.0];
            } completion:^(BOOL finished) {
                
            }];
        }
    }
}

- (void)hideControls {
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    for (UIView *view in _scrollView.subviews){
        if (view.tag == kContributorViewTag){
            [UIView animateWithDuration:.23 animations:^{
                [view setAlpha:0.0];
            } completion:^(BOOL finished) {
                [view setHidden:YES];
            }];
        }
    }
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    orientation = toInterfaceOrientation;
    if (toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft || toInterfaceOrientation == UIInterfaceOrientationLandscapeRight){
        //NSLog(@"rotating landscape");
        width = screenHeight();
        height = screenWidth();
        [self resetStoryBody];
        [self drawStoryBody];
    } else {
        //NSLog(@"rotating portrait");
        width = screenWidth();
        height = screenHeight();
        [self resetStoryBody];
        [self drawStoryBody];
    }
}

- (void)resetStory:(NSNotification*)notification{
    [self resetStoryBody];
    _story = [notification.userInfo objectForKey:@"story"];
    [self loadStory:_story.identifier];
}

- (void)resetStoryBody {
    contributionOffset = 0;
    titleFrame = CGRectZero;
    authorsFrame = CGRectZero;
    _storyPhoto = nil;
    for (id obj in _scrollView.subviews) {
        if ([obj isKindOfClass:[XXTextView class]] || [(UIView*)obj tag] == kSeparatorTag || [obj isKindOfClass:[UIButton class]] || [obj isKindOfClass:[XXStoryPhoto class]]) {
            [obj removeFromSuperview];
        }
    }
}

- (void)drawTitle {
    if (_titleLabel == nil) {
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    }
    
    NSMutableParagraphStyle *titleCenterStyle = [[NSMutableParagraphStyle alloc] init];
    titleCenterStyle.alignment = NSTextAlignmentCenter;
    titleCenterStyle.lineSpacing = 0.f;
    titleCenterStyle.lineHeightMultiple = 0.815f;
    
    NSString *titleText;
    if (_story.title.length){
        titleText = _story.title;
    } else {
        titleText = @"Untitled";
    }
    
    NSAttributedString *attributedTitle = [[NSAttributedString alloc] initWithString:titleText
                                                                          attributes:@{
                                                                                       NSFontAttributeName:self.titleLabel.font,
                                                                                       NSParagraphStyleAttributeName:titleCenterStyle
                                                                                       }];
    [_titleLabel setAttributedText:attributedTitle];
    [self resizeFontForLabel:_titleLabel maxSize:textSize minSize:14 labelWidth:width-spacer labelHeight:height*.223f];
    
    titleFrame.origin.x += spacer/2;
    if (_story.photos.count){
        titleFrame.origin.y += imageHeight + 11;
    } else {
        titleFrame.origin.y = height/2 - titleFrame.size.height;
    }
    titleFrame.size.width = width-spacer;
    [_titleLabel setFrame:titleFrame];
    
}

- (void)resizeFontForLabel:(UILabel*)aLabel maxSize:(int)maxSize minSize:(int)minSize labelWidth:(float)labelWidth labelHeight:(float)labelHeight {
    UIFont *font = aLabel.font;
    
    // start with maxSize and keep reducing until it doesn't clip
    for(int i = maxSize; i >= minSize; i--) {
        font = [font fontWithSize:i];
        titleFrame = [aLabel.text boundingRectWithSize:CGSizeMake(labelWidth, CGFLOAT_MAX)
                                                     options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading)
                                            attributes:@{NSFontAttributeName: font}
                                                     context:nil];

        if (titleFrame.size.height <= labelHeight){
            break;
        }
    }
    NSMutableAttributedString *newTitle = [[NSMutableAttributedString alloc] initWithAttributedString:_titleLabel.attributedText];
    [newTitle addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, newTitle.length)];
    _titleLabel.attributedText = newTitle;
}

- (void)drawAuthors {
    if (_authorsLabel == nil) {
        _authorsLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    }
    NSString *authorsText = [NSString stringWithFormat:@"by %@",_story.authorNames];
    [_authorsLabel setText:authorsText];
    
    NSMutableParagraphStyle *centerStyle = [[NSMutableParagraphStyle alloc] init];
    centerStyle.alignment = NSTextAlignmentCenter;
    NSAttributedString *attributedAuthors = [[NSAttributedString alloc] initWithString:authorsText
                                                                            attributes:@{
                                                                                         NSFontAttributeName: self.authorsLabel.font,
                                                                                         NSParagraphStyleAttributeName:centerStyle
                                                                                         }];
    authorsFrame = [attributedAuthors boundingRectWithSize:CGSizeMake(width-spacer, CGFLOAT_MAX)
                                                          options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading)
                                                          context:nil];
    
    authorsFrame.origin.x += spacer/2;
    authorsFrame.size.width = width-spacer;
    authorsFrame.size.height += 4;
    authorsFrame.origin.y += titleFrame.origin.y + titleFrame.size.height - 7;
    [_authorsLabel setFrame:authorsFrame];
}

- (void)generateAttributedString:(Contribution*)contribution {
    
    header1spacing = 14;
    header2spacing = 0;
  
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineHeightMultiple = 1.1f;
    paragraphStyle.lineSpacing = 3.f;
    paragraphStyle.paragraphSpacing = 21.f;
    
    NSDictionary* attributes = @{/*NSFontAttributeName:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForStyle:UIFontTextStyleBody forFont:kSourceSansPro] size:0],*/
                                 NSParagraphStyleAttributeName : paragraphStyle,
                                 NSDocumentTypeDocumentAttribute:NSHTMLTextDocumentType,
                                 };

    //This is the non-dt core text version
    /*NSError *error;
     NSDictionary *documentAttributes;
     NSMutableAttributedString *attributedContributionBody = [[NSMutableAttributedString alloc] initWithData:[contribution.body dataUsingEncoding:NSUnicodeStringEncoding] options:attributes documentAttributes:&documentAttributes error:&error];
    NSMutableAttributedString* attributedContributionBody = [[NSMutableAttributedString alloc] initWithHTMLData:[contribution.body dataUsingEncoding:NSUTF8StringEncoding] options:@{NSTextEncodingNameDocumentOption: @"UTF-8"} documentAttributes:nil];*/
    
    DTCSSStylesheet *styleSheet = [[DTCSSStylesheet alloc] initWithStyleBlock:@".screen {font-family:'Courier';}"];
    
    NSDictionary *options = @{DTUseiOS6Attributes: @YES,
                              DTDefaultFontSize: @21,
                              DTDefaultFontFamily: @"Crimson Text",
                              DTDefaultStyleSheet: styleSheet,
                              NSTextEncodingNameDocumentOption: @"UTF-8"};
    DTHTMLAttributedStringBuilder *stringBuilder = [[DTHTMLAttributedStringBuilder alloc] initWithHTML:[contribution.body dataUsingEncoding:NSUTF8StringEncoding] options:options documentAttributes:nil];
    NSMutableAttributedString *attributedContributionBody = [stringBuilder generatedAttributedString].mutableCopy;
    
    [attributedContributionBody beginEditing];
    [attributedContributionBody addAttributes:attributes range:NSMakeRange(0, attributedContributionBody.length)];
    [attributedContributionBody enumerateAttributesInRange:NSMakeRange(0, attributedContributionBody.length) options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired usingBlock:^(NSDictionary *attrs, NSRange range, BOOL *stop) {
        
        if ([[attrs objectForKey:@"DTHeaderLevel"]  isEqual: @1]){
            [attributedContributionBody addAttribute:NSFontAttributeName value:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleHeadline forFont:kSourceSansPro] size:0] range:range];
            NSMutableParagraphStyle *centerStyle = [[NSMutableParagraphStyle alloc] init];
            centerStyle.paragraphSpacing = header1spacing;
            [attributedContributionBody addAttribute:NSParagraphStyleAttributeName value:centerStyle range:range];
            contributionOffset += header1spacing;
        } else if ([[attrs objectForKey:@"DTHeaderLevel"]  isEqual: @2] || [[attrs objectForKey:@"DTHeaderLevel"]  isEqual: @3]){
            [attributedContributionBody addAttribute:NSFontAttributeName value:[UIFont fontWithDescriptor:[[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleSubheadline forFont:kSourceSansPro] fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold] size:0] range:range];
            NSMutableParagraphStyle *centerStyle = [[NSMutableParagraphStyle alloc] init];
            centerStyle.paragraphSpacing = header2spacing;
            [attributedContributionBody addAttribute:NSParagraphStyleAttributeName value:centerStyle range:range];
            contributionOffset += header2spacing;
        } else if ([[attrs objectForKey:@"DTBlockquote"]  isEqual: @1]){
            [attributedContributionBody addAttribute:NSFontAttributeName value:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kCrimsonRoman] size:0] range:range];
            NSMutableParagraphStyle *centerStyle = [[NSMutableParagraphStyle alloc] init];
            centerStyle.firstLineHeadIndent = 33.f;
            centerStyle.headIndent = 33.f;
            centerStyle.paragraphSpacingBefore = header1spacing;
            centerStyle.paragraphSpacing = header1spacing;
            [attributedContributionBody addAttribute:NSParagraphStyleAttributeName value:centerStyle range:range];
        }
    }];
    [attributedContributionBody endEditing];
    [_textStorage appendAttributedString:attributedContributionBody];
    [self drawContributionBody:attributedContributionBody forContribution:contribution];
}

- (void)drawContributionBody:(NSMutableAttributedString*)attributedContributionBody forContribution:(Contribution*)contribution {
    if ([_story.mystery isEqualToNumber:@YES]){
        NSString *tempString = [attributedContributionBody string];
        NSString *mysteryString;
        if (tempString.length > 250){
            mysteryString = [@"..." stringByAppendingString:[tempString substringFromIndex:tempString.length-250]];
            [[attributedContributionBody mutableString] setString:mysteryString];
        } else if (tempString.length) {
            mysteryString = [@"..." stringByAppendingString:tempString];
            [[attributedContributionBody mutableString] setString:mysteryString];
        }
        
        UIView *contributorView = [[UIView alloc] initWithFrame:CGRectMake(0, contributionOffset, width, 50)];
        [contributorView setTag:kContributorViewTag];
        
        UIButton *userImgButton = [UIButton buttonWithType:UIButtonTypeCustom];
        if (contribution.user.picSmall.length){
            [userImgButton sd_setImageWithURL:[NSURL URLWithString:contribution.user.picSmall] forState:UIControlStateNormal];
            [userImgButton.imageView.layer setBackgroundColor:[UIColor clearColor].CGColor];
            [userImgButton.imageView setBackgroundColor:[UIColor clearColor]];
            [userImgButton.imageView.layer setCornerRadius:25.f];
        } else {
            [userImgButton setTitle:[contribution.user.penName substringWithRange:NSMakeRange(0, 2)].uppercaseString forState:UIControlStateNormal];
            [userImgButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
            [userImgButton.titleLabel setFont:[UIFont fontWithName:kSourceSansProLight size:17]];
            [userImgButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            userImgButton.layer.borderColor = [UIColor blackColor].CGColor;
            userImgButton.layer.borderWidth = .5f;
            [userImgButton.layer setCornerRadius:25.f];
            [userImgButton.layer setBackgroundColor:[UIColor clearColor].CGColor];
            [userImgButton setBackgroundColor:[UIColor clearColor]];
        }
        
        [userImgButton setFrame:CGRectMake(spacer/2, 0, 50, 50)];
        [userImgButton setTag:[_story.contributions indexOfObject:contribution]];
        [userImgButton addTarget:self action:@selector(goToProfile:) forControlEvents:UIControlEventTouchUpInside];
        [contributorView addSubview:userImgButton];
        UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(spacer+50, 0, width-50-spacer, 50)];
        [nameLabel setTextColor:textColor];
        [nameLabel setText:[NSString stringWithFormat:@"%@\n%@",contribution.user.penName, [_formatter stringFromDate:contribution.updatedDate]]];
        [nameLabel setFont:[UIFont fontWithName:kSourceSansPro size:13]];
        [nameLabel setNumberOfLines:0];
        [nameLabel setTag:kSeparatorTag];
        [contributorView addSubview:nameLabel];
        
        if (signedIn){
            if ([contribution.user.identifier isEqualToNumber:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]]){
                UIButton *editContributionButton = [UIButton buttonWithType:UIButtonTypeCustom];
                [editContributionButton setFrame:CGRectMake(width-60, 0, 50, 50)];
                if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
                    [editContributionButton setImage:[UIImage imageNamed:@"whitePencil"] forState:UIControlStateNormal];
                } else {
                    [editContributionButton setImage:[UIImage imageNamed:@"pencil"] forState:UIControlStateNormal];
                }
                [editContributionButton setTag:[_story.contributions indexOfObject:contribution]];
                [editContributionButton addTarget:self action:@selector(editContribution:) forControlEvents:UIControlEventTouchUpInside];
                [contributorView addSubview:editContributionButton];
            }
        }
        [_scrollView addSubview:contributorView];
        contributionOffset += 57;
        
        XXTextView *textView = [[XXTextView alloc] initWithFrame:CGRectMake(spacer/2,contributionOffset,width-spacer,height)];
        [textView setContribution:contribution];
        if (contribution.allowFeedback){
            textView.keyboardEnabled = NO;
            textView.userInteractionEnabled = YES;
            textView.selectable = YES;
            [textView setupButtons];
        } else {
            textView.userInteractionEnabled = NO;
        }
        [textView setAttributedText:attributedContributionBody];
        CGFloat mysteryHeight = [textView sizeThatFits:CGSizeMake(width-spacer, CGFLOAT_MAX)].height;
        CGRect mysteryFrame = textView.frame;
        mysteryFrame.origin.y += spacer;
        mysteryFrame.size.height = mysteryHeight + spacer*2;
        [textView setFrame:mysteryFrame];
    
        [textView setTextColor:textColor];
        [_scrollView addSubview:textView];
        
        contributionOffset += mysteryFrame.size.height;
        
        [textView.flagButton addTarget:self action:@selector(flagContent) forControlEvents:UIControlEventTouchUpInside];
        /*UIView *separator = [[UIView alloc] initWithFrame:CGRectMake(spacer, contributionOffset, width-spacer*2, 1)];
        [separator setTag:kSeparatorTag];
        [separator setBackgroundColor:kSeparatorColor];
        [separator setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
        [_scrollView addSubview:separator];*/
        
    } else if (multiPage) {
        NSLog(@"multipage, loading first");
        [self loadPage:1];
        [self loadPage:2];
    } else {

        //draw the first contribution
        CGFloat textViewHeight;
        if (multiPage){
            textViewHeight = height;
        } else {
            textViewHeight = CGFLOAT_MAX;
        }
        
        if (_story.contributions.count > 1) {
            
            UIView *contributorView = [[UIView alloc] initWithFrame:CGRectMake(0, contributionOffset, width, 50)];
            [contributorView setTag:kContributorViewTag];
            
            UIButton *userImgButton = [UIButton buttonWithType:UIButtonTypeCustom];
            if (contribution.user.picSmall.length){
                [userImgButton sd_setImageWithURL:[NSURL URLWithString:contribution.user.picSmall] forState:UIControlStateNormal];
                [userImgButton.imageView.layer setBackgroundColor:[UIColor clearColor].CGColor];
                [userImgButton.imageView setBackgroundColor:[UIColor clearColor]];
                [userImgButton.imageView.layer setCornerRadius:25.f];
            } else {
                [userImgButton setTitle:[contribution.user.penName substringWithRange:NSMakeRange(0, 2)].uppercaseString forState:UIControlStateNormal];
                [userImgButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
                [userImgButton.titleLabel setFont:[UIFont fontWithName:kSourceSansProLight size:17]];
                [userImgButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
                userImgButton.layer.borderColor = [UIColor blackColor].CGColor;
                userImgButton.layer.borderWidth = .5f;
                [userImgButton.layer setCornerRadius:25.f];
                [userImgButton.layer setBackgroundColor:[UIColor clearColor].CGColor];
                [userImgButton setBackgroundColor:[UIColor clearColor]];
            }
            [userImgButton setFrame:CGRectMake(spacer/2, 0, 50, 50)];
            [userImgButton setTag:[_story.contributions indexOfObject:contribution]];
            [userImgButton addTarget:self action:@selector(goToProfile:) forControlEvents:UIControlEventTouchUpInside];
            [contributorView addSubview:userImgButton];
            UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(spacer+50, 0, width-50-spacer, 50)];
            [nameLabel setTextColor:textColor];
            [nameLabel setText:[NSString stringWithFormat:@"%@ | %@",contribution.user.penName, [_formatter stringFromDate:contribution.updatedDate]]];
            [nameLabel setFont:[UIFont fontWithName:kSourceSansPro size:14]];
            [nameLabel setNumberOfLines:0];
            [nameLabel setTag:kSeparatorTag];
            [contributorView addSubview:nameLabel];
            
            if (signedIn && [contribution.user.identifier isEqualToNumber:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]]){
                UIButton *editContributionButton = [UIButton buttonWithType:UIButtonTypeCustom];
                [editContributionButton setFrame:CGRectMake(width-60, 0, 50, 50)];
                if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
                    [editContributionButton setImage:[UIImage imageNamed:@"whitePencil"] forState:UIControlStateNormal];
                } else {
                    [editContributionButton setImage:[UIImage imageNamed:@"pencil"] forState:UIControlStateNormal];
                }
                [editContributionButton setTag:[_story.contributions indexOfObject:contribution]];
                [editContributionButton addTarget:self action:@selector(editContribution:) forControlEvents:UIControlEventTouchUpInside];
                [contributorView addSubview:editContributionButton];
            }
            
            [_scrollView addSubview:contributorView];
            contributionOffset += 57;
        }
        
        NSTextContainer *textContainer = [[NSTextContainer alloc] initWithSize:CGSizeMake(width-spacer, textViewHeight)];
        [layoutManager addTextContainer:textContainer];
        XXTextView *textView = [[XXTextView alloc] initWithFrame:CGRectMake(spacer/2,height,width-spacer,textViewHeight)];
        [textView setContribution:contribution];
        [textView setAttributedText: attributedContributionBody];
        CGFloat textViewMaxHeight = [textView sizeThatFits:CGSizeMake(width-spacer, textViewHeight)].height;
        
        pages += (int)ceilf(contributionOffset/height);

        [textView setSelectable:YES];
        [textView setKeyboardEnabled:NO];
        [textView setupButtons];
        [textView setTextColor:textColor];
        
        CGRect bodyRect = textView.frame;
        bodyRect.origin.y = contributionOffset;
        bodyRect.size.height = textViewMaxHeight;
        [textView setFrame:bodyRect];
        contributionOffset += textViewMaxHeight;
        
        [_scrollView addSubview:textView];
        [textView setTag:1];
        [visiblePages addObject:[NSNumber numberWithInt:1]];
    }
}

- (void)editContribution:(UIButton*)button {
    Contribution *contribution = [_story.contributions objectAtIndex:button.tag];
    XXWriteViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Write"];
    [vc setContribution:contribution];
    [vc setEditMode:YES];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
        [UIView animateWithDuration:.23 animations:^{
            [_scrollView setAlpha:0.0];
            _scrollView.transform = CGAffineTransformMakeScale(.8, .8);
        }];
    }
    
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)drawStoryBody {
    [self setupNavButtons];
    if (!visiblePages){
        visiblePages = [NSMutableSet set];
    } else {
        [visiblePages removeAllObjects];
    }
    
    if (IDIOM == IPAD){
        textSize = 53;
        spacer = 40;
        imageHeight = height/2;
    } else {
        imageHeight = height*.7;
        textSize = 37;
        spacer = 14;
    }
    [_titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleHeadline forFont:kSourceSansProSemibold] size:0]];
    [_authorsLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kCrimsonRoman] size:0]];
    
    [self drawTitle];
    [self drawAuthors];
    
    if (_story.photos.count){
        [_storyPhoto setHidden:NO];
        if (_storyPhoto == nil) {
            _storyPhoto = [[XXStoryPhoto alloc] initWithFrame:CGRectMake(0, 0, width, imageHeight)];
            [_scrollView addSubview:_storyPhoto];
        } else {
            [_storyPhoto setFrame:CGRectMake(0, 0, width, imageHeight)];
        }
        [_storyPhoto.imageView setContentMode:UIViewContentModeScaleAspectFill];
        [_storyPhoto initializeWithPhoto:(Photo*)_story.photos.firstObject forStory:_story inVC:self withButton:NO];
        [_storyPhoto setUserInteractionEnabled:NO];
        [_titleLabel setTextColor:textColor];
        [_authorsLabel setTextColor:textColor];

    } else {
        [_storyPhoto setHidden:YES];
        [_titleLabel setTextColor:textColor];
        _titleLabel.layer.shadowColor = [UIColor clearColor].CGColor;
        _titleLabel.layer.shadowOpacity = 0.f;
        [_authorsLabel setTextColor:textColor];
    }
    
    //only need to setup the text storage and layout manager once
    _textStorage = [[XXTextStorage alloc] init];
    layoutManager = [[NSLayoutManager alloc] init];
    layoutManager.allowsNonContiguousLayout = YES;
    [_textStorage addLayoutManager:layoutManager];
    
    if (_story.wordCount.intValue > 4000) {
        multiPage = YES;
    } else {
        multiPage = NO;
    }
    
    contributionOffset = height;
    if ([_story.mystery isEqualToNumber:@NO] && _story.contributions.count == 1){
        if ([_story.contributions.firstObject body].length) {
            [self generateAttributedString:_story.contributions.firstObject];
        }
    } else {
        for (Contribution *contribution in _story.contributions){
            if (contribution.body.length){
                
                if ([contribution.draft isEqualToNumber:@NO] || ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] && [contribution.user.identifier isEqualToNumber:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]])){
                    
                    //This is the method that generates the contribution string. it then calls the method to draw the contribution. Not getting in here means the piece was a draft and the current user is NOT the user that wrote the contribution
                    
                    [self generateAttributedString:contribution];
                    
                    //TODO draw what a draft placeholder
                }
            }
        }
    }
    
    if ([_story.mystery isEqualToNumber:@YES]){
        addSlowRevealButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [addSlowRevealButton setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
        [addSlowRevealButton setFrame:CGRectMake(0, contributionOffset, width, 176)];
        [addSlowRevealButton setTitle:@"Add to slow reveal..." forState:UIControlStateNormal];
        [addSlowRevealButton.titleLabel setFont:[UIFont fontWithName:kSourceSansPro size:19]];
        [addSlowRevealButton addTarget:self action:@selector(addToSlowReveal) forControlEvents:UIControlEventTouchUpInside];
        if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
            [addSlowRevealButton setTitleColor:textColor forState:UIControlStateNormal];
        } else {
            [addSlowRevealButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
        }
        [_scrollView addSubview:addSlowRevealButton];
        contributionOffset += addSlowRevealButton.frame.size.height;
        
        /*flagButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [flagButton setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
        [flagButton setFrame:CGRectMake(width/2-41, contributionOffset+20, 82, 48)];
        [flagButton setTitle:@"Flag" forState:UIControlStateNormal];
        [flagButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
        [flagButton.titleLabel setFont:[UIFont fontWithName:kSourceSansProSemibold size:16]];
        [flagButton addTarget:self action:@selector(flagContent) forControlEvents:UIControlEventTouchUpInside];
        [flagButton setTitleColor:textColor forState:UIControlStateNormal];
        [flagButton.layer setBorderColor:textColor.CGColor];
        [flagButton setBackgroundColor:[UIColor clearColor]];
        flagButton.layer.borderWidth = .5f;
        flagButton.layer.cornerRadius = 14.f;
        flagButton.clipsToBounds = YES;
        [_scrollView addSubview:flagButton];*/
        contributionOffset += 88;
        
    } else {
        
        shouldShareButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [shouldShareButton setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
        [shouldShareButton setFrame:CGRectMake(width/2-41, contributionOffset + 42, 82, 48)];
        [shouldShareButton setTitle:@"Share" forState:UIControlStateNormal];
        [shouldShareButton.titleLabel setFont:[UIFont fontWithName:kSourceSansPro size:16]];
        [shouldShareButton addTarget:self action:@selector(showActivityView) forControlEvents:UIControlEventTouchUpInside];
        [shouldShareButton setTitleColor:textColor forState:UIControlStateNormal];
        [shouldShareButton.layer setBorderColor:textColor.CGColor];
        [shouldShareButton setBackgroundColor:[UIColor clearColor]];
        if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
            shouldShareButton.layer.borderWidth = 1.f;
        } else {
            shouldShareButton.layer.borderWidth = .5f;
        }
        
        shouldShareButton.layer.cornerRadius = 14.f;
        [_scrollView addSubview:shouldShareButton];
        
        /*flagButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [flagButton setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
        [flagButton setFrame:CGRectMake(width*.75-41, contributionOffset + 42, 82, 48)];
        [flagButton setTitle:@"Flag" forState:UIControlStateNormal];
        [flagButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
        [flagButton.titleLabel setFont:[UIFont fontWithName:kSourceSansPro size:16]];
        [flagButton addTarget:self action:@selector(flagContent) forControlEvents:UIControlEventTouchUpInside];
        [flagButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
        [flagButton setTitleColor:textColor forState:UIControlStateNormal];
        [flagButton.layer setBorderColor:textColor.CGColor];
        [flagButton setBackgroundColor:[UIColor clearColor]];
        flagButton.layer.borderWidth = .5f;
        flagButton.layer.cornerRadius = 14.f;
        [_scrollView addSubview:flagButton];*/
        contributionOffset += 132;
    }
    
    [_scrollView setContentSize:CGSizeMake(width, contributionOffset)];

    [ProgressHUD dismiss];
}

- (void)flagContent {
    XXFlagContentViewController *flagVC = [[self storyboard] instantiateViewControllerWithIdentifier:@"Flag"];
    [flagVC setStory:_story];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:flagVC];
    [self presentViewController:nav animated:YES completion:^{
        
    }];
}

- (void)showActivityView {
    UIActivityViewController *activityView = [[UIActivityViewController alloc] initWithActivityItems:@[_story.storyUrl] applicationActivities:nil];
    [self presentViewController:activityView animated:YES completion:^{
        [[Mixpanel sharedInstance] track:@"Story share button tapped."];
    }];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat y = scrollView.contentOffset.y;
    
    if (y < 0){
        CGFloat y = scrollView.contentOffset.y;
        CGRect imageFrame = _storyPhoto.imageView.frame;
        imageFrame.origin.y = y;
        imageFrame.origin.x = y/2;
        imageFrame.size.width = width-y;
        imageFrame.size.height = imageHeight-y;
        _storyPhoto.imageView.frame = imageFrame;
        
        CGRect progressFrame = _storyPhoto.progressView.frame;
        CGFloat orig = (_storyPhoto.frame.size.height / 2.0) - _storyPhoto.progressView.frame.size.height/2;
        progressFrame.origin.y = y+orig;
        [_storyPhoto.progressView setFrame:progressFrame];
        
    } else {
        [self hideControls];
    }
    
    if ([_story.mystery isEqualToNumber:@NO]){
        static NSInteger previousPage = 0;
        CGFloat pageHeight = scrollView.frame.size.height;
        float fractionalPage = y / pageHeight;
        page = floorf(fractionalPage);
        if (page > previousPage) {
            previousPage = page;
            [self loadPage:page+1];
            [self loadPage:page+2];
        } else if (page < previousPage){
            previousPage = page;
            [self loadPage:page-1];
            [self loadPage:page-2];
        }
    }
}

- (void)loadPage:(NSInteger)newPage{
    if (multiPage && newPage > 0 && ![visiblePages containsObject:[NSNumber numberWithInteger:newPage]]){
        NSLog(@"attributed page count: %lu, new page: %ld",(unsigned long)_attributedPages.count, (long)newPage);
        XXTextView *textView;
        if (_attributedPages.count > newPage){
            NSLog(@"object pulled from attributed pages: %@",[_attributedPages objectAtIndex:newPage-1]);
            textView = [[XXTextView alloc] initWithFrame:CGRectMake(spacer/2,height*newPage-1,width-spacer,height)];
            [textView setAttributedText:[_attributedPages objectAtIndex:newPage-1]];
        } else {
            NSTextContainer *textContainer = [[NSTextContainer alloc] initWithSize:CGSizeMake(width-spacer, height)];
            [layoutManager addTextContainer:textContainer];
            textView = [[XXTextView alloc] initWithFrame:CGRectMake(spacer/2,height*newPage,width-spacer,height)];
            NSRange glyphRange = [layoutManager glyphRangeForTextContainer:textContainer];
            NSAttributedString *attributedSubstring = [_textStorage attributedSubstringFromRange:glyphRange];
            [textView setAttributedText: attributedSubstring];
            [_attributedPages addObject:attributedSubstring];
        }
        
        if (textView.text.length && textView.frame.size.height+textView.frame.origin.y > _scrollView.contentSize.height){
            CGFloat heightToAdd = [textView sizeThatFits:CGSizeMake(width-spacer, CGFLOAT_MAX)].height;
            contributionOffset += heightToAdd;
            CGSize contentSize = _scrollView.contentSize;
            contentSize.height = contributionOffset;
            if (shouldShareButton){
                CGRect shouldShareRect = shouldShareButton.frame;
                shouldShareRect.origin.y += heightToAdd + 88;
                [shouldShareButton setFrame:shouldShareRect];
            }
            if (flagButton){
                CGRect flagRect = flagButton.frame;
                flagRect.origin.y += heightToAdd + 88;
                [flagButton setFrame:flagRect];
            }
            contentSize.height += 88;
            
            //NSLog(@"added height: %f",[textView sizeThatFits:CGSizeMake(width-spacer, CGFLOAT_MAX)].height);
            [_scrollView setContentSize:contentSize];
        } else if (!textView.text.length) {
            //NSLog(@"no more text, scrollview height: %f",_scrollView.contentSize.height);
        }
        if (_story.contributions.count == 1){
            [textView setContribution:_story.contributions.firstObject];
        }
        
        [textView setupButtons];
        textView.selectable = YES;
        [textView setTextColor:textColor];
        [textView setTag:newPage];
        [_scrollView addSubview:textView];

        [visiblePages addObject:[NSNumber numberWithInteger:newPage]];
        //NSLog(@"visible pages: %d for page: %d",visiblePages.count,newPage);
    }
}

- (void)removeNonVisible {
    NSLog(@"removing non visible textviews, current page is: %ld",(long)page);
    for (id view in _scrollView.subviews) {
        if ([view isKindOfClass:[XXTextView class]]){
            XXTextView *textView = (XXTextView*)view;
            if (textView.tag != page && textView.tag != page-1 && textView.tag != page+1 ){
                [view removeFromSuperview];
                [visiblePages removeObject:[NSNumber numberWithInteger:textView.tag]];
            }
        }
    }
}

- (void)addFeedback:(NSNotification*)notification {
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
        [self hideControls];
        if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)){
            _backgroundImageView = [[UIImageView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        } else {
            _backgroundImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, height, width)];
        }
        backgroundImage = [self blurredSnapshot:YES];
        [_backgroundImageView setAlpha:0.0];
        [_backgroundImageView setImage:backgroundImage];
        [self.view addSubview:_backgroundImageView];
        [_backgroundImageView setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
        
        [UIView animateWithDuration:.55 delay:0 usingSpringWithDamping:.67 initialSpringVelocity:.01 options:UIViewAnimationOptionAllowAnimatedContent animations:^{
            [_backgroundImageView setAlpha:1.0];
        } completion:^(BOOL finished) {
            
        }];
        
        XXAddFeedbackViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"AddFeedback"];
        vc.transitioningDelegate = self;
        vc.modalPresentationStyle = UIModalPresentationCustom;
        [vc setStory:_story];
        [vc setContribution:[notification.userInfo objectForKey:@"contribution"]];
        [vc setSnippet:[notification.userInfo objectForKey:@"text"]];
        [vc setStringLocation:[notification.userInfo objectForKey:@"location"]];
        [vc setStoryViewController:self];
        [vc setTextColor:textColor];
        
        [self presentViewController:vc animated:YES completion:nil];
    } else {
        XXLoginViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Login"];
        [self presentViewController:vc animated:YES completion:^{
            [XXAlert show:@"You'll need to log in before leaving feedback" withTime:2.7f];
        }];
    }
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented
                                                                  presentingController:(UIViewController *)presenting
                                                                      sourceController:(UIViewController *)source {
    XXFeedbackTransition *animator = [XXFeedbackTransition new];
    animator.presenting = YES;
    return animator;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    XXFeedbackTransition *animator = [XXFeedbackTransition new];
    return animator;
}

- (void)showWriteControls {
    publishButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [publishButton setFrame:CGRectMake(width-100, addSlowRevealButton.frame.origin.y, 88, 68)];
    [publishButton setTitle:@"Add" forState:UIControlStateNormal];
    [publishButton setTitleColor:kElectricBlue forState:UIControlStateNormal];
    [publishButton.titleLabel setFont:[UIFont fontWithName:kSourceSansPro size:16]];
    [publishButton addTarget:self action:@selector(publishContribution) forControlEvents:UIControlEventTouchUpInside];
    [self.scrollView addSubview:publishButton];
    
    cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [cancelButton setFrame:CGRectMake(10, addSlowRevealButton.frame.origin.y, 88, 68)];
    [cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
    [cancelButton setTitleColor:kElectricBlue forState:UIControlStateNormal];
    [cancelButton.titleLabel setFont:[UIFont fontWithName:kSourceSansPro size:16]];
    [cancelButton addTarget:self action:@selector(doneEditing) forControlEvents:UIControlEventTouchUpInside];
    [self.scrollView addSubview:cancelButton];
}

- (void)publishContribution {
    [self.view endEditing:YES];
    if (_currentUser){
        if (newContributionTextView.text.length && ![newContributionTextView.text isEqualToString:kSlowRevealPlaceholder]){
            [UIView animateWithDuration:.23 animations:^{
                [publishButton setAlpha:0.0];
                [cancelButton setAlpha:0.0];
            }completion:^(BOOL finished) {
                [publishButton removeFromSuperview];
                [cancelButton removeFromSuperview];
            }];
            
            [ProgressHUD show:@"Adding your contribution..."];
            NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
            [parameters setObject:_story.identifier forKey:@"story_id"];
            [parameters setObject:_currentUser.identifier forKey:@"user_id"];
            [parameters setObject:[newContributionTextView.attributedText htmlFragment] forKey:@"body"];
            [manager POST:[NSString stringWithFormat:@"%@/contributions",kAPIBaseUrl] parameters:@{@"contribution":parameters} success:^(AFHTTPRequestOperation *operation, id responseObject) {
                NSLog(@"success posting a new contribution: %@",responseObject);
                Contribution *newContribution = [Contribution MR_findFirstByAttribute:@"identifier" withValue:[[responseObject objectForKey:@"contribution"] objectForKey:@"id"] inContext:[NSManagedObjectContext MR_defaultContext]];
                if (!newContribution){
                    newContribution = [Contribution MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                }
                [newContribution populateFromDict:[responseObject objectForKey:@"contribution"]];
                
                [_story addContribution:newContribution];
                [newContributionTextView removeFromSuperview];
                [self resetStoryBody];
                [self drawStoryBody];
                UIEdgeInsets contentInsets = _scrollView.contentInset;
                contentInsets.bottom = 0;
                [_scrollView setContentInset:contentInsets];
                _scrollView.pagingEnabled = YES;
                [ProgressHUD dismiss];
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                _scrollView.pagingEnabled = YES;
                [ProgressHUD dismiss];
                NSLog(@"Failed to post a new contribution: %@",error.description);
            }];
        }
    } else {
        XXLoginViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Login"];
        [self presentViewController:vc animated:YES completion:^{
            [XXAlert show:@"Please login before publishing" withTime:2.7f];
        }];
    }
}

- (void)doneEditing {
    [self.view endEditing:YES];
    [newContributionTextView removeFromSuperview];
    [UIView animateWithDuration:.23 animations:^{
        [publishButton setAlpha:0.0];
        [cancelButton setAlpha:0.0];
    }completion:^(BOOL finished) {
        [publishButton setHidden:YES];
        [cancelButton setHidden:YES];
        addSlowRevealButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [addSlowRevealButton setFrame:CGRectMake(0, contributionOffset, width, 176)];
        [addSlowRevealButton setTitle:@"Add to slow reveal..." forState:UIControlStateNormal];
        [addSlowRevealButton.titleLabel setFont:[UIFont fontWithName:kSourceSansPro size:20]];
        [addSlowRevealButton addTarget:self action:@selector(addToSlowReveal) forControlEvents:UIControlEventTouchUpInside];
        if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
            [addSlowRevealButton setTitleColor:textColor forState:UIControlStateNormal];
        } else {
            [addSlowRevealButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
        }
        [_scrollView addSubview:addSlowRevealButton];
    }];
}

- (void)addToSlowReveal {
    _scrollView.pagingEnabled = NO;
    [self hideControls];
    [self showWriteControls];
    
    CGRect newTextViewRect;
    newTextViewRect = CGRectMake(spacer/2, publishButton.frame.origin.y + publishButton.frame.size.height, width-spacer, height-publishButton.frame.size.height-keyboardHeight);
    
    newContributionTextView = [[XXTextView alloc] initWithFrame:newTextViewRect];
    newContributionTextView.keyboardEnabled = YES;
    [newContributionTextView setupButtons];
    
    [newContributionTextView.boldButton addTarget:self action:@selector(boldText) forControlEvents:UIControlEventTouchUpInside];
    [newContributionTextView.italicsButton addTarget:self action:@selector(italicText) forControlEvents:UIControlEventTouchUpInside];
    [newContributionTextView.underlineButton addTarget:self action:@selector(underlineText) forControlEvents:UIControlEventTouchUpInside];
    //[newContributionTextView.headerButton addTarget:self action:@selector(headline) forControlEvents:UIControlEventTouchUpInside];
    //[newContributionTextView.footnoteButton addTarget:self action:@selector(footnote) forControlEvents:UIControlEventTouchUpInside];
    
    newContributionTextView.delegate = self;
    [_scrollView addSubview:newContributionTextView];
    [newContributionTextView becomeFirstResponder];
    
    newContributionTextView.delegate = self;
    [newContributionTextView setFont:[UIFont fontWithName:kCrimsonRoman size:22]];
    [newContributionTextView setTextColor:textColor];
    [UIView animateWithDuration:.23 animations:^{
        [addSlowRevealButton setAlpha:0.0];
    }completion:^(BOOL finished) {
        [_scrollView setContentOffset:CGPointMake(0, publishButton.frame.origin.y) animated:YES];
    }];
}

- (void)textViewDidBeginEditing:(XXTextView *)textView {
    if ([textView.text isEqualToString:kSlowRevealPlaceholder]){
        [textView setText:@""];
        [textView setTextColor:textColor];
    }
    [publishButton setHidden:NO];
    [cancelButton setHidden:NO];
    [UIView animateWithDuration:.23 animations:^{
        [publishButton setAlpha:1.0];
        [cancelButton setAlpha:1.0];
    }];
}

- (void)textViewDidEndEditing:(XXTextView *)textView {
    if ([textView.text isEqualToString:@""]){
        [textView setText:kSlowRevealPlaceholder];
        [textView setTextColor:[UIColor lightGrayColor]];
    }
}

- (void)textViewDidChange:(UITextView *)textView {
    //54 is the extra height for the keyboard toolbar
    /*CGRect bodyRect = textView.frame;
    bodyRect.size.height = [textView sizeThatFits:CGSizeMake(textView.frame.size.width, CGFLOAT_MAX)].height;
    [textView setFrame:bodyRect];
    [_scrollView setContentSize:CGSizeMake(textView.frame.size.width,bodyRect.size.height + keyboardHeight+54)];
    if ([textView.text hasSuffix:@"\n"]) {
     [CATransaction setCompletionBlock:^{
     [self scrollToCaret:NO];
     }];
     } else {
     [self scrollToCaret:NO];
     }*/
}

- (void)boldText {
    [newContributionTextView toggleBoldface:nil];
}

- (void)italicText {
    [newContributionTextView toggleItalics:nil];
}

- (void)underlineText {
    [newContributionTextView toggleUnderline:nil];
}

- (void)headline {
    if (_selectedText.length){
        NSRange selectionRange = [self selectedRangeForText:_selectedRange];
        NSMutableAttributedString *attrString = [newContributionTextView.textStorage attributedSubstringFromRange:[self selectedRangeForText:_selectedRange]].mutableCopy;
        UIFontDescriptor *currentFontDescriptor = [[newContributionTextView.textStorage attributesAtIndex:selectionRange.location effectiveRange:NULL][NSFontAttributeName] fontDescriptor];
        CGFloat fontSize = [currentFontDescriptor.fontAttributes[UIFontDescriptorSizeAttribute] floatValue];
        
        [attrString beginEditing];
        if (fontSize < 25.f){
            [attrString addAttribute:NSFontAttributeName value:[UIFont fontWithDescriptor:[[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleSubheadline forFont:kSourceSansPro] fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold] size:0] range:NSMakeRange((0), attrString.length)];
            [newContributionTextView.textStorage replaceCharactersInRange:selectionRange withAttributedString:attrString];
        } else if (fontSize > 25.f && fontSize < 30.f){
            [attrString addAttribute:NSFontAttributeName value:[UIFont fontWithDescriptor:[[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleHeadline forFont:kSourceSansPro] fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold] size:0] range:NSMakeRange((0), attrString.length)];
            [newContributionTextView.textStorage replaceCharactersInRange:selectionRange withAttributedString:attrString];
        } else {
            [attrString addAttribute:NSFontAttributeName value:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kSourceSansPro] size:0] range:NSMakeRange((0), attrString.length)];
            [newContributionTextView.textStorage replaceCharactersInRange:selectionRange withAttributedString:attrString];
        }
        
        [attrString endEditing];
    }
}

- (void)footnote {
    if (_selectedText.length){
        NSRange selectionRange = [self selectedRangeForText:_selectedRange];
        NSMutableAttributedString *attrString = [newContributionTextView.textStorage attributedSubstringFromRange:[self selectedRangeForText:_selectedRange]].mutableCopy;
        
        [attrString beginEditing];
        [attrString addAttribute:NSFontAttributeName value:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleFootnote forFont:kCrimsonRoman] size:0] range:NSMakeRange((0), attrString.length)];
        [newContributionTextView.textStorage replaceCharactersInRange:selectionRange withAttributedString:attrString];
        
        [attrString endEditing];
    }
}

- (NSRange) selectedRangeForText:(UITextRange*)selectedRange
{
    UITextPosition* beginning = newContributionTextView.beginningOfDocument;
    UITextPosition* selectionStart = selectedRange.start;
    UITextPosition* selectionEnd = selectedRange.end;
    const NSInteger location = [newContributionTextView offsetFromPosition:beginning toPosition:selectionStart];
    const NSInteger length = [newContributionTextView offsetFromPosition:selectionStart toPosition:selectionEnd];
    return NSMakeRange(location, length);
}

-(void)textViewDidChangeSelection:(UITextView *)textView {
    //NSLog(@"text selection: %@",textView.text);
}


- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {

}

- (void)registerForKeyboardNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification object:nil];
}

- (void)keyboardWillShow:(NSNotification *)notification {
    NSDictionary* info = [notification userInfo];
    NSTimeInterval duration = [info[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationOptions curve = [info[UIKeyboardAnimationDurationUserInfoKey] unsignedIntegerValue];
    NSDictionary* keyboardInfo = [notification userInfo];
    NSValue* keyboardFrameBegin = [keyboardInfo valueForKey:UIKeyboardFrameBeginUserInfoKey];
    keyboardHeight = [keyboardFrameBegin CGRectValue].size.height;
    
    [UIView animateWithDuration:duration
                          delay:0
                        options:curve | UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         
                     }
                     completion:nil];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    NSDictionary* info = [notification userInfo];
    NSTimeInterval duration = [info[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationOptions curve = [info[UIKeyboardAnimationDurationUserInfoKey] unsignedIntegerValue];
    [UIView animateWithDuration:duration
                          delay:0
                        options:curve | UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         
                     }
                     completion:nil];
}

-(UIImage *)blurredSnapshot:(BOOL)light {
    if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)){
        UIGraphicsBeginImageContextWithOptions([UIScreen mainScreen].bounds.size, NO, self.view.window.screen.scale);
        [self.view drawViewHierarchyInRect:self.view.frame afterScreenUpdates:NO];
    } else {
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(height, width), NO, self.view.window.screen.scale);
        [self.view drawViewHierarchyInRect:CGRectMake(0, 0, height, width) afterScreenUpdates:NO];
    }
    
    UIImage *snapshotImage = UIGraphicsGetImageFromCurrentImageContext();
    UIImage *blurredSnapshotImage;
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
        blurredSnapshotImage = [snapshotImage applyBlurWithRadius:30 blurType:BOXFILTER tintColor:[UIColor colorWithWhite:0.08 alpha:0.93] saturationDeltaFactor:1.8 maskImage:nil];
    } else if (light){
        blurredSnapshotImage = [snapshotImage applyBlurWithRadius:10 blurType:BOXFILTER tintColor:[UIColor colorWithWhite:.93 alpha:0.23] saturationDeltaFactor:1.8 maskImage:nil];
    } else {
        blurredSnapshotImage = [snapshotImage applyBlurWithRadius:20 blurType:BOXFILTER tintColor:[UIColor colorWithWhite:0.11 alpha:0.5] saturationDeltaFactor:1.8 maskImage:nil];
    }
    UIGraphicsEndImageContext();
    return blurredSnapshotImage;
}

- (void)goToProfile:(UIButton*)button {
    XXProfileViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Profile"];
    Contribution *contribution = [_story.contributions objectAtIndex:button.tag];
    [vc setUser:contribution.user];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    [self presentViewController:nav animated:YES completion:^{
        
    }];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [readingTimer invalidate];
    readingTimer = nil;
    [self saveContext];
}

- (void)resetWithStory:(Story*)newStory {
    [self.scrollView setContentOffset:CGPointZero animated:NO];
    [self resetStoryBody];
    _story = newStory;
    storyInfoVc.story = newStory;
    [storyInfoVc.tableView reloadData];
    if (_story.contributions.count){
        [self drawStoryBody];
        [self loadFeedbacks];
    } else {
        [self loadStory:_story.identifier];
    }
    if (IDIOM == IPAD){
        self.title = _story.title;
    }
    
    readingTimer = [NSTimer scheduledTimerWithTimeInterval:1.5 target:self selector:@selector(hideControls) userInfo:nil repeats:NO];
}

- (void)storyFlagged {
    if (self.navigationController.viewControllers.firstObject == self){
        [self dismissViewControllerAnimated:YES completion:nil];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)saveContext {
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
        NSLog(@"%u success with saving story.",success);
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    NSLog(@"received memory warning");
    if (multiPage){
        [self removeNonVisible];
    }
}
@end

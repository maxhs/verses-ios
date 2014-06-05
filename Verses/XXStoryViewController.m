//
//  XXStoryViewController.m
//  Verses
//
//  Created by Max Haines-Stiles on 11/4/13.
//  Copyright (c) 2013 Verses. All rights reserved.
//

#import "XXStoryViewController.h"
#import "XXStoriesViewController.h"
#import "XXStoryInfoViewController.h"
#import "XXStoryCell.h"
#import "XXStoryBodyCell.h"
#import "XXPhoto.h"
#import "UIImage+ImageEffects.h"
#import <SDWebImage/UIButton+WebCache.h>
#import "XXBookmarksViewController.h"
#import "XXWelcomeViewController.h"
#import "XXWriteViewController.h"
#import "XXFeedback.h"
#import "UIFontDescriptor+CrimsonText.h"
#import "UIFontDescriptor+SourceSansPro.h"
#import "XXTextView.h"
#import "XXAddFeedbackViewController.h"
#import "XXFeedbackTransition.h"
#import <DTCoreText/DTCoreText.h>
#import "XXProfileViewController.h"
#import "XXFlagContentViewController.h"

@interface XXStoryViewController () <UIViewControllerTransitioningDelegate> {
    AFHTTPRequestOperationManager *manager;
    XXAppDelegate *appDelegate;
    CGFloat width;
    CGFloat height;
    UITableView *storiesTableView;
    UIButton *dismissButton;
    UITapGestureRecognizer *tapGesture;
    UIImage *backgroundImage;
    NSTimer *readingTimer;
    XXStoryInfoViewController *storyInfoVc;
    XXWelcomeViewController *welcomeVc;
    XXBookmarksViewController *bookmarkVc;
    UIInterfaceOrientation orientation;
    CGFloat rowHeight;
    UIBarButtonItem *backButton;
    UIBarButtonItem *themeButton;
    UIBarButtonItem *menuButton;
    UIBarButtonItem *editButton;
    NSDateFormatter *_formatter;
    UIImageView *navBarShadowView;
    UIColor *textColor;
    BOOL canLoadMore;
    BOOL loading;

    BOOL signedIn;
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
@synthesize stories = _stories;
@synthesize dynamicsViewController = _dynamicsViewController;

- (void)viewDidLoad
{
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)]){
        //self.edgesForExtendedLayout = UIRectEdgeNone;
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
    orientation = self.interfaceOrientation;
    if (UIInterfaceOrientationIsPortrait(orientation)){
        width = screenWidth();
        height = screenHeight();
        if (IDIOM == IPAD){
            keyboardHeight = 264;
        } else {
            keyboardHeight = 216;
        }
    } else {
        width = screenHeight();
        height = screenWidth();
        if (IDIOM == IPAD){
            keyboardHeight = 352;
        } else {
            keyboardHeight = 216;
        }
    }
    if (IDIOM == IPAD){
        rowHeight = height/3;
    } else {
        rowHeight = height/2;
    }
    
    appDelegate = (XXAppDelegate*)[UIApplication sharedApplication].delegate;
    [appDelegate.dynamicsDrawerViewController setPaneDragRevealEnabled:YES forDirection:MSDynamicsDrawerDirectionRight];
    manager = appDelegate.manager;
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]) signedIn = YES;
    else signedIn = NO;
    
    storiesTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, width, height)];
    [self.view addSubview:storiesTableView];
    
    tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleNavBar:)];
    [self.view addGestureRecognizer:tapGesture];
    
    storiesTableView.alpha = 0.0;
    storiesTableView.delegate = self;
    storiesTableView.dataSource = self;
    [storiesTableView setBackgroundColor:[UIColor clearColor]];
    [storiesTableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    storiesTableView.rowHeight = rowHeight;
    [storiesTableView setHidden:YES];
    canLoadMore = YES;
    
    dismissButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [storiesTableView addSubview:dismissButton];
    [dismissButton setFrame:CGRectMake(width-44, 0, 44, 44)];
    dismissButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [dismissButton setImage:[UIImage imageNamed:@"whiteX"] forState:UIControlStateNormal];
    [dismissButton addTarget:self action:@selector(hideStoriesMenu) forControlEvents:UIControlEventTouchUpInside];
    
    if (self.navigationController.viewControllers.firstObject == self){
        backButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"back"] style:UIBarButtonItemStylePlain target:self action:@selector(back)];
        self.navigationItem.leftBarButtonItem = backButton;
    } else if (self.navigationController.viewControllers.count > 1) {
        NSUInteger count = self.navigationController.viewControllers.count;
        backButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"back"] style:UIBarButtonItemStylePlain target:self action:@selector(pop)];
        self.navigationItem.leftBarButtonItem = backButton;
        if ([[self.navigationController.viewControllers objectAtIndex:count-2] isKindOfClass:[XXWelcomeViewController class]]) {
            welcomeVc = [self.navigationController.viewControllers objectAtIndex:count-2];
        } else if ([self.navigationController.viewControllers.firstObject isKindOfClass:[XXBookmarksViewController class]]){
            bookmarkVc = self.navigationController.viewControllers.firstObject;
        }
    }
    readingTimer = [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(hideControls) userInfo:nil repeats:NO];
    
    _attributedPages = [NSMutableArray array];
    if (!_stories) _stories = [appDelegate stories];
    storyInfoVc = (XXStoryInfoViewController*)[appDelegate.dynamicsDrawerViewController drawerViewControllerForDirection:MSDynamicsDrawerDirectionRight];

    _formatter= [[NSDateFormatter alloc] init];
    [_formatter setLocale:[NSLocale currentLocale]];
    [_formatter setDateFormat:@"MMM, d - h:mm a"];
    navBarShadowView = [Utilities findNavShadow:self.navigationController.navigationBar];
    
    [self showControls];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(willShowKeyboard:)
                                                 name:UIKeyboardWillShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(addFeedback:)
                                                 name:@"AddFeedback" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resetStory:) name:@"ResetStory" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(storyFlagged) name:@"StoryFlagged" object:nil];
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    navBarShadowView.hidden = YES;
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
        [self.view setBackgroundColor:[UIColor clearColor]];
        textColor = [UIColor whiteColor];
    } else {
        [self.view setBackgroundColor:[UIColor whiteColor]];
        textColor = [UIColor blackColor];
    }
    
    if (_storyId){
        [ProgressHUD show:@"Fetching story..."];
        [self loadStory:_storyId];
    } else if (_story.contributions.count){
        pages = 0;
        contributionOffset = 0;
        [self resetStoryBody];
        [self drawStoryBody];
        [storyInfoVc setStory:_story];
        [self loadFeedbacks];
    } else {
        [self loadStory:_story.identifier];
    }
    
    if (_scrollView.alpha == 0.0){
        [UIView animateWithDuration:.23 animations:^{
            [_scrollView setAlpha:1.0];
            _scrollView.transform = CGAffineTransformIdentity;
        }];
    }
    
    //_scrollView.pagingEnabled = YES;
}


- (void)loadStory:(NSNumber*)identifier {
    [self resetStoryBody];
    NSDictionary *parameters;
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
        parameters = @{@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]};
    }
    
    [manager GET:[NSString stringWithFormat:@"%@/stories/%@",kAPIBaseUrl,identifier] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"load story response: %@",responseObject);
        _story = [[XXStory alloc] initWithDictionary:[responseObject objectForKey:@"story"]];
        [self drawStoryBody];
        [self loadFeedbacks];
        storyInfoVc.story = _story;
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error loading story: %@",error.description);
    }];
    
}

- (void)confirmLoginPrompt {
    [[[UIAlertView alloc] initWithTitle:@"Easy does it!" message:@"You'll need to log in if you want to leave feedback." delegate:self cancelButtonTitle:@"No Thanks" otherButtonTitles:@"Login", nil] show];
}
- (void)confirmLoginPromptBookmark {
    [[[UIAlertView alloc] initWithTitle:@"Slow those horses!" message:@"You'll need to log in if you want to create bookmarks." delegate:self cancelButtonTitle:@"No Thanks" otherButtonTitles:@"Login", nil] show];
}

- (void)edit {
    XXWriteViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Write"];
    [vc setStory:_story];
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
    if (_story && _story.identifier){
        [manager POST:[NSString stringWithFormat:@"%@/bookmarks",kAPIBaseUrl] parameters:@{@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId],@"story_id":_story.identifier} success:^(AFHTTPRequestOperation *operation, id responseObject) {
            //NSLog(@"Success creating a bookmark: %@",responseObject);
            _story.bookmarked = YES;
            [self setupNavButtons];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Error creating a bookmark: %@",error.description);
        }];
    }
}

- (void)destroyBookmark {
    if (_story && _story.identifier){
        [manager DELETE:[NSString stringWithFormat:@"%@/bookmarks/%@",kAPIBaseUrl,_story.identifier] parameters:@{@"story_id":_story.identifier,@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
            //NSLog(@"success deleting a bookmark: %@",responseObject);
            _story.bookmarked = NO;
            [self setupNavButtons];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Failed to delete the bookmark: %@",error.description);
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
            _story.feedbacks = [[Utilities feedbacksFromJSONArray:[responseObject objectForKey:@"feedbacks"]] mutableCopy];
            _story.bookmarked = [(XXFeedback*)_story.feedbacks.firstObject story].bookmarked;
            [self setupNavButtons];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Failed to get feedbacks for %@, %@",_story.title,error.description);
        }];
    }
}

- (void)setupNavButtons {
    if (signedIn && [_story.owner.identifier isEqualToNumber:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]]){
        editButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"whitePencil"] style:UIBarButtonItemStylePlain target:self action:@selector(edit)];
    } else if (signedIn && _story.bookmarked){
        editButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"bookmarked"] style:UIBarButtonItemStylePlain target:self action:@selector(destroyBookmark)];
    } else if (signedIn){
        editButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"bookmark"] style:UIBarButtonItemStylePlain target:self action:@selector(createBookmark)];
    } else {
        editButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"bookmark"] style:UIBarButtonItemStylePlain target:self action:@selector(confirmLoginPromptBookmark)];
    }
    
    menuButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"menu"] style:UIBarButtonItemStylePlain target:self action:@selector(showStoriesMenu)];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
        themeButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"moon"] style:UIBarButtonItemStylePlain target:self action:@selector(themeSwitch)];
        self.navigationItem.rightBarButtonItems = @[menuButton,editButton,themeButton];
        [self.view setBackgroundColor:[UIColor clearColor]];
        textColor = [UIColor whiteColor];
    } else {
        themeButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"sun"] style:UIBarButtonItemStylePlain target:self action:@selector(themeSwitch)];
        
        self.navigationItem.rightBarButtonItems = @[menuButton,editButton,themeButton];
        [self.view setBackgroundColor:[UIColor whiteColor]];
        textColor = [UIColor blackColor];
    }
}

- (void)themeSwitch {
    NSShadow *clearShadow = [[NSShadow alloc] init];
    clearShadow.shadowColor = [UIColor clearColor];

    if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kDarkBackground];
        textColor = [UIColor blackColor];
        [backButton setTintColor:textColor];
        [themeButton setTintColor:textColor];
        [menuButton setTintColor:textColor];
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
        [backButton setTintColor:[UIColor whiteColor]];
        [themeButton setTintColor:[UIColor whiteColor]];
        [menuButton setTintColor:[UIColor whiteColor]];
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
}

- (void)hideControls {
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
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
    [storiesTableView setFrame:CGRectMake(0, 0, width, height)];
    if (storiesTableView.alpha == 1.0)[storiesTableView reloadData];
}

- (void)resetStory:(NSNotification*)notification{
    _story = [notification.userInfo objectForKey:@"story"];
    [self loadStory:_story.identifier];
}

- (void)resetStoryBody {
    contributionOffset = 0;
    titleFrame = CGRectZero;
    authorsFrame = CGRectZero;
    _imageButton = nil;
    for (id obj in _scrollView.subviews) {
        if ([obj isKindOfClass:[XXTextView class]] || [(UIView*)obj tag] == kSeparatorTag || [obj isKindOfClass:[UIButton class]]) {
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
    NSAttributedString *attributedTitle = [[NSAttributedString alloc] initWithString:_story.title
                                                                          attributes:@{
                                                                                       NSFontAttributeName:self.titleLabel.font,
                                                                                       NSParagraphStyleAttributeName:titleCenterStyle
                                                                                       }];
    [_titleLabel setAttributedText:attributedTitle];
    
    titleFrame = [attributedTitle boundingRectWithSize:CGSizeMake(width-spacer, CGFLOAT_MAX)
                                                      options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading)
                                                      context:nil];
    titleFrame.origin.x += spacer/2;
    if (_story.photos.count){
        titleFrame.origin.y += imageHeight + 11;
    } else {
        titleFrame.origin.y = height/2 - titleFrame.size.height;
    }
    titleFrame.size.width = width-spacer;
    [_titleLabel setFrame:titleFrame];
}

- (void)drawAuthors {
    if (_authorsLabel == nil) {
        _authorsLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    }
    NSString *authorsText = [NSString stringWithFormat:@"by %@",_story.authors];
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

- (void)generateAttributedString:(XXContribution*)contribution {
    
    if (IDIOM == IPAD){
        header1spacing = 23;
        header2spacing = 21;
    } else {
        header1spacing = 23;
        header2spacing = 21;
    }
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineHeightMultiple = 1.f;
    paragraphStyle.lineSpacing = 5.f;
    paragraphStyle.paragraphSpacing = 17.f;
    
    
    NSDictionary* attributes = @{NSFontAttributeName:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCrimsonTextFontDescriptorWithTextStyle:UIFontTextStyleBody] size:0],

                                 NSParagraphStyleAttributeName : paragraphStyle,
                                 NSDocumentTypeDocumentAttribute:NSHTMLTextDocumentType,
                                 };

    //This is the non-dt core text version
    /*NSError *error;
     NSDictionary *documentAttributes;
     NSMutableAttributedString *attributedContributionBody = [[NSMutableAttributedString alloc] initWithData:[contribution.body dataUsingEncoding:NSUnicodeStringEncoding] options:attributes documentAttributes:&documentAttributes error:&error];*/
    
    NSMutableAttributedString* attributedContributionBody = [[NSMutableAttributedString alloc] initWithHTMLData:[contribution.body dataUsingEncoding:NSUTF8StringEncoding] options:@{NSTextEncodingNameDocumentOption: @"UTF-8"} documentAttributes:nil];
    [attributedContributionBody beginEditing];
    [attributedContributionBody addAttributes:attributes range:NSMakeRange(0, attributedContributionBody.length)];
    [attributedContributionBody enumerateAttributesInRange:NSMakeRange(0, attributedContributionBody.length) options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired usingBlock:^(NSDictionary *attrs, NSRange range, BOOL *stop) {
        
        if ([[attrs objectForKey:@"DTHeaderLevel"]  isEqual: @1]){
            [attributedContributionBody addAttribute:NSFontAttributeName value:[UIFont fontWithDescriptor:[[UIFontDescriptor preferredSourceSansProFontDescriptorWithTextStyle:UIFontTextStyleHeadline] fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold] size:0] range:range];
            NSMutableParagraphStyle *centerStyle = [[NSMutableParagraphStyle alloc] init];
            centerStyle.paragraphSpacing = header1spacing;
            [attributedContributionBody addAttribute:NSParagraphStyleAttributeName value:centerStyle range:range];
            contributionOffset += header1spacing;
        } else if ([[attrs objectForKey:@"DTHeaderLevel"]  isEqual: @2] || [[attrs objectForKey:@"DTHeaderLevel"]  isEqual: @3]){
            [attributedContributionBody addAttribute:NSFontAttributeName value:[UIFont fontWithDescriptor:[[UIFontDescriptor preferredSourceSansProFontDescriptorWithTextStyle:UIFontTextStyleSubheadline] fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold] size:0] range:range];
            NSMutableParagraphStyle *centerStyle = [[NSMutableParagraphStyle alloc] init];
            centerStyle.paragraphSpacing = header2spacing;
            [attributedContributionBody addAttribute:NSParagraphStyleAttributeName value:centerStyle range:range];
            contributionOffset += header2spacing;
        } else if ([[attrs objectForKey:@"DTBlockquote"]  isEqual: @1]){
            [attributedContributionBody addAttribute:NSFontAttributeName value:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCrimsonTextFontDescriptorWithTextStyle:CrimsonTextBlockquoteStyle] size:0] range:range];
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

- (void)drawContributionBody:(NSMutableAttributedString*)attributedContributionBody forContribution:(XXContribution*)contribution {
    if (_story.mystery){
        NSString *tempString = [attributedContributionBody string];
        NSString *mysteryString;
        if (tempString.length > 250){
            mysteryString = [@"..." stringByAppendingString:[tempString substringFromIndex:tempString.length-250]];
            [[attributedContributionBody mutableString] setString:mysteryString];
        } else if (tempString.length) {
            mysteryString = [@"..." stringByAppendingString:tempString];
            [[attributedContributionBody mutableString] setString:mysteryString];
        }
        
        UIButton *userImgButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [userImgButton setImageWithURL:[NSURL URLWithString:contribution.user.picSmallUrl] forState:UIControlStateNormal];
        [userImgButton setFrame:CGRectMake(spacer/2, contributionOffset, 50, 50)];
        [userImgButton.imageView.layer setCornerRadius:25.f];
        [userImgButton.imageView.layer setBackgroundColor:[UIColor clearColor].CGColor];
        [userImgButton.imageView setBackgroundColor:[UIColor clearColor]];
        [userImgButton setTag:[_story.contributions indexOfObject:contribution]];
        [userImgButton addTarget:self action:@selector(goToProfile:) forControlEvents:UIControlEventTouchUpInside];
        [_scrollView addSubview:userImgButton];
        UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(spacer+50, contributionOffset, screenWidth()-50-spacer, 50)];
        [nameLabel setTextColor:textColor];
        [nameLabel setText:[NSString stringWithFormat:@"%@\n%@",contribution.user.penName, [_formatter stringFromDate:contribution.updatedDate]]];
        [nameLabel setFont:[UIFont fontWithName:kSourceSansProRegular size:14]];
        [nameLabel setNumberOfLines:0];
        [nameLabel setTag:kSeparatorTag];
        [_scrollView addSubview:nameLabel];
        
        contributionOffset += 50;
        
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
            UIButton *userImgButton = [UIButton buttonWithType:UIButtonTypeCustom];
            [userImgButton setImageWithURL:[NSURL URLWithString:contribution.user.picSmallUrl] forState:UIControlStateNormal];
            [userImgButton setFrame:CGRectMake(spacer/2, contributionOffset, 50, 50)];
            [userImgButton.imageView.layer setCornerRadius:25.f];
            [userImgButton.imageView.layer setBackgroundColor:[UIColor clearColor].CGColor];
            [userImgButton.imageView setBackgroundColor:[UIColor clearColor]];
            [userImgButton setTag:[_story.contributions indexOfObject:contribution]];
            [userImgButton addTarget:self action:@selector(goToProfile:) forControlEvents:UIControlEventTouchUpInside];
            [_scrollView addSubview:userImgButton];
            UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(spacer+50, contributionOffset, screenWidth()-50-spacer, 50)];
            [nameLabel setTextColor:textColor];
            [nameLabel setText:[NSString stringWithFormat:@"%@\n%@",contribution.user.penName, [_formatter stringFromDate:contribution.updatedDate]]];
            [nameLabel setFont:[UIFont fontWithName:kSourceSansProRegular size:14]];
            [nameLabel setNumberOfLines:0];
            [nameLabel setTag:kSeparatorTag];
            [_scrollView addSubview:nameLabel];
            contributionOffset += 50;
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

- (void)drawStoryBody {
    [self setupNavButtons];
    CGFloat textSize;
    if (visiblePages == nil){
        visiblePages = [NSMutableSet set];
    } else {
        [visiblePages removeAllObjects];
    }
    
    if (IDIOM == IPAD){
        textSize = 53;
        spacer = 40;
        imageHeight = height/2;
        [_titleLabel setFont:[UIFont fontWithName:kSourceSansProSemibold size:textSize]];
        [_authorsLabel setFont:[UIFont fontWithName:kCrimsonRoman size:19]];
    } else {
        imageHeight = height*.8;
        textSize = 37;
        spacer = 14;
        [_titleLabel setFont:[UIFont fontWithName:kSourceSansProSemibold size:textSize]];
        [_authorsLabel setFont:[UIFont fontWithName:kCrimsonRoman size:17]];
    }
    
    [self drawTitle];
    [self drawAuthors];
    
    if (_story.photos.count){
        [_imageButton setHidden:NO];
        if (_imageButton == nil) {
            _imageButton = [[XXPhotoButton alloc] initWithFrame:CGRectMake(0, 0, width, imageHeight)];
            [_scrollView addSubview:_imageButton];
        } else {
            [_imageButton setFrame:CGRectMake(0, 0, width, imageHeight)];
        }
        [_imageButton.imageView setContentMode:UIViewContentModeScaleAspectFill];
        [_imageButton initializeWithPhoto:(XXPhoto*)_story.photos.firstObject forStory:_story inVC:self];
        [_imageButton setUserInteractionEnabled:NO];
        [_titleLabel setTextColor:textColor];
        [_authorsLabel setTextColor:textColor];
    } else {
        [_imageButton setHidden:YES];
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
    if (!_story.mystery && _story.contributions.count == 1){
        [self generateAttributedString:_story.firstContribution];
    } else {
        for (XXContribution *contribution in _story.contributions){
            [self generateAttributedString:contribution];
        }
    }
    
    if (_story.mystery){
        addSlowRevealButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [addSlowRevealButton setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
        [addSlowRevealButton setFrame:CGRectMake(0, contributionOffset, width, 176)];
        [addSlowRevealButton setTitle:@"Add to slow reveal..." forState:UIControlStateNormal];
        [addSlowRevealButton.titleLabel setFont:[UIFont fontWithName:kSourceSansProRegular size:20]];
        [addSlowRevealButton addTarget:self action:@selector(addToSlowReveal) forControlEvents:UIControlEventTouchUpInside];
        if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
            [addSlowRevealButton setTitleColor:textColor forState:UIControlStateNormal];
        } else {
            [addSlowRevealButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
        }
        [_scrollView addSubview:addSlowRevealButton];
        contributionOffset += addSlowRevealButton.frame.size.height;
    } else {
        
        shouldShareButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [shouldShareButton setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
        [shouldShareButton setFrame:CGRectMake(0, contributionOffset , width, 176)];
        [shouldShareButton setTitle:@"Share this story" forState:UIControlStateNormal];
        [shouldShareButton.titleLabel setFont:[UIFont fontWithName:kSourceSansProLight size:20]];
        [shouldShareButton addTarget:self action:@selector(showActivityView) forControlEvents:UIControlEventTouchUpInside];
        [shouldShareButton setTitleColor:textColor forState:UIControlStateNormal];
        [_scrollView addSubview:shouldShareButton];
        contributionOffset += 176;
        
    }
    
    flagButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [flagButton setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    [flagButton setFrame:CGRectMake(0, contributionOffset , width, 66)];
    [flagButton setTitle:@"Flag" forState:UIControlStateNormal];
    [flagButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
    [flagButton.titleLabel setFont:[UIFont fontWithName:kSourceSansProLight size:16]];
    [flagButton addTarget:self action:@selector(flagContent) forControlEvents:UIControlEventTouchUpInside];
    [flagButton setTitleColor:textColor forState:UIControlStateNormal];
    [_scrollView addSubview:flagButton];
    contributionOffset += 66;
    
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
        
    }];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat y = scrollView.contentOffset.y;

    CGFloat contentHeight = scrollView.contentSize.height - (screenHeight()*2);
    if (y >= contentHeight && !loading && canLoadMore && scrollView == storiesTableView) {
        NSLog(@"should be loading more from story view");
        [self loadMore];
    }
    
    if (y < 0){
        CGFloat y = scrollView.contentOffset.y;
        CGRect imageFrame = _imageButton.frame;
        imageFrame.origin.y = y;
        imageFrame.origin.x = y/2;
        imageFrame.size.width = width-y;
        imageFrame.size.height = imageHeight-y;
        _imageButton.frame = imageFrame;
        
        /*titleFrame.origin.y = y + 11;
        _titleLabel.frame = titleFrame;
        authorsFrame.origin.y = y + titleFrame.size.height;
        _authorsLabel.frame = authorsFrame;*/
    } else {
        [self hideControls];
    }
    if (scrollView == storiesTableView){
        CGRect dismissFrame = dismissButton.frame;
        dismissFrame.origin.y = y;
        [dismissButton setFrame:dismissFrame];
    }
    
    if (!_story.mystery){
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

- (void)loadMore {
    loading = YES;
    XXStory *lastStory = _stories.lastObject;
    if (lastStory){
        [manager GET:[NSString stringWithFormat:@"%@/stories",kAPIBaseUrl] parameters:@{@"before_date":lastStory.epochTime, @"count":@"10"} success:^(AFHTTPRequestOperation *operation, id responseObject) {
            //NSLog(@"more stories response from story view controller: %@",responseObject);
            NSArray *newStories = [Utilities storiesFromJSONArray:[responseObject objectForKey:@"stories"]];
            NSMutableArray *indexesToInsert = [NSMutableArray array];
            for (int i = _stories.count; i < newStories.count+_stories.count; i++){
                [indexesToInsert addObject:[NSIndexPath indexPathForRow:i inSection:0]];
            }
            [_stories addObjectsFromArray:newStories];
            if (newStories.count < 10) {
                canLoadMore = NO;
                NSLog(@"can't load more, we now have %i stories in the storyview", _stories.count);
            }
            loading = NO;
            
            if ([storiesTableView numberOfRowsInSection:0] > 1){
                [storiesTableView insertRowsAtIndexPaths:indexesToInsert withRowAnimation:UITableViewRowAnimationFade];
            } else {
                [storiesTableView reloadData];
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            
        }];
    }
}

- (void)loadPage:(NSInteger)newPage{
    if (multiPage && newPage > 0 && ![visiblePages containsObject:[NSNumber numberWithInt:newPage]]){
        NSLog(@"attributed page count: %d, new page: %d",_attributedPages.count, newPage);
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
                shouldShareRect.origin.y += heightToAdd;
                [shouldShareButton setFrame:shouldShareRect];
            }
            //NSLog(@"added height: %f",[textView sizeThatFits:CGSizeMake(width-spacer, CGFLOAT_MAX)].height);
            [_scrollView setContentSize:contentSize];
        } else if (!textView.text.length) {
            //NSLog(@"no more text, scrollview height: %f",_scrollView.contentSize.height);
        }
        if (_story.contributions.count == 1){
            [textView setContribution:_story.firstContribution];
        }
        
        [textView setupButtons];
        textView.selectable = YES;
        [textView setTextColor:textColor];
        [textView setTag:newPage];
        [_scrollView addSubview:textView];

        [visiblePages addObject:[NSNumber numberWithInt:newPage]];
        //NSLog(@"visible pages: %d for page: %d",visiblePages.count,newPage);
    }
}

- (void)removeNonVisible {
    NSLog(@"removing non visible textviews, current page is: %d",page);
    for (id view in _scrollView.subviews) {
        if ([view isKindOfClass:[XXTextView class]]){
            XXTextView *textView = (XXTextView*)view;
            if (textView.tag != page && textView.tag != page-1 && textView.tag != page+1 ){
                [view removeFromSuperview];
                [visiblePages removeObject:[NSNumber numberWithInt:textView.tag]];
            }
        }
    }
}

- (void)addFeedback:(NSNotification*)notification {
    [self hideControls];
    if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)){
        _backgroundImageView = [[UIImageView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    } else {
        _backgroundImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, screenHeight(), screenWidth())];
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
    [publishButton setFrame:CGRectMake(screenWidth()-100, addSlowRevealButton.frame.origin.y, 88, 68)];
    [publishButton setTitle:@"Add" forState:UIControlStateNormal];
    [publishButton setTitleColor:kElectricBlue forState:UIControlStateNormal];
    [publishButton.titleLabel setFont:[UIFont fontWithName:kSourceSansProRegular size:16]];
    [publishButton addTarget:self action:@selector(publishContribution) forControlEvents:UIControlEventTouchUpInside];
    [self.scrollView addSubview:publishButton];
    
    cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [cancelButton setFrame:CGRectMake(10, addSlowRevealButton.frame.origin.y, 88, 68)];
    [cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
    [cancelButton setTitleColor:kElectricBlue forState:UIControlStateNormal];
    [cancelButton.titleLabel setFont:[UIFont fontWithName:kSourceSansProRegular size:16]];
    [cancelButton addTarget:self action:@selector(doneEditing) forControlEvents:UIControlEventTouchUpInside];
    [self.scrollView addSubview:cancelButton];
}

- (void)publishContribution {
    [self.view endEditing:YES];
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
        [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"user_id"];
        [parameters setObject:[newContributionTextView.attributedText htmlFragment] forKey:@"body"];
        [manager POST:[NSString stringWithFormat:@"%@/contributions",kAPIBaseUrl] parameters:@{@"contribution":parameters} success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"success posting a new contribution: %@",responseObject);
            XXContribution *newContribution = [[XXContribution alloc] initWithDictionary:[responseObject objectForKey:@"contribution"]];
            [_story.contributions addObject:newContribution];
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
        [addSlowRevealButton setFrame:CGRectMake(0, contributionOffset, screenWidth(), 176)];
        [addSlowRevealButton setTitle:@"Add to slow reveal..." forState:UIControlStateNormal];
        [addSlowRevealButton.titleLabel setFont:[UIFont fontWithName:kSourceSansProRegular size:20]];
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
    if (UIInterfaceOrientationIsPortrait(orientation)){
        newTextViewRect = CGRectMake(spacer/2, publishButton.frame.origin.y + publishButton.frame.size.height, screenWidth()-spacer, screenHeight()-publishButton.frame.size.height-keyboardHeight);
    } else {
        newTextViewRect = CGRectMake(spacer/2, publishButton.frame.origin.y + publishButton.frame.size.height, screenHeight()-spacer, screenWidth()-publishButton.frame.size.height-keyboardHeight);
    }
    
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
            [attrString addAttribute:NSFontAttributeName value:[UIFont fontWithDescriptor:[[UIFontDescriptor preferredSourceSansProFontDescriptorWithTextStyle:UIFontTextStyleSubheadline] fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold] size:0] range:NSMakeRange((0), attrString.length)];
            [newContributionTextView.textStorage replaceCharactersInRange:selectionRange withAttributedString:attrString];
        } else if (fontSize > 25.f && fontSize < 30.f){
            [attrString addAttribute:NSFontAttributeName value:[UIFont fontWithDescriptor:[[UIFontDescriptor preferredSourceSansProFontDescriptorWithTextStyle:UIFontTextStyleHeadline] fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold] size:0] range:NSMakeRange((0), attrString.length)];
            [newContributionTextView.textStorage replaceCharactersInRange:selectionRange withAttributedString:attrString];
        } else {
            [attrString addAttribute:NSFontAttributeName value:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCrimsonTextFontDescriptorWithTextStyle:UIFontTextStyleBody] size:0] range:NSMakeRange((0), attrString.length)];
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
        [attrString addAttribute:NSFontAttributeName value:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCrimsonTextFontDescriptorWithTextStyle:UIFontTextStyleFootnote] size:0] range:NSMakeRange((0), attrString.length)];
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

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == storiesTableView){
        return _stories.count;
    } else {
        
        return (int)pages;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    XXStoryCell *cell = (XXStoryCell *)[tableView dequeueReusableCellWithIdentifier:@"StoryCell"];
    if (cell == nil) {
        cell = [[[NSBundle mainBundle] loadNibNamed:@"XXStoryCell" owner:nil options:nil] lastObject];
    }
    XXStory *story = [_stories objectAtIndex:indexPath.row];
    [cell resetCell];
    [cell configureForStory:story withOrientation:orientation];
    [cell.scrollView setTag:indexPath.row];
    [cell.scrollTouch addTarget:self action:@selector(storyScrollViewTouched:)];
    
    if (story.views && ![story.views isEqualToNumber:[NSNumber numberWithInt:0]]) {
        [cell.countLabel setHidden:NO];
        if ([story.views isEqualToNumber:[NSNumber numberWithInt:1]]){
            [cell.countLabel setText:@"1 view"];
        } else {
            [cell.countLabel setText:[NSString stringWithFormat:@"%@ views",story.views]];
        }
    } else {
        [cell.countLabel setHidden:YES];
    }
    
    if (story.minutesToRead == [NSNumber numberWithInt:0]){
        [cell.infoLabel setText:[NSString stringWithFormat:@"%@ words  |  Quick Read  |  %@",story.wordCount,[_formatter stringFromDate:story.updatedDate]]];
    } else {
        [cell.infoLabel setText:[NSString stringWithFormat:@"%@ words  |  %@ min to read  |  %@",story.wordCount,story.minutesToRead,[_formatter stringFromDate:story.updatedDate]]];
    }
    [cell.titleLabel setTextColor:[UIColor whiteColor]];
    [cell.bodySnippet setTextColor:[UIColor whiteColor]];
    [cell.infoLabel setTextColor:[UIColor whiteColor]];
    
    return cell;
}

/*- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (tableView == storiesTableView) {
        return 44;
    } else {
        return 0;
    }
}

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (tableView == storiesTableView) {
        UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, 0)];
        [headerView setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
        UIButton *dismissButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [headerView addSubview:dismissButton];
        [dismissButton setFrame:CGRectMake(width-44, 0, 44, 44)];
        dismissButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        [dismissButton setImage:[UIImage imageNamed:@"whiteX"] forState:UIControlStateNormal];
        [dismissButton addTarget:self action:@selector(hideStoriesMenu) forControlEvents:UIControlEventTouchUpInside];
        return headerView;
    } else {
        return [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    }
}*/

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == storiesTableView) {
        cell.backgroundColor = [UIColor clearColor];
        UIView *selectedView = [[UIView alloc] initWithFrame:cell.frame];
        [selectedView setBackgroundColor:kSeparatorColor];
        cell.selectedBackgroundView = selectedView;
    }
}

-(void)willShowKeyboard:(NSNotification*)notification {
    NSDictionary* keyboardInfo = [notification userInfo];
    NSValue* keyboardFrameBegin = [keyboardInfo valueForKey:UIKeyboardFrameBeginUserInfoKey];
    keyboardHeight = [keyboardFrameBegin CGRectValue].size.height;
}

-(UIImage *)blurredSnapshot:(BOOL)light {
    if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)){
        UIGraphicsBeginImageContextWithOptions([UIScreen mainScreen].bounds.size, NO, self.view.window.screen.scale);
        [self.view drawViewHierarchyInRect:self.view.frame afterScreenUpdates:NO];
    } else {
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(screenHeight(), screenWidth()), NO, self.view.window.screen.scale);
        [self.view drawViewHierarchyInRect:CGRectMake(0, 0, screenHeight(), screenWidth()) afterScreenUpdates:NO];
    }
    
    UIImage *snapshotImage = UIGraphicsGetImageFromCurrentImageContext();
    UIImage *blurredSnapshotImage;
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
        blurredSnapshotImage = [snapshotImage applyBlurWithRadius:90 blurType:BOXFILTER tintColor:[UIColor colorWithWhite:0.08 alpha:0.93] saturationDeltaFactor:1.8 maskImage:nil];
    } else if (light){
        blurredSnapshotImage = [snapshotImage applyBlurWithRadius:10 blurType:BOXFILTER tintColor:[UIColor colorWithWhite:.93 alpha:0.23] saturationDeltaFactor:1.8 maskImage:nil];
    } else {
        blurredSnapshotImage = [snapshotImage applyBlurWithRadius:20 blurType:BOXFILTER tintColor:[UIColor colorWithWhite:0.11 alpha:0.5] saturationDeltaFactor:1.8 maskImage:nil];
    }
    UIGraphicsEndImageContext();
    return blurredSnapshotImage;
}

-(void)showStoriesMenu{
    [self hideControls];
    [readingTimer invalidate];

    if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)){
        _backgroundImageView = [[UIImageView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    } else {
        _backgroundImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, screenHeight(), screenWidth())];
    }
    backgroundImage = [self blurredSnapshot:NO];
    [_backgroundImageView setImage:backgroundImage];
    [storiesTableView setBackgroundView:_backgroundImageView];
    [storiesTableView setHidden:NO];
    
    [UIView animateWithDuration:.33 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        //storiesTableView.transform = CGAffineTransformIdentity;
        [storiesTableView setAlpha:1.0];
    } completion:^(BOOL finished) {
        [tapGesture setEnabled:NO];
    }];
}

- (void)hideStoriesMenu {
    [self showControls];
    //int randomNumber = (int)arc4random_uniform(17)-8;
    [UIView animateWithDuration:.27 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        //CGAffineTransform scale = CGAffineTransformMakeScale(1.2, 1.2);
        //CGAffineTransform rotate = CGAffineTransformRotate(CGAffineTransformIdentity,RADIANS(randomNumber));
        //storiesTableView.transform = CGAffineTransformConcat(scale, rotate);
        storiesTableView.alpha = 0.0;
    } completion:^(BOOL finished) {
        [tapGesture setEnabled:YES];
        storiesTableView.transform = CGAffineTransformIdentity;
        [storiesTableView setHidden:YES];
    }];
}

- (void)goToProfile:(UIButton*)button {
    XXProfileViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Profile"];
    XXContribution *contribution = [_story.contributions objectAtIndex:button.tag];
    [vc setUser:contribution.user];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    [self presentViewController:nav animated:YES completion:^{
        
    }];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [readingTimer invalidate];
    readingTimer = nil;
}

- (void)resetWithStory:(XXStory*)newStory {
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

- (void)storyScrollViewTouched:(UITapGestureRecognizer*)scrollTapGesture {
    XXStory *story = [_stories objectAtIndex:scrollTapGesture.view.tag];
    [self resetWithStory:story];
    [self hideStoriesMenu];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (tableView == storiesTableView){
        [self resetWithStory:[_stories objectAtIndex:indexPath.row]];
        [self hideStoriesMenu];
    }
}

- (void)storyFlagged {
    if (self.navigationController.viewControllers.firstObject == self){
        [self dismissViewControllerAnimated:YES completion:nil];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    NSLog(@"received memory warning");
    if (multiPage){
        [self removeNonVisible];
    }
    /*if (IDIOM == IPAD){
        [[(XXAppDelegate*)[UIApplication sharedApplication].delegate windowBackground] setImage:[UIImage imageNamed:@"background_ipad"]];
    } else {
        [[(XXAppDelegate*)[UIApplication sharedApplication].delegate windowBackground] setImage:[UIImage imageNamed:@"background"]];
    }*/
}
@end

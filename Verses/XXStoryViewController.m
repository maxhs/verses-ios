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
#import <DTCoreText/DTCoreText.h>
#import "XXPhoto.h"
#import "UIImage+ImageEffects.h"
#import <SDWebImage/UIButton+WebCache.h>
#import "XXBookmarksViewController.h"
#import "XXWelcomeViewController.h"
#import "XXWriteViewController.h"
#import "XXFeedback.h"
#import "UIFontDescriptor+CrimsonText.h"
#import "UIFontDescriptor+SourceSansPro.h"

@interface XXStoryViewController () {
    AFHTTPRequestOperationManager *manager;
    XXAppDelegate *appDelegate;
    CGFloat width;
    CGFloat height;
    UITableView *storiesTableView;
    UITapGestureRecognizer *tapGesture;
    UIImage *backgroundImage;
    NSTimer *readingTimer;
    XXStoryInfoViewController *storyInfoVc;
    UIInterfaceOrientation orientation;
    CGFloat rowHeight;
    UIBarButtonItem *backButton;
    UIBarButtonItem *themeButton;
    UIBarButtonItem *menuButton;
    UIBarButtonItem *editButton;
    NSDateFormatter *_formatter;
    UIImageView *navBarShadowView;
    UIColor *textColor;
    XXWelcomeViewController *welcomeVc;
    BOOL signedIn;
    UIStoryboard *storyboard;
    CGFloat imageHeight;
}
@end

@implementation XXStoryViewController

int const storyConstant = 87;

@synthesize story = _story;
@synthesize stories = _stories;
@synthesize storyId = _storyId;
@synthesize dynamicsViewController = _dynamicsViewController;

- (void)viewDidLoad
{
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)]){
        //self.edgesForExtendedLayout = UIRectEdgeNone;
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
    if (IDIOM == IPAD){
        rowHeight = 270;
    } else {
        rowHeight = 200;
    }
    
    orientation = self.interfaceOrientation;
    if (UIInterfaceOrientationIsPortrait(orientation)){
        width = screenWidth();
        height = screenHeight();
    } else {
        height = screenHeight();
        width = screenWidth();
    }
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]) signedIn = YES;
    else signedIn = NO;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone){
        storyboard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle:nil];
    } else {
        storyboard = [UIStoryboard storyboardWithName:@"Main_iPad" bundle:nil];
    }
    
    storiesTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, width, height)];
    [self.view addSubview:storiesTableView];
    manager = [AFHTTPRequestOperationManager manager];
    
    tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleNavBar:)];
    [self.view addGestureRecognizer:tapGesture];
    storiesTableView.transform = CGAffineTransformMakeScale(.9, .9);
    storiesTableView.alpha = 0.0;
    storiesTableView.delegate = self;
    storiesTableView.dataSource = self;
    [storiesTableView setBackgroundColor:[UIColor clearColor]];
    [storiesTableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    storiesTableView.rowHeight = rowHeight;
    storiesTableView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [storiesTableView setHidden:YES];
    
    if (self.navigationController.viewControllers.firstObject == self){
        backButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"back"] style:UIBarButtonItemStylePlain target:self action:@selector(back)];
        self.navigationItem.leftBarButtonItem = backButton;
    } else if (self.navigationController.viewControllers.count > 1) {
        NSUInteger count = self.navigationController.viewControllers.count;
        backButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"back"] style:UIBarButtonItemStylePlain target:self action:@selector(pop)];
        self.navigationItem.leftBarButtonItem = backButton;
        if ([[self.navigationController.viewControllers objectAtIndex:count-2] isKindOfClass:[XXWelcomeViewController class]]) {
            welcomeVc = [self.navigationController.viewControllers objectAtIndex:count-2];
        }
    }
    readingTimer = [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(hideControls) userInfo:nil repeats:NO];
    appDelegate = (XXAppDelegate*)[UIApplication sharedApplication].delegate;
    [appDelegate.dynamicsDrawerViewController setPaneDragRevealEnabled:YES forDirection:MSDynamicsDrawerDirectionRight];
    if (!_stories) _stories = [(XXMenuViewController*)[appDelegate.dynamicsDrawerViewController drawerViewControllerForDirection:MSDynamicsDrawerDirectionLeft] stories];
    
    storyInfoVc = (XXStoryInfoViewController*)[appDelegate.dynamicsDrawerViewController drawerViewControllerForDirection:MSDynamicsDrawerDirectionRight];
    _formatter= [[NSDateFormatter alloc] init];
    [_formatter setLocale:[NSLocale currentLocale]];
    [_formatter setDateFormat:@"MMM, d - h:mm a"];
    navBarShadowView = [Utilities findNavShadow:self.navigationController.navigationBar];
    
    [super viewDidLoad];
    //[[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
}

- (void)confirmLoginPrompt {
    [[[UIAlertView alloc] initWithTitle:@"Whoa there." message:@"You'll need to log in if you want to leave feedback." delegate:self cancelButtonTitle:@"No Thanks" otherButtonTitles:@"Login", nil] show];
}

- (void)pop {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)edit {
    XXWriteViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"Write"];
    [vc setStory:_story];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
        [UIView animateWithDuration:.23 animations:^{
            [self.scrollView setAlpha:0.0];
            self.scrollView.transform = CGAffineTransformMakeScale(.8, .8);
        }];
    }
    
    [self presentViewController:nav animated:YES completion:^{
        
    }];
}

- (void)createBookmark {
    if (_story && _story.identifier){
        [manager POST:[NSString stringWithFormat:@"%@/bookmarks",kAPIBaseUrl] parameters:@{@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId],@"story_id":_story.identifier} success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"Success creating a bookmark: %@",responseObject);
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
            NSLog(@"success deleting a bookmark: %@",responseObject);
            _story.bookmarked = NO;
            [self setupNavButtons];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Failed to delete the bookmark: %@",error.description);
        }];
    }
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
    
    if (_story){
        [self drawStoryBody];
        [self loadFeedbacks];
    }
    if (self.scrollView.alpha == 0.0){
        [UIView animateWithDuration:.23 animations:^{
            [self.scrollView setAlpha:1.0];
            self.scrollView.transform = CGAffineTransformIdentity;
        }];
    }
}

- (void)loadFeedbacks {
    if (signedIn){
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"user_id"];
        [parameters setObject:_story.identifier forKey:@"story_id"];
        [manager GET:[NSString stringWithFormat:@"%@/feedbacks/%@",kAPIBaseUrl,_story.identifier] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
            //NSLog(@"success getting feedbacks for story %@, %@",_story.title,responseObject);
            NSMutableArray *feedbacks = [[Utilities feedbacksFromJSONArray:[responseObject objectForKey:@"feedbacks"]] mutableCopy];
            XXFeedback *feedback = feedbacks.firstObject;
            [storyInfoVc setFeedback:feedback];
            [storyInfoVc setFeedbacks:feedbacks];
            _story.bookmarked = feedback.story.bookmarked;
            [self setupNavButtons];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Failed to get feedbacks for %@, %@",_story.title,error.description);
        }];
    }
}

- (void)setupNavButtons {
    if ([_story.owner.identifier isEqualToNumber:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]]){
        editButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"whitePencil"] style:UIBarButtonItemStylePlain target:self action:@selector(edit)];
    } else if (signedIn && _story.bookmarked){
        editButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"bookmarked"] style:UIBarButtonItemStylePlain target:self action:@selector(destroyBookmark)];
    } else if (signedIn){
        editButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"bookmark"] style:UIBarButtonItemStylePlain target:self action:@selector(createBookmark)];
    } else {
        editButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"bookmark"] style:UIBarButtonItemStylePlain target:self action:@selector(confirmLoginPrompt)];
    }
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
        themeButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"moon"] style:UIBarButtonItemStylePlain target:self action:@selector(themeSwitch)];
        menuButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"whiteMenu"] style:UIBarButtonItemStylePlain target:self action:@selector(showStoriesMenu)];
        self.navigationItem.rightBarButtonItems = @[menuButton,editButton,themeButton];
        [self.view setBackgroundColor:[UIColor clearColor]];
        textColor = [UIColor whiteColor];
    } else {
        themeButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"whiteSun"] style:UIBarButtonItemStylePlain target:self action:@selector(themeSwitch)];
        menuButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"menu"] style:UIBarButtonItemStylePlain target:self action:@selector(showStoriesMenu)];
        self.navigationItem.rightBarButtonItems = @[menuButton,editButton,themeButton];
        [self.view setBackgroundColor:[UIColor whiteColor]];
        textColor = [UIColor blackColor];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (!_story && _storyId) {
        [self loadStory];
    }
}

- (void)themeSwitch {
    NSShadow *clearShadow = [[NSShadow alloc] init];
    clearShadow.shadowColor = [UIColor clearColor];

    if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kDarkBackground];
        textColor = [UIColor blackColor];
        [backButton setTintColor:[UIColor blackColor]];
        [themeButton setTintColor:[UIColor blackColor]];
        [menuButton setTintColor:[UIColor blackColor]];
        [UIView animateWithDuration:.23 animations:^{
            [self.view setBackgroundColor:[UIColor whiteColor]];
            for (id obj in self.scrollView.subviews){
                if ([obj isKindOfClass:[UITextView class]] || [obj isKindOfClass:[UILabel class]]){
                    [obj setTextColor:textColor];
                }
            }
            if (_story.photos.count)[self.titleLabel setTextColor:[UIColor whiteColor]];
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
        
        [UIView animateWithDuration:.23 animations:^{
            [self.view setBackgroundColor:[UIColor clearColor]];
            for (id obj in self.scrollView.subviews){
                if ([obj isKindOfClass:[UITextView class]]){
                    [obj setTextColor:textColor];
                }
            }
            if (_story.photos.count)[self.titleLabel setTextColor:[UIColor whiteColor]];
            
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
    }
}

- (void)showControls {
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
}

- (void)hideControls {
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    orientation = toInterfaceOrientation;
    if (toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft || toInterfaceOrientation == UIInterfaceOrientationLandscapeRight){
        NSLog(@"rotating landscape");
        width = screenHeight();
        height = screenWidth();
        [self resetStoryBody];
        [self drawStoryBody];
        [self hideStoriesMenu];
    } else {
        NSLog(@"rotating portrait");
        width = screenWidth();
        height = screenHeight();
        [self resetStoryBody];
        [self drawStoryBody];
        [self hideStoriesMenu];
    }
}

- (NSAttributedString*)generateAttributedString:(XXContribution*)contribution mystery:(BOOL)mystery {
   NSDictionary *options = @{DTDefaultFontSize: @21,
                              DTDefaultTextColor: textColor,
                              DTDefaultLineHeightMultiplier:@10,
                              DTDefaultFontFamily: @"Crimson Text"};
    DTHTMLAttributedStringBuilder *stringBuilder = [[DTHTMLAttributedStringBuilder alloc] initWithHTML:[contribution.body dataUsingEncoding:NSUTF8StringEncoding] options:options documentAttributes:nil];
    if (mystery){
        NSMutableAttributedString *attributedString = [[stringBuilder generatedAttributedString] mutableCopy];
        NSString *tempString = [attributedString string];
        NSString *mysteryString = [@"..." stringByAppendingString:[tempString substringFromIndex:tempString.length-250]];
        [[attributedString mutableString] setString:mysteryString];
        return attributedString;
    } else {
        return [stringBuilder generatedAttributedString];
    }
}

- (void)resetStoryBody {
    for (id obj in self.scrollView.subviews) {
        if ([obj isKindOfClass:[UITextView class]]) {
            NSLog(@"removing %@",obj);
            [obj removeFromSuperview];
        }
    }
}

- (void)drawStoryBody {
    [self setupNavButtons];
    CGFloat textSize,header1spacing,header2spacing;
    int spacer;

    if (IDIOM == IPAD){
        textSize = 43;
        spacer = 40;
        header1spacing = 27;
        header2spacing = 23;
        imageHeight = 400;
        [self.titleLabel setFont:[UIFont fontWithName:kSourceSansProSemibold size:textSize]];
    } else {
        imageHeight = 200;
        textSize = 33;
        header1spacing = 23;
        header2spacing = 17;
        spacer = 10;
        [self.titleLabel setFont:[UIFont fontWithName:kSourceSansProSemibold size:textSize]];
    }
    [self.imageButton setFrame:CGRectMake(0, 0, width, imageHeight)];
    
    NSAttributedString *attributedTitle = [[NSAttributedString alloc] initWithString:_story.title
                                                                          attributes:@{
                                                                                       NSFontAttributeName:self.titleLabel.font,
                                                                                       }];
    [self.titleLabel setAttributedText:attributedTitle];
    
    CGRect titleFrame = [attributedTitle boundingRectWithSize:CGSizeMake(width-spacer, CGFLOAT_MAX)
                                      options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading)
                                      context:nil];
    titleFrame.origin.x += spacer/2;
   
    NSString *authorsText = [NSString stringWithFormat:@"by %@",_story.authors];
    [self.authorsLabel setText:authorsText];
    if (_story.photos.count){
        [self.authorsLabel setFont:[UIFont fontWithName:kSourceSansProSemibold size:18]];
    } else {
        [self.authorsLabel setFont:[UIFont fontWithName:kSourceSansProLight size:15]];
    }
    NSAttributedString *attributedAuthors = [[NSAttributedString alloc] initWithString:authorsText
                                                                            attributes:@{
                                                                                         NSFontAttributeName: self.authorsLabel.font,
                                                                                         }];
    CGRect authorsFrame = [attributedAuthors boundingRectWithSize:CGSizeMake(width-spacer, CGFLOAT_MAX)
                                                      options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading)
                                                      context:nil];
    authorsFrame.origin.x += spacer/2 + 4;
    authorsFrame.origin.y += titleFrame.size.height-6;
    
    //here's the tough part. creating contributions
    CGFloat offset = 23;
    if (_story.photos.count){
        offset += imageHeight;
    } else {
        offset += titleFrame.size.height + authorsFrame.size.height;
    }
    
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineHeightMultiple = 1.f;
    paragraphStyle.lineSpacing = 5.f;
    paragraphStyle.paragraphSpacing = 17.f;
    paragraphStyle.minimumLineHeight = 10.f;
    paragraphStyle.maximumLineHeight = 500.f;
    
    for (XXContribution *contribution in _story.contributions){
        NSDictionary* attributes = @{NSFontAttributeName:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCrimsonTextFontDescriptorWithTextStyle:UIFontTextStyleBody] size:0],
                                     NSParagraphStyleAttributeName:paragraphStyle,
                                     NSForegroundColorAttributeName:textColor,
                                     };
        NSMutableAttributedString* attributedContributionBody = [[[NSAttributedString alloc] initWithHTMLData:[contribution.body dataUsingEncoding:NSUTF8StringEncoding]
                                                                                              options:@{NSTextEncodingNameDocumentOption: @"UTF-8"}
                                                                                   documentAttributes:nil] mutableCopy];
        if (_story.mystery){
            NSString *tempString = [attributedContributionBody string];
            NSString *mysteryString = [@"..." stringByAppendingString:[tempString substringFromIndex:tempString.length-250]];
            [[attributedContributionBody mutableString] setString:mysteryString];
        }
        
        [attributedContributionBody beginEditing];
        [attributedContributionBody addAttributes:attributes range:NSMakeRange(0, attributedContributionBody.length)];
        __block CGRect bodyRect;
        __block CGFloat headerOffset = header1spacing;
        [attributedContributionBody enumerateAttributesInRange:NSMakeRange(0, attributedContributionBody.length) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) usingBlock:^(NSDictionary *attrs, NSRange range, BOOL *stop) {
            
            if ([[attrs objectForKey:@"DTHeaderLevel"]  isEqual: @1]){
                [attributedContributionBody addAttribute:NSFontAttributeName value:[UIFont fontWithDescriptor:[[UIFontDescriptor preferredSourceSansProFontDescriptorWithTextStyle:UIFontTextStyleHeadline] fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold] size:0] range:range];
                NSMutableParagraphStyle *centerStyle = [[NSMutableParagraphStyle alloc] init];
                centerStyle.paragraphSpacing = header1spacing;
                [attributedContributionBody addAttribute:NSParagraphStyleAttributeName value:centerStyle range:range];
                headerOffset += 30;
            } else if ([[attrs objectForKey:@"DTHeaderLevel"]  isEqual: @2] || [[attrs objectForKey:@"DTHeaderLevel"]  isEqual: @3]){
                [attributedContributionBody addAttribute:NSFontAttributeName value:[UIFont fontWithDescriptor:[[UIFontDescriptor preferredSourceSansProFontDescriptorWithTextStyle:UIFontTextStyleSubheadline] fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold] size:0] range:range];
                NSMutableParagraphStyle *centerStyle = [[NSMutableParagraphStyle alloc] init];
                centerStyle.paragraphSpacing = header2spacing;
                [attributedContributionBody addAttribute:NSParagraphStyleAttributeName value:centerStyle range:range];
                headerOffset += 30;
            } else if ([[attrs objectForKey:@"DTBlockquote"]  isEqual: @1]){
                [attributedContributionBody addAttribute:NSFontAttributeName value:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCrimsonTextFontDescriptorWithTextStyle:CrimsonTextBlockquoteStyle] size:0] range:range];
                NSMutableParagraphStyle *centerStyle = [[NSMutableParagraphStyle alloc] init];
                centerStyle.firstLineHeadIndent = 33.f;
                centerStyle.headIndent = 33.f;
                centerStyle.paragraphSpacingBefore = header1spacing;
                centerStyle.paragraphSpacing = header1spacing;
                [attributedContributionBody addAttribute:NSParagraphStyleAttributeName value:centerStyle range:range];
                headerOffset += header1spacing*2;
            } else {
                headerOffset += 7;
            }
            bodyRect = [attributedContributionBody boundingRectWithSize:CGSizeMake(width-spacer, CGFLOAT_MAX)
                                                                       options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading)
                                                                       context:nil];
        }];
        [attributedContributionBody endEditing];
        
        XXTextStorage *textStorage = [XXTextStorage new];
        [textStorage appendAttributedString:attributedContributionBody];
        
        
        bodyRect.origin.x += spacer/2;
        bodyRect.origin.y = offset;
        bodyRect.size.height += headerOffset;
        
        NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];
        CGSize containerSize = CGSizeMake(bodyRect.size.width,  CGFLOAT_MAX);
        NSTextContainer *container = [[NSTextContainer alloc] initWithSize:containerSize];
        container.widthTracksTextView = YES;
        [layoutManager addTextContainer:container];
        [textStorage addLayoutManager:layoutManager];
        
        UITextView *contributionTextView = [[UITextView alloc] initWithFrame:bodyRect
                                                               textContainer:container];
        //contributionTextView.delegate = self;
        [contributionTextView setBackgroundColor:[UIColor clearColor]];
        contributionTextView.userInteractionEnabled = NO;
        [contributionTextView setTextColor:textColor];
        [self.scrollView addSubview:contributionTextView];
        offset += bodyRect.size.height;
    }
    
    if (_story.photos.count){
        [self.imageButton setHidden:NO];
        [self.imageButton.imageView setContentMode:UIViewContentModeScaleAspectFill];
        [self.imageButton initializeWithPhoto:(XXPhoto*)_story.photos.firstObject forStory:_story inVC:self];
        
        [self.scrollView setContentSize:CGSizeMake(screenWidth()-spacer, offset)];
        [self.titleLabel setTextColor:[UIColor whiteColor]];
        self.titleLabel.layer.shadowColor = textColor.CGColor;
        self.titleLabel.layer.shadowOffset = CGSizeMake(0, 0);
        self.titleLabel.layer.shadowOpacity = .23f;
        self.titleLabel.layer.shadowRadius = 5.0f;
        
        [self.authorsLabel setTextColor:[UIColor whiteColor]];
        self.authorsLabel.layer.shadowColor = textColor.CGColor;
        self.authorsLabel.layer.shadowOffset = CGSizeMake(0, 0);
        self.authorsLabel.layer.shadowOpacity = .23f;
        self.authorsLabel.layer.shadowRadius = 2.3f;
    } else {
        
        [self.imageButton setHidden:YES];
        [self.scrollView setContentSize:CGSizeMake(screenWidth()-spacer, offset)];
        [self.titleLabel setTextColor:textColor];
        self.titleLabel.layer.shadowColor = [UIColor clearColor].CGColor;
        self.titleLabel.layer.shadowOpacity = 0.f;
        [self.authorsLabel setTextColor:textColor];
        self.authorsLabel.layer.shadowColor = [UIColor clearColor].CGColor;
        self.authorsLabel.layer.shadowOpacity = 0.f;
    }
    
    [self.titleLabel setFrame:titleFrame];
    [self.authorsLabel setFrame:authorsFrame];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kStoryPaging]){
        self.scrollView.pagingEnabled = YES;
    } else {
        self.scrollView.pagingEnabled = NO;
    }
    
    [ProgressHUD dismiss];
}

- (void)loadStory {
    NSDictionary *parameters;
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
        parameters = @{@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]};
    }
    
    [manager GET:[NSString stringWithFormat:@"%@/stories/%@",kAPIBaseUrl,_storyId] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"load story response: %@",responseObject);
        _story = [[XXStory alloc] initWithDictionary:[responseObject objectForKey:@"story"]];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"StoryInfo" object:nil userInfo:@{@"story":_story}];
        [self drawStoryBody];
        [self loadFeedbacks];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error loading story: %@",error.description);
    }];

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
        return 1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    XXStoryCell *cell = (XXStoryCell *)[tableView dequeueReusableCellWithIdentifier:@"StoryCell"];
    if (cell == nil) {
        cell = [[[NSBundle mainBundle] loadNibNamed:@"XXStoryCell" owner:nil options:nil] lastObject];
    }
    XXStory *aStory = [_stories objectAtIndex:indexPath.row];
    [cell configureForStory:aStory textColor:[UIColor whiteColor] featured:NO cellHeight:rowHeight];
    
    if (aStory.minutesToRead == [NSNumber numberWithInt:0]){
        [cell.infoLabel setText:[NSString stringWithFormat:@"%@ words  |  Quick Read  |  %@",aStory.wordCount,[_formatter stringFromDate:aStory.updatedDate]]];
    } else {
        [cell.infoLabel setText:[NSString stringWithFormat:@"%@ words  |  %@ min to read  |  %@",aStory.wordCount,aStory.minutesToRead,[_formatter stringFromDate:aStory.updatedDate]]];
    }
    
    [cell.infoLabel setTextColor:[UIColor whiteColor]];
    [cell.separatorView setBackgroundColor:[UIColor colorWithWhite:1 alpha:.1]];
    UIView *backgroundView = [[UIView alloc] init];
    [backgroundView setBackgroundColor:[UIColor clearColor]];
    cell.backgroundView = backgroundView;
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (tableView == storiesTableView) {
        return 44;
    } else {
        return 0;
    }
}

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (tableView == storiesTableView) {
        UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 0)];
        [headerView setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
        UIButton *dismissButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [headerView addSubview:dismissButton];
        [dismissButton setFrame:CGRectMake(width-44, 0, 44, 44)];
        [dismissButton setImage:[UIImage imageNamed:@"whiteX"] forState:UIControlStateNormal];
        [dismissButton addTarget:self action:@selector(hideStoriesMenu) forControlEvents:UIControlEventTouchUpInside];
        return headerView;
    } else {
        return [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == storiesTableView) {
        cell.backgroundColor = [UIColor clearColor];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {

    if (scrollView.contentOffset.y < 0){
        CGFloat y = scrollView.contentOffset.y;
        CGRect imageFrame = self.imageButton.frame;
        imageFrame.origin.y = y*1.08;
        self.imageButton.frame = imageFrame;
        
        CGRect titleFrame = self.titleLabel.frame;
        titleFrame.origin.y = y;
        self.titleLabel.frame = titleFrame;
        
        CGRect authorsFrame = self.authorsLabel.frame;
        authorsFrame.origin.y = y + titleFrame.size.height - 6;
        self.authorsLabel.frame = authorsFrame;
        self.imageButton.transform = CGAffineTransformMakeScale(1-(y/imageHeight), 1-(y/imageHeight));
    }
}

-(UIImage *)blurredSnapshot {
    UIGraphicsBeginImageContextWithOptions([UIScreen mainScreen].bounds.size, NO, self.view.window.screen.scale);
    [self.view drawViewHierarchyInRect:self.view.frame afterScreenUpdates:NO];
    UIImage *snapshotImage = UIGraphicsGetImageFromCurrentImageContext();
    UIImage *blurredSnapshotImage;
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
        blurredSnapshotImage = [snapshotImage applyBlurWithRadius:7 blurType:BOXFILTER tintColor:[UIColor colorWithWhite:0.0 alpha:.92] saturationDeltaFactor:1.0 maskImage:nil];
    } else {
        blurredSnapshotImage = [snapshotImage applyBlurWithRadius:20 blurType:BOXFILTER tintColor:[UIColor colorWithWhite:0.11 alpha:0.5] saturationDeltaFactor:1.8 maskImage:nil];
    }
    UIGraphicsEndImageContext();
    return blurredSnapshotImage;
}

-(void)showStoriesMenu{
    //[storiesTableView setBounds:CGRectMake(0, 0, width, height)];
    [self hideControls];
    [readingTimer invalidate];
    UIImageView *backgroundImageView = [[UIImageView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    backgroundImage = [self blurredSnapshot];
    [backgroundImageView setImage:backgroundImage];
    [storiesTableView setBackgroundView:backgroundImageView];
    [storiesTableView setHidden:NO];
    [UIView animateWithDuration:.55 delay:0 usingSpringWithDamping:.6 initialSpringVelocity:.01 options:UIViewAnimationOptionAllowAnimatedContent animations:^{
        storiesTableView.transform = CGAffineTransformIdentity;
        [storiesTableView setAlpha:1.0];
    } completion:^(BOOL finished) {
        [tapGesture setEnabled:NO];
    }];

}

- (void)hideStoriesMenu {
    [self showControls];
    int randomNumber = (int)arc4random_uniform(17)-8;
    [UIView animateWithDuration:.27 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        CGAffineTransform scale = CGAffineTransformMakeScale(1.2, 1.2);
        CGAffineTransform rotate = CGAffineTransformRotate(CGAffineTransformIdentity,RADIANS(randomNumber));
        storiesTableView.transform = CGAffineTransformConcat(scale, rotate);
        storiesTableView.alpha = 0.0;
    } completion:^(BOOL finished) {
        [tapGesture setEnabled:YES];
        storiesTableView.transform = CGAffineTransformMakeScale(.9, .9);
        [storiesTableView setHidden:YES];
    }];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [readingTimer invalidate];
    readingTimer = nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (tableView == storiesTableView){
        [self resetStoryBody];
        _story = nil;
        _story = [_stories objectAtIndex:indexPath.row];
        [self drawStoryBody];
        if (IDIOM == IPAD){
            self.title = _story.title;
        }
        [storiesTableView setContentOffset:CGPointZero animated:YES];
        [self hideStoriesMenu];
        readingTimer = [NSTimer scheduledTimerWithTimeInterval:1.5 target:self selector:@selector(hideControls) userInfo:nil repeats:NO];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
@end

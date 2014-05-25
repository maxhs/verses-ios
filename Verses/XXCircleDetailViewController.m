//
//  XXCircleDetailViewController.m
//  Verses
//
//  Created by Max Haines-Stiles on 3/30/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import "XXCircleDetailViewController.h"
#import "XXChatCell.h"
#import "XXCircleDetailsCell.h"
#import "XXSegmentedControl.h"
#import "XXStoryCell.h"
#import "XXProfileStoryCell.h"
#import "XXStoryViewController.h"
#import "XXCircleNotificationCell.h"

@interface XXCircleDetailViewController () <XXSegmentedControlDelegate, XXChatDelegate> {
    XXSegmentedControl *_circleControl;
    CGRect screen;
    AFHTTPRequestOperationManager *manager;
    UIColor *textColor;
    BOOL stories;
    BOOL chat;
    BOOL details;
    BOOL sent;
    NSDateFormatter *_detailsFormatter;
    NSDateFormatter *_formatter;
    XXComment *commentForDeletion;
    NSIndexPath *indexPathForDeletion;
    UIInterfaceOrientation currentOrientation;
    NSMutableArray *_notifications;
}

@end
//static int connectionStatusViewTag = 1701

@implementation XXCircleDetailViewController

@synthesize circle = _circle;

- (void)viewDidLoad
{
    screen = [UIScreen mainScreen].bounds;
    manager = [(XXAppDelegate*)[UIApplication sharedApplication].delegate manager];
    [super viewDidLoad];
    
    NSString *storyCount;
    if (_circle.stories.count == 1){
        storyCount = @"1 Story";
    } else {
        storyCount = [NSString stringWithFormat:@"%i Stories",_circle.stories.count];
    }
    _circleControl = [[XXSegmentedControl alloc] initWithItems:@[@"Back",@"Chat",@"Details",storyCount]];
    _circleControl.delegate = self;
    _circleControl.selectedSegmentIndex = 1;
    _circleControl.showsCount = NO;
    _circleControl.showsNavigationArrow = YES;
    
    [_circleControl addTarget:self action:@selector(selectedSegment:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:_circleControl];
    [_circleControl setFrame:CGRectMake(0, 20, 320, 68)];
    
    _detailsFormatter = [[NSDateFormatter alloc] init];
    [_detailsFormatter setLocale:[NSLocale currentLocale]];
    [_detailsFormatter setDateFormat:@"MMM, d  |  h:mm a"];
    _formatter = [[NSDateFormatter alloc] init];
    [_formatter setLocale:[NSLocale currentLocale]];
    [_formatter setDateFormat:@"MMM, d\nh:mm a"];
    if (_circle.comments.count == 0){
        [self loadDetails];
    } else {
        [self loadCircleNotifications];
    }
    if (!_chatInput){
        [self setupChat];
        [self.view addSubview:self.collectionView];
        [self.view addSubview:_chatInput];
    }
    [self scrollToBottom];
    
    //show chat by default//
    [self reset];
    chat = YES;
    [self hideTableView];
    //**//
    
    self.detailsTableView.rowHeight = 60;
    self.storiesTableView.rowHeight = 80;
}

- (void)loadDetails {
    [manager GET:[NSString stringWithFormat:@"%@/circles/%@",kAPIBaseUrl,_circle.identifier] parameters:@{@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"success getting circle details: %@", responseObject);
        _circle = [[XXCircle alloc] initWithDictionary:[responseObject objectForKey:@"circle"]];
        [self.collectionView reloadData];
        
        NSString *storyCount;
        if (_circle.stories.count == 1){
            storyCount = @"1 Story";
        } else {
            storyCount = [NSString stringWithFormat:@"%i Stories",_circle.stories.count];
        }
        
        [_circleControl setTitle:storyCount withImage:nil forSegmentAtIndex:3];

        [self loadCircleNotifications];
        [ProgressHUD dismiss];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failed to get cirlce details: %@",error.description);
    }];
}

- (void)loadCircleNotifications {
    [manager GET:[NSString stringWithFormat:@"%@/circles/%@/notifications",kAPIBaseUrl,_circle.identifier] parameters:@{@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"success getting circle notifications: %@", responseObject);
        _notifications = [[Utilities notificationsFromJSONArray:[responseObject objectForKey:@"notifications"]] mutableCopy];

    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failed to get circle notifications: %@",error.description);
    }];
}

- (void) viewWillAppear:(BOOL)animated {
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    currentOrientation = self.interfaceOrientation;
    
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
        [self.view setBackgroundColor:[UIColor clearColor]];
        [self.storiesTableView setBackgroundColor:[UIColor clearColor]];
        [self.detailsTableView setBackgroundColor:[UIColor clearColor]];
        textColor = [UIColor whiteColor];
        [_circleControl darkBackground];
        [_chatInput.bgToolbar setBarStyle:UIBarStyleBlackTranslucent];
        _chatInput.textView.keyboardAppearance = UIKeyboardAppearanceDark;
    } else {
        [self.view setBackgroundColor:[UIColor whiteColor]];
        [self.storiesTableView setBackgroundColor:[UIColor whiteColor]];
        [self.detailsTableView setBackgroundColor:[UIColor whiteColor]];
        textColor = [UIColor blackColor];
        [_circleControl lightBackground];
        [_chatInput.bgToolbar setBarStyle:UIBarStyleDefault];
        _chatInput.textView.keyboardAppearance = UIKeyboardAppearanceDefault;
    }
    if (self.view.alpha != 1.0){
        [UIView animateWithDuration:.23 animations:^{
            [self.view setAlpha:1.0];
        }];
    }
}

- (void)setupChat {
    _chatInput = [[XXChat alloc]init];
    _chatInput.stopAutoClose = NO;
    _chatInput.placeholderLabel.text = @"    Add your thoughts...";
    _chatInput.delegate = self;
    _chatInput.backgroundColor = [UIColor colorWithWhite:1 alpha:0.725f];
    
    UICollectionViewFlowLayout *flow = [[UICollectionViewFlowLayout alloc]init];
    flow.sectionInset = UIEdgeInsetsMake(0, 0, 0, 0);
    flow.scrollDirection = UICollectionViewScrollDirectionVertical;
    flow.minimumLineSpacing = 6;
    
    CGRect chatFrame = (UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication]statusBarOrientation])) ? CGRectMake(0, 88,screenHeight(), screenWidth() - height(_chatInput) - 88) : CGRectMake(0, 88, screenWidth(), screenHeight() - height(_chatInput) - 88);
    self.collectionView = [[UICollectionView alloc]initWithFrame:chatFrame collectionViewLayout:flow];
    self.collectionView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
    self.collectionView.backgroundColor = [UIColor clearColor];
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    self.collectionView.indicatorStyle = UIScrollViewIndicatorStyleDefault;
    self.collectionView.allowsSelection = YES;
    self.collectionView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self.collectionView registerClass:[XXChatCell class] forCellWithReuseIdentifier:@"ChatCell"];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void)selectedSegment:(XXSegmentedControl*)control {
    switch (control.selectedSegmentIndex) {
        case 0:
            if (self.needsNavigation){
                [[(XXAppDelegate*)[UIApplication sharedApplication].delegate dynamicsDrawerViewController] setPaneState:MSDynamicsDrawerPaneStateOpen inDirection:MSDynamicsDrawerDirectionLeft animated:YES allowUserInterruption:YES completion:nil];
            } else {
                [self.navigationController popViewControllerAnimated:YES];
            }
            break;
        case 1:
            [self reset];
            chat = YES;
            [self hideTableView];
            break;
        case 2:
            [self reset];
            details = YES;
            [self showTableView];
            [self.detailsTableView reloadData];
            break;
        case 3:
            [self reset];
            stories = YES;
            [self showTableView];
            [self.storiesTableView reloadData];
            break;
        default:
            break;
    }
}

- (void)reset {
    chat = NO;
    details = NO;
    stories = NO;
}

- (void)hideTableView {
    [UIView animateWithDuration:.5 delay:0 usingSpringWithDamping:.5 initialSpringVelocity:.0001 options:UIViewAnimationOptionCurveEaseIn animations:^{
        self.collectionView.transform = CGAffineTransformIdentity;
        self.collectionView.alpha = 1.0;
        _chatInput.transform = CGAffineTransformIdentity;
        
        [self.detailsTableView setAlpha:0.0];
        self.detailsTableView.transform = CGAffineTransformMakeScale(.87, .87);
        [self.storiesTableView setAlpha:0.0];
        self.storiesTableView.transform = CGAffineTransformMakeScale(.87, .87);
    } completion:^(BOOL finished) {
        
    }];
}

- (void)showTableView {
    [UIView animateWithDuration:.5 delay:0 usingSpringWithDamping:.5 initialSpringVelocity:.0001 options:UIViewAnimationOptionCurveEaseIn animations:^{
        self.collectionView.transform = CGAffineTransformMakeScale(.87, .87);
        self.collectionView.alpha = 0.0;
        _chatInput.transform = CGAffineTransformMakeTranslation(0, _chatInput.frame.size.height);
        if (details){
            [self.detailsTableView setAlpha:1.0];
            self.detailsTableView.transform = CGAffineTransformIdentity;
            [self.storiesTableView setAlpha:0.0];
            self.storiesTableView.transform = CGAffineTransformMakeScale(.87, .87);
        } else if (stories){
            [self.storiesTableView setAlpha:1.0];
            self.storiesTableView.transform = CGAffineTransformIdentity;
            [self.detailsTableView setAlpha:0.0];
            self.detailsTableView.transform = CGAffineTransformMakeScale(.87, .87);
        }
        
    } completion:^(BOOL finished) {
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (tableView == self.detailsTableView){
        return 2;
    } else {
        return 1;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (details){
        if (section == 0){
            return 3;
        } else {
            return _notifications.count;
        }
    } else {
        if (_circle.stories.count == 0){
            return 1;
        } else {
            return _circle.stories.count;
        }
        
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (details){
        if (indexPath.section == 0){
            XXCircleDetailsCell *cell = (XXCircleDetailsCell *)[tableView dequeueReusableCellWithIdentifier:@"CircleDetailsCell"];
            if (cell == nil) {
                cell = [[[NSBundle mainBundle] loadNibNamed:@"XXCircleDetailsCell" owner:nil options:nil] lastObject];
            }
            [cell configureWithTextColor:textColor];
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
            switch (indexPath.row) {
                case 0:
                    [cell.headingLabel setText:@"WHAT"];
                    [cell.contentLabel setText:_circle.name];
                    break;
                case 1:
                    [cell.headingLabel setText:@"CREATED"];
                    [cell.contentLabel setText:[_detailsFormatter stringFromDate:_circle.createdDate]];
                    break;
                case 2:
                    [cell.headingLabel setText:@"WHO"];
                    [cell.contentLabel setText:[NSString stringWithFormat:@"%@",_circle.members]];
                    break;
                    
                default:
                    break;
            }
            return cell;
        } else {
            XXCircleNotificationCell *cell = (XXCircleNotificationCell *)[tableView dequeueReusableCellWithIdentifier:@"CircleNotificationCell"];
            if (cell == nil) {
                cell = [[[NSBundle mainBundle] loadNibNamed:@"XXCircleNotificationCell" owner:nil options:nil] lastObject];
            }
            XXNotification *notification = [_notifications objectAtIndex:indexPath.row];
            [cell configureNotification:notification];
            [cell.timestamp setTextColor:textColor];
            [cell.timestamp setText:[_formatter stringFromDate:notification.createdAt]];
            [cell.notificationLabel setTextColor:textColor];
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];

            return cell;
        }
    } else {
        XXProfileStoryCell *cell = (XXProfileStoryCell *)[tableView dequeueReusableCellWithIdentifier:@"ProfileStoryCell"];
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"XXProfileStoryCell" owner:nil options:nil] lastObject];
        }
        if (_circle.stories.count == 0){
            [cell.titleLabel setText:@"No stories"];
            [cell.titleLabel setFont:[UIFont fontWithName:kSourceSansProLight size:20]];
            if ([[NSUserDefaults standardUserDefaults] objectForKey:kDarkBackground]){
                [cell.titleLabel setTextColor:textColor];
            } else {
                [cell.titleLabel setTextColor:[UIColor lightGrayColor]];
            }
            [cell.titleLabel setTextAlignment:NSTextAlignmentCenter];
        } else {
            XXStory *story = [_circle.stories objectAtIndex:indexPath.row];
            [cell configureStory:story withTextColor:textColor];
            [cell.titleLabel setTextAlignment:NSTextAlignmentLeft];
            [cell.subtitleLabel setText:[_detailsFormatter stringFromDate:story.updatedDate]];
        }
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    UIView *selectionView = [[UIView alloc] initWithFrame:cell.frame];
    [selectionView setBackgroundColor:[UIColor colorWithWhite:.9 alpha:.23]];
    cell.selectedBackgroundView = selectionView;
    cell.backgroundColor = [UIColor clearColor];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.storiesTableView){
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        [self performSegueWithIdentifier:@"Read" sender:indexPath];
    } else if (tableView == self.detailsTableView){
        if (indexPath.section == 1){
            XXNotification *notification = [_notifications objectAtIndex:indexPath.row];
            if ([notification.type isEqualToString:kCircleComment]){
                [self reset];
                chat = YES;
                [self hideTableView];
            }
        }
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(NSIndexPath*)indexPath {
    [super prepareForSegue:segue sender:indexPath];
    
    if ([segue.identifier isEqualToString:@"Read"]){
        XXStoryViewController *storyVC = [segue destinationViewController];
        XXStory *story = (XXStory*)[_circle.stories objectAtIndex:indexPath.row];
        [storyVC setStory:story];
        [ProgressHUD show:@"Fetching story..."];
        if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
            [UIView animateWithDuration:.23 animations:^{
                [self.view setAlpha:0.0];
            }];
        }
    }
}

#pragma mark - UIBarPositioningDelegate Methods

- (UIBarPosition)positionForBar:(id <UIBarPositioning>)view
{
    return UIBarPositionBottom;
}

#pragma mark COLLECTION VIEW DELEGATE

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout*)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    XXComment *comment = _circle.comments[indexPath.row];
    static int offset = 20;
    
    if (comment.body.length) {
        
        NSMutableDictionary * attributes = [NSMutableDictionary new];
        attributes[NSFontAttributeName] = [UIFont fontWithName:kSourceSansProRegular size:15.0f];
        attributes[NSStrokeColorAttributeName] = [UIColor darkTextColor];
        
        NSAttributedString * attrStr = [[NSAttributedString alloc] initWithString:comment.body
                                                                       attributes:attributes];
        
        int maxTextLabelWidth = UIInterfaceOrientationIsPortrait(self.interfaceOrientation) ? screenWidth()*4/5 - OUTLINE : screenHeight()*4/5 - OUTLINE;
        CGRect rect = [attrStr boundingRectWithSize:CGSizeMake(maxTextLabelWidth, CGFLOAT_MAX)
                                            options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                            context:nil];
        
        comment.rectSize = rect.size;
        
        return CGSizeMake(width(self.collectionView), rect.size.height + offset);
    } else {
        return CGSizeMake(self.collectionView.bounds.size.width, comment.rectSize.height + offset);
    }
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _circle.comments.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    XXChatCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"ChatCell" forIndexPath:indexPath];
    XXComment *comment = [_circle.comments objectAtIndex:indexPath.row];
    [cell drawCell:comment withTextColor:textColor];
    cell.deleteButton.tag = indexPath.row;
    [cell.deleteButton addTarget:self action:@selector(deleteComment:) forControlEvents:UIControlEventTouchUpInside];
    if (currentOrientation == UIInterfaceOrientationPortrait){
        [cell.timestamp setAlpha:0.0];
    } else {
        [cell.timestamp setText:[_formatter stringFromDate:comment.createdDate]];
        [cell.timestamp setAlpha:1.0];
    }
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    XXChatCell *cell = (XXChatCell*)[collectionView cellForItemAtIndexPath:indexPath];
    if (cell.deleteButton.hidden){
        [cell.deleteButton setHidden:NO];
        [UIView animateWithDuration:.2 animations:^{
            [cell.deleteButton setAlpha:1.0];
        } completion:^(BOOL finished) {
            
        }];
    } else {
        [UIView animateWithDuration:.2 animations:^{
            [cell.deleteButton setAlpha:0.0];
        } completion:^(BOOL finished) {
            [cell.deleteButton setHidden:YES];
        }];
    }
}

- (void)deleteComment:(UIButton*)button {
    commentForDeletion = [_circle.comments objectAtIndex:button.tag];
    indexPathForDeletion = [NSIndexPath indexPathForRow:button.tag inSection:0];
    [[[UIAlertView alloc] initWithTitle:@"One sec..." message:@"Are you sure you want to delete this comment?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Delete", nil] show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Delete"] && commentForDeletion){
        [manager DELETE:[NSString stringWithFormat:@"%@/comments/%@,",kAPIBaseUrl,commentForDeletion.identifier] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
            //NSLog(@"success deleting comment: %@",responseObject);
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Failed to delete comment: %@",error.description);
        }];
        [_circle.comments removeObject:commentForDeletion];
        [self.collectionView deleteItemsAtIndexPaths:@[indexPathForDeletion]];
       
    }
    indexPathForDeletion = nil;
    commentForDeletion = nil;
}

#pragma mark Interface Rotation

- (void) willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [_chatInput willRotate];
}
- (void) willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [_chatInput isRotating];
    self.collectionView.frame = (UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) ? CGRectMake(0, 88, screenHeight(), screenWidth() - height(_chatInput) - 88) : CGRectMake(0, 88, screenWidth(), screenHeight() - height(_chatInput) - 88);
    currentOrientation = toInterfaceOrientation;
    [self.collectionView reloadData];
    [self.collectionView.collectionViewLayout invalidateLayout];
}
- (void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [_chatInput didRotate];
    [self scrollToBottom];
}

- (void) chatInputNewMessageSent:(NSString *)messageString {
    NSMutableDictionary *commentDict = [NSMutableDictionary dictionary];
    [commentDict setObject:messageString forKey:@"body"];
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsPicSmall]){
        [commentDict setObject:@{@"id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId],@"pen_name":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsPenName],@"pic_small_url":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsPicSmall]} forKey:@"user"];
    } else {
        [commentDict setObject:@{@"id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId],@"pen_name":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsPenName],} forKey:@"user"];
    }
    
    XXComment *newComment = [[XXComment alloc] initWithDictionary:commentDict];
    [self addNewComment:newComment];
}

#pragma mark ADD NEW MESSAGE

- (void) addNewComment:(XXComment *)comment {
    if (_circle.identifier && comment.body.length){
        sent = YES;
        if (_circle.comments == nil)  _circle.comments = [NSMutableArray array];
        [_circle.comments addObject:comment];
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        [parameters setObject:_circle.identifier forKey:@"circle_id"];
        [parameters setObject:comment.body forKey:@"body"];
        [parameters setObject:comment.user.identifier forKey:@"user_id"];
        [parameters setObject:@"circle" forKey:@"comment_type"];
        
        [manager POST:[NSString stringWithFormat:@"%@/comments",kAPIBaseUrl] parameters:@{@"comment":parameters} success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"success posting circle comment: %@",responseObject);
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Error posting circle comment: %@",error.description);
        }];
        [self.collectionView insertItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:_circle.comments.count-1 inSection:0]]];
        [self scrollToBottom];
    }
}

#pragma mark KEYBOARD NOTIFICATIONS

- (void) keyboardWillShow:(NSNotification *)note {
    
    if (!_chatInput.shouldIgnoreKeyboardNotifications) {
        
        NSDictionary *keyboardAnimationDetail = [note userInfo];
        UIViewAnimationCurve animationCurve = [keyboardAnimationDetail[UIKeyboardAnimationCurveUserInfoKey] integerValue];
        CGFloat duration = [keyboardAnimationDetail[UIKeyboardAnimationDurationUserInfoKey] floatValue];
        
        NSValue* keyboardFrameBegin = [keyboardAnimationDetail valueForKey:UIKeyboardFrameEndUserInfoKey];
        CGRect keyboardFrameBeginRect = [keyboardFrameBegin CGRectValue];
        int keyboardHeight = (UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication]statusBarOrientation])) ? keyboardFrameBeginRect.size.height : keyboardFrameBeginRect.size.width;
        
        self.collectionView.scrollEnabled = NO;
        self.collectionView.decelerationRate = UIScrollViewDecelerationRateFast;
        [UIView animateWithDuration:duration delay:0.0 options:(animationCurve << 16) animations:^{
            if (UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication]statusBarOrientation])){
                _circleControl.transform = CGAffineTransformMakeTranslation(0, -88);
                self.collectionView.frame = CGRectMake(0, 20, screenHeight(), screenWidth() - height(_chatInput) - keyboardHeight - 20);
            } else {
                self.collectionView.frame = CGRectMake(0, 88, screenWidth(), screenHeight() - height(_chatInput) - keyboardHeight - 88);
            }
            
        } completion:^(BOOL finished) {

                [self scrollToBottom];
                self.collectionView.scrollEnabled = YES;
                self.collectionView.decelerationRate = UIScrollViewDecelerationRateNormal;
            
        }];
    }
}

- (void) keyboardWillHide:(NSNotification *)note {
    
    if (!_chatInput.shouldIgnoreKeyboardNotifications) {
        NSDictionary *keyboardAnimationDetail = [note userInfo];
        UIViewAnimationCurve animationCurve = [keyboardAnimationDetail[UIKeyboardAnimationCurveUserInfoKey] integerValue];
        CGFloat duration = [keyboardAnimationDetail[UIKeyboardAnimationDurationUserInfoKey] floatValue];
        
        self.collectionView.scrollEnabled = NO;
        self.collectionView.decelerationRate = UIScrollViewDecelerationRateFast;
        [UIView animateWithDuration:duration delay:0.0 options:(animationCurve << 16) animations:^{
            self.collectionView.frame = (UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication]statusBarOrientation])) ? CGRectMake(0, 88, screenHeight(), screenWidth() - height(_chatInput) - 88) : CGRectMake(0, 88, screenWidth(), screenHeight() - height(_chatInput) - 88);
            _circleControl.transform = CGAffineTransformIdentity;
        } completion:^(BOOL finished) {
            if (finished) {
                self.collectionView.scrollEnabled = YES;
                self.collectionView.decelerationRate = UIScrollViewDecelerationRateNormal;
                if (sent)[self scrollToBottom];
                sent = NO;
            }
        }];
    }
}

#pragma mark COLLECTION VIEW METHODS

- (void) scrollToBottom {
    if (_circle.comments.count > 0) {
        static NSInteger section = 0;
        NSInteger item = [self collectionView:self.collectionView numberOfItemsInSection:section] - 1;
        if (item < 0) item = 0;
        NSIndexPath *lastIndexPath = [NSIndexPath indexPathForItem:item inSection:section];
        [self.collectionView scrollToItemAtIndexPath:lastIndexPath atScrollPosition:UICollectionViewScrollPositionBottom animated:YES];
    }
}

@end

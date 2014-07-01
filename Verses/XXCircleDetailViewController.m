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
#import "XXManageCircleViewController.h"

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
    Comment *commentForDeletion;
    NSIndexPath *indexPathForDeletion;
    UIInterfaceOrientation currentOrientation;
    NSMutableArray *_comments;
    NSMutableArray *_stories;
}

@end
//static int connectionStatusViewTag = 1701

@implementation XXCircleDetailViewController

@synthesize circle = _circle;
@synthesize circleId = _circleId;

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
    _circleControl = [[XXSegmentedControl alloc] initWithItems:@[@"Back",storyCount,@"Details",@"Chat"]];
    _circleControl.delegate = self;
    _circleControl.selectedSegmentIndex = 1;
    _circleControl.showsCount = NO;
    _circleControl.showsNavigationArrow = YES;
    
    [_circleControl addTarget:self action:@selector(selectSegment:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:_circleControl];
    [_circleControl setFrame:CGRectMake(0, 20, 320, 48)];
    
    _detailsFormatter = [[NSDateFormatter alloc] init];
    [_detailsFormatter setLocale:[NSLocale currentLocale]];
    [_detailsFormatter setDateFormat:@"MMM, d  |  h:mm a"];
    _formatter = [[NSDateFormatter alloc] init];
    [_formatter setLocale:[NSLocale currentLocale]];
    [_formatter setDateFormat:@"MMM, d\nh:mm a"];
    
    if (_circleId){
        [self loadDetails:_circleId];
    } else if (_comments.count == 0){
        [self loadDetails:_circle.identifier];
    } else {
        [self loadCircleNotifications];
    }
    _comments = _circle.comments.array.mutableCopy;
    _stories = _circle.stories.array.mutableCopy;
    
    if (!_chatInput){
        [self setupChat];
        [self.view addSubview:self.collectionView];
        [self.view addSubview:_chatInput];
    }
    [self.view bringSubviewToFront:self.storiesTableView];
    [self scrollToBottom];
    
    //show stories by default
    [self reset];
    stories = YES;
    [self showTableView];
    
    self.detailsTableView.rowHeight = 60;
    self.storiesTableView.rowHeight = 80;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deleteCircle) name:@"DeleteCircle" object:nil];
}

- (void)deleteCircle {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)editCircle{
    XXManageCircleViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"ManageCircle"];
    [vc setCircle:_circle];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    
    [UIView animateWithDuration:.23 animations:^{
        [self.view setAlpha:0.0];
        self.view.transform = CGAffineTransformMakeScale(.77, .77);
    }];
    
    [self presentViewController:nav animated:YES completion:^{
        
    }];
}

- (void)loadDetails:(NSNumber*)identifier {
    [manager GET:[NSString stringWithFormat:@"%@/circles/%@",kAPIBaseUrl,identifier] parameters:@{@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"success getting circle details: %@", responseObject);
        [_circle populateFromDict:[responseObject objectForKey:@"circle"]];
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            _comments = _circle.comments.array.mutableCopy;
            _stories = _circle.stories.array.mutableCopy;
            [self.collectionView reloadData];
            NSString *storyCount;
            if (_stories.count == 1){
                storyCount = @"1 Story";
            } else {
                storyCount = [NSString stringWithFormat:@"%i Stories",_stories.count];
            }
            
            [_circleControl setTitle:storyCount withImage:nil forSegmentAtIndex:1];
            
            if (stories && _stories.count){
                [self.storiesTableView beginUpdates];
                [self.storiesTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
                [self.storiesTableView endUpdates];
            }
            
        }];
        
        [self loadCircleNotifications];
        [ProgressHUD dismiss];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failed to get cirlce details: %@",error.description);
    }];
}

- (void)loadCircleNotifications {
    [manager GET:[NSString stringWithFormat:@"%@/circles/%@/notifications",kAPIBaseUrl,_circle.identifier] parameters:@{@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"success getting circle notifications: %@", responseObject);
        NSMutableOrderedSet *circleNotifications = [NSMutableOrderedSet orderedSet];
        for (NSDictionary *dict in [responseObject objectForKey:@"notifications"]){
            Notification *notification = [Notification MR_findFirstByAttribute:@"identifier" withValue:[dict objectForKey:@"id"]];
            if (!notification){
                notification = [Notification MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [notification populateFromDict:dict];
            [circleNotifications addObject:notification];
        }
        
        for (Notification *notification in _circle.notifications){
            if (![circleNotifications containsObject:notification]){
                NSLog(@"Deleting a circle notification that no longer exists");
                [notification MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
            }
        }
        _circle.notifications = circleNotifications;

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
            self.view.transform = CGAffineTransformIdentity;
        }];
    }
    
    if ([_circle.owner.identifier isEqualToNumber:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]]){
        UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screenWidth(), 39)];
        [headerView setBackgroundColor:[UIColor clearColor]];
        UIButton *headerButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [headerButton setFrame:CGRectMake(screenWidth()/2-44, 0, 88, 34)];
        headerButton.layer.borderColor = [UIColor colorWithWhite:.5 alpha:.5].CGColor;
        headerButton.layer.borderWidth = .5f;
        [headerButton setBackgroundColor:[UIColor clearColor]];
        [headerButton setTitle:@"Tap to edit" forState:UIControlStateNormal];
        [headerButton.titleLabel setFont:[UIFont fontWithName:kSourceSansProRegular size:13]];
        [headerButton addTarget:self action:@selector(editCircle) forControlEvents:UIControlEventTouchUpInside];
        [headerButton setTitleColor:textColor forState:UIControlStateNormal];
        [headerView addSubview:headerButton];
        self.detailsTableView.tableHeaderView = headerView;
    }
    [self.detailsTableView reloadData];
    [self.storiesTableView reloadData];
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
    
    CGRect chatFrame = (UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication]statusBarOrientation])) ? CGRectMake(0, 68,screenHeight(), screenWidth() - height(_chatInput) - 68) : CGRectMake(0, 68, screenWidth(), screenHeight() - height(_chatInput) - 68);
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

- (void)selectSegment:(XXSegmentedControl*)control {
    switch (control.selectedSegmentIndex) {
        case 0:
            if (self.needsNavigation){
                [[(XXAppDelegate*)[UIApplication sharedApplication].delegate dynamicsDrawerViewController] setPaneState:MSDynamicsDrawerPaneStateOpen inDirection:MSDynamicsDrawerDirectionLeft animated:YES allowUserInterruption:NO completion:^{
                    [_circleControl setSelectedSegmentIndex:1];
                }];
            } else {
                if (self.navigationController.viewControllers.firstObject == self){
                    [[(XXAppDelegate*)[UIApplication sharedApplication].delegate dynamicsDrawerViewController] setPaneState:MSDynamicsDrawerPaneStateOpen inDirection:MSDynamicsDrawerDirectionLeft animated:YES allowUserInterruption:NO completion:^{
                        [_circleControl setSelectedSegmentIndex:1];
                    }];
                } else {
                    [self.navigationController popViewControllerAnimated:YES];
                }
            }
            break;
        case 1:
            [self reset];
            stories = YES;
            [self showTableView];
            [self.storiesTableView reloadData];
            break;
        case 2:
            [self reset];
            details = YES;
            [self showTableView];
            [self.detailsTableView reloadData];
            break;
        case 3:
            [self reset];
            chat = YES;
            [self hideTableView];
            
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
            return _circle.notifications.count;
        }
    } else {
        if (_stories.count == 0){
            return 1;
        } else {
            return _stories.count;
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
            Notification *notification = [_circle.notifications objectAtIndex:indexPath.row];
            [cell configureNotification:notification];
            [cell.timestamp setTextColor:textColor];
            [cell.timestamp setText:[_formatter stringFromDate:notification.createdDate]];
            [cell.notificationLabel setTextColor:textColor];
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];

            return cell;
        }
    } else {
        XXProfileStoryCell *cell = (XXProfileStoryCell *)[tableView dequeueReusableCellWithIdentifier:@"ProfileStoryCell"];
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"XXProfileStoryCell" owner:nil options:nil] lastObject];
        }
        if (_stories.count == 0){
            [cell.textLabel setText:@"No stories"];
            [cell.textLabel setFont:[UIFont fontWithName:kSourceSansProLight size:20]];
            [cell.textLabel setTextAlignment:NSTextAlignmentCenter];
            if ([[NSUserDefaults standardUserDefaults] objectForKey:kDarkBackground]){
                [cell.textLabel setTextColor:textColor];
            } else {
                [cell.textLabel setTextColor:[UIColor lightGrayColor]];
            }
            
        } else {
            Story *story = [_stories objectAtIndex:indexPath.row];
            [cell configureStory:story withTextColor:textColor];
            [cell.titleLabel setTextAlignment:NSTextAlignmentLeft];
            [cell.subtitleLabel setText:[_detailsFormatter stringFromDate:story.updatedDate]];
            [cell.textLabel setText:@""];
        }
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    UIView *selectionView = [[UIView alloc] initWithFrame:cell.frame];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
        [selectionView setBackgroundColor:kTableViewCellSelectionColorDark];
    } else {
        [selectionView setBackgroundColor:kTableViewCellSelectionColor];
    }
    
    cell.selectedBackgroundView = selectionView;
    cell.backgroundColor = [UIColor clearColor];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.storiesTableView){
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        [self performSegueWithIdentifier:@"Read" sender:indexPath];
    } else if (tableView == self.detailsTableView){
        if (indexPath.section == 1){
            Notification *notification = [_circle.notifications objectAtIndex:indexPath.row];
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
        Story *story = (Story*)[_stories objectAtIndex:indexPath.row];
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
    
    Comment *comment = _comments[indexPath.row];
    static int offset = 20;
    
    if (comment.body.length) {
        
        NSMutableDictionary * attributes = [NSMutableDictionary new];
        attributes[NSFontAttributeName] = [UIFont fontWithName:kSourceSansProRegular size:15.0f];
        attributes[NSStrokeColorAttributeName] = [UIColor darkTextColor];
        
        NSAttributedString * attrStr = [[NSAttributedString alloc] initWithString:comment.body
                                                                       attributes:attributes];
        
        int maxTextLabelWidth = UIInterfaceOrientationIsPortrait(self.interfaceOrientation) ? screenWidth()*.75 - OUTLINE : screenHeight()*.75 - OUTLINE;
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
    return _comments.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    XXChatCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"ChatCell" forIndexPath:indexPath];
    Comment *comment = [_comments objectAtIndex:indexPath.row];
    [cell drawCell:comment withTextColor:textColor];
    cell.deleteButton.tag = indexPath.row;
    [cell.deleteButton addTarget:self action:@selector(deleteComment:) forControlEvents:UIControlEventTouchUpInside];
    /*if (currentOrientation == UIInterfaceOrientationPortrait){
        [cell.timestamp setAlpha:0.0];
    } else {*/
        [cell.timestamp setText:[_formatter stringFromDate:comment.createdDate]];
        [cell.timestamp setAlpha:1.0];
    //}
    
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
    commentForDeletion = [_comments objectAtIndex:button.tag];
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
        [_circle removeComment:commentForDeletion];
        _comments = _circle.comments.array.mutableCopy;
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
    self.collectionView.frame = (UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) ? CGRectMake(0, 68, screenHeight(), screenWidth() - height(_chatInput) - 68) : CGRectMake(0, 68, screenWidth(), screenHeight() - height(_chatInput) - 68);
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
    Comment *newComment = [Comment MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
    [newComment populateFromDict:commentDict];
    newComment.createdDate = [NSDate date];
    [self addNewComment:newComment];
}

#pragma mark ADD NEW MESSAGE

- (void) addNewComment:(Comment *)comment {
    if (_circle.identifier && comment.body.length){
        sent = YES;
        [_circle addComment:comment];
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        [parameters setObject:_circle.identifier forKey:@"circle_id"];
        [parameters setObject:comment.body forKey:@"body"];
        [parameters setObject:comment.user.identifier forKey:@"user_id"];
        [parameters setObject:@"circle" forKey:@"comment_type"];
        
        [manager POST:[NSString stringWithFormat:@"%@/comments",kAPIBaseUrl] parameters:@{@"comment":parameters} success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"success posting circle comment: %@",responseObject);
            [comment populateFromDict:responseObject];
            _comments = _circle.comments.array.mutableCopy;
            [self.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:_comments.count-1 inSection:0]]];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Error posting circle comment: %@",error.description);
        }];
        _comments = _circle.comments.array.mutableCopy;
        [self.collectionView insertItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:_comments.count-1 inSection:0]]];
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
                _circleControl.transform = CGAffineTransformMakeTranslation(0, -68);
                self.collectionView.frame = CGRectMake(0, 20, screenHeight(), screenWidth() - height(_chatInput) - keyboardHeight - 20);
            } else {
                self.collectionView.frame = CGRectMake(0, 68, screenWidth(), screenHeight() - height(_chatInput) - keyboardHeight - 68);
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
            self.collectionView.frame = (UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication]statusBarOrientation])) ? CGRectMake(0, 68, screenHeight(), screenWidth() - height(_chatInput) - 68) : CGRectMake(0, 68, screenWidth(), screenHeight() - height(_chatInput) - 68);
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
    if (_comments.count > 0) {
        static NSInteger section = 0;
        NSInteger item = [self collectionView:self.collectionView numberOfItemsInSection:section] - 1;
        if (item < 0) item = 0;
        NSIndexPath *lastIndexPath = [NSIndexPath indexPathForItem:item inSection:section];
        [self.collectionView scrollToItemAtIndexPath:lastIndexPath atScrollPosition:UICollectionViewScrollPositionBottom animated:YES];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self saveContext];
}

- (void)saveContext {
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
        NSLog(@"Saving circle detail information: %u",success);
    }];
}

@end

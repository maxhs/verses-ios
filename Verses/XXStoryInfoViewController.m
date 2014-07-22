//
//  XXStoryInfoViewController.m
//  Verses
//
//  Created by Max Haines-Stiles on 2/25/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import "XXStoryInfoViewController.h"
#import "XXStoryInfoCell.h"
#import "XXLeaveFeedbackCell.h"
#import "XXCommentCell.h"
#import "XXAuthorInfoCell.h"
#import "XXStoryViewController.h"
#import "XXWriteViewController.h"
#import "XXLoginController.h"
#import "XXNoRotateNavController.h"
#import "XXProfileViewController.h"
#import "Feedback+helper.h"
#import "XXFeedbackResponseCell.h"
#import "XXFeedbackResponseTextView.h"

@interface XXStoryInfoViewController () <UITextViewDelegate, UIAlertViewDelegate, UIPopoverControllerDelegate> {
    AFHTTPRequestOperationManager *manager;
    XXAppDelegate *delegate;
    UIButton *cancelFeedback;
    UIButton *sendFeedback;
    UIButton *cancelResponse;
    UIButton *sendResponse;
    UITextView *feedbackTextView;
    BOOL signedIn;
    NSDateFormatter *_formatter;
    NSIndexPath *indexPathForDeletion;
    CGFloat infoHeight;
    CGRect screen;
    User *_currentUser;
    NSTimeInterval duration;
    UIViewAnimationOptions animationCurve;
}
@end

@implementation XXStoryInfoViewController
@synthesize story = _story;

- (void)viewDidLoad {
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    delegate = (XXAppDelegate*)[UIApplication sharedApplication].delegate;
    manager = [delegate manager];
    _formatter= [[NSDateFormatter alloc] init];
    [_formatter setLocale:[NSLocale currentLocale]];
    [_formatter setDateFormat:@"MMM d , h:mm a"];
    screen = [UIScreen mainScreen].bounds;
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]) signedIn = YES;
    else signedIn = NO;
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadStoryInfo:) name:@"ReloadStoryInfo" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reload) name:@"ReloadMenu" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willShowKeyboard:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willHideKeyboard:) name:UIKeyboardWillHideNotification object:nil];
}

-(void)willShowKeyboard:(NSNotification*)notification {
    NSDictionary* keyboardInfo = [notification userInfo];
    NSValue* keyboardFrameBegin = [keyboardInfo valueForKey:UIKeyboardFrameBeginUserInfoKey];
    CGFloat keyboardHeight = [keyboardFrameBegin CGRectValue].size.height;
    duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    animationCurve = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] unsignedIntegerValue];
    [UIView animateWithDuration:duration
                          delay:0
                        options:(animationCurve << 16)
                     animations:^{
                         self.tableView.contentInset = UIEdgeInsetsMake(0, 0, keyboardHeight, 0);
                         self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, keyboardHeight, 0);
                     }
                     completion:NULL];
}

- (void)willHideKeyboard:(NSNotification *)notification
{
    duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    animationCurve = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] unsignedIntegerValue];
    [UIView animateWithDuration:duration
                          delay:0
                        options:(animationCurve << 16)
                     animations:^{
                         self.tableView.contentInset = UIEdgeInsetsZero;
                         self.tableView.scrollIndicatorInsets = UIEdgeInsetsZero;
                     }
                     completion:NULL];
}

- (void)reload{
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
        signedIn = YES;
        if ([delegate currentUser]){
            _currentUser = delegate.currentUser;
        } else {
            _currentUser = [User MR_findFirstByAttribute:@"identifier" withValue:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] inContext:[NSManagedObjectContext MR_defaultContext]];
        }
    } else {
        signedIn = NO;
    }
    [self.tableView reloadData];
}

- (void)reloadStoryInfo:(NSNotification*)notification {
    _story = [notification.userInfo objectForKey:@"story"];
}

- (void)viewWillAppear:(BOOL)animated {
    //[[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    if (self.tableView.alpha != 1.0){
        [UIView animateWithDuration:.23 animations:^{
            [self.tableView setAlpha:1.0];
            [_dynamicsDrawerViewController.view setAlpha:1.0];
            self.tableView.transform = CGAffineTransformIdentity;
        }];
    }
    if (_dynamicsDrawerViewController.paneViewController.view.alpha != 1.0){
        [UIView animateWithDuration:.23 animations:^{
            [_dynamicsDrawerViewController.paneViewController.view setAlpha:1.0];
        } completion:^(BOOL finished) {
            
        }];
    }
    [self.tableView reloadData];
    [super viewWillAppear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (signedIn && _story.feedbacks.count){
        return 3 + _story.feedbacks.count;
    } else {
        return 3;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 1){
        return _story.users.count;
    } else if (section == 0 || section == 2){
        return 1;
    } else {
        Feedback *feedback = [_story.feedbacks objectAtIndex:section-3];
        return feedback.comments.count + 1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0){
        XXStoryInfoCell *cell = (XXStoryInfoCell *)[tableView dequeueReusableCellWithIdentifier:@"StoryInfoCell"];
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"XXStoryInfoCell" owner:nil options:nil] lastObject];
        }
        [cell configureForStory:_story];
        infoHeight = cell.cellHeight;
        [cell.lastUpdatedAt setText:[NSString stringWithFormat:@"Last updated: %@",[_formatter stringFromDate:_story.updatedDate]]];

        return cell;
    } else if (indexPath.section == 1){
        User *author = [_story.users objectAtIndex:indexPath.row];
        XXAuthorInfoCell *cell = (XXAuthorInfoCell *)[tableView dequeueReusableCellWithIdentifier:@"AuthorInfoCell"];
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"XXAuthorInfoCell" owner:nil options:nil] lastObject];
        }
        [cell configureForAuthor:author];
        [cell.authorPhoto setTag:indexPath.row];
        [cell.authorPhoto addTarget:self action:@selector(goToProfile:) forControlEvents:UIControlEventTouchUpInside];
        UIView *selectedView = [[UIView alloc] initWithFrame:cell.frame];
        [selectedView setBackgroundColor:[UIColor colorWithWhite:1 alpha:.5]];
        cell.selectedBackgroundView = selectedView;
        
        return cell;
        
    } else if (indexPath.section == 2) {
        XXLeaveFeedbackCell *cell = (XXLeaveFeedbackCell *)[tableView dequeueReusableCellWithIdentifier:@"LeaveFeedbackCell"];
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"XXLeaveFeedbackCell" owner:nil options:nil] lastObject];
        }
        [cell configure];
        feedbackTextView = cell.feedbackTextView;
        sendFeedback = cell.sendButton;
        cancelFeedback = cell.cancelButton;
        if (signedIn && _story){
            [cell.cancelButton addTarget:self action:@selector(doneEditing) forControlEvents:UIControlEventTouchUpInside];
            [cell.sendButton addTarget:self action:@selector(sendFeedback:) forControlEvents:UIControlEventTouchUpInside];
            [feedbackTextView setUserInteractionEnabled:YES];
            [feedbackTextView setDelegate:self];
        } else {
            [feedbackTextView setUserInteractionEnabled:NO];
        }
        if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
            feedbackTextView.keyboardAppearance = UIKeyboardAppearanceDark;
        } else {
            feedbackTextView.keyboardAppearance = UIKeyboardAppearanceDefault;
        }
        
        return cell;
    } else {
        Feedback *feedback = [_story.feedbacks objectAtIndex:indexPath.section-3];
        if (indexPath.row == feedback.comments.count){
            XXFeedbackResponseCell *cell = (XXFeedbackResponseCell *)[tableView dequeueReusableCellWithIdentifier:@"FeedbackResponseCell"];
            if (cell == nil) {
                cell = [[[NSBundle mainBundle] loadNibNamed:@"XXFeedbackResponseCell" owner:nil options:nil] lastObject];
            }
            [cell configure];
            [cell.feedbackTextView setTag:feedback.identifier.integerValue];
            sendResponse = cell.sendButton;
            cancelResponse = cell.cancelButton;
            
            if (signedIn && _story){
                [cancelResponse addTarget:self action:@selector(doneEditing) forControlEvents:UIControlEventTouchUpInside];
                [sendResponse addTarget:self action:@selector(sendFeedback:) forControlEvents:UIControlEventTouchUpInside];
                [cell.feedbackTextView setUserInteractionEnabled:YES];
                [cell.feedbackTextView setDelegate:self];
            } else {
                [cell.feedbackTextView setUserInteractionEnabled:NO];
            }
            if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
                cell.feedbackTextView.keyboardAppearance = UIKeyboardAppearanceDark;
            } else {
                cell.feedbackTextView.keyboardAppearance = UIKeyboardAppearanceDefault;
            }
            return cell;
        } else {
            XXCommentCell *cell = (XXCommentCell *)[tableView dequeueReusableCellWithIdentifier:@"CommentCell"];
            if (cell == nil) {
                cell = [[[NSBundle mainBundle] loadNibNamed:@"XXCommentCell" owner:nil options:nil] lastObject];
            }
            
            Comment *comment = [feedback.comments objectAtIndex:indexPath.row];
            [cell configureComment:comment];
            [cell.timestampLabel setText:[NSString stringWithFormat:@"- %@  |  %@",comment.user.penName,[_formatter stringFromDate:comment.createdDate]]];
            return cell;
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section > 2){
        Feedback *feedback = [_story.feedbacks objectAtIndex:section-3];
        if (feedback.comments.count){
            return 34;
        } else {
            return 0;
        }
    } else {
        return 0;
    }
}

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section > 2){
        UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 34)];
        [headerLabel setTextColor:[UIColor whiteColor]];
        
        if (IDIOM == IPAD){
            [headerLabel setFont:[UIFont fontWithName:kSourceSansProLight size:16]];
        } else {
            [headerLabel setFont:[UIFont fontWithName:kSourceSansProLight size:15]];
        }
        Feedback *feedback = [_story.feedbacks objectAtIndex:section-3];
        [headerLabel setText:[NSString stringWithFormat:@"FROM:  %@",feedback.user.penName.uppercaseString]];
        [headerLabel setTextAlignment:NSTextAlignmentCenter];
        headerLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        return headerLabel;
    } else {
        UIView *empty = [[UIView alloc] init];
        return empty;
    }
}

- (void)sendFeedback:(id)sender {
    if (signedIn){
        [self doneEditing];
        [ProgressHUD show:@"Sending Feedback..."];
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"user_id"];
        [parameters setObject:_story.identifier forKey:@"story_id"];
    
        XXFeedbackResponseTextView *responseTextView;
        if ([sender isKindOfClass:[XXFeedbackResponseTextView class]]) {
            responseTextView = (XXFeedbackResponseTextView*)sender;
            [parameters setObject:[NSNumber numberWithInteger:responseTextView.tag] forKey:@"feedback_id"];
        }
        
        if (feedbackTextView.text.length && ![feedbackTextView.text isEqualToString:kFeedbackPlaceholder]){
            [parameters setObject:feedbackTextView.text forKey:@"feedback"];
        } else if (responseTextView.text.length && ![responseTextView.text isEqualToString:kFeedbackResponsePlaceholder]) {
            [parameters setObject:responseTextView.text forKey:@"feedback"];
        }
        
        NSLog(@"send feedback parameters: %@",parameters);
        if ([parameters objectForKey:@"feedback"]){
            [manager POST:[NSString stringWithFormat:@"%@/feedbacks",kAPIBaseUrl] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
                //NSLog(@"Success sending feedback: %@",responseObject);
                Feedback *feedback = [Feedback MR_findFirstByAttribute:@"identifier" withValue:[[responseObject objectForKey:@"feedback"] objectForKey:@"id"] inContext:[NSManagedObjectContext MR_defaultContext]];
                if (feedback){
                    [feedback update:[responseObject objectForKey:@"feedback"]];
                } else {
                    feedback = [Feedback MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                    [feedback populateFromDict:[responseObject objectForKey:@"feedback"]];
                }
                
                BOOL new = YES;
                for (Feedback *f in _story.feedbacks) {
                    if ([f.identifier isEqualToNumber:feedback.identifier]){
                        [_story replaceFeedback:feedback];
                        new = NO;
                        [self.tableView reloadData];
                        break;
                    }
                }
                if (new){
                    [_story addFeedback:feedback];
                    [self.tableView reloadData];
                }
                
                [ProgressHUD dismiss];
                
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                NSLog(@"Error sending feedback: %@",error.description);
                [ProgressHUD dismiss];
            }];
        }
        
    }
}

- (void) doneEditing {
    [self.view endEditing:YES];
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
    [UIView animateWithDuration:.25 animations:^{
        if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
            [textView setBackgroundColor:[UIColor clearColor]];
            textView.layer.borderColor = [UIColor whiteColor].CGColor;
            textView.layer.borderWidth = 1.f;
            [textView setTextColor:[UIColor whiteColor]];
        } else {
            [textView setBackgroundColor:[UIColor colorWithWhite:1 alpha:1]];
            [textView setTextColor:[UIColor blackColor]];
        }
        [textView setFont:[UIFont fontWithName:kSourceSansProRegular size:17]];
    }];
    
    if (textView == feedbackTextView){
        [UIView animateWithDuration:.5 delay:0 usingSpringWithDamping:.5 initialSpringVelocity:.0001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            sendFeedback.alpha = 1.0;
            cancelFeedback.alpha = 1.0;
            sendFeedback.transform = CGAffineTransformMakeTranslation(0, 17);
            cancelFeedback.transform = CGAffineTransformMakeTranslation(0, 17);
            feedbackTextView.transform = CGAffineTransformMakeTranslation(0, 27);
        } completion:^(BOOL finished) {
            
        }];
    }/* else {
        [UIView animateWithDuration:.5 delay:0 usingSpringWithDamping:.5 initialSpringVelocity:.0001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            sendResponse.alpha = 1.0;
            cancelResponse.alpha = 1.0;
            sendResponse.transform = CGAffineTransformMakeTranslation(0, 17);
            cancelResponse.transform = CGAffineTransformMakeTranslation(0, 17);
            feedbackResponseTextView.transform = CGAffineTransformMakeTranslation(0, 27);
        } completion:^(BOOL finished) {
            
        }];
    }*/
    
    if ([textView.text isEqualToString:kFeedbackPlaceholder] || [textView.text isEqualToString:kFeedbackResponsePlaceholder]) {
        textView.text = @"";
    }
    if (textView == feedbackTextView){
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:2] atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
    } else if ([textView isKindOfClass:[XXFeedbackResponseTextView class]]){
        __block NSIndexPath *indexPath;
        [_story.feedbacks enumerateObjectsUsingBlock:^(Feedback *feedback, NSUInteger idx, BOOL *stop) {
            if (feedback.identifier.integerValue == textView.tag){
                indexPath = [NSIndexPath indexPathForRow:feedback.comments.count inSection:idx+3];                
                [UIView animateWithDuration:duration
                                      delay:0
                                    options:(animationCurve << 16)
                                 animations:^{
                                    [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
                                 }
                                 completion:NULL];
                *stop = YES;
            }
        }];
    }
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    
    [UIView animateWithDuration:.25 animations:^{
        [textView setBackgroundColor:[UIColor clearColor]];
        if ([textView.text isEqualToString:@""]) {
            if (textView == feedbackTextView){
                textView.text = kFeedbackPlaceholder;
            } else if ([textView isKindOfClass:[XXFeedbackResponseTextView class]]){
                textView.text = kFeedbackResponsePlaceholder;
            }
            [textView setFont:[UIFont fontWithName:kSourceSansProLight size:17]];
        }
        [textView setTextColor:[UIColor whiteColor]];
        
        if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
            textView.layer.borderWidth = 0.f;
        }
    }];
    
    if (textView == feedbackTextView){
        [UIView animateWithDuration:.5 delay:0 usingSpringWithDamping:.5 initialSpringVelocity:.0001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            sendFeedback.alpha = 0;
            cancelFeedback.alpha = 0;
            sendFeedback.transform = CGAffineTransformIdentity;
            cancelFeedback.transform = CGAffineTransformIdentity;
            feedbackTextView.transform = CGAffineTransformIdentity;
        } completion:^(BOOL finished) {
            
        }];
    }/* else {
        [UIView animateWithDuration:.5 delay:0 usingSpringWithDamping:.5 initialSpringVelocity:.0001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            sendResponse.alpha = 0;
            cancelResponse.alpha = 0;
            sendResponse.transform = CGAffineTransformIdentity;
            cancelResponse.transform = CGAffineTransformIdentity;
            feedbackResponseTextView.transform = CGAffineTransformIdentity;
        } completion:^(BOOL finished) {
            
        }];
    }*/
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if ([text isEqualToString:@"\n"]) {
        if ([textView isKindOfClass:[XXFeedbackResponseTextView class]]){
            [self sendFeedback:textView];
        } else {
            [self sendFeedback:nil];
        }
        return NO;
    } else {
        return YES;
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor clearColor];
}

- (void)edit {
    XXWriteViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Write"];
    [vc setStory:_story];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
        [UIView animateWithDuration:.23 animations:^{
            [self.dynamicsDrawerViewController.paneViewController.view setAlpha:0.0];
            [self.tableView setAlpha:0.0];
        }];
    }
    
    [self presentViewController:nav animated:YES completion:nil];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0){
        return 80;
    } else if (indexPath.section == 1){
        return 50;
    } else if (indexPath.section == 2) {
        return 110;
    } else {
        return 90;
    }
}

-(void)goToProfile:(UIButton*)button {
    if (IDIOM == IPAD){
        User *user = [_story.users objectAtIndex:button.tag];
        XXProfileViewController* vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Profile"];
        [vc setStoryInfoVc:self];
        [vc setUser:user];
        self.popover = [[UIPopoverController alloc] initWithContentViewController:vc];
        self.popover.delegate = self;
        XXAuthorInfoCell *cell = (XXAuthorInfoCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:button.tag inSection:1]];
        [self.popover presentPopoverFromRect:cell.frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        
    } else {
        User *user = [_story.users objectAtIndex:button.tag];
        XXProfileViewController* vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Profile"];
        [vc setUser:user];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        [self presentViewController:nav animated:YES completion:^{
            
        }];
    }
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
        [UIView animateWithDuration:.23 animations:^{
            [self.tableView setAlpha:0.0];
            self.tableView.transform = CGAffineTransformMakeScale(.77, .77);
        }];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (!signedIn && indexPath.section == 2){
        [self confirmLoginPrompt];
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    } else if (indexPath.section == 1){
        //[ProgressHUD show:@"Fetching profile..."];
        if (IDIOM == IPAD){
            User *user = [_story.users objectAtIndex:indexPath.row];
            XXProfileViewController* vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Profile"];
            [vc setStoryInfoVc:self];
            [vc setUser:user];
            self.popover = [[UIPopoverController alloc] initWithContentViewController:vc];
            self.popover.delegate = self;
            XXAuthorInfoCell *cell = (XXAuthorInfoCell*)[self.tableView cellForRowAtIndexPath:indexPath];
            [self.popover presentPopoverFromRect:cell.frame inView:self.tableView permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
            [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        } else {
            User *user = [_story.users objectAtIndex:indexPath.row];
            XXProfileViewController* vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Profile"];
            [vc setUser:user];
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
            
            [UIView animateWithDuration:.23 animations:^{
                [_dynamicsDrawerViewController.paneViewController.view setAlpha:0.0];
                [self.tableView setAlpha:0.0];
                
            } completion:^(BOOL finished) {
                
            }];
            
            [self presentViewController:nav animated:YES completion:NULL];
            [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
        }
    }
}

- (void)confirmLoginPrompt {
    [[[UIAlertView alloc] initWithTitle:@"Whoa there." message:@"You'll need to log in if you want to leave feedback." delegate:self cancelButtonTitle:@"No Thanks" otherButtonTitles:@"Login", nil] show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Login"]){
        XXLoginController *login = [[self storyboard] instantiateViewControllerWithIdentifier:@"Login"];
        XXNoRotateNavController *nav = [[XXNoRotateNavController alloc] initWithRootViewController:login];
        [self presentViewController:nav animated:YES completion:^{
            
        }];
    } else if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Delete"]){
       [self deleteComment];
    }
}

- (void)deleteComment {
    Feedback *feedback = [_story.feedbacks objectAtIndex:indexPathForDeletion.section-3];
    Comment *comment = [feedback.comments objectAtIndex:indexPathForDeletion.row];
    [manager DELETE:[NSString stringWithFormat:@"%@/comments/%@",kAPIBaseUrl,comment.identifier] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"Success deleting comment: %@",responseObject);
        [feedback removeComment:comment];
        
        [self.tableView beginUpdates];
        [self.tableView deleteRowsAtIndexPaths:@[indexPathForDeletion] withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView endUpdates];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error deleting comment: %@",error.description);
        [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Something went wrong while trying to delete your feedback. Please try agian soon" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    }];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section >= 3){
        Feedback *feedback = [_story.feedbacks objectAtIndex:indexPath.section-3];
        if (indexPath.row != feedback.comments.count){
            Comment *comment = [feedback.comments objectAtIndex:indexPath.row];
            if (signedIn && comment.user.identifier && [[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] isEqualToNumber:comment.user.identifier]){
                return YES;
            }
        } else {
            return NO;
        }
    }
    return NO;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        indexPathForDeletion = indexPath;
        [[[UIAlertView alloc] initWithTitle:@"Just checking" message:@"Are you sure you want to delete this feedback?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Delete", nil] show];
    }
}

@end

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
#import "XXProfileViewController.h"


@interface XXStoryInfoViewController () <UITextViewDelegate, UIAlertViewDelegate, UIPopoverControllerDelegate> {
    XXStoryViewController *storyVC;
    UIStoryboard *storyboard;
    AFHTTPRequestOperationManager *manager;
    UIButton *cancelFeedback;
    UIButton *sendFeedback;
    UITextView *feedbackTextView;
    BOOL signedIn;
    NSDateFormatter *_formatter;
    NSIndexPath *indexPathForDeletion;
    CGFloat infoHeight;
    CGRect screen;
}

@end

@implementation XXStoryInfoViewController
@synthesize story = _story;
@synthesize feedbacks = _feedbacks;
@synthesize feedback = _feedback;

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone){
        storyboard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle:nil];
    } else {
        storyboard = [UIStoryboard storyboardWithName:@"Main_iPad" bundle:nil];
    }
    manager = [AFHTTPRequestOperationManager manager];
    _formatter= [[NSDateFormatter alloc] init];
    [_formatter setLocale:[NSLocale currentLocale]];
    [_formatter setDateFormat:@"MMM, d  |  HH:mm a"];
    screen = [UIScreen mainScreen].bounds;
}

- (void)viewWillAppear:(BOOL)animated {
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]) signedIn = YES;
    else signedIn = NO;
    UINavigationController *nav = (UINavigationController*)self.dynamicsDrawerViewController.paneViewController;
    if ([nav.viewControllers.lastObject isKindOfClass:[XXStoryViewController class]]){
        storyVC = (XXStoryViewController*)nav.viewControllers.lastObject;
        _story = storyVC.story;
        [self drawStoryInfo];
    }
    
    if (self.tableView.alpha != 1.0){
        [UIView animateWithDuration:.23 animations:^{
            [self.tableView setAlpha:1.0];
            self.tableView.transform = CGAffineTransformIdentity;
            if (storyVC) {
                storyVC.view.transform = CGAffineTransformIdentity;
                [storyVC.view setAlpha:1.0];
            }
        }];
    }
    
    [super viewWillAppear:animated];
}

- (void)drawStoryInfo {
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (signedIn && _feedback){
        return 4;
    } else {
        return 3;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case 0:
        {
            return 1;
        }
            break;
            
        case 1:
        {
            return _story.collaborators.count;
        }
            break;
        case 2:
        {
            return 1;
        }
            break;
        case 3:
        {
            return _feedback.comments.count;
        }
            break;
            
        default:
            return 0;
            break;
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
        [cell.bookmarkButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
        if (signedIn){
            if (_story.bookmarked){
                [cell.bookmarkButton addTarget:self action:@selector(destroyBookmark:) forControlEvents:UIControlEventTouchUpInside];
            } else {
                [cell.bookmarkButton addTarget:self action:@selector(createBookmark:) forControlEvents:UIControlEventTouchUpInside];
            }
        } else {
            [cell.bookmarkButton addTarget:self action:@selector(confirmLoginPrompt) forControlEvents:UIControlEventTouchUpInside];
        }
        
        if ([_story.owner.identifier isEqualToNumber:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]]){
            [cell.editButton addTarget:self action:@selector(edit) forControlEvents:UIControlEventTouchUpInside];
        }
        return cell;
    } else if (indexPath.section == 1){
        XXUser *author = [_story.collaborators objectAtIndex:indexPath.row];

        XXAuthorInfoCell *cell = (XXAuthorInfoCell *)[tableView dequeueReusableCellWithIdentifier:@"AuthorInfoCell"];
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"XXAuthorInfoCell" owner:nil options:nil] lastObject];
        }
        [cell configureForAuthor:author];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
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
            [cell.sendButton addTarget:self action:@selector(sendFeedback) forControlEvents:UIControlEventTouchUpInside];
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
        XXCommentCell *cell = (XXCommentCell *)[tableView dequeueReusableCellWithIdentifier:@"CommentCell"];
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"XXCommentCell" owner:nil options:nil] lastObject];
        }
        XXComment *comment = [_feedback.comments objectAtIndex:indexPath.row];
        [cell configureComment:comment];
        [cell.timestampLabel setText:[_formatter stringFromDate:comment.createdDate]];
        return cell;
    }
}

- (void) sendFeedback {
    if (feedbackTextView.text.length && ![feedbackTextView.text isEqualToString:kFeedbackPlaceholder]){
        [self doneEditing];
        [ProgressHUD show:@"Sending Feedback..."];
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"user_id"];
        [parameters setObject:_story.identifier forKey:@"story_id"];
        [parameters setObject:feedbackTextView.text forKey:@"feedback"];
        [manager POST:[NSString stringWithFormat:@"%@/feedbacks",kAPIBaseUrl] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"Success sending feedback: %@",responseObject);
            _feedback = [[XXFeedback alloc] initWithDictionary:[responseObject objectForKey:@"feedback"]];
            [self.tableView reloadData];
            [ProgressHUD dismiss];
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Error sending feedback: %@",error.description);
            [ProgressHUD dismiss];
        }];
    }
}

- (void)createBookmark:(UIButton*)button {
    if (_story && _story.identifier){
        [button setImage:[UIImage imageNamed:@"bookmarked"] forState:UIControlStateNormal];
        [manager POST:[NSString stringWithFormat:@"%@/bookmarks",kAPIBaseUrl] parameters:@{@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId],@"story_id":_story.identifier} success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"Success creating a bookmark: %@",responseObject);
            [button removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
            [button addTarget:self action:@selector(destroyBookmark:) forControlEvents:UIControlEventTouchUpInside];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Error creating a bookmark: %@",error.description);
        }];
    }
}

- (void)destroyBookmark:(UIButton*)button {
    if (_story && _story.identifier){
        [button setImage:[UIImage imageNamed:@"bookmark"] forState:UIControlStateNormal];
        [manager DELETE:[NSString stringWithFormat:@"%@/bookmarks/%@",kAPIBaseUrl,_story.identifier] parameters:@{@"story_id":_story.identifier,@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"success deleting a bookmark: %@",responseObject);
            [button removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
            [button addTarget:self action:@selector(createBookmark:) forControlEvents:UIControlEventTouchUpInside];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Failed to delete the bookmark: %@",error.description);
        }];
    }
}
- (void) doneEditing {
    [self.view endEditing:YES];
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
    [UIView animateWithDuration:.25 animations:^{
        [textView setBackgroundColor:[UIColor colorWithWhite:1 alpha:1]];
        [textView setTextColor:[UIColor blackColor]];
        [textView setFont:[UIFont fontWithName:kSourceSansProRegular size:17]];
    }];
    
    [UIView animateWithDuration:.5 delay:0 usingSpringWithDamping:.5 initialSpringVelocity:.0001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        sendFeedback.alpha = 1.0;
        cancelFeedback.alpha = 1.0;
        sendFeedback.transform = CGAffineTransformMakeTranslation(0, 10);
        cancelFeedback.transform = CGAffineTransformMakeTranslation(0, 10);
        feedbackTextView.transform = CGAffineTransformMakeTranslation(0, 30);
    } completion:^(BOOL finished) {
        
    }];
    
    if ([textView.text isEqualToString:kFeedbackPlaceholder]) {
        textView.text = @"";
    }
    [self.tableView setContentInset:UIEdgeInsetsMake(0, 0, 216, 0)];
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:2] atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    
    [UIView animateWithDuration:.25 animations:^{
        [textView setBackgroundColor:[UIColor clearColor]];
        if ([textView.text isEqualToString:@""]) {
            textView.text = kFeedbackPlaceholder;
            [textView setFont:[UIFont fontWithName:kSourceSansProLight size:17]];
        }
        [textView setTextColor:[UIColor whiteColor]];
    }];
    
    [UIView animateWithDuration:.5 delay:0 usingSpringWithDamping:.5 initialSpringVelocity:.0001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        sendFeedback.alpha = 0;
        cancelFeedback.alpha = 0;
        sendFeedback.transform = CGAffineTransformIdentity;
        cancelFeedback.transform = CGAffineTransformIdentity;
        feedbackTextView.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        
    }];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor clearColor];
}

- (void)edit {
    XXWriteViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"Write"];
    [vc setStory:_story];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
        [UIView animateWithDuration:.23 animations:^{
            [self.dynamicsDrawerViewController.paneViewController.view setAlpha:0.0];
            [self.tableView setAlpha:0.0];
        }];
    }
    
    [self presentViewController:nav animated:YES completion:^{
        
    }];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0){
        return 80;
    } else if (indexPath.section == 1){
        return 55;
    } else if (indexPath.section == 2) {
        return 102;
    } else {
        return 70;
    }
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (!signedIn && indexPath.section == 2){
        [self confirmLoginPrompt];
    } else if (indexPath.section == 1){
        if (IDIOM == IPAD){
            XXUser *user = [_story.collaborators objectAtIndex:indexPath.row];
            XXProfileViewController* vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Profile"];
            [vc setUser:user];
            self.popover = [[UIPopoverController alloc] initWithContentViewController:vc];
            self.popover.delegate = self;
            
            XXAuthorInfoCell *cell = (XXAuthorInfoCell*)[self.tableView cellForRowAtIndexPath:indexPath];
            CGRect displayFrom = CGRectMake(cell.frame.origin.x, 0/*cell.center.y + self.tableView.frame.origin.y - self.tableView.contentOffset.y*/, screen.size.width/2, screen.size.height/2);
            [self.popover presentPopoverFromRect:displayFrom inView:self.view permittedArrowDirections:UIPopoverArrowDirectionLeft animated:YES];
        } else {
            XXUser *user = [_story.collaborators objectAtIndex:indexPath.row];
            XXProfileViewController* vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Profile"];
            [vc setUser:user];
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
            [self presentViewController:nav animated:YES completion:^{
                
            }];
        }
        if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
            [UIView animateWithDuration:.23 animations:^{
                [self.tableView setAlpha:0.0];
                self.tableView.transform = CGAffineTransformMakeScale(.8, .8);
                if (storyVC) {
                    storyVC.view.transform = CGAffineTransformMakeScale(.8, .8);
                    [storyVC.view setAlpha:0.0];
                }
            }];
        }
    }
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)confirmLoginPrompt {
    [[[UIAlertView alloc] initWithTitle:@"Whoa there." message:@"You'll need to log in if you want to leave feedback." delegate:self cancelButtonTitle:@"No Thanks" otherButtonTitles:@"Login", nil] show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Login"]){
        XXLoginController *login = [storyboard instantiateViewControllerWithIdentifier:@"Login"];
        [self presentViewController:login animated:YES completion:^{
            
        }];
    } else if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Delete"]){
        [self deleteComment];
    }
}

- (void)deleteComment {
    XXComment *comment = [_feedback.comments objectAtIndex:indexPathForDeletion.row];
    [manager DELETE:[NSString stringWithFormat:@"%@/comments/%@",kAPIBaseUrl,comment.identifier] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Success deleting comment: %@",responseObject);
        [_feedback.comments removeObject:comment];
        [self.tableView deleteRowsAtIndexPaths:@[indexPathForDeletion] withRowAnimation:UITableViewRowAnimationFade];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error deleting comment: %@",error.description);
        [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Something went wrong while trying to delete your feedback. Please try agian soon" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    }];
}

- (void)viewDidDisappear:(BOOL)animated {
    _story = nil;
    [self.tableView reloadData];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 3){
        XXComment *comment = [_feedback.comments objectAtIndex:indexPath.row];
        if ([[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] isEqualToNumber:comment.user.identifier]){
            return YES;
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

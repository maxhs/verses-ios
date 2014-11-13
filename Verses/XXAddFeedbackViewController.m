//
//  XXAddFeedbackViewController.m
//  Verses
//
//  Created by Max Haines-Stiles on 5/2/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import "XXAddFeedbackViewController.h"
#import "XXLeaveFeedbackCell.h"
#import "XXLoginController.h"
#import "XXAlert.h"

@interface XXAddFeedbackViewController () {
    UITextView *feedbackTextView;
    CGRect labelRect;
}

@end

@implementation XXAddFeedbackViewController

@synthesize snippet = _snippet;
@synthesize story = _story;
@synthesize contribution = _contribution;
@synthesize storyViewController = _storyViewController;
@synthesize stringLocation = _stringLocation;

- (void)viewDidLoad
{
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    [headerView setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    UIButton *dismissButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [headerView addSubview:dismissButton];
    [dismissButton setFrame:CGRectMake(0, 0, 44, 44)];
    [dismissButton addTarget:self action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
        [dismissButton setImage:[UIImage imageNamed:@"whiteX"] forState:UIControlStateNormal];
    } else {
        [dismissButton setImage:[UIImage imageNamed:@"blackX"] forState:UIControlStateNormal];
    }
    
    UIButton *sendButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [headerView addSubview:sendButton];
    [sendButton setFrame:CGRectMake(screenWidth()-54, 0, 44, 44)];
    [sendButton addTarget:self action:@selector(postFeedback) forControlEvents:UIControlEventTouchUpInside];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
        [sendButton setImage:[UIImage imageNamed:@"sendButton"] forState:UIControlStateNormal];
    } else {
        [sendButton setImage:[UIImage imageNamed:@"sendButtonBlack"] forState:UIControlStateNormal];
    }
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, screenWidth(), 44)];
    [label setFont:[UIFont fontWithName:kCrimsonRoman size:21]];
    [label setText:[NSString stringWithFormat:@"\"%@\"",_snippet]];
    [label setBackgroundColor:[UIColor clearColor]];
    [label setTextColor:_textColor];
    [label setNumberOfLines:0];
    labelRect = [_snippet boundingRectWithSize:CGSizeMake(screenWidth()-40, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:label.font} context:nil];
    
    labelRect.size.height += 56;
    labelRect.origin.x = 20;
    labelRect.origin.y += 24;
    labelRect.size.width = screenWidth()-20;
    [headerView setFrame:CGRectMake(0, 0, screenWidth(), labelRect.size.height)];
    
    [headerView addSubview:label];
    [label setFrame:labelRect];
    
    self.tableView.tableHeaderView = headerView;
    [super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [feedbackTextView becomeFirstResponder];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    XXLeaveFeedbackCell *cell = (XXLeaveFeedbackCell *)[tableView dequeueReusableCellWithIdentifier:@"LeaveFeedbackCell"];
    if (cell == nil) {
        cell = [[[NSBundle mainBundle] loadNibNamed:@"XXLeaveFeedbackCell" owner:nil options:nil] lastObject];
    }
    [cell configure];
    [cell.cancelButton setHidden:YES];
    [cell.sendButton setHidden:YES];
    feedbackTextView = cell.feedbackTextView;
    feedbackTextView.delegate = self;
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (IDIOM == IPAD){
        return screenHeight()-labelRect.size.height-256;
    } else {
        return screenHeight()-labelRect.size.height-216;
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor clearColor];
}

- (void) doneEditing {
    [self.view endEditing:YES];
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
    [UIView animateWithDuration:.25 animations:^{
        if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
            [textView setBackgroundColor:[UIColor clearColor]];
            textView.layer.borderColor = [UIColor colorWithWhite:1 alpha:.27].CGColor;
            textView.layer.borderWidth = .5f;
        } else {
            [textView setBackgroundColor:[UIColor colorWithWhite:1 alpha:1]];
        }
        
        [textView setTextColor:_textColor];
        [textView setFont:[UIFont fontWithName:kSourceSansProRegular size:17]];
    }];
    
    if ([textView.text isEqualToString:kFeedbackPlaceholder]) {
        textView.text = @"";
    }
}

- (void)textViewDidEndEditing:(UITextView *)textView {

    [UIView animateWithDuration:.25 animations:^{
        [textView setBackgroundColor:[UIColor clearColor]];
        if ([textView.text isEqualToString:@""]) {
            textView.text = kFeedbackPlaceholder;
            [textView setFont:[UIFont fontWithName:kSourceSansProLight size:17]];
        }
        [textView setTextColor:_textColor];
    }];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if ([text isEqualToString:@"\n"]) {
        [self postFeedback];
        return NO;
    } else {
        return YES;
    }
}

- (void)postFeedback {
    [self doneEditing];
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
        if (feedbackTextView.text.length){
            NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
            if (_snippet.length){
                [parameters setObject:_snippet forKey:@"snippet"];
            }
            if (_stringLocation){
                [parameters setObject:_stringLocation forKey:@"location"];
            }
            if (_contribution && ![_contribution.identifier isEqualToNumber:[NSNumber numberWithInt:0]]){
                [parameters setObject:_contribution.identifier forKey:@"contribution_id"];
            }
            if (_story && ![_story.identifier isEqualToNumber:[NSNumber numberWithInt:0]]){
                [parameters setObject:_story.identifier forKey:@"story_id"];
            }
            [parameters setObject:feedbackTextView.text forKey:@"feedback"];
            [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"user_id"];
            [[(XXAppDelegate*)[UIApplication sharedApplication].delegate manager] POST:[NSString stringWithFormat:@"%@/feedbacks",kAPIBaseUrl] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
                //NSLog(@"success posting feedback for snippet %@, %@",_snippet, responseObject);
                [self dismiss];
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                NSLog(@"Error posting feedback");
                [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Something went wrong while trying to post your feedback. Please try again soon." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
            }];
        }
    } else {
        XXLoginController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Login"];
        [self presentViewController:vc animated:YES completion:^{
            [XXAlert show:@"You'll need to log in to leave feedback" withTime:2.7f];
        }];
    }
}

- (void)dismiss{
    [UIView animateWithDuration:.23 delay:.23 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [_storyViewController.backgroundImageView setAlpha:0.0];
    } completion:^(BOOL finished) {
        
    }];
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}


@end

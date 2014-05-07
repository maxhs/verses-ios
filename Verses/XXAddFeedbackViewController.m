//
//  XXAddFeedbackViewController.m
//  Verses
//
//  Created by Max Haines-Stiles on 5/2/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import "XXAddFeedbackViewController.h"
#import "XXLeaveFeedbackCell.h"

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
        [sendButton setImage:[UIImage imageNamed:@"sendButton"] forState:UIControlStateNormal];
    }
    //[sendButton setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin];
    
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
    
    NSLog(@"%@ string location",_stringLocation);
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

- (void)postFeedback {
    [self doneEditing];
    if (feedbackTextView.text.length){
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        if (_snippet.length){
            [parameters setObject:_snippet forKey:@"snippet"];
        }
        if (_stringLocation){
            [parameters setObject:_stringLocation forKey:@"location"];
        }
        if (_contribution){
            [parameters setObject:_contribution.identifier forKey:@"contribution_id"];
            [parameters setObject:_contribution.user.identifier forKey:@"recipient_id"];
        }
        [parameters setObject:feedbackTextView.text forKey:@"feedback"];
        [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"user_id"];
        [[(XXAppDelegate*)[UIApplication sharedApplication].delegate manager] POST:[NSString stringWithFormat:@"%@/feedbacks",kAPIBaseUrl] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"success posting feedback for snippet %@, %@",_snippet, responseObject);
            [self dismiss];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Error posting feedback");
            [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Something went wrong while trying to post your feedback. Please try again soon." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
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

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end

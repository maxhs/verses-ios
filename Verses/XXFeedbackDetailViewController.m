//
//  XXFeedbackDetailViewController.m
//  Verses
//
//  Created by Max Haines-Stiles on 3/26/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import "XXFeedbackDetailViewController.h"
#import "XXFeedbackCell.h"
#import "XXCommentCell.h"

@interface XXFeedbackDetailViewController ()

@end

@implementation XXFeedbackDetailViewController

@synthesize feedback = _feedback;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) return 1;
    else return _feedback.comments.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0){
        XXFeedbackCell *cell = (XXFeedbackCell *)[tableView dequeueReusableCellWithIdentifier:@"FeedbackCell"];
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"XXFeedbackCell" owner:nil options:nil] lastObject];
        }
        return cell;
    } else {
        XXCommentCell *cell = (XXCommentCell *)[tableView dequeueReusableCellWithIdentifier:@"CommentCell"];
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"XXCommentCell" owner:nil options:nil] lastObject];
        }
        Comment *comment = [_feedback.comments objectAtIndex:indexPath.row];
        [cell configureComment:comment];
        return cell;
    }
}

@end

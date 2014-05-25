//
//  XXStoriesViewController.m
//  Verses
//
//  Created by Max Haines-Stiles on 10/6/13.
//  Copyright (c) 2013 Verses. All rights reserved.
//

#import "XXStoriesViewController.h"
#import "XXStoryCell.h"
#import "XXStory.h"
#import "XXPhoto.h"
#import "XXContribution.h"
#import "SWTableViewCell.h"
#import "XXStoryViewController.h"

@interface XXStoriesViewController () {
    AFHTTPRequestOperationManager *manager;
    CGRect screen;
    UIBarButtonItem *backButton;
}
@end

@implementation XXStoriesViewController
@synthesize contributions;
@synthesize stories = _stories;

- (void)viewDidLoad
{
    [super viewDidLoad];
    if (self.featured){
        self.title = @"Featured";
    } else {
        self.title = @"Trending";
    }
    manager = [(XXAppDelegate*)[UIApplication sharedApplication].delegate manager];
    screen = [UIScreen mainScreen].bounds;
    self.tableView.rowHeight = screen.size.height/2;
    
    if (!_stories.count){
        [self loadStories];
    }
    [self.tableView setSeparatorColor:[UIColor colorWithWhite:0.25 alpha:0.5]];
    backButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"back"] style:UIBarButtonItemStylePlain target:self action:@selector(back)];
    self.navigationItem.leftBarButtonItem = backButton;
}

- (void)back {
    [[(XXAppDelegate*)[UIApplication sharedApplication].delegate dynamicsDrawerViewController] setPaneState:MSDynamicsDrawerPaneStateOpen inDirection:MSDynamicsDrawerDirectionLeft animated:YES allowUserInterruption:YES completion:^{
        
    }];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
}

- (void)loadStories {
    if (self.featured){
        [manager GET:[NSString stringWithFormat:@"%@/stories/featured",kAPIBaseUrl] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"success loading featured stories: %@",responseObject);
            _stories = [[Utilities storiesFromJSONArray:[responseObject objectForKey:@"stories"]] mutableCopy];
            [self.tableView reloadData];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            [self.tableView reloadData];
            NSLog(@"Failure getting featured: %@",error.description);
        }];
    } else {
        [manager GET:[NSString stringWithFormat:@"%@/stories/trending",kAPIBaseUrl] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"success loading trending stories: %@",responseObject);
            _stories = [[Utilities storiesFromJSONArray:[responseObject objectForKey:@"stories"]] mutableCopy];
            [self.tableView reloadData];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            [self.tableView reloadData];
            NSLog(@"Failure getting trending: %@",error.description);
        }];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    if (toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft || toInterfaceOrientation == UIInterfaceOrientationLandscapeRight) {
        
    }
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSLog(@"stories count: %lu",(unsigned long)_stories.count);
    return _stories.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    XXStoryCell *cell = (XXStoryCell *)[tableView dequeueReusableCellWithIdentifier:@"StoryCell"];
    if (cell == nil) {
        cell = [[[NSBundle mainBundle] loadNibNamed:@"XXStoryCell" owner:nil options:nil] lastObject];
    }
    XXStory *story = [_stories objectAtIndex:indexPath.row];
    [cell configureForStory:story];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self performSegueWithIdentifier:@"Story" sender:indexPath];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor whiteColor];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(NSIndexPath*)indexPath {
    [super prepareForSegue:segue sender:indexPath];
    if ([segue.identifier isEqualToString:@"Story"]){
        XXStory *story = [_stories objectAtIndex:indexPath.row];
        XXStoryViewController *vc = [segue destinationViewController];
        [vc setStory:story];
        [vc setStories:[[(XXAppDelegate*)[UIApplication sharedApplication].delegate menuViewController] stories]];
    }
}

@end

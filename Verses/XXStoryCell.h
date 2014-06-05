//
//  XXStoryCell.h
//  Verses
//
//  Created by Max Haines-Stiles on 10/11/13.
//  Copyright (c) 2013 Verses. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XXContribution.h"
#import "XXStory.h"
#import "XXTextView.h"
#import "XXTextStorage.h"

@interface XXStoryCell : UITableViewCell <UIScrollViewDelegate>
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *countLabel;
@property (weak, nonatomic) IBOutlet UIButton *imageButton;
@property (weak, nonatomic) IBOutlet UILabel *authorLabel;
@property (weak, nonatomic) IBOutlet UIButton *authorPhoto;
@property (weak, nonatomic) IBOutlet UILabel *infoLabel;
@property (weak, nonatomic) IBOutlet UIView *separatorView;
@property (weak, nonatomic) IBOutlet UIImageView *backgroundImageView;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) UITextView *textView;
@property (strong, nonatomic) XXTextView *bodySnippet;
@property (strong, nonatomic) UITapGestureRecognizer *scrollTouch;
- (void)configureForStory:(XXStory*)story withOrientation:(UIInterfaceOrientation)orientation;
- (void)resetCell;
@end

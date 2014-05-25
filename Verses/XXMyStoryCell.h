//
//  XXMyStoryCell.h
//  Verses
//
//  Created by Max Haines-Stiles on 3/16/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XXStory.h"
#import "XXTextView.h"
#import "XXTextStorage.h"

@interface XXMyStoryCell : UITableViewCell <UIScrollViewDelegate,UIGestureRecognizerDelegate>
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIButton *readButton;
@property (weak, nonatomic) IBOutlet UIButton *editButton;
@property (weak, nonatomic) IBOutlet UIImageView *background;
@property (weak, nonatomic) IBOutlet UILabel *wordCountLabel;
@property (weak, nonatomic) IBOutlet UILabel *revealLabel;
@property (weak, nonatomic) IBOutlet UILabel *draftLabel;
@property (weak, nonatomic) IBOutlet UIView *separatorView;
@property (strong, nonatomic) XXTextView *bodySnippet;

- (void)configureForStory:(XXStory*)story textColor:(UIColor*)color;
- (void)swipe;

@end

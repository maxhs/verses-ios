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
#import "XXTextStorage.h"

@interface XXStoryCell : UITableViewCell <UIScrollViewDelegate>
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *bodySnippet;
@property (weak, nonatomic) IBOutlet UIButton *imageButton;
@property (weak, nonatomic) IBOutlet UILabel *authorLabel;
@property (weak, nonatomic) IBOutlet UIButton *authorPhoto;
@property (strong, nonatomic) UITextView *textView;
@property (weak, nonatomic) IBOutlet UILabel *infoLabel;
@property (weak, nonatomic) IBOutlet UIImageView *separatorView;
- (void)configureForStory:(XXStory*)story textColor:(UIColor*)color featured:(BOOL)featured cellHeight:(CGFloat)height;

@end

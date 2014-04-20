//
//  XXWritingCell.h
//  Verses
//
//  Created by Max Haines-Stiles on 11/4/13.
//  Copyright (c) 2013 Verses. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XXTextView.h"
#import "XXTextStorage.h"
#import "XXStory.h"

@interface XXWritingCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UITextField *titleTextField;
@property (strong, nonatomic) UITextView *textView;
- (void)configure:(XXStory*)storyInput withOrientation:(UIInterfaceOrientation)orientation;

@end

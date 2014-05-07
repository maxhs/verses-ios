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

@property (strong, nonatomic) XXTextView *textView;
@property (nonatomic) CGFloat cellHeight;
@property (strong, nonatomic) UIColor *textColor;

@end

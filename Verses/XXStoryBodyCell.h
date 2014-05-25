//
//  XXStoryBodyCell.h
//  Verses
//
//  Created by Max Haines-Stiles on 2/24/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XXTextView.h"

@interface XXStoryBodyCell : UITableViewCell
@property (strong, nonatomic) XXTextView *textView;
@property (strong, nonatomic) NSTextContainer *textContainer;
@end

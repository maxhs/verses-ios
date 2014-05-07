//
//  XXChatCell.h
//  Verses
//
//  Created by Max Haines-Stiles on 4/18/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XXComment.h"
#import "XXTextView.h"

typedef enum {
    kSentByMe,
    kSentByOther,
} SentBy;

@interface XXChatCell : UICollectionViewCell

@property (strong, nonatomic) UIColor *senderColor;
@property (strong, nonatomic) UIColor *myColor;
@property (strong, nonatomic) UIButton *deleteButton;
@property (strong, nonatomic) UILabel *timestamp;
-(void)drawCell:(XXComment*)comment withTextColor:(UIColor*)textColor;
@end

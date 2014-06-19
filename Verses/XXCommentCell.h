//
//  XXCommentCell.h
//  Verses
//
//  Created by Max Haines-Stiles on 3/28/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Comment.h"

@interface XXCommentCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *userLabel;
@property (weak, nonatomic) IBOutlet UILabel *timestampLabel;
@property (weak, nonatomic) IBOutlet UILabel *commentLabel;
@property (weak, nonatomic) IBOutlet UIView *separatorView;

-(void)configureComment:(Comment*)comment;
@end

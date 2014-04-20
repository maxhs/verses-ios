//
//  XXCommentCell.h
//  Verses
//
//  Created by Max Haines-Stiles on 3/28/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XXComment.h"

@interface XXCommentCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *userLabel;
@property (weak, nonatomic) IBOutlet UILabel *timestampLabel;
@property (weak, nonatomic) IBOutlet UILabel *commentLabel;
-(void)configureComment:(XXComment*)comment;
@end

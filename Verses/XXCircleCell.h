//
//  XXCircleCell.h
//  Verses
//
//  Created by Max Haines-Stiles on 3/16/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XXCircle.h"

@interface XXCircleCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *circleName;
@property (weak, nonatomic) IBOutlet UILabel *infoLabel;
@property (weak, nonatomic) IBOutlet UIImageView *separatorView;
@property (weak, nonatomic) IBOutlet UILabel *unreadLabel;
- (void)configureCell:(XXCircle*)circle withTextColor:(UIColor*)textColor;
@end

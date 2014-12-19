//
//  XXProfileCell.h
//  Verses
//
//  Created by Max Haines-Stiles on 4/14/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "User+helper.h"

@interface XXProfileCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIButton *imageButton;
@property (weak, nonatomic) IBOutlet UIImageView *background;
@property (weak, nonatomic) IBOutlet UIImageView *blurredBackground;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *locationLabel;
@property (weak, nonatomic) IBOutlet UILabel *bioLabel;
@property (weak, nonatomic) IBOutlet UILabel *dayJobLabel;
@property (weak, nonatomic) IBOutlet UILabel *nightJobLabel;
@property (weak, nonatomic) IBOutlet UIButton *subscribeButton;
- (void)configureForUser:(User*)user;
@end

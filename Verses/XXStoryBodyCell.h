//
//  XXStoryBodyCell.h
//  Verses
//
//  Created by Max Haines-Stiles on 2/24/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface XXStoryBodyCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *bodySnippet;
@property (weak, nonatomic) IBOutlet UIButton *imageButton;
@end

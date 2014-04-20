//
//  XXCircleDetailsCell.h
//  Verses
//
//  Created by Max Haines-Stiles on 4/18/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface XXCircleDetailsCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *headingLabel;
@property (weak, nonatomic) IBOutlet UILabel *contentLabel;

- (void)configureWithTextColor:(UIColor*)textColor;
@end

//
//  XXMenuCell.h
//  Verses
//
//  Created by Max Haines-Stiles on 3/23/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface XXMenuCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *menuImage;
@property (weak, nonatomic) IBOutlet UILabel *menuLabel;
@property (weak, nonatomic) IBOutlet UILabel *alertLabel;
- (void)configureAlert:(NSInteger)alertCount;
@end

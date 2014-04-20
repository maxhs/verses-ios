//
//  XXProfileStoryCell.h
//  Verses
//
//  Created by Max Haines-Stiles on 4/14/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface XXProfileStoryCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

- (void)configureStory:(XXStory*)story withTextColor:(UIColor*)textColor;
@end

//
//  XXSearchCell.h
//  Verses
//
//  Created by Max Haines-Stiles on 3/24/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XXStory.h"

@interface XXSearchCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *storyTitle;
@property (weak, nonatomic) IBOutlet UILabel *authorLabel;
- (void)configure:(XXStory*)story;
@end

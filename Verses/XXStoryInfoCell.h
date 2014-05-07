//
//  XXStoryInfoCell.h
//  Verses
//
//  Created by Max Haines-Stiles on 2/25/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XXStory.h"

@interface XXStoryInfoCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *storyTitle;
@property (weak, nonatomic) IBOutlet UILabel *viewsLabel;
@property (weak, nonatomic) IBOutlet UILabel *lastUpdatedAt;
@property CGFloat cellHeight;
- (void)configureForStory:(XXStory*)story;
@end

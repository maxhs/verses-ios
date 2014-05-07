//
//  XXWritingTitleCell.h
//  Verses
//
//  Created by Max Haines-Stiles on 4/24/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface XXWritingTitleCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UITextField *titleTextField;
- (void)configure:(XXStory*)storyInput withOrientation:(UIInterfaceOrientation)orientation;
@end

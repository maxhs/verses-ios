//
//  XXAuthorInfoCell.h
//  Verses
//
//  Created by Max Haines-Stiles on 3/29/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XXUser.h"
#import "XXStory.h"

@interface XXAuthorInfoCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *authorLabel;
@property (weak, nonatomic) IBOutlet UILabel *storiesCount;
@property (weak, nonatomic) IBOutlet UIButton *authorPhoto;
-(void)configureForAuthor:(XXUser*)author;
@end

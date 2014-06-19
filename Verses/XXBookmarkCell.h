//
//  XXBookmarkCell.h
//  Verses
//
//  Created by Max Haines-Stiles on 3/26/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Bookmark.h"

@interface XXBookmarkCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *bookmarkLabel;
@property (weak, nonatomic) IBOutlet UILabel *createdLabel;
@property (weak, nonatomic) IBOutlet UIImageView *separatorView;
- (void)configureBookmark:(Bookmark*)bookmark;
@end

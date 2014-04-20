//
//  XXStoryInfoCell.m
//  Verses
//
//  Created by Max Haines-Stiles on 2/25/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import "XXStoryInfoCell.h"

@implementation XXStoryInfoCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)configureForStory:(XXStory*)story {
    [self.storyTitle setText:story.title];
    [self.storyTitle setFont:[UIFont fontWithName:kSourceSansProSemibold size:23]];
    [self.lastUpdatedAt setFont:[UIFont fontWithName:kSourceSansProLight size:15]];
    
    if ([story.owner.identifier isEqualToNumber:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]]){
        [self.bookmarkButton setHidden:YES];
        [self.editButton setHidden:NO];
        [self.editButton.titleLabel setFont:[UIFont fontWithName:kSourceSansProRegular size:17]];
    } else {
        [self.editButton setHidden:YES];
        [self.bookmarkButton setHidden:NO];
        if (story.bookmarked == YES){
            [self.bookmarkButton setImage:[UIImage imageNamed:@"bookmarked"] forState:UIControlStateNormal];
        } else {
            [self.bookmarkButton setImage:[UIImage imageNamed:@"bookmark"] forState:UIControlStateNormal];
        }
    }
    
    if (story.views){
        [self.viewsLabel setText:[NSString stringWithFormat:@"%@ views",story.views]];
        [self.viewsLabel setFont:[UIFont fontWithName:kSourceSansProLight size:17]];
    }
}

@end

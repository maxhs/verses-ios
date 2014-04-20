//
//  XXAuthorInfoCell.m
//  Verses
//
//  Created by Max Haines-Stiles on 3/29/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import "XXAuthorInfoCell.h"
#import <SDWebImage/UIButton+WebCache.h>

@implementation XXAuthorInfoCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(void)configureForAuthor:(XXUser*)author {
    [self.authorLabel setText:author.penName];
    [self.authorLabel setFont:[UIFont fontWithName:kSourceSansProLight size:19]];
    [self.storiesCount setText:[NSString stringWithFormat:@"%@ stories",author.storyCount]];
    [self.storiesCount setFont:[UIFont fontWithName:kCrimsonRoman size:16]];
    [self.authorPhoto.titleLabel setFont:[UIFont fontWithName:kSourceSansProLight size:12]];
    [self.authorPhoto.titleLabel setNumberOfLines:0];
    self.authorPhoto.layer.cornerRadius = 20.f;
    self.authorPhoto.clipsToBounds = YES;
    if (author.picSmallUrl.length){
        [self.authorPhoto setTitle:@"" forState:UIControlStateNormal];
        self.authorPhoto.layer.borderWidth = 0.f;
        [self.authorPhoto setImageWithURL:[NSURL URLWithString:author.picSmallUrl] forState:UIControlStateNormal completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
            [UIView animateWithDuration:.25 animations:^{
                [self.authorPhoto setAlpha:1.0];
            }];
        }];
    } else {
        self.authorPhoto.layer.cornerRadius = 20.f;
        [self.authorPhoto setImage:nil forState:UIControlStateNormal];
        [self.authorPhoto setTitle:[author.penName substringWithRange:NSMakeRange(0, 2)].uppercaseString forState:UIControlStateNormal];
        [self.authorPhoto.titleLabel setTextAlignment:NSTextAlignmentCenter];
        self.authorPhoto.layer.borderColor = [UIColor colorWithWhite:1 alpha:.1].CGColor;
        self.authorPhoto.layer.borderWidth = 1.f;
        [UIView animateWithDuration:.25 animations:^{
            [self.authorPhoto setAlpha:1.0];
        }];
    }
}

@end

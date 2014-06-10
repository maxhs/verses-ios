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

-(void)configureForAuthor:(User*)author {
    [_authorLabel setText:author.penName];
    [_authorLabel setFont:[UIFont fontWithName:kSourceSansProLight size:19]];

    [_authorPhoto.titleLabel setFont:[UIFont fontWithName:kSourceSansProLight size:12]];
    [_authorPhoto.titleLabel setNumberOfLines:0];
    _authorPhoto.layer.cornerRadius = 20.f;
    _authorPhoto.clipsToBounds = YES;
    if (author.picSmall.length){
        [_authorPhoto setTitle:@"" forState:UIControlStateNormal];
        _authorPhoto.layer.borderWidth = 0.f;
        [_authorPhoto setImageWithURL:[NSURL URLWithString:author.picSmall] forState:UIControlStateNormal completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
            [UIView animateWithDuration:.25 animations:^{
                [_authorPhoto setAlpha:1.0];
            }];
        }];
    } else {
        _authorPhoto.layer.cornerRadius = 20.f;
        [_authorPhoto setImage:nil forState:UIControlStateNormal];
        [_authorPhoto setTitle:[author.penName substringWithRange:NSMakeRange(0, 2)].uppercaseString forState:UIControlStateNormal];
        [_authorPhoto.titleLabel setTextAlignment:NSTextAlignmentCenter];
        _authorPhoto.layer.borderColor = [UIColor colorWithWhite:1 alpha:.1].CGColor;
        _authorPhoto.layer.borderWidth = 1.f;
        [UIView animateWithDuration:.25 animations:^{
            [_authorPhoto setAlpha:1.0];
        }];
    }
}

@end

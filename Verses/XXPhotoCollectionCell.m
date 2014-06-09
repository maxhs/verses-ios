//
//  XXPhotoCollectionCell.m
//  Verses
//
//  Created by Max Haines-Stiles on 6/8/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import "XXPhotoCollectionCell.h"
#import <SDWebImage/UIButton+WebCache.h>
@implementation XXPhotoCollectionCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

-(void)configureForPhoto:(Photo*)photo{
    [_photoButton setBackgroundColor:[UIColor clearColor]];
    [_photoButton setImageWithURL:[NSURL URLWithString:photo.mediumUrl] forState:UIControlStateNormal];
    _photoButton.imageView.contentMode = UIViewContentModeScaleAspectFill;
    _photoButton.imageView.clipsToBounds = YES;
    _photoButton.layer.shouldRasterize = YES;
    _photoButton.layer.rasterizationScale = [UIScreen mainScreen].scale;
}

@end

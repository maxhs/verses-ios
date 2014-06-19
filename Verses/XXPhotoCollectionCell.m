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
@synthesize photo = _photo;
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
    _photo = photo;
    [_photoButton setBackgroundColor:[UIColor clearColor]];
    if (!_photoButton.imageView.image)[_photoButton setAlpha:0.0];
    [_photoButton setImageWithURL:[NSURL URLWithString:photo.mediumUrl] forState:UIControlStateNormal completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
        [UIView animateWithDuration:.3 animations:^{
            [_photoButton setAlpha:1.0];
        }];
    }];
    _photoButton.imageView.contentMode = UIViewContentModeScaleAspectFill;
    _photoButton.imageView.clipsToBounds = YES;
    _photoButton.layer.shouldRasterize = YES;
    _photoButton.layer.rasterizationScale = [UIScreen mainScreen].scale;
}

@end

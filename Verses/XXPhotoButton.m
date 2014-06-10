//
//  XXPhotoButton.m
//  Verses
//
//  Created by Max Haines-Stiles on 3/29/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import "XXPhotoButton.h"
#import <SDWebImage/UIButton+WebCache.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import "UIImage+ImageEffects.h"

@implementation XXPhotoButton {
    Story *_story;
    Photo *_photo;
    UIViewController *_vc;
    NSMutableArray *browserPhotos;
    XXAppDelegate *delegate;
}

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

- (void)initializeWithPhoto:(Photo*)photo forStory:(Story*)story inVC:(UIViewController *)vc{
    _story = story;
    _photo = photo;
    _vc = vc;
    delegate = (XXAppDelegate*)[UIApplication sharedApplication].delegate;
    __weak typeof(self) weakSelf = self;
    [weakSelf setAlpha:0.0];
    [weakSelf setImageWithURL:[NSURL URLWithString:photo.largeUrl] forState:UIControlStateNormal completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
        [UIView animateWithDuration:.27 animations:^{
            [weakSelf setAlpha:1.0];
            
            if ([[(NSURL*)[delegate backgroundURL] absoluteString] isEqualToString:[[NSURL URLWithString:photo.largeUrl] absoluteString]] || delegate.loadingBackground){
                NSLog(@"Background image already set");
            } else {
                delegate.loadingBackground = YES;
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    
                    [delegate.windowBackground setContentMode:UIViewContentModeScaleAspectFill];
                    UIImage *blurred;
                    if (IDIOM == IPAD){
                        blurred = [image applyBlurWithRadius:39 blurType:BOXFILTER tintColor:[UIColor colorWithWhite:0 alpha:.53] saturationDeltaFactor:1.8 maskImage:nil];
                    } else {
                        blurred = [image applyBlurWithRadius:39 blurType:BOXFILTER tintColor:[UIColor colorWithWhite:0 alpha:.43] saturationDeltaFactor:1.8 maskImage:nil];
                    }
                    dispatch_async(dispatch_get_main_queue(), ^{
                        CATransition *transition = [CATransition animation];
                        transition.duration = 1.0f;
                        transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
                        transition.type = kCATransitionFade;
                        
                        [UIView transitionWithView:[(XXAppDelegate*)[UIApplication sharedApplication].delegate windowBackground] duration:1 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
                            [[(XXAppDelegate*)[UIApplication sharedApplication].delegate windowBackground] setImage:blurred];
                        } completion:^(BOOL finished) {
                            [(XXAppDelegate*)[UIApplication sharedApplication].delegate setBackgroundURL:[NSURL URLWithString:photo.largeUrl]];
                            delegate.loadingBackground = NO;
                        }];
                    });
                });
            }
        }];
    }];
    

}
@end

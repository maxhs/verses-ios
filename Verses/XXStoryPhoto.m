//
//  XXPhotoButton.m
//  Verses
//
//  Created by Max Haines-Stiles on 3/29/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import "XXStoryPhoto.h"
#import <SDWebImage/UIButton+WebCache.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import "UIImage+ImageEffects.h"

@implementation XXStoryPhoto {
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
        [self setBackgroundColor:[UIColor clearColor]];
        self.clipsToBounds = NO;
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

- (void)initializeWithPhoto:(Photo*)photo forStory:(Story*)story inVC:(UIViewController *)vc withButton:(BOOL)withButton{
    _story = story;
    _photo = photo;
    _vc = vc;
    delegate = (XXAppDelegate*)[UIApplication sharedApplication].delegate;
    [self addProgressView];
    
    if (withButton){
        _button = [UIButton buttonWithType:UIButtonTypeCustom];
        [_button setFrame:self.frame];
        [_button.imageView setContentMode:UIViewContentModeScaleAspectFill];
        _button.clipsToBounds = YES;
        [_button setAlpha:0.0];
        [_button setBackgroundColor:[UIColor clearColor]];
        [_button setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
        [self addSubview:_button];
    } else {
        _imageView = [[UIImageView alloc] initWithFrame:self.frame];
        [_imageView setContentMode:UIViewContentModeScaleAspectFill];
        _imageView.clipsToBounds = YES;
        [_imageView setAlpha:0.0];
        [_imageView setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
        [self addSubview:_imageView];
    }
    
    SDWebImageManager *manager = [SDWebImageManager sharedManager];
    
    if (photo.image){
        if (withButton){
            [_button setImage:photo.image forState:UIControlStateNormal];
        } else {
            [_imageView setImage:photo.image];
        }
        [UIView animateWithDuration:.27 animations:^{
            if (withButton){
                [_button setAlpha:1.0];
            } else {
                [_imageView setAlpha:1.0];
            }
            
        } completion:^(BOOL finished) {
        }];
        
        if ([[(NSURL*)[delegate backgroundURL] absoluteString] isEqualToString:[[NSURL URLWithString:photo.largeUrl] absoluteString]] || delegate.loadingBackground){
            //NSLog(@"Background image already set");
        } else {
            delegate.loadingBackground = YES;
            [self appBackground:photo forImage:photo.image];
        }
    } else {
        [manager downloadWithURL:[NSURL URLWithString:photo.largeUrl] options:0 progress:^(NSInteger receivedSize, NSInteger expectedSize) {
            _progressView.progress = ((CGFloat)receivedSize / (CGFloat)expectedSize);
           
        } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished) {
            if (withButton){
                [_button setImage:image forState:UIControlStateNormal];
            } else {
                [_imageView setImage:image];
            }
            
            [UIView animateWithDuration:.27 animations:^{
                [_progressView setAlpha:0.0];
                if (withButton){
                    [_button setAlpha:1.0];
                } else {
                    [_imageView setAlpha:1.0];
                }
                if ([[(NSURL*)[delegate backgroundURL] absoluteString] isEqualToString:[[NSURL URLWithString:photo.largeUrl] absoluteString]] || delegate.loadingBackground){
                    NSLog(@"Background image already set");
                }/* else if (delegate.currentUser.backgroundImageView) {
                    NSLog(@"User already has a background image");
                }*/ else {
                    delegate.loadingBackground = YES;
                    [self appBackground:photo forImage:image];
                }
            } completion:^(BOOL finished) {
                [_progressView removeFromSuperview];
            }];
        }];
    }
}

- (void)appBackground:(Photo*)photo forImage:(UIImage*)image {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        [delegate.windowBackground setContentMode:UIViewContentModeScaleAspectFill];
        UIImage *blurred;
        if (IDIOM == IPAD){
            blurred = [image applyBlurWithRadius:27 blurType:BOXFILTER tintColor:[UIColor colorWithWhite:0 alpha:.43] saturationDeltaFactor:1.8 maskImage:nil];
        } else {
            blurred = [image applyBlurWithRadius:33 blurType:BOXFILTER tintColor:[UIColor colorWithWhite:.23 alpha:.37] saturationDeltaFactor:1.8 maskImage:nil];
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

- (void)addProgressView {
    if (!_progressView) {
        _progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    }

    if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
        _progressView.trackTintColor = [UIColor colorWithWhite:.15 alpha:1];
        _progressView.tintColor = [UIColor colorWithWhite:.4 alpha:1];
    } else {
        _progressView.trackTintColor = [UIColor colorWithWhite:.95 alpha:1];
        _progressView.tintColor = [UIColor colorWithWhite:.8 alpha:1];
    }
    
    _progressView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin;
    
    float width = _progressView.frame.size.width;
    float height = _progressView.frame.size.height;
    float x = (self.frame.size.width / 2.0) - width/2;
    float y = (self.frame.size.height / 2.0) - height/2;
    _progressView.frame = CGRectMake(x, y, width, height);
    [self addSubview:_progressView];
}
@end

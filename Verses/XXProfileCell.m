//
//  XXProfileCell.m
//  Verses
//
//  Created by Max Haines-Stiles on 4/14/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import "XXProfileCell.h"
#import "UIImage+ImageEffects.h"
#import <SDWebImage/UIButton+WebCache.h>

@implementation XXProfileCell {

}

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

- (void)configureForUser:(User*)user {
    if (user.location.length){
        [_locationLabel setFont:[UIFont fontWithName:kCrimsonItalic size:18]];
        [_locationLabel setText:user.location];
    } else {
        [_locationLabel setText:@"No location listed..."];
        [_locationLabel setFont:[UIFont fontWithName:kCrimsonItalic size:18]];
    }
    
    if (user.bio.length) {
        [_bioLabel setText:[NSString stringWithFormat:@"\"%@\"",user.bio]];
        [_bioLabel setFont:[UIFont fontWithName:kCrimsonRoman size:17]];
        [_bioLabel setHidden:NO];
    } else {
        [_bioLabel setHidden:YES];
    }
    
    if (user.dayJob.length) {
        [_dayJobLabel setText:user.dayJob];
        [_dayJobLabel setFont:[UIFont fontWithName:kSourceSansProSemibold size:18]];
        [_dayJobLabel setHidden:NO];
    } else {
        [_dayJobLabel setHidden:YES];
    }
    
    if ([[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] isEqualToNumber:user.identifier]){
        [_subscribeButton setHidden:YES];
    } else {
        if ([user.subscribed isEqualToNumber:[NSNumber numberWithBool:YES]]){
            [_subscribeButton setTitle:@"Unsubscribe" forState:UIControlStateNormal];
            [_subscribeButton addTarget:self action:@selector(unsubscribe:) forControlEvents:UIControlEventTouchUpInside];
        } else {
            [_subscribeButton setTitle:@"Subscribe" forState:UIControlStateNormal];
            [_subscribeButton addTarget:self action:@selector(subscribe:) forControlEvents:UIControlEventTouchUpInside];
        }
        [_subscribeButton setHidden:NO];
        [_subscribeButton.titleLabel setFont:[UIFont fontWithName:kSourceSansProRegular size:14]];
        
        [_subscribeButton setTitleColor:_locationLabel.textColor forState:UIControlStateNormal];
        [_subscribeButton.layer setBorderColor:_locationLabel.textColor.CGColor];
        [_subscribeButton.layer setBorderWidth:.5f];
        [_subscribeButton setTag:user.identifier.intValue];
    }
    
    NSString *urlString;
    if (IDIOM == IPAD){
        urlString = user.picLarge;
    } else {
        urlString = user.picMedium;
    }
    if (urlString.length){
        [_imageButton setImageWithURL:[NSURL URLWithString:urlString] forState:UIControlStateNormal completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
            //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            
                [_blurredBackground setImage:[image applyBlurWithRadius:14 blurType:BOXFILTER tintColor:[UIColor colorWithWhite:1 alpha:.77] saturationDeltaFactor:1.8 maskImage:nil]];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [UIView animateWithDuration:.75 animations:^{
                        [_blurredBackground setAlpha:1.0];
                        [_imageButton setAlpha:1.0];
                        [_locationLabel setAlpha:1.0];
                        [_dayJobLabel setAlpha:1.0];
                        [_bioLabel setAlpha:1.0];
                        [_subscribeButton setAlpha:1.0];
                    } completion:^(BOOL finished) {
                        [_background setImage:image];
                        [_background setAlpha:1.0];
                    }];
                });
            //});
        }];
    } else {
        [_imageButton setTitle:@"NO PHOTO" forState:UIControlStateNormal];
        [_imageButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
        [_imageButton.titleLabel setFont:[UIFont fontWithName:kSourceSansProLight size:14]];
        [UIView animateWithDuration:.23 animations:^{
            [_imageButton setAlpha:1.0];
            [_locationLabel setAlpha:1.0];
            [_dayJobLabel setAlpha:1.0];
            [_bioLabel setAlpha:1.0];
            [_subscribeButton setAlpha:1.0];
        }];
    }
}

- (void)subscribe:(UIButton*)button{
    [[(XXAppDelegate*)[UIApplication sharedApplication].delegate manager] POST:[NSString stringWithFormat:@"%@/users/%d/subscribe",kAPIBaseUrl,button.tag] parameters:@{@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if ([responseObject objectForKey:@"success"]){
            [_subscribeButton setTitle:@"Unsubscribe" forState:UIControlStateNormal];
            [_subscribeButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
            [_subscribeButton addTarget:self action:@selector(unsubscribe:) forControlEvents:UIControlEventTouchUpInside];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        //NSLog(@"Failed to subcsribe: %@",error.description);
        [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Something went wrong. Our bad. Please try again soon." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    }];
}

- (void)unsubscribe:(UIButton*)button{
    [[(XXAppDelegate*)[UIApplication sharedApplication].delegate manager] POST:[NSString stringWithFormat:@"%@/users/%d/unsubscribe",kAPIBaseUrl,button.tag] parameters:@{@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if ([responseObject objectForKey:@"success"]){
            [_subscribeButton setTitle:@"Subscribe" forState:UIControlStateNormal];
            [_subscribeButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
            [_subscribeButton addTarget:self action:@selector(subscribe:) forControlEvents:UIControlEventTouchUpInside];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        //NSLog(@"Failed to subcsribe: %@",error.description);
        [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Something went wrong. Our bad. Please try again soon." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    }];
}

@end

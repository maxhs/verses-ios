//
//  XXMyStoryCell.m
//  Verses
//
//  Created by Max Haines-Stiles on 3/16/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import "XXMyStoryCell.h"
#import "XXPhoto.h"
#import <SDWebImage/UIButton+WebCache.h>
#import <DTCoreText/DTCoreText.h>
#import "XXContribution.h"
#import "UIImage+ImageEffects.h"

@implementation XXMyStoryCell {
    UITapGestureRecognizer *tapGesture;
    XXTextStorage *_textStorage;
    CGRect screen;
    int readY;
    int editY;
}

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

- (void)configureForStory:(XXStory*)story textColor:(UIColor*)color {
    screen = [UIScreen mainScreen].bounds;
    [self.wordCountLabel setFont:[UIFont fontWithName:kCrimsonItalic size:15]];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
        [self.wordCountLabel setTextColor:[UIColor whiteColor]];
    } else {
        [self.wordCountLabel setTextColor:[UIColor lightGrayColor]];
    }
    
    [self.draftLabel setFont:[UIFont fontWithName:kSourceSansProRegular size:14]];
    [self.revealLabel setFont:[UIFont fontWithName:kSourceSansProRegular size:14]];
    [self.revealLabel setTextColor:kElectricBlue];
    NSString *storyBody;
    NSRange range;
    if (story.mystery){
        storyBody = [story.contributions.firstObject body];
    } else {
        storyBody = [story.contributions.lastObject body];
    }
    
    if ([storyBody length] > 160){
        if (story.mystery){
            range = NSMakeRange([storyBody length]-160, 160);
        } else {
            range = NSMakeRange(0, 160);
        }
    } else {
        range = NSMakeRange(0, [storyBody length]);
    }
    
    [self.bodySnippet setHidden:NO];
    NSDictionary *options = @{DTUseiOS6Attributes: [NSNumber numberWithBool:YES],
                              DTDefaultFontSize: @18,
                              DTDefaultFontFamily: @"Crimson Text"};
    
    DTHTMLAttributedStringBuilder *stringBuilder = [[DTHTMLAttributedStringBuilder alloc] initWithHTML:[[storyBody substringWithRange:range] dataUsingEncoding:NSUTF8StringEncoding] options:options documentAttributes:nil];
    NSMutableAttributedString *aString = [[stringBuilder generatedAttributedString] mutableCopy];
    [[aString mutableString] replaceOccurrencesOfString:@"\n" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, aString.length)];
    NSMutableAttributedString *ellipsis = [[NSMutableAttributedString alloc] initWithString:@"..."];
    
    if (story.mystery){
        [ellipsis appendAttributedString:aString];
        self.bodySnippet.attributedText = ellipsis;
    } else {
        [aString appendAttributedString:ellipsis];
        self.bodySnippet.attributedText = aString;
    }
    [self.bodySnippet setTextColor:color];
    
    [self.titleLabel setText:story.title];
    [self.titleLabel setFont:[UIFont fontWithName:kSourceSansProSemibold size:23]];
    [self.titleLabel setTextColor:color];
    
    [self.readButton.titleLabel setFont:[UIFont fontWithName:kSourceSansProRegular size:20]];
    [self buttonTreatment:self.readButton];
    [self.writeButton.titleLabel setFont:[UIFont fontWithName:kSourceSansProRegular size:20]];
    [self buttonTreatment:self.writeButton];
    
    readY = (int)arc4random_uniform(320)-160;
    editY = (int)arc4random_uniform(320)-160;
    
    self.writeButton.transform = CGAffineTransformMakeTranslation(screen.size.width, editY);
    self.readButton.transform = CGAffineTransformMakeTranslation(-screen.size.width, readY);
    
    if (story.saved){
        [self.draftLabel setHidden:NO];
        if (story.mystery){
            [self.revealLabel setHidden:NO];
        } else {
            [self.revealLabel setHidden:YES];
        }
    } else {
        [self.draftLabel setHidden:YES];
        if (story.mystery){
            self.revealLabel.transform = CGAffineTransformMakeTranslation(0, -24);
            [self.revealLabel setHidden:NO];
        } else {
            [self.revealLabel setHidden:YES];
        }
    }
    [UIView animateWithDuration:.25 animations:^{
        [self.bodySnippet setAlpha:1.0];
        [self.titleLabel setAlpha:1.0];
    }];
}

- (void)buttonTreatment:(UIButton*)button {
    //button.layer.borderColor = kElectricBlue.CGColor;
    [button setBackgroundColor:kElectricBlue];
    //button.layer.borderWidth = .5f;
    button.layer.cornerRadius = 14.f;
    button.clipsToBounds = YES;
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
}

-(UIImage *)blurredSnapshot
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(screen.size.width, 140), NO, self.window.screen.scale);
    [self drawViewHierarchyInRect:CGRectMake(0, 0, screen.size.width, 140) afterScreenUpdates:NO];
    UIImage *snapshotImage = UIGraphicsGetImageFromCurrentImageContext();
    UIImage *blurredSnapshotImage;
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
        blurredSnapshotImage = [snapshotImage applyBlurWithRadius:20 blurType:BOXFILTER tintColor:[UIColor colorWithWhite:.0 alpha:.7] saturationDeltaFactor:1.8 maskImage:nil];
    } else {
        blurredSnapshotImage = [snapshotImage applyBlurWithRadius:7 blurType:BOXFILTER tintColor:[UIColor colorWithWhite:1 alpha:.25] saturationDeltaFactor:1.8 maskImage:nil];
    }
    
    UIGraphicsEndImageContext();
    
    return blurredSnapshotImage;
}

- (void)swipe{
    if (self.background.alpha == 0.0){
        [self.background setImage:[self blurredSnapshot]];
        [UIView animateWithDuration:.75 delay:0 usingSpringWithDamping:.5 initialSpringVelocity:.001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            [self.background setAlpha:1.0];
            self.readButton.transform = CGAffineTransformIdentity;
            self.writeButton.transform = CGAffineTransformIdentity;
            [self.readButton setAlpha:1.0];
            [self.writeButton setAlpha:1.0];
        } completion:^(BOOL finished) {
            
        }];
    } else {
        readY = (int)arc4random_uniform(320)-160;
        editY = (int)arc4random_uniform(320)-160;
        [UIView animateWithDuration:1 delay:0 usingSpringWithDamping:.4 initialSpringVelocity:.0001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            [self.background setAlpha:0];
            self.writeButton.transform = CGAffineTransformMakeTranslation(screen.size.width, editY);
            self.readButton.transform = CGAffineTransformMakeTranslation(-screen.size.width, readY);
            [self.readButton setAlpha:0.0];
            [self.writeButton setAlpha:0.0];
        } completion:^(BOOL finished) {
            
        }];
    }
}


@end

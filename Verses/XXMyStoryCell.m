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
    [_wordCountLabel setFont:[UIFont fontWithName:kCrimsonItalic size:15]];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
        [_wordCountLabel setTextColor:[UIColor whiteColor]];
    } else {
        [_wordCountLabel setTextColor:[UIColor lightGrayColor]];
    }
    
    [_draftLabel setFont:[UIFont fontWithName:kSourceSansProRegular size:14]];
    [_revealLabel setFont:[UIFont fontWithName:kSourceSansProRegular size:14]];
    [_revealLabel setTextColor:kElectricBlue];
    
    [_titleLabel setText:story.title];
    [_titleLabel setFont:[UIFont fontWithName:kSourceSansProSemibold size:33]];
    [_titleLabel setTextColor:color];
    [_titleLabel setAdjustsFontSizeToFitWidth:YES];
    
    NSString *storyBody;
    NSRange range;
    if (story.mystery){
        storyBody = [story.contributions.firstObject body];
    } else {
        storyBody = [story.contributions.lastObject body];
    }
    
    int snippetLength;
    if (IDIOM == IPAD){
        snippetLength = 600;
    } else {
        snippetLength = 400;
    }
    
    if ([storyBody length] > snippetLength){
        if (story.mystery){
            range = NSMakeRange([storyBody length]-snippetLength, snippetLength);
        } else {
            range = NSMakeRange(0, snippetLength);
        }
    } else {
        range = NSMakeRange(0, [storyBody length]);
    }
    
    NSDictionary *options = @{DTUseiOS6Attributes: [NSNumber numberWithBool:YES],
                              DTDefaultFontSize: @21,
                              DTDefaultFontFamily: @"Crimson Text"};
    
    DTHTMLAttributedStringBuilder *stringBuilder = [[DTHTMLAttributedStringBuilder alloc] initWithHTML:[[storyBody substringWithRange:range] dataUsingEncoding:NSUTF8StringEncoding] options:options documentAttributes:nil];
    NSAttributedString *aString = [stringBuilder generatedAttributedString];
    /*[[aString mutableString] replaceOccurrencesOfString:@"\n" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, aString.length)];
    NSMutableAttributedString *ellipsis = [[NSMutableAttributedString alloc] initWithString:@"..."];*/
    
    if (!_bodySnippet){
        _bodySnippet = [[XXTextView alloc] init];
        [_bodySnippet setUserInteractionEnabled:NO];
        [_bodySnippet setScrollEnabled:NO];
        [_bodySnippet setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
        [_bodySnippet.textContainer setMaximumNumberOfLines:0];
        [_bodySnippet.textContainer setLineBreakMode:NSLineBreakByTruncatingTail];

        CGFloat textContainerHeight;
        if (IDIOM == IPAD){
            textContainerHeight = self.contentView.frame.size.height*2/3;
        } else {
            if (screenHeight() == 568){
                textContainerHeight = self.contentView.frame.size.height*2/3;
            } else {
                textContainerHeight = self.contentView.frame.size.height/2;
            }
            
        }
        CGFloat spacer = 10;
        
        [_bodySnippet setFrame:CGRectMake(spacer/2, _titleLabel.frame.size.height+_titleLabel.frame.origin.y, self.contentView.frame.size.width-spacer, textContainerHeight)];
        [self.contentView insertSubview:_bodySnippet belowSubview:_background];
    }
    
    [_bodySnippet setAttributedText:aString];
    [_bodySnippet setTextColor:color];
    
    [_readButton.titleLabel setFont:[UIFont fontWithName:kSourceSansProSemibold size:17]];
    [self buttonTreatment:_readButton];
    [_editButton.titleLabel setFont:[UIFont fontWithName:kSourceSansProSemibold size:17]];
    [self buttonTreatment:_editButton];
    
    readY = (int)arc4random_uniform(320)-160;
    editY = (int)arc4random_uniform(320)-160;
    
    _editButton.transform = CGAffineTransformMakeTranslation(screen.size.width, editY);
    _readButton.transform = CGAffineTransformMakeTranslation(-screen.size.width, readY);
    
    if (story.saved){
        [_draftLabel setHidden:NO];
        if (story.mystery){
            [_revealLabel setHidden:NO];
        } else {
            [_revealLabel setHidden:YES];
        }
    } else {
        [_draftLabel setHidden:YES];
        if (story.mystery){
            _revealLabel.transform = CGAffineTransformMakeTranslation(0, -24);
            [_revealLabel setHidden:NO];
        } else {
            _revealLabel.transform = CGAffineTransformIdentity;
            [_revealLabel setHidden:YES];
        }
    }
    [UIView animateWithDuration:.25 animations:^{
        [_bodySnippet setAlpha:1.0];
        [_titleLabel setAlpha:1.0];
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
    if (_background.alpha == 0.0){
        [_background setImage:[self blurredSnapshot]];
        [UIView animateWithDuration:.75 delay:0 usingSpringWithDamping:.5 initialSpringVelocity:.001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            [_background setAlpha:1.0];
            _readButton.transform = CGAffineTransformIdentity;
            _editButton.transform = CGAffineTransformIdentity;
            [_readButton setAlpha:1.0];
            [_editButton setAlpha:1.0];
        } completion:^(BOOL finished) {
            
        }];
    } else {
        readY = (int)arc4random_uniform(320)-160;
        editY = (int)arc4random_uniform(320)-160;
        [UIView animateWithDuration:1 delay:0 usingSpringWithDamping:.4 initialSpringVelocity:.0001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            [_background setAlpha:0];
            _editButton.transform = CGAffineTransformMakeTranslation(screen.size.width, editY);
            _readButton.transform = CGAffineTransformMakeTranslation(-screen.size.width, readY);
            [_readButton setAlpha:0.0];
            [_editButton setAlpha:0.0];
        } completion:^(BOOL finished) {
            
        }];
    }
}


@end

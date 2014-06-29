//
//  XXPortfolioCell.m
//  Verses
//
//  Created by Max Haines-Stiles on 3/16/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import "XXPortfolioCell.h"
#import "Photo+helper.h"
#import <SDWebImage/UIButton+WebCache.h>
#import <DTCoreText/DTCoreText.h>
#import "UIImage+ImageEffects.h"
#import "XXTextStorage.h"

@implementation XXPortfolioCell {
    UITapGestureRecognizer *tapGesture;
    CGFloat width;
    CGFloat height;
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

- (void)configureForStory:(Story*)story textColor:(UIColor*)color withOrientation:(UIInterfaceOrientation)orientation {
    //remove existing textviews from reused cells
    for (id view in self.contentView.subviews){
        if ([view isKindOfClass:[XXTextView class]]){
            [view removeFromSuperview];
            break;
        }
    }
    if (UIInterfaceOrientationIsPortrait(orientation)){
        width = screenWidth();
        if (IDIOM == IPAD){
            height = screenHeight()/3;
        } else {
            height = screenHeight()/2;
        }
    } else {
        width = screenHeight();
        if (IDIOM == IPAD){
            height = screenWidth()/3;
        } else {
            height = screenWidth()/2;
        }
    }
    
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
    if ([story.mystery isEqualToNumber:[NSNumber numberWithBool:YES]]){
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
        if ([story.mystery isEqualToNumber:[NSNumber numberWithBool:YES]]){
            range = NSMakeRange([storyBody length]-snippetLength, snippetLength);
        } else {
            range = NSMakeRange(0, snippetLength);
        }
    } else {
        range = NSMakeRange(0, [storyBody length]);
    }
    
    XXTextStorage *_textStorage = [XXTextStorage new];
    [_textStorage setAttributedString:story.attributedSnippet];
    NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];
    [_textStorage addLayoutManager:layoutManager];
    CGFloat spacer = 10;
    CGFloat titleOffset = (_titleLabel.frame.size.height + _titleLabel.frame.origin.y);
    CGFloat containerHeight = height*.823 - titleOffset;
    
    NSTextContainer *container = [[NSTextContainer alloc] initWithSize:CGSizeMake(width-spacer, containerHeight)];
    container.widthTracksTextView = YES;
    container.heightTracksTextView = YES;
    [layoutManager addTextContainer:container];
    _bodySnippet = [[XXTextView alloc] initWithFrame:CGRectMake(spacer/2, titleOffset, width - spacer, containerHeight-3) textContainer:container];
    _bodySnippet.userInteractionEnabled = NO;
    [self.contentView addSubview:_bodySnippet];
    [self.contentView sendSubviewToBack:_bodySnippet];
    
    [_bodySnippet setAlpha:0.0];
    if (IDIOM == IPAD) {
        //_bodySnippet.autoresizingMask = UIViewAutoresizingNone;
        CGRect bodyRect = _bodySnippet.frame;
        bodyRect.size.width = width-spacer;
        bodyRect.size.height = containerHeight;
        [_bodySnippet setFrame:bodyRect];
    } else {
        _bodySnippet.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin);
    }
    
    _bodySnippet.clipsToBounds = NO;
    _bodySnippet.textContainer.maximumNumberOfLines = 0;
    _bodySnippet.textContainer.lineBreakMode = NSLineBreakByTruncatingTail;
    [_bodySnippet setTextColor:color];
    
    [_readButton.titleLabel setFont:[UIFont fontWithName:kSourceSansProSemibold size:16]];
    [_editButton.titleLabel setFont:[UIFont fontWithName:kSourceSansProSemibold size:16]];

    [self buttonTreatment:_readButton withColor:color];
    [self buttonTreatment:_editButton withColor:color];
    
    
    readY = (int)arc4random_uniform(320)-160;
    editY = (int)arc4random_uniform(320)-160;
    
    _editButton.transform = CGAffineTransformMakeTranslation(width, editY);
    _readButton.transform = CGAffineTransformMakeTranslation(-width, readY);
    
    if ([story.draft isEqualToNumber:[NSNumber numberWithBool:YES]]){
        [_draftLabel setHidden:NO];
        if ([story.mystery isEqualToNumber:[NSNumber numberWithBool:YES]]){
            [_revealLabel setHidden:NO];
        } else {
            [_revealLabel setHidden:YES];
        }
    } else {
        [_draftLabel setHidden:YES];
        if ([story.mystery isEqualToNumber:[NSNumber numberWithBool:YES]]){
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

- (void)buttonTreatment:(UIButton*)button withColor:(UIColor*)color {
    
    [button setBackgroundColor:[UIColor clearColor]];
    if (color == [UIColor whiteColor]){
        button.layer.borderWidth = 1.f;
    } else {
        button.layer.borderWidth = .5f;
    }
    
    button.layer.cornerRadius = 14.f;
    button.clipsToBounds = YES;
    button.layer.borderColor = color.CGColor;
    [button setTitleColor:color forState:UIControlStateNormal];
    button.layer.rasterizationScale = [UIScreen mainScreen].scale;
    button.layer.shouldRasterize = YES;
}

-(UIImage *)blurredSnapshot
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(width, height), NO, self.window.screen.scale);
    [self drawViewHierarchyInRect:CGRectMake(0, 0, width, height) afterScreenUpdates:NO];
    UIImage *snapshotImage = UIGraphicsGetImageFromCurrentImageContext();
    UIImage *blurredSnapshotImage;
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
        blurredSnapshotImage = [snapshotImage applyBlurWithRadius:10 blurType:BOXFILTER tintColor:[UIColor colorWithWhite:.0 alpha:.87] saturationDeltaFactor:.8 maskImage:nil];
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
            _editButton.transform = CGAffineTransformMakeTranslation(width, editY);
            _readButton.transform = CGAffineTransformMakeTranslation(-width, readY);
            [_readButton setAlpha:0.0];
            [_editButton setAlpha:0.0];
        } completion:^(BOOL finished) {
            
        }];
    }
}


@end

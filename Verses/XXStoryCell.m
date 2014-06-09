//
//  XXStoryCell.m
//  Verses
//
//  Created by Max Haines-Stiles on 10/11/13.
//  Copyright (c) 2013 Verses. All rights reserved.
//

#import "XXStoryCell.h"
#import "Photo+helper.h"
#import <SDWebImage/UIButton+WebCache.h>
#import <DTCoreText/DTCoreText.h>
#import "UIFontDescriptor+CrimsonText.h"
#import "UIImage+ImageEffects.h"
#import <SDWebImage/UIImageView+WebCache.h>

@implementation XXStoryCell {
    CGFloat width;
    CGFloat height;
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

- (void)configureForStory:(Story*)story  withOrientation:(UIInterfaceOrientation)orientation {
    [_flagButton.titleLabel setFont:[UIFont fontWithName:kSourceSansProLight size:15]];
    
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
    [_scrollView setContentSize:CGSizeMake(width*2, height)];
    
    [_infoLabel setFont:[UIFont fontWithName:kCrimsonItalic size:14]];
    [_infoLabel setTextColor:[UIColor lightGrayColor]];
    [_infoLabel setAlpha:0.0];
    [_authorLabel setText:[NSString stringWithFormat:@"by %@",story.authorNames]];
    [_separatorView setBackgroundColor:kSeparatorColor];
    [_titleLabel setFont:[UIFont fontWithName:kSourceSansProSemibold size:33]];
    
    [_countLabel setFont:[UIFont fontWithName:kSourceSansProRegular size:15]];
    [_authorLabel setFont:[UIFont fontWithName:kSourceSansProRegular size:15]];
    
    [_titleLabel setAlpha:0.0];
    [_authorLabel setAlpha:0.0];
    [_countLabel setAlpha:0.0];
    
    if (story.photos.count){
        [_titleLabel setTextColor:[UIColor whiteColor]];
        [_authorLabel setTextColor:[UIColor whiteColor]];
        [_countLabel setTextColor:[UIColor whiteColor]];
        [_backgroundImageView setHidden:NO];
        [_backgroundImageView setImageWithURL:[NSURL URLWithString:[(Photo*)story.photos.firstObject mediumUrl]] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
        
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                UIImage *blurredImage = [image applyBlurWithRadius:21 blurType:BOXFILTER tintColor:[UIColor colorWithWhite:0 alpha:.13] saturationDeltaFactor:1.8 maskImage:nil];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [_backgroundImageView setImage:blurredImage];
                    [UIView animateWithDuration:.5 animations:^{
                        [_backgroundImageView setAlpha:.75];
                        [_titleLabel setAlpha:1.0];
                        [_authorLabel setAlpha:1.0];
                        [_countLabel setAlpha:1.0];
                    } completion:^(BOOL finished) {
                        _backgroundImageView.layer.rasterizationScale = [UIScreen mainScreen].scale;
                        _backgroundImageView.layer.shouldRasterize = YES;
                    }];
                });
            });
        }];
        [_separatorView setHidden:YES];
    } else {
        [_backgroundImageView setHidden:YES];
        [_separatorView setHidden:NO];
        [UIView animateWithDuration:.3 animations:^{
            [_titleLabel setAlpha:1.0];
            [_authorLabel setAlpha:1.0];
            [_countLabel setAlpha:1.0];
        } completion:^(BOOL finished) {
            
        }];
    }
    
    XXTextStorage *_textStorage = [XXTextStorage new];
    [_textStorage setAttributedString:story.attributedSnippet];
    NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];
    [_textStorage addLayoutManager:layoutManager];
    CGFloat spacer = 18;
    CGFloat containerHeight = height*.823;
    
    NSTextContainer *container = [[NSTextContainer alloc] initWithSize:CGSizeMake(width-spacer, containerHeight)];
    container.widthTracksTextView = YES;
    container.heightTracksTextView = YES;
    [layoutManager addTextContainer:container];
    _bodySnippet = [[XXTextView alloc] initWithFrame:CGRectMake(spacer/2, 3, width - spacer, containerHeight-3) textContainer:container];
    _bodySnippet.userInteractionEnabled = NO;
    [self.contentView addSubview:_bodySnippet];
    
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
    [_titleLabel setText:story.title];
    _scrollTouch = [[UITapGestureRecognizer alloc] init];
    [_scrollTouch setNumberOfTapsRequired:1];
    [_scrollView addGestureRecognizer:_scrollTouch];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat x = scrollView.contentOffset.x;
    CGFloat alpha = (x/width);
    [_bodySnippet setAlpha:alpha];
    [_authorLabel setAlpha:alpha];
    [_infoLabel setAlpha:alpha];
    [_flagButton setAlpha:alpha];
    [_titleLabel setAlpha:1-alpha];
    [_authorLabel setAlpha:1-alpha];
    [_backgroundImageView setAlpha:.75-alpha];
}

- (void) resetCell {
    [_scrollView setContentOffset:CGPointZero];
    [_backgroundImageView setAlpha:0.0];
}

/*- (void)createTextView:(NSString*)text withCellHeight:(CGFloat)height withOrientation:(UIInterfaceOrientation)orientation {
    
    NSDictionary* attributes = @{NSDocumentTypeDocumentAttribute:NSHTMLTextDocumentType};
    NSMutableAttributedString* initialString = [[NSMutableAttributedString alloc] initWithData:[text dataUsingEncoding:NSUTF32StringEncoding] options:attributes documentAttributes:nil error:nil];
    [[initialString mutableString] replaceOccurrencesOfString:@"\n" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, initialString.length)];
    NSAttributedString *ellipsis = [[NSAttributedString alloc] initWithString:@"..."];
    [initialString appendAttributedString:ellipsis];
    
    _textStorage = [XXTextStorage new];
    [_textStorage appendAttributedString:initialString];
    NSLog(@"initial string: %@",initialString);

    NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];
    CGRect newTextViewRect;
    if (UIInterfaceOrientationIsPortrait(orientation)){
        newTextViewRect = CGRectMake(5, 56, screenWidth()-10, height-56);
    } else {
        newTextViewRect = CGRectMake(5, 56, screenWidth()-10, height-56);
    }
    CGSize containerSize = CGSizeMake(newTextViewRect.size.width,  CGFLOAT_MAX);
    NSTextContainer *container = [[NSTextContainer alloc] initWithSize:containerSize];
    container.widthTracksTextView = YES;
    [layoutManager addTextContainer:container];
    [_textStorage addLayoutManager:layoutManager];
    
    if (self.textView){
        [self.textView setFrame:newTextViewRect];
    } else {
        self.textView = [[UITextView alloc] initWithFrame:newTextViewRect
                                            textContainer:container];
        [self.textView setUserInteractionEnabled:NO];
        [self addSubview:self.textView];
        [self.textView setFont:[UIFont fontWithName:kCrimsonRoman size:20]];
        [self.textView setBackgroundColor:[UIColor clearColor]];
    }
    
    if ([self.textView.text isEqualToString:kStoryPlaceholder]){
        [self.textView setTextColor:[UIColor lightGrayColor]];
    } else {
        [self.textView setTextColor:[UIColor blackColor]];
    }
}*/

@end

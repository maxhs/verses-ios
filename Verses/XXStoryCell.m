//
//  XXStoryCell.m
//  Verses
//
//  Created by Max Haines-Stiles on 10/11/13.
//  Copyright (c) 2013 Verses. All rights reserved.
//

#import "XXStoryCell.h"
#import "XXPhoto.h"
#import <SDWebImage/UIButton+WebCache.h>
#import <DTCoreText/DTCoreText.h>
#import "UIFontDescriptor+CrimsonText.h"
#import "UIImage+ImageEffects.h"

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

- (void)configureForStory:(XXStory*)story {
    [_infoLabel setFont:[UIFont fontWithName:kCrimsonItalic size:15]];
    [_infoLabel setTextColor:[UIColor lightGrayColor]];
    [_authorLabel setText:[NSString stringWithFormat:@"by %@",story.authors]];
    [_separatorView setBackgroundColor:kSeparatorColor];
    
    width = self.contentView.frame.size.width;
    height = self.contentView.frame.size.height;
    
    if (IDIOM == IPAD){
        [_authorLabel setFont:[UIFont fontWithName:kCrimsonRoman size:15]];
        [_titleLabel setFont:[UIFont fontWithName:kSourceSansProSemibold size:33]];
        if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
            [_authorLabel setTextColor:[UIColor whiteColor]];
        } else {
            [_authorLabel setTextColor:[UIColor lightGrayColor]];
        }
        
        [_authorPhoto setHidden:NO];
        [_authorLabel setHidden:NO];
        
    } else {
        [_titleLabel setFont:[UIFont fontWithName:kSourceSansProSemibold size:33]];
        [_authorPhoto setHidden:YES];
        [_authorLabel setHidden:YES];
    }
    
    XXTextStorage *_textStorage = [XXTextStorage new];
    [_textStorage setAttributedString:story.attributedSnippet];
    
    NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];
    
    [_textStorage addLayoutManager:layoutManager];
    
    if (!_bodySnippet){
        CGFloat containerHeight;
        if (IDIOM == IPAD){
            containerHeight = height*.9;
        } else {
            if (screenHeight() == 568){
                containerHeight = height*2/3;
            } else {
                containerHeight = height/2;
            }
        }
        CGFloat spacer = 18;
        
        NSTextContainer *container = [[NSTextContainer alloc] initWithSize:CGSizeMake(width-spacer, containerHeight)];
        container.widthTracksTextView = YES;
        [layoutManager addTextContainer:container];
        _bodySnippet = [[XXTextView alloc] initWithFrame:CGRectMake(spacer/2, _titleLabel.frame.size.height+_titleLabel.frame.origin.y, width-spacer, container.size.height) textContainer:container];
        _bodySnippet.userInteractionEnabled = NO;
        [self.contentView addSubview:_bodySnippet];
    }
    
    [_bodySnippet setAttributedText:story.attributedSnippet];
    [_bodySnippet setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    _bodySnippet.textContainer.widthTracksTextView = YES;
    _bodySnippet.textContainer.maximumNumberOfLines = 0;
    _bodySnippet.textContainer.lineBreakMode = NSLineBreakByTruncatingTail;
    [_titleLabel setText:story.title];
    
    [UIView animateWithDuration:.25 animations:^{
        [_bodySnippet setAlpha:1.0];
        [_titleLabel setAlpha:1.0];
    }];
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

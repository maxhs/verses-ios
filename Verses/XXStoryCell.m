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

@implementation XXStoryCell {
    XXTextStorage *_textStorage;
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

- (void)configureForStory:(XXStory*)story textColor:(UIColor*)color featured:(BOOL)featured cellHeight:(CGFloat)height {
    [self.infoLabel setFont:[UIFont fontWithName:kCrimsonItalic size:15]];
    [self.infoLabel setTextColor:[UIColor lightGrayColor]];
    [self.authorLabel setText:[NSString stringWithFormat:@"by %@",story.authors]];
    
    if (IDIOM == IPAD){
        [self.authorLabel setFont:[UIFont fontWithName:kSourceSansProRegular size:14]];
        [self.titleLabel setFont:[UIFont fontWithName:kSourceSansProSemibold size:31]];
        if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
            [self.authorLabel setTextColor:[UIColor whiteColor]];
        } else {
            [self.authorLabel setTextColor:[UIColor lightGrayColor]];
        }
        
        [self.authorPhoto setHidden:NO];
        [self.authorLabel setHidden:NO];
        
    } else {
        [self.titleLabel setFont:[UIFont fontWithName:kSourceSansProSemibold size:25]];
        [self.authorPhoto setHidden:YES];
        [self.authorLabel setHidden:YES];
    }
    /*if (story.owner.picSmallUrl.length){
        self.authorLabel.transform = CGAffineTransformMakeTranslation(-44, 0);
        
        self.authorPhoto.imageView.layer.cornerRadius = 18.f;
        [self.authorPhoto.imageView setBackgroundColor:[UIColor clearColor]];
        [self.authorPhoto.imageView.layer setBackgroundColor:[UIColor whiteColor].CGColor];
        self.authorPhoto.imageView.layer.shouldRasterize = YES;
        self.authorPhoto.imageView.layer.rasterizationScale = [UIScreen mainScreen].scale;
        
        [self.authorPhoto setImageWithURL:[NSURL URLWithString:story.owner.picSmallUrl] forState:UIControlStateNormal completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
            [UIView animateWithDuration:.23 animations:^{
                [self.authorPhoto setAlpha:1.0];
            }];
        }];
    } else {
        self.authorLabel.transform = CGAffineTransformIdentity;
        [self.authorPhoto setAlpha:0.0];
    }*/
    
    if (story.firstContribution.body.length){
        int rangeAmount;
        if (story.mystery){
            rangeAmount = 250;
        } else if (IDIOM == IPAD) {
            rangeAmount = 500;
        } else {
            rangeAmount = 300;
        }
        NSRange range;
        if ([[story.contributions.firstObject body] length] > rangeAmount){
            range = NSMakeRange(0, rangeAmount);
        } else {
            range = NSMakeRange(0, [[story.contributions.firstObject body] length]);
        }

    
        NSDictionary *options = @{DTUseiOS6Attributes: [NSNumber numberWithBool:YES],
                                  DTDefaultFontSize: @19,
                                  DTDefaultFontFamily: @"Crimson Text"};
        
        DTHTMLAttributedStringBuilder *stringBuilder = [[DTHTMLAttributedStringBuilder alloc] initWithHTML:[[[story.contributions.firstObject body] substringWithRange:range] dataUsingEncoding:NSUTF8StringEncoding] options:options documentAttributes:nil];
        NSMutableAttributedString *aString = [[stringBuilder generatedAttributedString] mutableCopy];
        NSRange fullRange = NSMakeRange(0, aString.length);
        [[aString mutableString] replaceOccurrencesOfString:@"\n" withString:@"" options:NSCaseInsensitiveSearch range:fullRange];
        NSAttributedString *ellipsis = [[NSAttributedString alloc] initWithString:@"..."];
        [aString appendAttributedString:ellipsis];
//        if (aString.length) [aString addAttributes:@{NSFontAttributeName:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCrimsonTextFontDescriptorWithTextStyle:UIFontTextStyleBody] size:0]} range:fullRange];
        self.bodySnippet.attributedText = aString;
        [self.bodySnippet setTextColor:color];
    } else {
        [self.bodySnippet setText:@""];
    }
    
    [self.titleLabel setTextColor:color];
    [self.titleLabel setText:story.title];
    
    [UIView animateWithDuration:.25 animations:^{
        [self.bodySnippet setAlpha:1.0];
        [self.titleLabel setAlpha:1.0];
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

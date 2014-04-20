//
//  XXChatCell.m
//  Verses
//
//  Created by Max Haines-Stiles on 4/18/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import "XXChatCell.h"
#import "XXTextStorage.h"
#import <SDWebImage/UIButton+WebCache.h>

@interface XXChatCell()

@property (nonatomic) SentBy sentBy;
@property CGSize textSize;
@property (strong, nonatomic) UILabel *textLabel;
@property (strong, nonatomic) UILabel *outlineLabel;
@property (strong, nonatomic) UIButton *imageButton;

@end

@implementation XXChatCell {
    XXTextStorage *_textStorage;
}

static int offsetX = 6; // 6 px from each side
static int minimumHeight = 30;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        // Initialization code
        self.contentView.layer.rasterizationScale = 2.0f;
        self.contentView.layer.shouldRasterize = YES;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        
        _senderColor = [UIColor colorWithWhite:.5 alpha:.5];
        _myColor = kElectricBlue;
        
        if (!_outlineLabel) {
            _outlineLabel = [UILabel new];
            _outlineLabel.layer.rasterizationScale = 2.0f;
            _outlineLabel.layer.shouldRasterize = YES;
            _outlineLabel.layer.borderWidth = .5f;
            _outlineLabel.layer.cornerRadius = minimumHeight / 2;
            _outlineLabel.alpha = .925;
            [self.contentView addSubview:_outlineLabel];
        }
        
        if (!_textLabel) {
            _textLabel = [UILabel new];
            _textLabel.layer.rasterizationScale = 2.0f;
            _textLabel.layer.shouldRasterize = YES;
            _textLabel.font = [UIFont fontWithName:kSourceSansProRegular size:15.0f];
            _textLabel.textColor = [UIColor darkTextColor];
            _textLabel.numberOfLines = 0;
            [self.contentView addSubview:_textLabel];
        }
    }
    
    return self;
}

- (void)drawCell:(XXComment *)comment withTextColor:(UIColor *)textColor{
    _textSize = comment.rectSize;
    _textLabel.text = comment.body;
    CGFloat height = self.contentView.bounds.size.height - 10;
    if (height < minimumHeight) height = minimumHeight;
    
    if (!_imageButton) {
        _imageButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _imageButton.imageView.layer.cornerRadius = minimumHeight / 2;
        _imageButton.layer.cornerRadius = minimumHeight / 2;
        _imageButton.layer.backgroundColor = [UIColor colorWithWhite:.8 alpha:1].CGColor;
        [_imageButton setBackgroundColor:[UIColor clearColor]];
        _imageButton.imageView.layer.rasterizationScale = [UIScreen mainScreen].scale;
        _imageButton.imageView.layer.shouldRasterize = YES;
        [self.contentView addSubview:_imageButton];
    }
    
    if ([comment.user.identifier isEqualToNumber:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]]){
        _imageButton.frame = CGRectMake(offsetX / 2, 0, minimumHeight, minimumHeight);
    } else {
        _imageButton.frame = (UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication]statusBarOrientation])) ? CGRectMake(screenWidth() - offsetX/2 - minimumHeight, 0, minimumHeight, minimumHeight) : CGRectMake(screenHeight() - offsetX/2 - minimumHeight, 0, minimumHeight, minimumHeight);
    }
    
    if ([comment.user.identifier isEqualToNumber:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]]) {
        _outlineLabel.frame = CGRectMake(offsetX + minimumHeight, 0, _textSize.width + OUTLINE, height);
        _outlineLabel.layer.borderColor = _senderColor.CGColor;
    } else {
        _outlineLabel.frame = (UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication]statusBarOrientation])) ? CGRectMake(screenWidth() - offsetX - minimumHeight*2, 0, -_textSize.width - OUTLINE, height) : CGRectMake(screenHeight() - offsetX - minimumHeight*2, 0, -_textSize.width - OUTLINE, height);
        _outlineLabel.layer.borderColor = _myColor.CGColor;
       
    }
    
    if (comment.user.picSmallUrl.length) {
        [_imageButton setImageWithURL:[NSURL URLWithString:comment.user.picSmallUrl] forState:UIControlStateNormal completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
            
        }];
        [_imageButton.imageView setBackgroundColor:[UIColor clearColor]];
        _imageButton.layer.borderColor = [UIColor colorWithWhite:0 alpha:0].CGColor;
        _imageButton.layer.borderWidth = 0.f;
        [_imageButton setTitle:@"" forState:UIControlStateNormal];
    } else {
        [_imageButton setImage:nil forState:UIControlStateNormal];
        [_imageButton.imageView setBackgroundColor:[UIColor colorWithWhite:.8 alpha:1]];
        [_imageButton setTitle:[comment.user.penName substringToIndex:2] forState:UIControlStateNormal];
        [_imageButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
        [_imageButton.titleLabel setFont:[UIFont fontWithName:kSourceSansProLight size:12]];
        _imageButton.layer.borderColor = [UIColor colorWithWhite:.9 alpha:1].CGColor;
        _imageButton.layer.borderWidth = 1.f;
        
        /*for (UIView * v in @[_outlineLabel, _textLabel]) {
            v.center = CGPointMake(v.center.x + _imageButton.bounds.size.width, v.center.y);
        }
        _imageButton.hidden = NO;*/
    }
    [_textLabel setTextColor:textColor];
    _textLabel.frame = CGRectMake(_outlineLabel.frame.origin.x + (OUTLINE / 2), 0, _outlineLabel.bounds.size.width - OUTLINE, _outlineLabel.bounds.size.height);
}

@end

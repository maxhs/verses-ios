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
        
        _senderColor = [UIColor colorWithWhite:.5 alpha:.25];
        _myColor = kElectricBlue;
        
        if (!_outlineLabel) {
            _outlineLabel = [UILabel new];
            _outlineLabel.layer.rasterizationScale = 2.0f;
            _outlineLabel.layer.cornerRadius = minimumHeight / 2;
            _outlineLabel.clipsToBounds = YES;
            if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
                _outlineLabel.alpha = .5;
            }
            _outlineLabel.layer.shouldRasterize = YES;
            _outlineLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
            [self.contentView addSubview:_outlineLabel];
        }
        
        if (!_textLabel) {
            _textLabel = [UILabel new];
            _textLabel.layer.rasterizationScale = [UIScreen mainScreen].scale;
            _textLabel.layer.shouldRasterize = YES;
            _textLabel.font = [UIFont fontWithName:kSourceSansProRegular size:15.0f];
            _textLabel.textColor = [UIColor darkTextColor];
            _textLabel.numberOfLines = 0;
            _textLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
            
            [self.contentView addSubview:_textLabel];
        }
        
        if (!_timestamp) {
            _timestamp = [UILabel new];
            _timestamp.font = [UIFont fontWithName:kSourceSansProRegular size:10.f];
            _timestamp.textColor = [UIColor lightGrayColor];
            _timestamp.numberOfLines = 0;
            [self.contentView addSubview:_timestamp];
        }
        
        if (!_deleteButton) {
            _deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
            if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
                [_deleteButton setImage:[UIImage imageNamed:@"whiteTrashButton"] forState:UIControlStateNormal];
            } else {
                [_deleteButton setImage:[UIImage imageNamed:@"trashButton"] forState:UIControlStateNormal];
            }
            
            [_deleteButton setHidden:YES];
            [_deleteButton setAlpha:0.0];
            [self.contentView addSubview:_deleteButton];
        }
        
    }
    
    return self;
}

- (void)drawCell:(Comment *)comment withTextColor:(UIColor *)textColor{
    _textSize = comment.rectSize;
    _textLabel.text = comment.body;
    CGFloat height = self.contentView.bounds.size.height - 10;
    CGFloat width = self.contentView.bounds.size.width;
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
    
    if ([comment.user.identifier isEqualToNumber:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]]) {
         _imageButton.frame = CGRectMake(offsetX / 2, 0, minimumHeight, minimumHeight);
        _outlineLabel.frame = CGRectMake(offsetX + minimumHeight, 0, _textSize.width + OUTLINE, height);
        _outlineLabel.backgroundColor = _myColor;
        _deleteButton.frame = (UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication]statusBarOrientation])) ? CGRectMake(width-34, self.frame.size.height/2-23, 34, 34) : CGRectMake(screenHeight()-34, self.frame.size.height/2-23, 34, 34);
        _timestamp.frame = CGRectMake(_outlineLabel.frame.origin.x + _outlineLabel.bounds.size.width + offsetX, 0, 40, height);
        [_textLabel setTextColor:[UIColor whiteColor]];
    } else {
        _imageButton.frame = (UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication]statusBarOrientation])) ? CGRectMake(width - offsetX/2 - minimumHeight, 0, minimumHeight, minimumHeight) : CGRectMake(screenHeight() - offsetX/2 - minimumHeight, 0, minimumHeight, minimumHeight);
        _outlineLabel.frame = (UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication]statusBarOrientation])) ? CGRectMake(width - offsetX - minimumHeight, 0, -_textSize.width - OUTLINE, height) : CGRectMake(screenHeight() - offsetX - minimumHeight, 0, -_textSize.width - OUTLINE, height);
        _outlineLabel.backgroundColor = _senderColor;
        _deleteButton.frame = CGRectMake(0, 0, 0, 0);
        _timestamp.frame = CGRectMake(_outlineLabel.frame.origin.x - 40, 0, 40, height);
        if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
            [_textLabel setTextColor:[UIColor whiteColor]];
        } else {
            [_textLabel setTextColor:[UIColor blackColor]];
        }
    }
    
    if (comment.user.picSmall) {
        [_imageButton sd_setImageWithURL:[NSURL URLWithString:comment.user.picSmall] forState:UIControlStateNormal];
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
        }*/
    }
    
    [_deleteButton setHidden:YES];
    [_deleteButton setAlpha:0.0];
    _textLabel.frame = CGRectMake(_outlineLabel.frame.origin.x + (OUTLINE / 2), 0, _outlineLabel.bounds.size.width - OUTLINE, _outlineLabel.bounds.size.height);
}

@end

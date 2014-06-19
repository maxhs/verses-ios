//
//  XXSettingsCell.m
//  Verses
//
//  Created by Max Haines-Stiles on 3/25/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import "XXSettingsCell.h"

@implementation XXSettingsCell

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

-(void)configure:(User*)user {
    [_textField setFont:[UIFont fontWithName:kSourceSansProRegular size:15]];
    [_imageLabel setFont:[UIFont fontWithName:kSourceSansProRegular size:15]];
    if (user){
        if (user.picSmall || user.thumbImage){
            [_imageLabel setText:@"Change your profile photo"];
            _imageButton.imageView.layer.cornerRadius = self.imageButton.frame.size.height/2;
            _imageButton.imageView.layer.backgroundColor = [UIColor clearColor].CGColor;
            [_imageButton.imageView setBackgroundColor:[UIColor clearColor]];
            _imageButton.imageView.contentMode = UIViewContentModeScaleAspectFill;
            _imageButton.imageView.layer.rasterizationScale = [UIScreen mainScreen].scale;
            _imageButton.imageView.layer.shouldRasterize = YES;
        } else {
            [_imageLabel setText:@"Your profile photo"];
            _imageButton.layer.borderColor = [UIColor colorWithWhite:.8 alpha:1].CGColor;
            [_imageButton setTitleColor:[UIColor colorWithWhite:.8 alpha:1] forState:UIControlStateNormal];
            _imageButton.layer.borderWidth = .5f;
            [_imageButton.titleLabel setFont:[UIFont fontWithName:kSourceSansProRegular size:12]];
            _imageButton.layer.cornerRadius = self.imageButton.frame.size.height/2;
            _imageButton.layer.backgroundColor = [UIColor clearColor].CGColor;
            _imageButton.layer.rasterizationScale = [UIScreen mainScreen].scale;
            _imageButton.layer.shouldRasterize = YES;
        }
    }
}

@end


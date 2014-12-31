//
//  XXMenuCell.m
//  Verses
//
//  Created by Max Haines-Stiles on 3/23/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import "XXMenuCell.h"
#import "Constants.h"

@implementation XXMenuCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib {
    UIView *selectedBackgroundView = [[UIView alloc] initWithFrame:self.contentView.frame];
    [selectedBackgroundView setBackgroundColor:[UIColor colorWithWhite:1 alpha:.5]];
    self.selectedBackgroundView = selectedBackgroundView;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)configureAlert:(NSInteger)alertCount{

    [_menuLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleSubheadline forFont:kSourceSansProSemibold] size:0]];
    _menuLabel.layer.rasterizationScale = [UIScreen mainScreen].scale;
    _menuLabel.layer.shouldRasterize = YES;
    
    CGRect labelRect;
    if (alertCount == 0){
        [_alertLabel setHidden:YES];
        [_alertLabel setAlpha:0.0];
    } else {
        [_alertLabel setText:[NSString stringWithFormat:@"%ld",(long)alertCount]];
        labelRect = [@"Writing Circles" boundingRectWithSize:_menuLabel.frame.size options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:_menuLabel.font} context:nil];

        CGFloat alertWidth;
        if (alertCount > 999){
            alertWidth = 33;
        } else if (alertCount > 99){
            alertWidth = 27;
        } else {
            alertWidth = 20;
        }
        [_alertLabel setFrame:CGRectMake(_menuLabel.frame.origin.x+labelRect.size.width-6, _menuLabel.frame.origin.y+8, alertWidth, 20)];
        if (_alertLabel.backgroundColor != [UIColor redColor]){
            [_alertLabel setBackgroundColor:[UIColor redColor]];
            [_alertLabel setTextColor:[UIColor whiteColor]];
            [_alertLabel setFont:[UIFont systemFontOfSize:13]];
            [_alertLabel.layer setBackgroundColor:[UIColor clearColor].CGColor];
            _alertLabel.layer.cornerRadius = _alertLabel.frame.size.height/2;
            [_alertLabel setTextAlignment:NSTextAlignmentCenter];
        }
        [_alertLabel setHidden:NO];
        _alertLabel.layer.rasterizationScale = [UIScreen mainScreen].scale;
        _alertLabel.layer.shouldRasterize = YES;
        [UIView animateWithDuration:.33 animations:^{
            [_alertLabel setAlpha:1.0];
        }];
        
    }
}

@end

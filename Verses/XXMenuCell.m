//
//  XXMenuCell.m
//  Verses
//
//  Created by Max Haines-Stiles on 3/23/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import "XXMenuCell.h"

@implementation XXMenuCell

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

- (void)configureAlert:(NSInteger)alertCount{
    [_menuLabel setFont:[UIFont fontWithName:kSourceSansProSemibold size:18]];
    _menuLabel.layer.rasterizationScale = [UIScreen mainScreen].scale;
    _menuLabel.layer.shouldRasterize = YES;
    
    CGRect expectedSize;
    if (alertCount == 0){
        [_alertLabel setHidden:YES];
    } else {
        [_alertLabel setText:[NSString stringWithFormat:@"%d",alertCount]];
        expectedSize = [@"Writing Circles" boundingRectWithSize:_menuLabel.frame.size options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:_menuLabel.font} context:nil];

        [_alertLabel setFrame:CGRectMake(_menuLabel.frame.origin.x+expectedSize.size.width-7, _menuLabel.frame.origin.y+7, 21, 21)];
        if (_alertLabel.backgroundColor != [UIColor redColor]){
            [_alertLabel setBackgroundColor:[UIColor redColor]];
            [_alertLabel setTextColor:[UIColor whiteColor]];
            [_alertLabel setFont:[UIFont fontWithName:kSourceSansProRegular size:13]];
            [_alertLabel.layer setBackgroundColor:[UIColor clearColor].CGColor];
            _alertLabel.layer.cornerRadius = _alertLabel.frame.size.height/2;
            [_alertLabel setTextAlignment:NSTextAlignmentCenter];
        }
        [_alertLabel setHidden:NO];
        _alertLabel.layer.rasterizationScale = [UIScreen mainScreen].scale;
        _alertLabel.layer.shouldRasterize = YES;
    }
}

@end

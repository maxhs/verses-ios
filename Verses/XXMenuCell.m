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
    CGRect expectedSize;
    if (alertCount == 0){
        [self.alertLabel setHidden:YES];
    } else {
        [self.alertLabel setText:[NSString stringWithFormat:@"%d",alertCount]];
        expectedSize = [self.firstButton.titleLabel.text boundingRectWithSize:self.firstButton.titleLabel.frame.size options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:self.firstButton.titleLabel.font} context:nil];
        [self.alertLabel setHidden:NO];
        if (self.alertLabel.backgroundColor != [UIColor redColor]){
            [self.alertLabel setBackgroundColor:[UIColor redColor]];
            [self.alertLabel setTextColor:[UIColor whiteColor]];
            [self.alertLabel setFont:[UIFont fontWithName:kSourceSansProRegular size:13]];
            [self.alertLabel.layer setBackgroundColor:[UIColor clearColor].CGColor];
            self.alertLabel.layer.cornerRadius = self.alertLabel.frame.size.height/2;
            self.alertLabel.layer.rasterizationScale = [UIScreen mainScreen].scale;
            self.alertLabel.layer.shouldRasterize = YES;
            [self.alertLabel setTextAlignment:NSTextAlignmentCenter];
        }
    }
}

@end

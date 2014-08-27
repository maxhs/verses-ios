//
//  XXAddressBookContactCell.m
//  Verses
//
//  Created by Max Haines-Stiles on 6/28/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import "XXAddressBookContactCell.h"

@implementation XXAddressBookContactCell

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

- (void)configureContact:(NSDictionary *)contactDict {
    NSString *name;
    if ([contactDict objectForKey:@"first_name"] && [contactDict objectForKey:@"last_name"]){
        name = [NSString stringWithFormat:@"%@ %@",[contactDict objectForKey:@"first_name"], [contactDict objectForKey:@"last_name"]];
    } else if ([contactDict objectForKey:@"first_name"]){
        name = [contactDict objectForKey:@"first_name"];
    }
    [self.textLabel setFont:[UIFont fontWithName:kSourceSansProRegular size:19]];
    [self.textLabel setText:name];
    
    NSString *detail;
    if ([contactDict objectForKey:@"email"]){
        detail = [contactDict objectForKey:@"email"];
    } else if ([contactDict objectForKey:@"phone"]){
        detail = [contactDict objectForKey:@"phone"];
    }
    [self.detailTextLabel setFont:[UIFont fontWithName:kSourceSansProItalic size:15]];
    [self.detailTextLabel setText:detail];

    if ([contactDict objectForKey:@"image"] && [[contactDict objectForKey:@"image"] isKindOfClass:[UIImage class]]){
        [self.imageView setImage:[contactDict objectForKey:@"image"]];
    } else {
        [self.imageView setImage:nil];
    }
    self.imageView.layer.cornerRadius = self.imageView.frame.size.width/2;
    self.imageView.clipsToBounds = YES;
    self.imageView.layer.rasterizationScale = [UIScreen mainScreen].scale;
    self.imageView.layer.shouldRasterize = YES;
}

@end

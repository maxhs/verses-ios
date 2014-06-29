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
    if ([contactDict objectForKey:@"firstName"] && [contactDict objectForKey:@"lastName"]){
        name = [NSString stringWithFormat:@"%@ %@",[contactDict objectForKey:@"firstName"], [contactDict objectForKey:@"lastName"]];
    } else if ([contactDict objectForKey:@"firstName"]){
        name = [contactDict objectForKey:@"firstName"];
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
}

@end

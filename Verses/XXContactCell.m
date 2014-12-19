//
//  XXContactCell.m
//  Verses
//
//  Created by Max Haines-Stiles on 3/31/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import "XXContactCell.h"
#import "User+helper.h"
#import "Constants.h"

@implementation XXContactCell

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

-(void)configureContact:(User*)contact {
    [self.nameLabel setText:contact.penName];
    [self.nameLabel setFont:[UIFont fontWithName:kCrimsonRoman size:23]];
    if (contact.location.length){
        [self.locationLabel setText:contact.location];
        [self.locationLabel setFont:[UIFont fontWithName:kSourceSansProLight size:16]];
        [self.locationLabel setTextColor:[UIColor darkGrayColor]];
    } else {
        [self.locationLabel setText:@"No location listed"];
        [self.locationLabel setFont:[UIFont fontWithName:kSourceSansProLight size:15]];
        [self.locationLabel setTextColor:[UIColor lightGrayColor]];
    }
}
-(void)configureCircle:(Circle *)circle {
    [self.nameLabel setText:circle.name];
    [self.nameLabel setFont:[UIFont fontWithName:kCrimsonRoman size:23]];
    [self.locationLabel setText:circle.members];
    [self.locationLabel setFont:[UIFont fontWithName:kSourceSansProLight size:16]];
    [self.locationLabel setTextColor:[UIColor darkGrayColor]];

}

@end

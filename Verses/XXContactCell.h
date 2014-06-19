//
//  XXContactCell.h
//  Verses
//
//  Created by Max Haines-Stiles on 3/31/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Circle.h"

@interface XXContactCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *locationLabel;
-(void)configureContact:(User*)contact;
-(void)configureCircle:(Circle*)circle;
@end

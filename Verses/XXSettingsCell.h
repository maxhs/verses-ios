//
//  XXSettingsCell.h
//  Verses
//
//  Created by Max Haines-Stiles on 3/25/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XXUser.h"

@interface XXSettingsCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UITextField *textField;
-(void)configure:(XXUser*)user;
@end

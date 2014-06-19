//
//  XXSettingsCell.h
//  Verses
//
//  Created by Max Haines-Stiles on 3/25/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "User+helper.h"

@interface XXSettingsCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UITextField *textField;
@property (weak, nonatomic) IBOutlet UIButton *imageButton;
@property (weak, nonatomic) IBOutlet UILabel *imageLabel;
-(void)configure:(User*)user;
@end

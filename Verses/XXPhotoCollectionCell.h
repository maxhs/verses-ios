//
//  XXPhotoCollectionCell.h
//  Verses
//
//  Created by Max Haines-Stiles on 6/8/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Photo+helper.h"

@interface XXPhotoCollectionCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UIButton *photoButton;
@property (strong, nonatomic) Photo *photo;
-(void)configureForPhoto:(Photo*)photo;
@end

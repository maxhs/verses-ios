//
//  XXPhotoButton.h
//  Verses
//
//  Created by Max Haines-Stiles on 3/29/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Story+helper.h"
#import "Photo+helper.h"

@interface XXPhotoButton : UIButton
- (void)initializeWithPhoto:(Photo*)photo forStory:(Story*)story inVC:(UIViewController*)vc;
@end

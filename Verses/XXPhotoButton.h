//
//  XXPhotoButton.h
//  Verses
//
//  Created by Max Haines-Stiles on 3/29/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XXStory.h"
#import "XXPhoto.h"
#import "MWPhotoBrowser.h"

@interface XXPhotoButton : UIButton <MWPhotoBrowserDelegate>
- (void)initializeWithPhoto:(XXPhoto*)photo forStory:(XXStory*)story inVC:(UIViewController*)vc;
@end

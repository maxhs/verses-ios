//
//  XXProgress.h
//  Verses
//
//  Created by Max Haines-Stiles on 10/11/13.
//  Copyright (c) 2013 Verses. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface XXProgress : UIView

@property BOOL inProgress;

+ (XXProgress*)sharedView;
- (void)animateSharedView;
+ (void)dismiss;
@end

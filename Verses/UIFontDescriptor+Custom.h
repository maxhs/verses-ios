//
//  UIFontDescriptor+Custom.h
//  Verses
//
//  Created by Max Haines-Stiles on 4/19/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIFontDescriptor (Custom)
+(UIFontDescriptor *)preferredCustomFontForTextStyle:(NSString *)style forFont:(NSString*)font;
@end

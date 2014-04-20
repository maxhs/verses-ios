//
//  UIFontDescriptor+CrimsonText.h
//  Verses
//
//  Created by Max Haines-Stiles on 4/19/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import <UIKit/UIKit.h>
NSString *const CrimsonTextBlockquoteStyle;
@interface UIFontDescriptor (CrimsonText)

+(UIFontDescriptor *)preferredCrimsonTextFontDescriptorWithTextStyle:(NSString *)style;

@end

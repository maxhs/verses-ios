//
//  UIFontDescriptor+CrimsonText.m
//  Verses
//
//  Created by Max Haines-Stiles on 4/19/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import "UIFontDescriptor+CrimsonText.h"

NSString *const CrimsonTextBlockquoteStyle = @"CrimsonTextBlockquoteStyle";

@implementation UIFontDescriptor (CrimsonText)

+(UIFontDescriptor *)preferredCrimsonTextFontDescriptorWithTextStyle:(NSString *)style {
    static dispatch_once_t onceToken;
    static NSDictionary *fontSizeTable;
    dispatch_once(&onceToken, ^{
        fontSizeTable = @{
                          UIFontTextStyleHeadline: @{UIContentSizeCategoryExtraExtraExtraLarge: @(44),
                                                     UIContentSizeCategoryExtraExtraLarge: @(41),
                                                     UIContentSizeCategoryExtraLarge: @(37),
                                                     UIContentSizeCategoryLarge: @(33),
                                                     UIContentSizeCategoryMedium: @(30),
                                                     UIContentSizeCategorySmall: @(27),
                                                     UIContentSizeCategoryExtraSmall: @(23),},
                          
                          UIFontTextStyleSubheadline: @{UIContentSizeCategoryExtraExtraExtraLarge: @(37),
                                                        UIContentSizeCategoryExtraExtraLarge: @(30),
                                                        UIContentSizeCategoryExtraLarge: @(27),
                                                        UIContentSizeCategoryLarge: @(24),
                                                        UIContentSizeCategoryMedium: @(21),
                                                        UIContentSizeCategorySmall: @(19),
                                                        UIContentSizeCategoryExtraSmall: @(17),},
                          
                          UIFontTextStyleBody: @{UIContentSizeCategoryExtraExtraExtraLarge: @(30),
                                                 UIContentSizeCategoryExtraExtraLarge: @(27),
                                                 UIContentSizeCategoryExtraLarge: @(24),
                                                 UIContentSizeCategoryLarge: @(22),
                                                 UIContentSizeCategoryMedium: @(18),
                                                 UIContentSizeCategorySmall: @(15),
                                                 UIContentSizeCategoryExtraSmall: @(12),},
                          
                          UIFontTextStyleCaption1: @{UIContentSizeCategoryExtraExtraExtraLarge: @(20),
                                                     UIContentSizeCategoryExtraExtraLarge: @(18),
                                                     UIContentSizeCategoryExtraLarge: @(15),
                                                     UIContentSizeCategoryLarge: @(14),
                                                     UIContentSizeCategoryMedium: @(13),
                                                     UIContentSizeCategorySmall: @(12),
                                                     UIContentSizeCategoryExtraSmall: @(11),},
                          
                          UIFontTextStyleCaption2: @{UIContentSizeCategoryExtraExtraExtraLarge: @(19),
                                                     UIContentSizeCategoryExtraExtraLarge: @(17),
                                                     UIContentSizeCategoryExtraLarge: @(14),
                                                     UIContentSizeCategoryLarge: @(13),
                                                     UIContentSizeCategoryMedium: @(12),
                                                     UIContentSizeCategorySmall: @(12),
                                                     UIContentSizeCategoryExtraSmall: @(11),},
                          
                          UIFontTextStyleFootnote: @{UIContentSizeCategoryExtraExtraExtraLarge: @(23),
                                                     UIContentSizeCategoryExtraExtraLarge: @(21),
                                                     UIContentSizeCategoryExtraLarge: @(19),
                                                     UIContentSizeCategoryLarge: @(17),
                                                     UIContentSizeCategoryMedium: @(14),
                                                     UIContentSizeCategorySmall: @(12),
                                                     UIContentSizeCategoryExtraSmall: @(10),},
                          
                          CrimsonTextBlockquoteStyle: @{UIContentSizeCategoryExtraExtraExtraLarge: @(27),
                                                        UIContentSizeCategoryExtraExtraLarge: @(24),
                                                        UIContentSizeCategoryExtraLarge: @(22),
                                                        UIContentSizeCategoryLarge: @(20),
                                                        UIContentSizeCategoryMedium: @(17),
                                                        UIContentSizeCategorySmall: @(14),
                                                        UIContentSizeCategoryExtraSmall: @(12),},
    };
    });
    
    
    NSString *contentSize = [UIApplication sharedApplication].preferredContentSizeCategory;
    
    return [UIFontDescriptor fontDescriptorWithName:@"Crimson Text" size:((NSNumber *)fontSizeTable[style][contentSize]).floatValue];
}
@end

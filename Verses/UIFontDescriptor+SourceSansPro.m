//
//  UIFontDescriptor+SourceSansPro.m
//  Verses
//
//  Created by Max Haines-Stiles on 4/19/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import "UIFontDescriptor+SourceSansPro.h"

@implementation UIFontDescriptor (SourceSansPro)

+(UIFontDescriptor *)preferredSourceSansProFontDescriptorWithTextStyle:(NSString *)style {
    static dispatch_once_t onceToken;
    static NSDictionary *fontSizeTable;
    dispatch_once(&onceToken, ^{
        fontSizeTable = @{
                          UIFontTextStyleHeadline: @{UIContentSizeCategoryExtraExtraExtraLarge: @(44),
                                                     UIContentSizeCategoryExtraExtraLarge: @(41),
                                                     UIContentSizeCategoryExtraLarge: @(37),
                                                     UIContentSizeCategoryLarge: @(35),
                                                     UIContentSizeCategoryMedium: @(30),
                                                     UIContentSizeCategorySmall: @(27),
                                                     UIContentSizeCategoryExtraSmall: @(23),},
                          
                          UIFontTextStyleSubheadline: @{UIContentSizeCategoryExtraExtraExtraLarge: @(39),
                                                        UIContentSizeCategoryExtraExtraLarge: @(36),
                                                        UIContentSizeCategoryExtraLarge: @(33),
                                                        UIContentSizeCategoryLarge: @(27),
                                                        UIContentSizeCategoryMedium: @(24),
                                                        UIContentSizeCategorySmall: @(21),
                                                        UIContentSizeCategoryExtraSmall: @(19),},
                          
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
                          
                          UIFontTextStyleFootnote: @{UIContentSizeCategoryExtraExtraExtraLarge: @(17),
                                                     UIContentSizeCategoryExtraExtraLarge: @(15),
                                                     UIContentSizeCategoryExtraLarge: @(12),
                                                     UIContentSizeCategoryLarge: @(12),
                                                     UIContentSizeCategoryMedium: @(11),
                                                     UIContentSizeCategorySmall: @(10),
                                                     UIContentSizeCategoryExtraSmall: @(10),},
                          };
    });
    
    
    NSString *contentSize = [UIApplication sharedApplication].preferredContentSizeCategory;
    
    return [UIFontDescriptor fontDescriptorWithName:@"Source Sans Pro" size:((NSNumber *)fontSizeTable[style][contentSize]).floatValue];
}
@end

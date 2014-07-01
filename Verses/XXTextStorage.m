//
//  XXTextStorage.m
//  Verses
//
//  Created by Max Haines-Stiles on 3/16/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import "XXTextStorage.h"
#import "UIFontDescriptor+CrimsonText.h"
#import "UIFontDescriptor+SourceSansPro.h"

@implementation XXTextStorage {
    NSMutableAttributedString *_storage;
    NSDictionary *_replacements;
}

- (id)init
{
    if (self = [super init]) {
        _storage = [NSMutableAttributedString new];
        //[self createStyling];
    }
    return self;
}

- (NSString *)string
{
    return [_storage string];
}

- (NSDictionary *)attributesAtIndex:(NSUInteger)location
                     effectiveRange:(NSRangePointer)range
{
    return [_storage attributesAtIndex:location
                             effectiveRange:range];
}

- (void)replaceCharactersInRange:(NSRange)range withString:(NSString *)str {
    if (str != nil){
        //NSLog(@"replaceCharactersInRange:%@ withString:%@", NSStringFromRange(range), str);
        [self beginEditing];
        [_storage replaceCharactersInRange:range withString:str];
        [self edited:NSTextStorageEditedCharacters | NSTextStorageEditedAttributes range:range
       changeInLength:str.length - range.length];
        [self endEditing];
    }
}

- (void)setAttributes:(NSDictionary *)attrs range:(NSRange)range
{
    //NSLog(@"setAttributes:%@ range:%@", attrs, NSStringFromRange(range));
    [self beginEditing];
    [_storage setAttributes:attrs range:range];
    [self edited:NSTextStorageEditedAttributes range:range changeInLength:0];
    [self endEditing];
}

- (void)performReplacementsForRange:(NSRange)changedRange {
    //NSRange extendedRange = NSUnionRange(changedRange, [[_storage string] lineRangeForRange:NSMakeRange(NSMaxRange(changedRange), 0)]);
    //[self applyStylesToRange:extendedRange];
}

-(void)processEditing {
    [self performReplacementsForRange:[self editedRange]];
    [super processEditing];
}

- (void) createStyling {
    NSDictionary* boldAttributes = [self createAttributesForFontStyle:UIFontTextStyleBody withTrait:UIFontDescriptorTraitBold];
    NSDictionary* italicAttributes = [self createAttributesForFontStyle:UIFontTextStyleBody withTrait:UIFontDescriptorTraitItalic];
    NSDictionary* strikeThroughAttributes = @{ NSStrikethroughStyleAttributeName : @1};
    //NSDictionary* redTextAttributes = @{ NSForegroundColorAttributeName : [UIColor redColor]};
    NSDictionary* headingAttributes = @{NSFontAttributeName : [UIFont fontWithDescriptor:[UIFontDescriptor preferredSourceSansProFontDescriptorWithTextStyle:UIFontTextStyleHeadline] size:0]};
    
    // construct a dictionary of replacements based on regexes
    _replacements = @{
                      @"(\\*\\w+(\\s\\w+)*\\*)\\s" : boldAttributes,
                      @"(_\\w+(\\s\\w+)*_)\\s" : italicAttributes,
                      @"([0-9]+\\.)\\s" : boldAttributes,
                      @"(-\\w+(\\s\\w+)*-)\\s" : strikeThroughAttributes,
                      @"<h1>(.*?)</h1>)" : headingAttributes,
                    };
}

- (void)applyStylesToRange:(NSRange)searchRange {
    NSDictionary* normalAttrs = @{NSFontAttributeName:[UIFont preferredFontForTextStyle:UIFontTextStyleBody]};
    
    // iterate over each replacement
    for (NSString* key in _replacements) {
        NSRegularExpression *regex = [NSRegularExpression
                                      regularExpressionWithPattern:key
                                      options:0
                                      error:nil];
        
        NSDictionary* attributes = _replacements[key];
        
        [regex enumerateMatchesInString:[_storage string]
                                options:0
                                  range:searchRange
                             usingBlock:^(NSTextCheckingResult *match,
                                          NSMatchingFlags flags,
                                          BOOL *stop){
                                 // apply the style
                                 NSRange matchRange = [match rangeAtIndex:1];
                                 [self addAttributes:attributes range:matchRange];
                                 
                                 // reset the style to the original
                                 if (NSMaxRange(matchRange)+1 < self.length) {
                                     [self addAttributes:normalAttrs range:NSMakeRange(NSMaxRange(matchRange)+1, 1)];
                                 }
                             }];
    }
}

- (NSDictionary*)createAttributesForFontStyle:(NSString*)style
                                    withTrait:(uint32_t)trait {
    UIFontDescriptor *fontDescriptor = [UIFontDescriptor preferredCrimsonTextFontDescriptorWithTextStyle:UIFontTextStyleBody];
    UIFontDescriptor *descriptorWithTrait = [fontDescriptor fontDescriptorWithSymbolicTraits:trait];
    
    UIFont* font =  [UIFont fontWithDescriptor:descriptorWithTrait size: 0.0];
    return @{ NSFontAttributeName : font };
}

@end

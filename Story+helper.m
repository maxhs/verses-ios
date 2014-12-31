//
//  Story+helper.m
//  Verses
//
//  Created by Max Haines-Stiles on 6/7/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import "Story+helper.h"
#import "User+helper.h"
#import "Photo+helper.h"
#import "Contribution+helper.h"
#import <DTCoreText/DTCoreText.h>
#import "Constants.h"
#import <MagicalRecord/CoreData+MagicalRecord.h>

@implementation Story (helper)
- (void)populateFromDict:(NSDictionary*)dictionary {
    if ([dictionary objectForKey:@"id"] && [dictionary objectForKey:@"id"] != [NSNull null]) {
        self.identifier = [dictionary objectForKey:@"id"];
    }
    if ([dictionary objectForKey:@"title"] && [dictionary objectForKey:@"title"] != [NSNull null]) {
        self.title = [dictionary objectForKey:@"title"];
    }
    if ([dictionary objectForKey:@"views"] && [dictionary objectForKey:@"views"] != [NSNull null]) {
        self.views = [dictionary objectForKey:@"views"];
    }
    if ([dictionary objectForKey:@"word_count"] && [dictionary objectForKey:@"word_count"] != [NSNull null]) {
        self.wordCount = [dictionary objectForKey:@"word_count"];
    }
    if ([dictionary objectForKey:@"trending_count"] && [dictionary objectForKey:@"trending_count"] != [NSNull null]) {
        self.trendingCount = [dictionary objectForKey:@"trending_count"];
    }
    if ([dictionary objectForKey:@"minutes_to_read"] && [dictionary objectForKey:@"minutes_to_read"] != [NSNull null]) {
        self.minutesToRead = [dictionary objectForKey:@"minutes_to_read"];
    }
    if ([dictionary objectForKey:@"mystery"] && [dictionary objectForKey:@"mystery"] != [NSNull null]) {
        self.mystery = [dictionary objectForKey:@"mystery"];
    }
    if ([dictionary objectForKey:@"featured"] && [dictionary objectForKey:@"featured"] != [NSNull null]) {
        self.featured = [dictionary objectForKey:@"featured"];
    }
    if ([dictionary objectForKey:@"invite_only"] && [dictionary objectForKey:@"invite_only"] != [NSNull null]) {
        self.inviteOnly = [dictionary objectForKey:@"invite_only"];
    }
    if ([dictionary objectForKey:@"created_date"] && [dictionary objectForKey:@"created_date"] != [NSNull null]) {
        NSTimeInterval _interval = [[dictionary objectForKey:@"created_date"] doubleValue];
        self.createdDate = [NSDate dateWithTimeIntervalSince1970:_interval];
    }
    if ([dictionary objectForKey:@"updated_date"] && [dictionary objectForKey:@"updated_date"] != [NSNull null]) {
        NSTimeInterval _interval = [[dictionary objectForKey:@"updated_date"] doubleValue];
        self.updatedDate = [NSDate dateWithTimeIntervalSince1970:_interval];
    }
    if ([dictionary objectForKey:@"published_date"] && [dictionary objectForKey:@"published_date"] != [NSNull null]) {
        NSTimeInterval _interval = [[dictionary objectForKey:@"published_date"] doubleValue];
        self.publishedDate = [NSDate dateWithTimeIntervalSince1970:_interval];
    }
    if ([dictionary objectForKey:@"authors"] && [dictionary objectForKey:@"authors"] != [NSNull null]) {
        self.authorNames = [dictionary objectForKey:@"authors"];
    }
    if ([dictionary objectForKey:@"to_param"] && [dictionary objectForKey:@"to_param"] != [NSNull null]) {
        self.storyUrl = [NSString stringWithFormat:@"%@/stories/%@",kBaseUrl,[dictionary objectForKey:@"to_param"]];
    }
    if ([dictionary objectForKey:@"bookmarked"] && [dictionary objectForKey:@"bookmarked"] != [NSNull null]) {
        //for determining whether the current user has bookmarked this story
        self.bookmarked = [dictionary objectForKey:@"bookmarked"];
    }
    if ([dictionary objectForKey:@"owner"] && [dictionary objectForKey:@"owner"] != [NSNull null]) {
        User *owner = [User MR_findFirstByAttribute:@"identifier" withValue:[[dictionary objectForKey:@"owner"] objectForKey:@"id"] inContext:[NSManagedObjectContext MR_defaultContext]];
        if (owner){
            [owner update:[dictionary objectForKey:@"owner"]];
        } else {
            owner = [User MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            [owner populateFromDict:[dictionary objectForKey:@"owner"]];
        }
        
        self.owner = owner;
        self.ownerId = owner.identifier;
    } else {
        if ([self.owner.ownedStories containsObject:self]){
            [self.owner removeOwnedStory:self];
        }
    }
    
    if ([dictionary objectForKey:@"draft"] && [dictionary objectForKey:@"draft"] != [NSNull null]) {
        self.draft = [dictionary objectForKey:@"draft"];
        [self.owner addDraft:self];
    }
    
    if ([dictionary objectForKey:@"users"] && [dictionary objectForKey:@"users"] != [NSNull null]) {
        NSMutableOrderedSet *orderedUsers = [NSMutableOrderedSet orderedSet];
        for (NSDictionary *dict in [dictionary objectForKey:@"users"]){
            if ([dict objectForKey:@"id"] && [dict objectForKey:@"id"] != [NSNull null]){
                User *user = [User MR_findFirstByAttribute:@"identifier" withValue:[dict objectForKey:@"id"] inContext:[NSManagedObjectContext MR_defaultContext]];
                if (user){
                    [user update:dict];
                } else {
                    user = [User MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                    [user populateFromDict:dict];
                }
                
                [orderedUsers addObject:user];
            }
        }
        for (User *user in self.users){
            if (![orderedUsers containsObject:user]){
                [user MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
            }
        }
        self.users = orderedUsers;
    }
    if ([dictionary objectForKey:@"photos"] && [dictionary objectForKey:@"photos"] != [NSNull null]) {
        NSMutableOrderedSet *orderedPhotos = [NSMutableOrderedSet orderedSet];
        for (NSDictionary *photoDict in [dictionary objectForKey:@"photos"]){
            if ([photoDict objectForKey:@"id"] && [photoDict objectForKey:@"id"] != [NSNull null]){
                Photo *photo = [Photo MR_findFirstByAttribute:@"identifier" withValue:[photoDict objectForKey:@"id"] inContext:[NSManagedObjectContext MR_defaultContext]];
                if (photo){
                    [photo update:photoDict];
                } else {
                    photo = [Photo MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                    [photo populateFromDict:photoDict];
                }
                
                [orderedPhotos addObject:photo];
            }
        }
        for (Photo *photo in self.photos){
            if (![orderedPhotos containsObject:photo]){
                [photo MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
            }
        }
        self.photos = orderedPhotos;
    }
    
    if ([dictionary objectForKey:@"feedbacks"] && [dictionary objectForKey:@"feedbacks"] != [NSNull null]) {
        NSMutableOrderedSet *orderedFeedbacks = [NSMutableOrderedSet orderedSet];
        for (NSDictionary *dict in [dictionary objectForKey:@"feedbacks"]){
            for (NSDictionary *feedbackDict in dict){
                if ([feedbackDict objectForKey:@"id"] != [NSNull null]){
                    Feedback *feedback = [Feedback MR_findFirstByAttribute:@"identifier" withValue:[feedbackDict objectForKey:@"id"] inContext:[NSManagedObjectContext MR_defaultContext]];
                    if (feedback){
                        [feedback update:feedbackDict];
                    } else {
                        feedback = [Feedback MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                        [feedback populateFromDict:feedbackDict];
                    }
                    [orderedFeedbacks addObject:feedback];
                }
            }
        }
        for (Feedback *feedback in self.feedbacks){
            if (![orderedFeedbacks containsObject:feedback]){
                [feedback MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
            }
        }
        self.feedbacks = orderedFeedbacks;
    }
    
    if ([dictionary objectForKey:@"contributions"] && [dictionary objectForKey:@"contributions"] != [NSNull null]) {
        NSMutableOrderedSet *orderedContributions = [NSMutableOrderedSet orderedSet];
        for (NSDictionary *dict in [dictionary objectForKey:@"contributions"]){
            Contribution *contribution = [Contribution MR_findFirstByAttribute:@"identifier" withValue:[dict objectForKey:@"id"] inContext:[NSManagedObjectContext MR_defaultContext]];
            if (contribution){
                [contribution update:dict];
            } else {
                contribution = [Contribution MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                [contribution populateFromDict:dict];
            }
            
            [orderedContributions addObject:contribution];
        }
        for (Contribution *contribution in self.contributions){
            if (![orderedContributions containsObject:contribution]){
                [contribution MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
            }
        }
        self.contributions = orderedContributions;
        
        int rangeAmount;
        if ([self.mystery isEqualToNumber:[NSNumber numberWithBool:YES]]){
            rangeAmount = 250;
        } else {
            rangeAmount = 1200;
        }
        NSRange range;
        if ([[self.contributions.firstObject body] length] > rangeAmount){
            range = NSMakeRange(0, rangeAmount);
        } else {
            range = NSMakeRange(0, [[self.contributions.firstObject body] length]);
        }
        
        DTCSSStylesheet *styleSheet = [[DTCSSStylesheet alloc] initWithStyleBlock:@".screen {font-family:'Courier';}"];
        
        NSDictionary *options = @{DTUseiOS6Attributes: [NSNumber numberWithBool:YES],
                                  DTDefaultFontSize: @21,
                                  DTDefaultStyleSheet: styleSheet,
                                  DTDefaultFontFamily: @"Crimson Text",
                                  NSTextEncodingNameDocumentOption: @"UTF-8"};
        DTHTMLAttributedStringBuilder *stringBuilder = [[DTHTMLAttributedStringBuilder alloc] initWithHTML:[[[self.contributions.firstObject body] substringWithRange:range] dataUsingEncoding:NSUTF8StringEncoding] options:options documentAttributes:nil];
        NSMutableAttributedString *mutableString = [stringBuilder generatedAttributedString].mutableCopy;
        
        [mutableString enumerateAttributesInRange:NSMakeRange(0, mutableString.length) options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired usingBlock:^(NSDictionary *attrs, NSRange range, BOOL *stop) {

            if ([[attrs objectForKey:@"DTHeaderLevel"]  isEqual: @1]){
                [mutableString addAttribute:NSFontAttributeName value:[UIFont fontWithDescriptor:[[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleHeadline forFont:kSourceSansPro] fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold] size:0] range:range];
                NSMutableParagraphStyle *centerStyle = [[NSMutableParagraphStyle alloc] init];
                [mutableString addAttribute:NSParagraphStyleAttributeName value:centerStyle range:range];
                
            } else if ([[attrs objectForKey:@"DTHeaderLevel"]  isEqual: @2] || [[attrs objectForKey:@"DTHeaderLevel"]  isEqual: @3]){
                [mutableString addAttribute:NSFontAttributeName value:[UIFont fontWithDescriptor:[[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleSubheadline forFont:kSourceSansPro] fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold] size:0] range:range];
                
                
            } else if ([[attrs objectForKey:@"DTBlockquote"]  isEqual: @1]){
                [mutableString addAttribute:NSFontAttributeName value:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kCrimsonRoman] size:0] range:range];
                NSMutableParagraphStyle *centerStyle = [[NSMutableParagraphStyle alloc] init];
                [mutableString addAttribute:NSParagraphStyleAttributeName value:centerStyle range:range];
            }
        }];
        [mutableString endEditing];
        self.attributedSnippet = mutableString;
    }
}

- (void)createFromDict:(NSDictionary*)dictionary {
    if ([dictionary objectForKey:@"id"] && [dictionary objectForKey:@"id"] != [NSNull null]) {
        self.identifier = [dictionary objectForKey:@"id"];
    }
    if ([dictionary objectForKey:@"views"] && [dictionary objectForKey:@"views"] != [NSNull null]) {
        self.views = [dictionary objectForKey:@"views"];
    }
    if ([dictionary objectForKey:@"word_count"] && [dictionary objectForKey:@"word_count"] != [NSNull null]) {
        self.wordCount = [dictionary objectForKey:@"word_count"];
    }
    if ([dictionary objectForKey:@"trending_count"] && [dictionary objectForKey:@"trending_count"] != [NSNull null]) {
        self.trendingCount = [dictionary objectForKey:@"trending_count"];
    }
    if ([dictionary objectForKey:@"minutes_to_read"] && [dictionary objectForKey:@"minutes_to_read"] != [NSNull null]) {
        self.minutesToRead = [dictionary objectForKey:@"minutes_to_read"];
    }
    if ([dictionary objectForKey:@"created_date"] && [dictionary objectForKey:@"created_date"] != [NSNull null]) {
        NSTimeInterval _interval = [[dictionary objectForKey:@"created_date"] doubleValue];
        self.createdDate = [NSDate dateWithTimeIntervalSince1970:_interval];
    }
    if ([dictionary objectForKey:@"updated_date"] && [dictionary objectForKey:@"updated_date"] != [NSNull null]) {
        NSTimeInterval _interval = [[dictionary objectForKey:@"updated_date"] doubleValue];
        self.updatedDate = [NSDate dateWithTimeIntervalSince1970:_interval];
    }
    if ([dictionary objectForKey:@"published_date"] && [dictionary objectForKey:@"published_date"] != [NSNull null]) {
        NSTimeInterval _interval = [[dictionary objectForKey:@"published_date"] doubleValue];
        self.publishedDate = [NSDate dateWithTimeIntervalSince1970:_interval];
    }
    if ([dictionary objectForKey:@"authors"] && [dictionary objectForKey:@"authors"] != [NSNull null]) {
        self.authorNames = [dictionary objectForKey:@"authors"];
    }
    if ([dictionary objectForKey:@"to_param"] && [dictionary objectForKey:@"to_param"] != [NSNull null]) {
        self.storyUrl = [NSString stringWithFormat:@"%@/stories/%@",kBaseUrl,[dictionary objectForKey:@"to_param"]];
    }
    if ([dictionary objectForKey:@"contributions"] && [dictionary objectForKey:@"contributions"] != [NSNull null]) {
        NSMutableOrderedSet *orderedContributions = [NSMutableOrderedSet orderedSet];
        for (NSDictionary *dict in [dictionary objectForKey:@"contributions"]){
            Contribution *contribution = [Contribution MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            [contribution populateFromDict:dict];
            [orderedContributions addObject:contribution];
        }
        self.contributions = orderedContributions;
    }
}

- (void)addContribution:(Contribution*)contribution{
    NSMutableOrderedSet *contributionSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.contributions];
    [contributionSet addObject:contribution];
    self.contributions = contributionSet;
}

- (void)removeContribution:(Contribution*)contribution{
    NSMutableOrderedSet *contributionSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.contributions];
    [contributionSet removeObject:contribution];
    self.contributions = contributionSet;
}

- (void)replaceFeedback:(Feedback*)newFeedback{
    NSMutableOrderedSet *orderedFeedbacks = [NSMutableOrderedSet orderedSetWithOrderedSet:self.feedbacks];
    for (Feedback *feedback in self.feedbacks){
        if ([feedback.identifier isEqualToNumber:newFeedback.identifier]){
            [orderedFeedbacks replaceObjectAtIndex:[self.feedbacks indexOfObject:feedback] withObject:newFeedback];
            break;
        }
    }
    self.feedbacks = orderedFeedbacks;
}

- (void)addFeedback:(Feedback*)feedback{
    NSMutableOrderedSet *set = [[NSMutableOrderedSet alloc] initWithOrderedSet:self.feedbacks];
    [set addObject:feedback];
    self.feedbacks = set;
}

- (void)removeFeedback:(Feedback*)feedback{
    NSMutableOrderedSet *set = [[NSMutableOrderedSet alloc] initWithOrderedSet:self.feedbacks];
    [set removeObject:feedback];
    self.feedbacks = set;
}

- (void)addPhoto:(Photo*)photo {
    NSMutableOrderedSet *photoSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.photos];
    [photoSet addObject:photo];
    self.photos = photoSet;
}

- (void)removePhoto:(Photo*)photo {
    NSMutableOrderedSet *photoSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.photos];
    [photoSet removeObject:photo];
    self.photos = photoSet;
}

- (void)addUser:(User*)user {
    NSMutableOrderedSet *set = [NSMutableOrderedSet orderedSetWithOrderedSet:self.users];
    if (user)[set addObject:user];
    self.users = set;
}

- (void)removeUser:(User*)user {
    NSMutableOrderedSet *set = [NSMutableOrderedSet orderedSetWithOrderedSet:self.users];
    if (user)[set removeObject:user];
    self.users = set;
}

- (void)addCircle:(Circle*)circle {
    NSMutableOrderedSet *set = [NSMutableOrderedSet orderedSetWithOrderedSet:self.circles];
    if (circle)[set addObject:circle];
    self.circles = set;
}

- (void)removeCircle:(Circle*)circle {
    NSMutableOrderedSet *set = [NSMutableOrderedSet orderedSetWithOrderedSet:self.circles];
    if (circle)[set removeObject:circle];
    self.circles = set;
}

@end


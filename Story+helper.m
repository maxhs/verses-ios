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
    if ([dictionary objectForKey:@"created_date"] && [dictionary objectForKey:@"created_date"] != [NSNull null]) {
        self.epochTime = [dictionary objectForKey:@"created_date"];
        NSTimeInterval _interval = [self.epochTime doubleValue];
        self.createdDate = [NSDate dateWithTimeIntervalSince1970:_interval];
    }
    if ([dictionary objectForKey:@"updated_date"] && [dictionary objectForKey:@"updated_date"] != [NSNull null]) {
        NSTimeInterval _interval = [[dictionary objectForKey:@"updated_date"] doubleValue];
        self.updatedDate = [NSDate dateWithTimeIntervalSince1970:_interval];
    }
    if ([dictionary objectForKey:@"published_date"] && [dictionary objectForKey:@"published_date"] != [NSNull null]) {
        NSTimeInterval _interval = [[dictionary objectForKey:@"published_date"] doubleValue];
        self.published = [NSDate dateWithTimeIntervalSince1970:_interval];
    }
    if ([dictionary objectForKey:@"authors"] != [NSNull null]) {
        self.authorNames = [dictionary objectForKey:@"authors"];
    }
    if ([dictionary objectForKey:@"to_param"] != [NSNull null]) {
        self.storyUrl = [NSString stringWithFormat:@"%@/stories/%@",kBaseUrl,[dictionary objectForKey:@"to_param"]];
    }
    if ([dictionary objectForKey:@"owner"] && [dictionary objectForKey:@"owner"] != [NSNull null]) {
        User *owner = [User MR_findFirstByAttribute:@"identifier" withValue:[[dictionary objectForKey:@"owner"] objectForKey:@"id"]];
        if (!owner){
            owner = [User MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
        }
        [owner populateFromDict:[dictionary objectForKey:@"owner"]];
        self.owner = owner;
    }
    if ([dictionary objectForKey:@"users"] != [NSNull null]) {
        NSMutableOrderedSet *orderedUsers = [NSMutableOrderedSet orderedSet];
        NSLog(@"users: %@",[dictionary objectForKey:@"users"]);
        for (NSDictionary *dict in [dictionary objectForKey:@"users"]){
            User *user = [User MR_findFirstByAttribute:@"identifier" withValue:[dict objectForKey:@"id"]];
            if (!user){
                user = [User MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [user populateFromDict:dict];
            [orderedUsers addObject:user];
            
        }
        for (User *user in self.photos){
            if (![orderedUsers containsObject:user]){
                [user MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
            }
        }
        self.users = orderedUsers;
    }
    if ([dictionary objectForKey:@"photos"] && [dictionary objectForKey:@"photos"] != [NSNull null]) {
        NSMutableOrderedSet *orderedPhotos = [NSMutableOrderedSet orderedSet];
        for (NSDictionary *dict in [dictionary objectForKey:@"photos"]){
            for (NSDictionary *photoDict in dict){
                if ([photoDict objectForKey:@"id"] && [photoDict objectForKey:@"id"] != [NSNull null]){
                    Photo *photo = [Photo MR_findFirstByAttribute:@"identifier" withValue:[photoDict objectForKey:@"id"]];
                    if (!photo){
                        photo = [Photo MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                    }
                    [photo populateFromDict:photoDict];
                    [orderedPhotos addObject:photo];
                }
            }
        }
        for (Photo *photo in self.photos){
            if (![orderedPhotos containsObject:photo]){
                [photo MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
            }
        }
        self.photos = orderedPhotos;
    }
    if ([dictionary objectForKey:@"contributions"] && [dictionary objectForKey:@"contributions"] != [NSNull null]) {
        NSMutableOrderedSet *orderedContributions = [NSMutableOrderedSet orderedSet];
        for (NSDictionary *dict in [dictionary objectForKey:@"contributions"]){
            Contribution *contribution = [Contribution MR_findFirstByAttribute:@"identifier" withValue:[dict objectForKey:@"id"]];
            if (!contribution){
                contribution = [Contribution MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [contribution populateFromDict:dict];
            [orderedContributions addObject:contribution];
        }
        for (Contribution *contribution in self.contributions){
            if (![orderedContributions containsObject:contribution]){
                [contribution MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
            }
        }
        self.contributions = orderedContributions;
        int rangeAmount;
        if (self.mystery){
            rangeAmount = 250;
        } else if (IDIOM == IPAD) {
            rangeAmount = 1000;
        } else {
            rangeAmount = 700;
        }
        NSRange range;
        if ([[self.contributions.firstObject body] length] > rangeAmount){
            range = NSMakeRange(0, rangeAmount);
        } else {
            range = NSMakeRange(0, [[self.contributions.firstObject body] length]);
        }
        
        NSDictionary *options = @{DTUseiOS6Attributes: [NSNumber numberWithBool:YES],
                                  DTDefaultFontSize: @21,
                                  DTDefaultFontFamily: @"Crimson Text",
                                  NSTextEncodingNameDocumentOption: @"UTF-8"};
        DTHTMLAttributedStringBuilder *stringBuilder = [[DTHTMLAttributedStringBuilder alloc] initWithHTML:[[[self.contributions.firstObject body] substringWithRange:range] dataUsingEncoding:NSUTF8StringEncoding] options:options documentAttributes:nil];
        self.attributedSnippet = [stringBuilder generatedAttributedString];
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
    [self.feedbacks enumerateObjectsUsingBlock:^(Feedback *feedback, NSUInteger idx, BOOL *stop) {
        if ([feedback.identifier isEqualToNumber:newFeedback.identifier]){
            [orderedFeedbacks replaceObjectAtIndex:idx withObject:newFeedback];
            self.feedbacks = orderedFeedbacks;
            *stop = YES;
        }
    }];
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


@end


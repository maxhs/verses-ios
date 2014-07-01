//
//  Contribution+helper.m
//  Verses
//
//  Created by Max Haines-Stiles on 6/7/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import "Contribution+helper.h"
#import "User+helper.h"

@implementation Contribution (helper)
- (void)populateFromDict:(NSDictionary*)dictionary {
    if ([dictionary objectForKey:@"id"] && [dictionary objectForKey:@"id"] != [NSNull null]) {
        self.identifier = [dictionary objectForKey:@"id"];
    }
    if ([dictionary objectForKey:@"body"] && [dictionary objectForKey:@"body"] != [NSNull null]) {
        self.body = [dictionary objectForKey:@"body"];
    }
    if ([dictionary objectForKey:@"word_count"] && [dictionary objectForKey:@"word_count"] != [NSNull null]) {
        self.wordCount = [dictionary objectForKey:@"word_count"];
    }
    if ([dictionary objectForKey:@"allow_feedback"] && [dictionary objectForKey:@"allow_feedback"] != [NSNull null]) {
        self.allowFeedback = [dictionary objectForKey:@"allow_feedback"];
    }
    if ([dictionary objectForKey:@"user"] && [dictionary objectForKey:@"user"] != [NSNull null]) {
        User *user = [User MR_findFirstByAttribute:@"identifier" withValue:[[dictionary objectForKey:@"user"] objectForKey:@"id"]];
        if (user){
            [user update:[dictionary objectForKey:@"user"]];
        } else {
            user = [User MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            [user populateFromDict:[dictionary objectForKey:@"user"]];
        }
        
        self.user = user;
    }
    if ([dictionary objectForKey:@"story"] && [dictionary objectForKey:@"story"] != [NSNull null]) {
        Story *story = [Story MR_findFirstByAttribute:@"identifier" withValue:[[dictionary objectForKey:@"story"] objectForKey:@"id"]];
        if (story){
            self.story = story;
        }
    }
    if ([dictionary objectForKey:@"draft"] && [dictionary objectForKey:@"draft"] != [NSNull null]) {
        self.draft = [dictionary objectForKey:@"draft"];
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
    if ([dictionary objectForKey:@"photos"] && [dictionary objectForKey:@"photos"] != [NSNull null]) {
        NSMutableOrderedSet *orderedPhotos = [NSMutableOrderedSet orderedSet];
        for (NSDictionary *photoDict in [dictionary objectForKey:@"photos"]){
            if ([photoDict objectForKey:@"id"] && [photoDict objectForKey:@"id"] != [NSNull null]){
                Photo *photo = [Photo MR_findFirstByAttribute:@"identifier" withValue:[photoDict objectForKey:@"id"]];
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
}

- (void)update:(NSDictionary*)dictionary {

    if ([dictionary objectForKey:@"body"] && [dictionary objectForKey:@"body"] != [NSNull null]) {
        self.body = [dictionary objectForKey:@"body"];
    }
    if ([dictionary objectForKey:@"word_count"] && [dictionary objectForKey:@"word_count"] != [NSNull null]) {
        self.wordCount = [dictionary objectForKey:@"word_count"];
    }
    if ([dictionary objectForKey:@"allow_feedback"] && [dictionary objectForKey:@"allow_feedback"] != [NSNull null]) {
        self.allowFeedback = [dictionary objectForKey:@"allow_feedback"];
    }
    if ([dictionary objectForKey:@"user"] && [dictionary objectForKey:@"user"] != [NSNull null]) {
        User *user = [User MR_findFirstByAttribute:@"identifier" withValue:[[dictionary objectForKey:@"user"] objectForKey:@"id"]];
        if (user){
            [user update:[dictionary objectForKey:@"user"]];
        } else {
            user = [User MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            [user populateFromDict:[dictionary objectForKey:@"user"]];
        }
        
        self.user = user;
    }

    if ([dictionary objectForKey:@"draft"] && [dictionary objectForKey:@"draft"] != [NSNull null]) {
        self.draft = [dictionary objectForKey:@"draft"];
    }

    if ([dictionary objectForKey:@"updated_date"] && [dictionary objectForKey:@"updated_date"] != [NSNull null]) {
        NSTimeInterval _interval = [[dictionary objectForKey:@"updated_date"] doubleValue];
        self.updatedDate = [NSDate dateWithTimeIntervalSince1970:_interval];
    }
    if ([dictionary objectForKey:@"published_date"] && [dictionary objectForKey:@"published_date"] != [NSNull null]) {
        NSTimeInterval _interval = [[dictionary objectForKey:@"published_date"] doubleValue];
        self.publishedDate = [NSDate dateWithTimeIntervalSince1970:_interval];
    }
    if ([dictionary objectForKey:@"photos"] && [dictionary objectForKey:@"photos"] != [NSNull null]) {
        NSMutableOrderedSet *orderedPhotos = [NSMutableOrderedSet orderedSet];
        for (NSDictionary *photoDict in [dictionary objectForKey:@"photos"]){
            if ([photoDict objectForKey:@"id"] && [photoDict objectForKey:@"id"] != [NSNull null]){
                Photo *photo = [Photo MR_findFirstByAttribute:@"identifier" withValue:[photoDict objectForKey:@"id"]];
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
}


- (void)addPhoto:(Photo*)photo {
    NSMutableOrderedSet *photoSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.photos];
    [photoSet addObject:photo];
    [self.story addPhoto:photo];
    self.photos = photoSet;
}

- (void)removePhoto:(Photo*)photo {
    NSMutableOrderedSet *photoSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.photos];
    [photoSet removeObject:photo];
    [self.story removePhoto:photo];
    self.photos = photoSet;
}

@end

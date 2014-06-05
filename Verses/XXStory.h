//
//  XXStory.h
//  Verses
//
//  Created by Max Haines-Stiles on 10/7/13.
//  Copyright (c) 2013 Verses. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XXContribution.h"
#import "XXUser.h"

@interface XXStory : NSObject

@property (strong, nonatomic) NSMutableArray *contributions;
@property (strong, nonatomic) NSArray *photos;
@property (strong, nonatomic) NSArray *userPhotos;
@property (strong, nonatomic) NSMutableArray *tags;
@property (strong, nonatomic) NSNumber *identifier;
@property (strong, nonatomic) NSString *title;
@property (strong, nonatomic) NSAttributedString *attributedSnippet;
@property (strong, nonatomic) NSNumber *views;
@property (strong, nonatomic) NSNumber *wordCount;
@property (strong, nonatomic) NSNumber *trendingCount;
@property (strong, nonatomic) NSNumber *minutesToRead;
@property (strong, nonatomic) NSNumber *epochTime;
@property (strong, nonatomic) NSDate *createdDate;
@property (strong, nonatomic) NSDate *updatedDate;
@property (strong, nonatomic) NSDate *published;
@property (strong, nonatomic) XXUser *owner;
@property (strong, nonatomic) NSString *author;
@property (strong, nonatomic) NSString *authors;
@property (strong, nonatomic) NSMutableArray *collaborators;
@property (strong, nonatomic) NSMutableArray *circles;
@property (strong, nonatomic) NSMutableArray *feedbacks;
@property (strong, nonatomic) NSString *storyUrl;

@property BOOL privateStory;
@property BOOL saved;
@property BOOL mystery;
@property BOOL joinable;
@property BOOL bookmarked;

- (id) initWithDictionary:(NSDictionary*)dictionary;
- (XXContribution*)lastContribution;
- (XXContribution*)firstContribution;

@end

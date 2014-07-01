//
//  Story+helper.h
//  Verses
//
//  Created by Max Haines-Stiles on 6/7/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import "Story.h"
#import "Contribution+helper.h"
#import "Feedback+helper.h"
#import "User.h"
#import "Circle+helper.h"

@interface Story (helper)
- (void)populateFromDict:(NSDictionary*)dict;
- (void)createFromDict:(NSDictionary*)dict;
- (void)addContribution:(Contribution*)contribution;
- (void)removeContribution:(Contribution*)contribution;
- (void)replaceFeedback:(Feedback*)feedback;
- (void)addFeedback:(Feedback*)feedback;
- (void)removeFeedback:(Feedback*)feedback;
- (void)addPhoto:(Photo*)photo;
- (void)removePhoto:(Photo*)photo;
- (void)addUser:(User*)user;
- (void)removeUser:(User*)user;
- (void)addCircle:(Circle*)circle;
- (void)removeCircle:(Circle*)circle;
@end

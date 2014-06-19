//
//  User+helper.h
//  Verses
//
//  Created by Max Haines-Stiles on 6/7/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import "User.h"

@interface User (helper)
- (void)populateFromDict:(NSDictionary*)dict;
- (void)addNotification:(Notification*)notification;
- (void)removeNotification:(Notification*)notification;
- (void)addBookmark:(Bookmark*)bookmark;
- (void)removeBookmark:(Bookmark*)bookmark;
- (void)addDraft:(Story*)story;
- (void)removeDraft:(Story*)story;
- (void)addOwnedStory:(Story*)story;
- (void)removeOwnedStory:(Story*)story;
- (void)addStory:(Story*)story;
- (void)removeStory:(Story*)story;
- (void)addCircle:(Circle*)circle;
- (void)removeCircle:(Circle*)circle;
- (void)addContact:(User*)user;
- (void)removeContact:(User*)user;
@end

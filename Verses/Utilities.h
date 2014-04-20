//
//  Utilities.h
//  Verses
//
//  Created by Max Haines-Stiles on 10/11/13.
//  Copyright (c) 2013 Verses. All rights reserved.
//

typedef NS_ENUM(NSUInteger, MSPaneViewControllerType) {
    MSPaneViewControllerTypeStylers,
    MSPaneViewControllerTypeDynamics,
    MSPaneViewControllerTypeBounce,
    MSPaneViewControllerTypeGestures,
    MSPaneViewControllerTypeControls,
    MSPaneViewControllerTypeMap,
    MSPaneViewControllerTypeLongTable,
    MSPaneViewControllerTypeMonospace,
    MSPaneViewControllerTypeCount
};

#import <Foundation/Foundation.h>

@interface Utilities : NSObject

+ (UIImageView *)findNavShadow:(UIView *)view;
+ (NSArray *)storiesFromJSONArray:(NSMutableArray *) array;
+ (NSArray *)contributionsFromJSONArray:(NSMutableArray *) array;
+ (NSArray *)tagsFromJSONArray:(NSMutableArray *) array;
+ (NSArray *)photosFromJSONArray:(NSMutableArray *) array;
+ (NSArray *)notificationsFromJSONArray:(NSMutableArray *) array;
+ (NSArray *)circlesFromJSONArray:(NSMutableArray *) array;
+ (NSArray *)usersFromJSONArray:(NSMutableArray *) array;
+ (NSArray *)feedbacksFromJSONArray:(NSMutableArray *) array;
+ (NSArray *)commentsFromJSONArray:(NSMutableArray *) array;
+ (NSArray *)bookmarksFromJSONArray:(NSMutableArray *) array;
@end

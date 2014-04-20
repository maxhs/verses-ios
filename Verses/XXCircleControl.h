//
//  XXCircleControl.h
//  Verses
//
//  Created by Max Haines-Stiles on 4/18/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol XXCircleControlDelegate;

@interface XXCircleControl : UIControl <UIBarPositioning, UIAppearance>

@property (nonatomic, weak) id <XXCircleControlDelegate> delegate;
@property (nonatomic, retain) NSArray *items;
@property (nonatomic) NSInteger selectedSegmentIndex;
@property (nonatomic, readonly) NSUInteger numberOfSegments;
@property (nonatomic, readonly) CGFloat height; //defaultts to 56px
@property (nonatomic, readwrite) CGFloat selectionIndicatorHeight UI_APPEARANCE_SELECTOR; //default is 2px
@property (nonatomic, readwrite) CGFloat animationDuration UI_APPEARANCE_SELECTOR; //default is .17 sec
@property (nonatomic, retain) UIFont *font UI_APPEARANCE_SELECTOR;
@property (nonatomic, readwrite) UIColor *hairlineColor UI_APPEARANCE_SELECTOR;
@property (nonatomic) BOOL showsCount;
@property (nonatomic) BOOL autoAdjustSelectionIndicatorWidth;

- (id)initWithItems:(NSArray *)items;
- (void)setTitle:(NSString *)title withImage:(UIImage*)image forSegmentAtIndex:(NSUInteger)segment;
- (void)setTitleColor:(UIColor *)color forState:(UIControlState)state;

- (void)darkBackground;
- (void)lightBackground;
 //@param segment An index number identifying a segment in the control. It must be a number between 0 and the number of segments (numberOfSegments) minus 1; values exceeding this upper range are pinned to it.
- (void)setCount:(NSNumber *)count forSegmentAtIndex:(NSUInteger)segment;

 //@param enabled YES to enable the specified segment or NO to disable the segment. By default, segments are enabled.
 //@param segment An index number identifying a segment in the control. It must be a number between 0 and the number of segments (numberOfSegments) minus 1; values exceeding this upper range are pinned to it.
- (void)setEnabled:(BOOL)enabled forSegmentAtIndex:(NSUInteger)segment;
- (NSString *)titleForSegmentAtIndex:(NSUInteger)segment;
- (NSNumber *)countForSegmentAtIndex:(NSUInteger)segment;
- (void)removeAllSegments;

@end

@protocol XXCircleControlDelegate <UIBarPositioningDelegate>

@end

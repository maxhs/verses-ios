//
//  XXChat.h
//  Verses
//
//  Created by Max Haines-Stiles on 4/18/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol XXChatDelegate

@required - (void) chatInputNewMessageSent:(NSString *)messageString;

@end

@interface XXChat : UIView <UITextViewDelegate>

@property (retain, nonatomic) id<XXChatDelegate>delegate;

@property (strong, nonatomic) UILabel * placeholderLabel;
@property (strong, nonatomic) UIColor * sendButtonActiveColor;
@property (strong, nonatomic) UIColor * sendButtonInactiveColor;
@property (strong, nonatomic) UIToolbar * bgToolbar;
@property (strong, nonatomic) UITextView * textView;
@property BOOL stopAutoClose;
@property (strong, nonatomic) NSNumber * maxY;
@property (strong, nonatomic) NSNumber * maxCharacters;
- (void) close;
- (void) open;
- (void) willRotate;
- (void) isRotating;
- (void) didRotate;

@property BOOL shouldIgnoreKeyboardNotifications; //for autocorrect

@end


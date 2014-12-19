//
//  XXChat.m
//  Verses
//
//  Created by Max Haines-Stiles on 4/18/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import "XXChat.h"
#import "Constants.h"

@interface XXChat ()

@property (strong, nonatomic) UIButton * sendButton;

@end

@implementation XXChat {
    int currentKeyboardHeight;
    BOOL isAnimatingRotation;
    BOOL isKeyboardVisible;
}

@synthesize stopAutoClose;

- (id)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {
        
        UIInterfaceOrientation myOrientation = [UIApplication sharedApplication].statusBarOrientation;
        if (UIInterfaceOrientationIsPortrait(myOrientation)) {
            self.frame = CGRectMake(0, screenHeight() - 40, screenWidth(), 40);
        }
        else {
            self.frame = CGRectMake(0, screenWidth() - 40, screenHeight(), 40);
        }
        
        // Other Properties
        self.layer.masksToBounds = YES;
        self.clipsToBounds = YES;
        self.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
        
        // Set Defaults
        _maxY = [NSNumber numberWithInt:60]; // A frame origin y of 60 will prevent further expansion
        
        // Expanding Text View
        if (!_textView) _textView = [[UITextView alloc]init];
        _textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _textView.frame = CGRectMake(5, 6, self.bounds.size.width - 75, 28);
        _textView.delegate = self;
        _textView.layer.cornerRadius = 7;
        _textView.font = [UIFont fontWithName:kSourceSansProRegular size:16];
        
        if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
            _textView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.f];
            _textView.textColor = [UIColor whiteColor];
            _textView.layer.borderWidth = 1;
            _textView.layer.borderColor = [UIColor colorWithWhite:1 alpha:.23].CGColor;
        } else {
            _textView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.9f];
            _textView.textColor = [UIColor darkTextColor];
            _textView.layer.borderWidth = .5;
            _textView.layer.borderColor = [UIColor colorWithWhite:.87 alpha:1].CGColor;
        }
        
        [self addSubview:_textView];
        
        _sendButton = [UIButton buttonWithType:UIButtonTypeSystem];
        _sendButtonActiveColor = kElectricBlue;
        _sendButtonInactiveColor = [UIColor lightGrayColor];
        [self deactivateSendBtn];
        
        _sendButton.frame = CGRectMake(self.bounds.size.width - 60, 0, 50, 40);
        _sendButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
        [_sendButton setTitle:@"Send" forState:UIControlStateNormal];
        _sendButton.titleLabel.font = [UIFont fontWithName:kSourceSansProSemibold size:15.0];
        [_sendButton addTarget:self action:@selector(sendBtnPressed:) forControlEvents:UIControlEventTouchUpInside];
        _sendButton.userInteractionEnabled = YES;
        [self addSubview:_sendButton];
        
        // toolbar styling
        _bgToolbar = [[UIToolbar alloc] initWithFrame:self.bounds];
        if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
            self.backgroundColor = [UIColor clearColor];
            _bgToolbar.barStyle = UIBarStyleBlackTranslucent;
            [_bgToolbar setBackgroundColor:[UIColor colorWithWhite:0 alpha:.75]];
        } else {
            self.backgroundColor = [UIColor whiteColor];
            _bgToolbar.barStyle = UIBarStyleDefault;
        }
        
        _bgToolbar.translucent = YES;
        _bgToolbar.clipsToBounds = YES;
        _bgToolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self insertSubview:_bgToolbar belowSubview:_textView];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardWillShow:)
                                                     name:UIKeyboardWillShowNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardWillHide:)
                                                     name:UIKeyboardWillHideNotification
                                                   object:nil];
        
    }
    
    return self;
}

#pragma mark Layout Subviews

- (void) layoutSubviews {
    _bgToolbar.frame = self.bounds;
}

#pragma mark Burn it down

- (void) removeFromSuperview {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [_placeholderLabel removeFromSuperview];
    _placeholderLabel = nil;
    
    [_textView removeFromSuperview];
    _textView.text = nil;
    _textView.delegate = nil;
    _textView = nil;
    
    [_sendButton removeTarget:self action:@selector(sendBtnPressed:) forControlEvents:UIControlEventTouchUpInside];
    [_sendButton removeFromSuperview];
    _sendButton = nil;
    
    [_bgToolbar removeFromSuperview];;
    _bgToolbar = nil;
    
    _delegate = nil;
    _maxY = nil;
    _maxCharacters = nil;
    _sendButtonActiveColor = nil;
    _sendButtonInactiveColor = nil;
    
    [super removeFromSuperview];
}

#pragma mark SEND MESSAGE

- (void)sendBtnPressed:(id)sender {
    
    if (_textView.text.length > 0) {
        
        // start - finishes autocorrects
        _shouldIgnoreKeyboardNotifications = YES;
        [_textView endEditing:YES];
        [_textView setKeyboardType:UIKeyboardTypeAlphabet];
        [_textView becomeFirstResponder];
        _shouldIgnoreKeyboardNotifications = NO; // implemented lower?
        // end - finishes autocorrects
        
        NSString * string = _textView.text;
        
        [UIView animateWithDuration:.2 animations:^{
            
            // update placeholder
            _placeholderLabel.hidden = NO;
            
            // Reset Text
            _textView.text = @"";
            
            // Reset Send
            [self deactivateSendBtn];
            
            // Reset Frame
            self.frame = CGRectMake(0, self.frame.origin.y + self.bounds.size.height, self.bounds.size.width, -40);
            
        } completion:^(BOOL finished) {
            
            // Resize & Alyne
            [self resizeView];
            [self alignTextViewWithAnimation:NO];
            
            // Pass Off The Message
            [_delegate chatInputNewMessageSent:string];
        }];
    }
}

#pragma mark ACTIVATE | DEACTIVATE - SEND BTN

- (void) activateSendBtn {
    [_sendButton setTitleColor:_sendButtonActiveColor forState:UIControlStateNormal];
}

- (void) deactivateSendBtn {
    [_sendButton setTitleColor:_sendButtonInactiveColor forState:UIControlStateNormal];
}

#pragma mark OPEN | CLOSE

- (void) close {
    [_textView resignFirstResponder];
}

- (void) open {
    [_textView becomeFirstResponder];
}

#pragma mark TEXT VIEW DELEGATE

- (void) textViewDidBeginEditing:(UITextView *)textView {
    if (![textView.text isEqualToString:@""]) {
        _placeholderLabel.hidden = YES;
    }
    
    [self resizeView];
    [self alignTextViewWithAnimation:NO];
}

- (void) textViewDidChange:(UITextView *)textView {
    
    if (![textView.text isEqualToString:@""]) {
        _placeholderLabel.hidden = YES;
    }
    else {
        _placeholderLabel.hidden = NO;
    }
    
    [self resizeView];
    [self alignTextViewWithAnimation:NO];
}

- (BOOL) textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    
    if (_maxCharacters) {
        return textView.text.length + (text.length - range.length) <= _maxCharacters.intValue;
    }
    else return YES;
}

- (void) textViewDidEndEditing:(UITextView *)textView {
    if ([textView.text isEqualToString:@""]) {
        _placeholderLabel.hidden = NO;
    }
}

#pragma mark TEXT VIEW RESIZE | ALIGN

- (void) resizeView {
    CGFloat inputStartingPoint;
    CGFloat maxHeight;
    if (UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
        if (isKeyboardVisible) {
            inputStartingPoint = screenWidth() - currentKeyboardHeight;
        }
        else inputStartingPoint = screenWidth();
    }
    else {
        if (isKeyboardVisible) {
            inputStartingPoint = screenHeight() - currentKeyboardHeight;
            
        }
        else inputStartingPoint = screenHeight();
    }
    
    if (isKeyboardVisible) maxHeight = inputStartingPoint - _maxY.intValue;
    else {
        
        // I'd rather not use constants (162, 216) but it seems to be necessary in case a hardware keyboard is active
        
        if (UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
            int adjustment = 162; // landscape keyboard height
            maxHeight = screenWidth() - adjustment - _maxY.intValue;
        }
        else {
            int adjustment = 216; // portrait keyboard height
            maxHeight = screenHeight() - adjustment - _maxY.intValue;
        }
    }
    
    
    NSString * content = _textView.text;
    
    NSAttributedString * attrStr = [[NSAttributedString alloc] initWithString:content attributes:@{ NSFontAttributeName : _textView.font, NSStrokeColorAttributeName : [UIColor darkTextColor]}];
    
    CGFloat width = _textView.bounds.size.width - 10; // whatever your desired width is
    // 10 less than our target because it seems to frame better
    
    CGRect rect = [attrStr boundingRectWithSize:CGSizeMake(width, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil];
    CGFloat height = rect.size.height;
    
    if ([_textView.text hasSuffix:@"\n"]) {
        height = height + _textView.font.lineHeight;
    }
    
    int originalHeight = 30; // starting chat input height
    int offset = originalHeight - _textView.font.lineHeight;
    int targetHeight = height + offset + 6; // should this be plus 12? it works with 6 but I don't know why
    // when we format the text, we use width 235.  Then we put it back onto here at 245 px.  This is then compensated here.  It seems to work.
    
    // adding this to help with rotation animations.
    if (targetHeight > maxHeight) targetHeight = maxHeight;
    else if (targetHeight < 40) targetHeight = 40;
    
    self.frame = CGRectMake(0, inputStartingPoint, self.bounds.size.width, -targetHeight);
    
    // in case they backspaced and we need to block send
    if (_textView.text.length > 0) {
        [self activateSendBtn];
    }
    else {
        [self deactivateSendBtn];
    }
}

- (void) alignTextViewWithAnimation:(BOOL)shouldAnimate {
    
    // where the blinky caret is
    CGRect line = [_textView caretRectForPosition:_textView.selectedTextRange.start];
    CGFloat overflow = line.origin.y + line.size.height - (_textView.contentOffset.y + _textView.bounds.size.height - _textView.contentInset.bottom - _textView.contentInset.top);
    
    CGPoint offsetP = _textView.contentOffset;
    offsetP.y += overflow + 3; // 3 px margin
    
    if (offsetP.y >= 0) {
        if (shouldAnimate) {
            [UIView animateWithDuration:0.2 animations:^{
                [_textView setContentOffset:offsetP];
            }];
        }
        else {
            [_textView setContentOffset:offsetP];
        }
    }
}

#pragma mark KEYBOARD NOTIFICATIONS

- (void) keyboardWillShow:(NSNotification *)note {
    
    // Parse Keyboard Animation Details
    NSDictionary *keyboardAnimationDetail = [note userInfo];
    UIViewAnimationCurve animationCurve = [keyboardAnimationDetail[UIKeyboardAnimationCurveUserInfoKey] integerValue];
    CGFloat duration = [keyboardAnimationDetail[UIKeyboardAnimationDurationUserInfoKey] floatValue];
    
    // Get Keyboard Height
    NSValue* keyboardFrameBegin = [keyboardAnimationDetail valueForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardFrameBeginRect = [keyboardFrameBegin CGRectValue];
    
    UIInterfaceOrientation myOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (UIInterfaceOrientationIsPortrait(myOrientation)) currentKeyboardHeight = keyboardFrameBeginRect.size.height;
    else currentKeyboardHeight = keyboardFrameBeginRect.size.width;
    // keyboard height seems to always be portrait height so, when in landscape, it returns screen size
    // width will return what we want to consider as height
    
    // because this gets called on send button & rotation due to autocorrect fix, need to catch
    if (_shouldIgnoreKeyboardNotifications != YES && isAnimatingRotation != YES) {
        
        // Keyboard Is Visible
        isKeyboardVisible = YES;
        
        UIViewAnimationOptions options = (animationCurve << 16);
        
        // working for hardware keyboard
        // UIViewAnimationOptions options = (UIViewAnimationOptions)animationCurve;
        
        [UIView animateWithDuration:duration delay:0.0 options:options animations:^{
            [self resizeView];
        } completion:^(BOOL finished) {
            [self alignTextViewWithAnimation:YES];
        }];
    }
    else if (isAnimatingRotation == YES) {
        UIInterfaceOrientation myOrientation = [[UIApplication sharedApplication] statusBarOrientation];
        if (UIInterfaceOrientationIsPortrait(myOrientation)) {
            self.frame = CGRectMake(0, screenHeight() - currentKeyboardHeight, screenWidth(), -self.bounds.size.height);
        }
        else {
            self.frame = CGRectMake(0, screenWidth() - currentKeyboardHeight, self.bounds.size.width, -self.bounds.size.height);
        }
        
        // necessary to call here in order to adjust final height
        [self resizeView];
    }
}

- (void) keyboardWillHide:(NSNotification *)note {
    
    // because this gets called on send button due to autocorrect fix
    // &&
    // during rotation animation
    if (isAnimatingRotation != YES && _shouldIgnoreKeyboardNotifications != YES) {
        isKeyboardVisible = NO;
        NSDictionary *keyboardAnimationDetail = [note userInfo];
        UIViewAnimationCurve animationCurve = [keyboardAnimationDetail[UIKeyboardAnimationCurveUserInfoKey] integerValue];
        CGFloat duration = [keyboardAnimationDetail[UIKeyboardAnimationDurationUserInfoKey] floatValue];
        
        
        UIViewAnimationOptions options = (animationCurve << 16);
        
        // working for hardware keyboard
        // UIViewAnimationOptions options = (UIViewAnimationOptions)animationCurve;
        
        [UIView animateWithDuration:duration delay:0.0 options:options animations:^{
            [self resizeView];
        } completion:^(BOOL finished) {
            [self alignTextViewWithAnimation:YES];
        }];
    }
}

#pragma mark ROTATION METHODSf
/*
 
 I'm not quite sure why this area needs so much reinforcement, but it tends to animate sloppily without it.
 
 */
- (void) willRotate {
    isAnimatingRotation = YES;
}
- (void) isRotating {
    if (!isKeyboardVisible) [self resizeView];
}
- (void) didRotate {
    isAnimatingRotation = NO;
    // clean it up now that we're done!
    [self alignTextViewWithAnimation:YES];
}

#pragma mark GETTERS | SETTERS

- (void) setSendBtnActiveColor:(UIColor *)sendBtnActiveColor {
    _sendButtonActiveColor = sendBtnActiveColor;
    if (_textView.text.length > 0) [_sendButton setTitleColor:sendBtnActiveColor forState:UIControlStateNormal];
}

- (void) setSendBtnInactiveColor:(UIColor *)sendBtnInactiveColor {
    _sendButtonInactiveColor = sendBtnInactiveColor;
    if (_textView.text.length == 0) [_sendButton setTitleColor:sendBtnInactiveColor forState:UIControlStateNormal];
}

- (UILabel *) placeholderLabel {
    if (!_placeholderLabel) {
        _placeholderLabel = [[UILabel alloc]initWithFrame:_textView.frame];
        _placeholderLabel.userInteractionEnabled = NO;
        _placeholderLabel.backgroundColor = [UIColor clearColor];
        _placeholderLabel.font = [UIFont fontWithName:kSourceSansProRegular size:14];
        _placeholderLabel.textColor = [UIColor lightGrayColor];
        _placeholderLabel.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth;
        [self insertSubview:_placeholderLabel aboveSubview:_textView];
    }
    
    return _placeholderLabel;
}

- (NSNumber *) maxY {
    if (!_maxY) {
        _maxY = [NSNumber numberWithInt:60];
    }
    return _maxY;
}

#pragma mark HIT TESTS -- AUTO CLOSE

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    if (CGRectContainsPoint(self.bounds, point)) {
        if (CGRectContainsPoint(_textView.frame, point)) {
            [self open];
        }
        
        return YES;
    }
    else {
        if (isKeyboardVisible && !stopAutoClose && _textView.text.length == 0) {
            [self close];
        }
        return NO;
    }
}

@end


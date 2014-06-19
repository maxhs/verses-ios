//
//  XXTextView.m
//  Verses
//
//  Created by Max Haines-Stiles on 3/16/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import "XXTextView.h"
#import "UIFontDescriptor+CrimsonText.h"
#import "UIFontDescriptor+SourceSansPro.h"

@implementation XXTextView {
    NSString *_selectedText;
    UITextRange *_selectedRange;
    NSUInteger _stringLocation;
}

- (id)initWithFrame:(CGRect)frame textContainer:(NSTextContainer *)textContainer
{
    self = [super initWithFrame:frame textContainer:textContainer];
    if (self) {
        [self setBackgroundColor:[UIColor clearColor]];
        self.scrollEnabled = NO;
        if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
            self.keyboardAppearance = UIKeyboardAppearanceDark;
        } else {
            self.keyboardAppearance = UIKeyboardAppearanceDefault;
        }
        self.userInteractionEnabled = YES;
        self.keyboardEnabled = NO;
        self.selectable = YES;
        self.delegate = self;
    }
    return self;
}

- (void)setupButtons {
    _keyboardView = [[UIInputView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 44) inputViewStyle:UIInputViewStyleKeyboard];
    
    if (self.keyboardEnabled){
        _boldButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_boldButton setTitle:@"B" forState:UIControlStateNormal];
        [_boldButton.titleLabel setFont:[UIFont fontWithName:kCrimsonRoman size:23]];
        _boldButton.layer.borderColor = kStyleButtonBorderColor;
        _boldButton.layer.borderWidth = .5f;
        _boldButton.layer.cornerRadius = 3.f;
        [_keyboardView addSubview:_boldButton];
        
        _underlineButton = [UIButton buttonWithType:UIButtonTypeCustom];
        NSDictionary *underlineAttribute;
        if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
            underlineAttribute = @{NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle),
                                   NSForegroundColorAttributeName: [UIColor whiteColor]
                                   };
        } else {
            underlineAttribute = @{NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle)};
        }
        
        NSAttributedString *underline = [[NSAttributedString alloc] initWithString:@"U"
                                                                 attributes:underlineAttribute];
        [_underlineButton setAttributedTitle:underline forState:UIControlStateNormal];
        [_underlineButton.titleLabel setFont:[UIFont fontWithName:kCrimsonRoman size:23]];
        _underlineButton.layer.borderColor = kStyleButtonBorderColor;
        _underlineButton.layer.borderWidth = .5f;
        _underlineButton.layer.cornerRadius = 3.f;
        [_keyboardView addSubview:_underlineButton];
        
        _italicsButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_italicsButton setTitle:@"I" forState:UIControlStateNormal];
        [_italicsButton.titleLabel setFont:[UIFont italicSystemFontOfSize:21]];
        _italicsButton.layer.borderColor = [UIColor colorWithWhite:1 alpha:.2].CGColor;
        _italicsButton.layer.borderWidth = .5f;
        _italicsButton.layer.cornerRadius = 3.f;
        [_keyboardView addSubview:_italicsButton];
        
        _headerButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_headerButton setTitle:@"Header" forState:UIControlStateNormal];
        [_headerButton.titleLabel setFont:[UIFont fontWithName:kSourceSansProSemibold size:24]];
        _headerButton.layer.borderColor = [UIColor colorWithWhite:1 alpha:.2].CGColor;
        _headerButton.layer.borderWidth = .5f;
        _headerButton.layer.cornerRadius = 3.f;
        [_keyboardView addSubview:_headerButton];
        
        _cameraButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_cameraButton setTitle:@"" forState:UIControlStateNormal];
        [_cameraButton setImage:[UIImage imageNamed:@"camera"] forState:UIControlStateNormal];
        _cameraButton.layer.borderColor = [UIColor colorWithWhite:1 alpha:.2].CGColor;
        _cameraButton.layer.borderWidth = .5f;
        _cameraButton.layer.cornerRadius = 3.f;
        [_keyboardView addSubview:_cameraButton];
        
        /*_footnoteButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_footnoteButton setTitle:@"Footnote" forState:UIControlStateNormal];
        [_footnoteButton.titleLabel setFont:[UIFont fontWithName:kCrimsonRoman size:16]];
        _footnoteButton.layer.borderColor = [UIColor colorWithWhite:1 alpha:.2].CGColor;
        _footnoteButton.layer.borderWidth = .5f;
        _footnoteButton.layer.cornerRadius = 3.f;
        [_keyboardView addSubview:_footnoteButton];*/
        
        if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
            [_boldButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [_italicsButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [_headerButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            //[_footnoteButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        } else {
            [_boldButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            [_italicsButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            [_headerButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            //[_footnoteButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        }
        
        [_boldButton setFrame:CGRectMake(4, 2, 40, 40)];
        [_italicsButton setFrame:CGRectMake(48, 2, 40, 40)];
        [_underlineButton setFrame:CGRectMake(92, 2, 40, 40)];
        [_headerButton setFrame:CGRectMake(136, 2, 88, 40)];
        [_cameraButton setFrame:CGRectMake(228, 2, 88, 40)];
        //[_footnoteButton setFrame:CGRectMake(228, 2, 88, 40)];
        
        self.editable = YES;
        self.inputAccessoryView = _keyboardView;
    } else {
        _feedbackButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_feedbackButton setFrame:CGRectMake(0, 0, self.frame.size.width, 44)];
        [_feedbackButton.titleLabel setFont:[UIFont fontWithName:kSourceSansProSemibold size:19]];
        [_feedbackButton addTarget:self action:@selector(newFeedback) forControlEvents:UIControlEventTouchUpInside];
        
        //if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
            [_feedbackButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [_feedbackButton setImage:[UIImage imageNamed:@"whiteFeedbackFlag"] forState:UIControlStateNormal];
        /*} else {
            [_feedbackButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [_feedbackButton setImage:[UIImage imageNamed:@"blackFeedbackFlag"] forState:UIControlStateNormal];
        }*/
        [_feedbackButton setTitle:@"   Feedback" forState:UIControlStateNormal];
        [_feedbackButton setBackgroundColor:kElectricBlue];
        self.editable = NO;
        self.inputAccessoryView = _feedbackButton;
    }
}

- (NSRange) selectedRangeForText:(UITextRange*)selectedRange
{
    UITextPosition* beginning = self.beginningOfDocument;
    UITextPosition* selectionStart = selectedRange.start;
    UITextPosition* selectionEnd = selectedRange.end;
    
    const NSInteger location = [self offsetFromPosition:beginning toPosition:selectionStart];
    const NSInteger length = [self offsetFromPosition:selectionStart toPosition:selectionEnd];
    
    return NSMakeRange(location, length);
}

- (void)newFeedback {
    [self resignFirstResponder];
    NSLog(@"should be adding new feedback, %@",_contribution);
    if (_selectedText.length && _contribution){
        [[NSNotificationCenter defaultCenter] postNotificationName:@"AddFeedback" object:nil userInfo:@{@"text":_selectedText,@"contribution":_contribution,@"location":[NSNumber numberWithUnsignedInteger:_stringLocation]}];
    }
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kDarkBackground]){
        self.keyboardAppearance = UIKeyboardAppearanceDark;
    } else {
        self.keyboardAppearance = UIKeyboardAppearanceDefault;
    }
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    
}

- (void)textWillChange:(id<UITextInput>)textInput {
    NSLog(@"text will change: %@",textInput);
}

- (void)textDidChange:(id<UITextInput>)textInput {
    NSLog(@"text did change: %@",textInput);
}

- (void)selectionDidChange:(id<UITextInput>)textInput {
    NSLog(@"selection did change: %@",textInput);
}

- (void)selectionWillChange:(id<UITextInput>)textInput {
    NSLog(@"selection will change: %@",textInput);
}

- (void)textViewDidChangeSelection:(UITextView *)textView {
    _selectedRange = [textView selectedTextRange];
    _selectedText = [textView textInRange:_selectedRange];
    _stringLocation = [self selectedRangeForText:_selectedRange].location;
    if (!_selectedText.length) {
        [self resignFirstResponder];
        _selectedText = nil;
        _selectedRange = nil;
    }
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
/*- (void)drawRect:(CGRect)rect
{
    NSLog(@"draw rect");
}*/


@end

//
//  XXWritingCell.m
//  Verses
//
//  Created by Max Haines-Stiles on 11/4/13.
//  Copyright (c) 2013 Verses. All rights reserved.
//

#import "XXWritingCell.h"

@implementation XXWritingCell {
    XXTextStorage *_textStorage;
    CGRect screen;
    XXStory *_story;
    NSString *storyBody;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)configure:(XXStory*)storyInput withOrientation:(UIInterfaceOrientation)orientation {
    _story = storyInput;
    storyBody = @"";
    screen = [UIScreen mainScreen].bounds;
    [self createTextViewWithOrientation:orientation];
    [self.titleTextField setFont:[UIFont fontWithName:kSourceSansProSemibold size:25]];
    [self.titleTextField setPlaceholder:kTitlePlaceholder];
    if (_story.title.length) {
        [self.titleTextField setText:_story.title];
    } else {
        [self.titleTextField setText:@""];
    }
}

- (void)getStoryBody {
    if (_story && _story.contributions.count){
        for (XXContribution *contribution in _story.contributions) {
            if (contribution.body.length) storyBody = [storyBody stringByAppendingString:contribution.body];
        }
        if (!storyBody.length) storyBody = kStoryPlaceholder;
    } else {
        storyBody = kStoryPlaceholder;
    }
}

- (void)createTextViewWithOrientation:(UIInterfaceOrientation)orientation {
    [self getStoryBody];
    NSDictionary* attributes = @{NSDocumentTypeDocumentAttribute:NSHTMLTextDocumentType};
    NSAttributedString* attrString = [[NSAttributedString alloc] initWithData:[storyBody dataUsingEncoding:NSUTF32StringEncoding] options:attributes documentAttributes:nil error:nil];
    _textStorage = [XXTextStorage new];
    [_textStorage appendAttributedString:attrString];
    
    NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];
    CGRect newTextViewRect;
    if (UIInterfaceOrientationIsPortrait(orientation)){
        newTextViewRect = CGRectMake(5, 56, screen.size.width-10, screen.size.height-56);
    } else {
        newTextViewRect = CGRectMake(5, 56, screen.size.height-10, screen.size.width-56);
    }
    CGSize containerSize = CGSizeMake(newTextViewRect.size.width,  CGFLOAT_MAX);
    NSTextContainer *container = [[NSTextContainer alloc] initWithSize:containerSize];
    container.widthTracksTextView = YES;
    [layoutManager addTextContainer:container];
    [_textStorage addLayoutManager:layoutManager];
    
    if (self.textView){
        [self.textView setFrame:newTextViewRect];
    } else {
        self.textView = [[UITextView alloc] initWithFrame:newTextViewRect textContainer:container];
        [self addSubview:self.textView];
    }
    if ([self.textView.text isEqualToString:kStoryPlaceholder]){
        [self.textView setTextColor:[UIColor lightGrayColor]];
    } else {
        [self.textView setTextColor:[UIColor blackColor]];
    }
    
    [self.textView setFont:[UIFont fontWithName:kCrimsonRoman size:22]];
    [self.textView setBackgroundColor:[UIColor clearColor]];
}
@end

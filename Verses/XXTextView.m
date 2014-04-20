//
//  XXTextView.m
//  Verses
//
//  Created by Max Haines-Stiles on 3/16/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import "XXTextView.h"

@implementation XXTextView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        NSLog(@"init code for custom text view");
    }
    return self;
}

- (void)awakeFromNib {
    
    [self.inputAccessoryView setBackgroundColor:[UIColor blackColor]];
    [self.inputAccessoryView setFrame:CGRectMake(0, 0, 320, 44)];
    [super awakeFromNib];
}


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
/*- (void)drawRect:(CGRect)rect
{
    NSLog(@"draw rect");
}*/


@end

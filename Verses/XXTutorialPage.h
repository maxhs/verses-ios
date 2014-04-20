//
//  XXTutorialPage.h
//  Verses
//
//  Created by Max Haines-Stiles on 3/29/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import <UIKit/UIKit.h>
@class XXTutorialPage;

@interface XXTutorialPage : UIView
@property (strong, nonatomic) UIView *containerView;
@property (strong, nonatomic) UIImageView *arrowImageView;
@property (strong, nonatomic) UILabel *title;
@property (strong, nonatomic) UILabel *explanation;
@property (strong, nonatomic) UILabel *desc;
-(void)initDesc:(NSString*)string withFrame:(CGRect)frame;
-(void)initExplanation:(NSString*)string withFrame:(CGRect)frame;
-(void)initTitle:(NSString*)string withFrame:(CGRect)frame;
@end

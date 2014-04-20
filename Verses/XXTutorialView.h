//
//  XXTutorialView.h
//  Verses
//
//  Created by Max Haines-Stiles on 3/29/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface XXTutorialView : UIView <UIScrollViewDelegate>
@property (nonatomic, assign) id<UIScrollViewDelegate> delegate;
@property (strong, nonatomic) UIScrollView *scrollView;
-(void)showInView:(UIView*)view animateDuration:(CGFloat)duration withBackgroundImage:(UIImage*)image;
@end

//
//  XXWebViewController.h
//  Verses
//
//  Created by Max Haines-Stiles on 5/30/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface XXWebViewController : UIViewController <UIWebViewDelegate>
@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (strong, nonatomic) NSString *urlString;
@end

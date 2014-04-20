//
//  Constants.h
//  Verses
//
//  Created by Max Haines-Stiles on 10/7/13.
//  Copyright (c) 2013 Verses. All rights reserved.
//

#ifndef Verses_Constants_h
#define Verses_Constants_h

static inline int screenHeight(){ return [UIScreen mainScreen].bounds.size.height; }
static inline int screenWidth(){ return [UIScreen mainScreen].bounds.size.width; }
static inline CGFloat width(UIView *view) { return view.frame.size.width; }
static inline CGFloat height(UIView *view) { return view.frame.size.height; }

#define OUTLINE ((int) 22)
#define MAX_BUBBLE_WIDTH ((int) 260)

#define kAPIBaseUrl @"https://www.writeverses.com/api/v1"

#define MIXPANEL_TOKEN @"8184fc9baafab30a5c51cceefb90e2d0"
#define RADIANS(degrees) ((degrees * M_PI) / 180.0)

#define IDIOM    UI_USER_INTERFACE_IDIOM()
#define IPAD     UIUserInterfaceIdiomPad

#define kFeedbackEmail @"feedback@writeverses.com"
#define kDarkBackground @"darkBackground"
#define kStoryPaging @"storyPaging"
#define kNoPreview @"noPreview"
#define kCommentBody @"CommentBody"
#define kCommentSize @"CommentSize"
#define kMessageRuntimeSentBy @"runtimeSentBy"
#define kMessageSize @"MessageSize"

#define kUserDefaultsId @"userId"
#define kUserDefaultsPassword @"password"
#define kUserDefaultsEmail @"email"
#define kUserDefaultsAuthToken @"authToken"
#define kUserDefaultsLocation @"location"
#define kUserDefaultsPenName @"penName"
#define kUserDefaultsFullName @"fullName"
#define kUserDefaultsPicThumb @"pic_thumb_url"
#define kUserDefaultsPicSmall @"pic_small_url"
#define kUserDefaultsDeviceToken @"deviceToken"

#define kElectricBlue [UIColor colorWithRed:(0.0/255.0) green:(128.0/255.0) blue:(255.0/255.0) alpha:1]

//String constants
#define kStoryPlaceholder @"Start your story..."
#define kTitlePlaceholder @"Title your story..."
#define kFeedbackPlaceholder @"Tap to leave feedback..."

//Font constants
#define kGotham @"GothamBook"
#define kGothamRounded @"GothamRounded-Book"
#define kCrimsonRoman @"CrimsonText-Roman"
#define kCrimsonItalic @"CrimsonText-Italic"
#define kCrimsonSemibold @"CrimsonText-Semibold"
#define kExistenceLight @"Existence-Light"
#define kBostonTraffic @"BostonTraffic"
#define kGothamBold @"GothamBold"
#define kGothamExtraLight @"GothamExtraLight"
#define kGothamLight @"GothamLight"
#define kGothamUltra @"GothamUltra"
#define kGothamThin @"GothamThin"
#define kSourceSansProLight @"SourceSansPro-Light"
#define kSourceSansProRegular @"SourceSansPro-Regular"
#define kSourceSansProSemibold @"SourceSansPro-Semibold"
#define kSourceSansProBold @"SourceSansPro-Bold"
#define kSourceSansProItalic @"SourceSansPro-It"
#define kMontserrat @"Montserrat-Regular"
#endif
//
//  Constants.h
//  Verses
//
//  Created by Max Haines-Stiles on 10/7/13.
//  Copyright (c) 2013 Verses. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIFontDescriptor+Custom.h"

#ifndef Verses_Constants_h
#define Verses_Constants_h

static inline int screenHeight(){ return [UIScreen mainScreen].bounds.size.height; }
static inline int screenWidth(){ return [UIScreen mainScreen].bounds.size.width; }
static inline CGFloat width(UIView *view) { return view.frame.size.width; }
static inline CGFloat height(UIView *view) { return view.frame.size.height; }

#define OUTLINE ((int) 22)
#define kSeparatorTag 21
#define kContributorViewTag 2376
#define kBaseUrl @"https://writeverses.com"
#define kAPIBaseUrl @"https://writeverses.com/api/v1"
#define kApiLogin @"verses_mobile"
#define kApiKey @"721efc8ead5fe421291acb94f1625f35"
#define kUrlScheme @"verses"

#define MIXPANEL_TOKEN @"8184fc9baafab30a5c51cceefb90e2d0"
#define RADIANS(degrees) ((degrees * M_PI) / 180.0)

#define IDIOM    UI_USER_INTERFACE_IDIOM()
#define IPAD     UIUserInterfaceIdiomPad
#define kGuideAnimatorTime .65f

#define kFeedbackEmail @"feedback@writeverses.com"
#define kDarkBackground @"darkBackground"
#define kStoryPaging @"storyPaging"
#define kCommentBody @"CommentBody"
#define kCommentSize @"CommentSize"
#define kMessageRuntimeSentBy @"runtimeSentBy"
#define kMessageSize @"MessageSize"

#define kExistingUser @"existingUser"
#define kExistingUserWrite @"existingUserWrite"
#define kHasSeenGuideView @"hasSeenGuideView"
#define kAlreadyDestroyed @"Already destroyed"
#define kIncorrectPassword @"Incorrect password"
#define kUserAlreadyExists @"User already exists"
#define kNoEmail @"No email"
#define kPenNameTaken @"Pen name taken"

#define kUserDefaultsId @"userId"
#define kUserDefaultsPassword @"password"
#define kUserDefaultsEmail @"email"
#define kUserDefaultsAuthToken @"authToken"
#define kUserDefaultsLocation @"location"
#define kUserDefaultsPenName @"penName"
#define kUserDefaultsFullName @"fullName"
#define kUserDefaultsPicLarge @"pic_large_url"
#define kUserDefaultsPicMedium @"pic_medium_url"
#define kUserDefaultsPicSmall @"pic_small_url"
#define kUserDefaultsMobileToken @"mobileToken"
#define kUserDefaultsDeviceToken @"deviceToken"

#define kSeparatorColor [UIColor colorWithWhite:.77 alpha:.23]
#define kElectricBlue [UIColor colorWithRed:(0.0/255.0) green:(128.0/255.0) blue:(255.0/255.0) alpha:1]
#define kHotOrange [UIColor colorWithRed:(255.0/255.0) green:(92.0/255.0) blue:(22.0/255.0) alpha:1]
#define kStyleButtonBorderColor [UIColor colorWithWhite:1 alpha:.2].CGColor
#define kTableViewCellSelectionColor [UIColor colorWithWhite:.9 alpha:.23]
#define kTableViewCellSelectionColorDark [UIColor colorWithWhite:.5 alpha:.23]
#define kPlaceholderTextColor [UIColor colorWithWhite:.45 alpha:.5]

//String constants
#define kStoryPlaceholder @"Start your story..."
#define kSlowRevealPlaceholder @"Add to this slow reveal story..."
#define kTitlePlaceholder @"Title your story..."
#define kFeedbackPlaceholder @"Leave feedback..."
#define kFeedbackResponsePlaceholder @"Leave a response..."
#define kCircleBlurbPlaceholder @"Describe your writing circle..."
#define kCircleNamePlaceholder @"Name your writing circle..."
#define kAddCollaboratorPlaceholder @"Add an email address..."

//Notification constants
#define kCircleComment @"circle_comment"
#define kCirclePublish @"circle_publish"
#define kCircle @"circle"
#define kSlowPublish @"revealed"
#define kSubscription @"subscription"

//Font constants
#define kSourceSansProLight @"SourceSansPro-Light"
#define kSourceSansPro @"SourceSansPro-Regular"
#define kSourceSansProSemibold @"SourceSansPro-Semibold"
#define kSourceSansProBold @"SourceSansPro-Bold"
#define kSourceSansProItalic @"SourceSansPro-It"
#define kCrimsonRoman @"CrimsonText-Roman"
#define kCrimsonItalic @"CrimsonText-Italic"
#define kCrimsonSemibold @"CrimsonText-Semibold"
#define kTrashHand @"TrashHand"
#define kLato @"Lato-Regular"
#define kLatoLight @"Lato-Light"
#define kLatoLightItalic @"Lato-LightItalic"
#define kLatoBold @"Lato-Bold"


#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)

#endif
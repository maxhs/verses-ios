//
//  XXPhotoButton.m
//  Verses
//
//  Created by Max Haines-Stiles on 3/29/14.
//  Copyright (c) 2014 Verses. All rights reserved.
//

#import "XXPhotoButton.h"
#import <SDWebImage/UIButton+WebCache.h>

@implementation XXPhotoButton {
    XXStory *_story;
    XXPhoto *_photo;
    UIViewController *_vc;
    NSMutableArray *browserPhotos;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (void)initializeWithPhoto:(XXPhoto*)photo forStory:(XXStory*)story inVC:(UIViewController *)vc{
    _story = story;
    _photo = photo;
    _vc = vc;

    __weak typeof(self) weakSelf = self;
    [weakSelf setAlpha:0.0];
    [weakSelf setImageWithURL:photo.imageLargeUrl forState:UIControlStateNormal completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
        [UIView animateWithDuration:.25 animations:^{
            [weakSelf setAlpha:1.0];
        }];
    }];
    [self addTarget:self action:@selector(expandPhoto) forControlEvents:UIControlEventTouchUpInside];
}

- (void)expandPhoto {
    browserPhotos = [NSMutableArray new];
    for (XXPhoto *thisPhoto in _story.photos) {
        MWPhoto *mwPhoto = [MWPhoto photoWithURL:thisPhoto.imageLargeUrl];
        [browserPhotos addObject:mwPhoto];
    }
    
    // Create browser
    MWPhotoBrowser *browser = [[MWPhotoBrowser alloc] initWithDelegate:self];
    
    // Set options
    browser.displayActionButton = YES; // Show action button to allow sharing, copying, etc (defaults to YES)
    browser.displayNavArrows = NO; // Whether to display left and right nav arrows on toolbar (defaults to NO)
    browser.displaySelectionButtons = NO; // Whether selection buttons are shown on each image (defaults to NO)
    browser.zoomPhotosToFill = YES; // Images that almost fill the screen will be initially zoomed to fill (defaults to YES)
    browser.alwaysShowControls = NO; // Allows to control whether the bars and controls are always visible or whether they fade away to show the photo full (defaults to NO)
    browser.enableGrid = YES; // Whether to allow the viewing of all the photo thumbnails on a grid (defaults to YES)
    browser.startOnGrid = NO; // Whether to start on the grid of thumbnails instead of the first photo (defaults to NO)
    /*if ([[[UIDevice currentDevice] systemVersion] floatValue] < 7.0){
        browser.wantsFullScreenLayout = YES; // iOS 5 & 6 only: Decide if you want the photo browser full screen, i.e. whether the status bar is affected (defaults to YES)
    }*/
    [browser setCurrentPhotoIndex:[_story.photos indexOfObject:_photo]];
    [_vc.navigationController pushViewController:browser animated:YES];
    [browser showNextPhotoAnimated:YES];
    [browser showPreviousPhotoAnimated:YES];
}

- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser {
    return browserPhotos.count;
}

- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index {
    if (index < browserPhotos.count)
        return [browserPhotos objectAtIndex:index];
    return nil;
}
@end

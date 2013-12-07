//
//  WeHeartItScreensaverView.m
//  We Heart It Screensaver
//
//  Created by Jesse Ditson on 11/25/13.
//  Copyright (c) 2013 We Heart It. All rights reserved.
//

#import "WeHeartItScreensaverView.h"
#import "ApiClient.h"

@interface WeHeartItScreensaverView()
{
    OptionsPanelWindowController *optionsPanelWindowController;
    ImageGenerator *imageGenerator;
}

@end

@implementation WeHeartItScreensaverView

- (id)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview
{
    self = [super initWithFrame:frame isPreview:isPreview];
    if (self) {
        [self setAnimationTimeInterval:1/30.0];
        [ApiClient initialize];
        imageGenerator = [[ImageGenerator alloc] init];
        imageGenerator.delegate = self;
    }
    return self;
}

- (void)startAnimation
{
    [super startAnimation];
}

- (void)stopAnimation
{
    [super stopAnimation];
}

- (void)drawRect:(NSRect)rect
{
    [super drawRect:rect];
    // note that for the small preview, [self isPreview] will be YES.
}

- (void)animateOneFrame
{
    // to trigger drawRect, run [self setNeedsDisplay:YES];
    return;
}

- (BOOL)hasConfigureSheet
{
    return YES;
}

+ (BOOL)performGammaFade
{
    // adds a gradual fade to black before the screen saver starts
    return YES;
}

- (NSWindow*)configureSheet
{
    if (!optionsPanelWindowController) {
        optionsPanelWindowController = [OptionsPanelWindowController controller];
        optionsPanelWindowController.delegate = self;
    }
    return optionsPanelWindowController.panel;
}

# pragma mark - OptionsPanelWindowControllerDelegate

- (void)dismissWindow
{
    [NSApp endSheet:optionsPanelWindowController.panel];
}

#pragma mark - ImageGeneratorDelegate

- (void)imagesLoaded:(NSArray *)images
{
    NSLog(@"Loaded images: %@",images);
}

@end

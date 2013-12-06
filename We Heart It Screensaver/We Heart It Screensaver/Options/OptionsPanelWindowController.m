//
//  OptionsPanelWindowController.m
//  We Heart It Screensaver
//
//  Created by Jesse Ditson on 12/5/13.
//  Copyright (c) 2013 We Heart It. All rights reserved.
//

#import "OptionsPanelWindowController.h"

@interface OptionsPanelWindowController()

@property (strong) LoginViewController *loginViewController;

@end

@implementation OptionsPanelWindowController

+ (id)controller
{
    OptionsPanelWindowController *controller = [[OptionsPanelWindowController alloc] init];
    [controller showWindow:nil];
    [controller.window makeKeyAndOrderFront:self];
    return controller;
}

- (id)init
{
    self = [super initWithWindowNibName:@"OptionsPanel"];
    if (self) {
        // nothing needed here
    }
    return self;
}

- (void)windowDidLoad
{
    // TODO: check if already logged in? login view controller delegate will make a new request every time otherwise, which will be more consistent (can't have a bad access token)
    if (true) {
        _loginViewController = [[LoginViewController alloc] init];
        _loginViewController.delegate = self;
        [self.mainView addSubview:_loginViewController.view];
    }
}

- (void)showLoggedInView
{
    
}

- (IBAction)cancelSheetAction:(id)sender
{
    [self.delegate dismissWindow];
}
- (IBAction)okSheetAction:(id)sender
{
    [self.delegate dismissWindow];
}

#pragma mark - LoginViewControllerDelegate

- (void)userLoggedIn
{
    // swap out the view for the logged in view
}
- (void)userLoggedOut
{
    // don't think we need to do anything here
}

@end

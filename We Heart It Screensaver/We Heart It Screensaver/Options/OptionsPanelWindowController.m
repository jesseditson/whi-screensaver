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
@property (strong) SettingsViewController *settingsViewController;

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
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showLoading:) name:@"api:loading" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showError:) name:@"api:error" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showComplete:) name:@"api:complete" object:nil];
        [self.progressIndicator setHidden:YES];
    }
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)showLoading:(NSNotification *)notification
{
    [self.progressIndicator setHidden:NO];
    [self.progressIndicator startAnimation:nil];
}
- (void)showError:(NSNotification *)notification
{
    
}
- (void)showComplete:(NSNotification *)notification
{
    [self.progressIndicator setHidden:YES];
    [self.progressIndicator stopAnimation:nil];
}

- (void)showSettings
{
    if (!_settingsViewController) {
        _settingsViewController = [[SettingsViewController alloc] init];
        _settingsViewController.delegate = self;
    }
    if(_loginViewController.view.superview) [_loginViewController.view removeFromSuperview];
    [self.mainView addSubview:_settingsViewController.view];
}

- (IBAction)cancelSheetAction:(id)sender
{
    [self.delegate dismissWindow];
}
- (IBAction)okSheetAction:(id)sender
{
    // save the current settings
    [[NSUserDefaults standardUserDefaults] setObject:[_settingsViewController currentSourceInfo] forKey:@"whi-screensaver-settings"];
    [self.delegate dismissWindow];
}

#pragma mark - LoginViewControllerDelegate

- (void)userLoggedIn
{
    // swap out the view for the logged in view
    [self showSettings];
}
- (void)userLoggedOut
{
    if(_settingsViewController.view.superview) [_settingsViewController.view removeFromSuperview];
    [self.mainView addSubview:_loginViewController.view];
}

#pragma mark - SettingsViewControllerDelegate

- (void)logOut
{
    [_loginViewController logOut];
}

@end

//
//  OptionsPanelWindowController.h
//  We Heart It Screensaver
//
//  Created by Jesse Ditson on 12/5/13.
//  Copyright (c) 2013 We Heart It. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import "LoginViewController.h"
#import "SettingsViewController.h"

@protocol OptionsPanelWindowControllerDelegate <NSObject>

- (void)dismissWindow;

@end

@interface OptionsPanelWindowController : NSWindowController <LoginViewControllerDelegate,SettingsViewControllerDelegate>

@property (strong) IBOutlet NSPanel *panel;
@property (strong) id<OptionsPanelWindowControllerDelegate> delegate;
@property (strong) IBOutlet NSView *mainView;
@property (strong) IBOutlet NSProgressIndicator *progressIndicator;

+ (id) controller;

- (IBAction) cancelSheetAction: (id) sender;
- (IBAction) okSheetAction: (id) sender;

@end

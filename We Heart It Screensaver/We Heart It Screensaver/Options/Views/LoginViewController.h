//
//  LoginViewController.h
//  We Heart It Screensaver
//
//  Created by Jesse Ditson on 12/5/13.
//  Copyright (c) 2013 We Heart It. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@protocol LoginViewControllerDelegate <NSObject>

- (void)userLoggedIn;
- (void)userLoggedOut;

@end

@interface LoginViewController : NSViewController

@property (strong) id<LoginViewControllerDelegate> delegate;
@property (strong) IBOutlet WebView *webView;
@property (strong) IBOutlet NSButton *signInButton;
@property (strong) IBOutlet NSProgressIndicator *loadingSpinner;
@property (strong) IBOutlet NSTextField *errorLabel;

- (void)logOut;

- (IBAction)signInPressed:(id)sender;

@end

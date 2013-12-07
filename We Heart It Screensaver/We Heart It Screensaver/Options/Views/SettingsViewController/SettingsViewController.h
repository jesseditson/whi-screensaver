//
//  SettingsViewController.h
//  We Heart It Screensaver
//
//  Created by Jesse Ditson on 12/6/13.
//  Copyright (c) 2013 We Heart It. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol SettingsViewControllerDelegate <NSObject>

- (void)logOut;

@end

@interface SettingsViewController : NSViewController

@property (strong) id<SettingsViewControllerDelegate>delegate;

@property (strong) IBOutlet NSImageView *avatarImageView;
@property (strong) IBOutlet NSTextField *usernameLabel;

@property (strong) IBOutlet NSPopUpButton *mainSourceSelect;
@property (strong) IBOutlet NSTextField *searchField;
@property (strong) IBOutlet NSView *searchView;
@property (strong) IBOutlet NSPopUpButton *collectionsSelect;

- (NSDictionary *)currentSourceInfo;

- (IBAction)mainSourceSelected:(id)sender;
- (IBAction)userSourceSelected:(id)sender;

- (IBAction)logOutPressed:(id)sender;

@end

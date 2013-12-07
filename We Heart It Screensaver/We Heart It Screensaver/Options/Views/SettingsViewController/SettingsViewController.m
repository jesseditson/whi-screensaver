//
//  SettingsViewController.m
//  We Heart It Screensaver
//
//  Created by Jesse Ditson on 12/6/13.
//  Copyright (c) 2013 We Heart It. All rights reserved.
//

#import "SettingsViewController.h"
#import "ApiClient.h"
#import "NSImageView+AFNetworking.h"

@interface SettingsViewController ()
{
    NSDictionary *userInfo;
    NSArray *currentCollections;
}

@end

@implementation SettingsViewController

- (id)init
{
    NSBundle *saverBundle = [NSBundle bundleForClass:[self class]];
    return [self initWithNibName:@"SettingsViewController" bundle:saverBundle];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        __block SettingsViewController *blockSelf = self;
        [ApiClient updateCurrentUser:^(NSDictionary *user,NSError *error){
            userInfo = user;
            [blockSelf userLoaded];
        }];
    }
    return self;
}

- (void)loadView
{
    [super loadView];
    // init UI
    [self.mainSourceSelect addItemWithTitle:@"My Hearts"];
    [self.mainSourceSelect addItemWithTitle:@"All Hearts"];
    [self.searchView setHidden:YES];
    [self.collectionsSelect setHidden:YES];
}

- (void)userLoaded
{
    NSString *avatarUrlString = [[[userInfo objectForKey:@"avatar"] objectAtIndex:0] objectForKey:@"url"];
    [self.avatarImageView setImageWithURL:[NSURL URLWithString:avatarUrlString]];
    [self.usernameLabel setStringValue:[userInfo objectForKey:@"name"]];
    __block SettingsViewController *blockSelf = self;
    [ApiClient getCurrentUserCollections:^(NSArray *collections,NSError *error){
        currentCollections = collections;
        [blockSelf.collectionsSelect removeAllItems];
        [blockSelf.collectionsSelect addItemWithTitle:@"All My Hearts"];
        for (NSDictionary *collection in collections) {
            [blockSelf.collectionsSelect addItemWithTitle:[collection objectForKey:@"name"]];
        }
    }];
}

- (NSDictionary *)currentSourceInfo
{
    NSString *value;
    NSString *identifier;
    if ([[self.mainSourceSelect titleOfSelectedItem] isEqualToString:@"All Hearts"]) {
        value = [self.searchField stringValue];
    } else if([[self.mainSourceSelect titleOfSelectedItem] isEqualToString:@"My Hearts"]) {
        value = [self.collectionsSelect titleOfSelectedItem];
        if (![value isEqualToString:@"All My Hearts"]) {
            // this is a user collection, get the ID
            identifier = [currentCollections objectAtIndex:[self.collectionsSelect indexOfSelectedItem] - 1];
        }
    }
    return @{
             @"source": [self.mainSourceSelect titleOfSelectedItem],
             @"value": value,
             @"identifier":identifier
             };
}

- (IBAction)mainSourceSelected:(id)sender
{
    if ([[self.mainSourceSelect titleOfSelectedItem] isEqualToString:@"All Hearts"]) {
        [self.searchView setHidden:NO];
        [self.collectionsSelect setHidden:YES];
    } else if([[self.mainSourceSelect titleOfSelectedItem] isEqualToString:@"My Hearts"]) {
        [self.searchView setHidden:YES];
        [self.collectionsSelect setHidden:NO];
    }
}
- (IBAction)userSourceSelected:(id)sender
{
    
}

- (IBAction)logOutPressed:(id)sender
{
    [self.delegate logOut];
}

@end

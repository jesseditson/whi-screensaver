//
//  ImageGenerator.m
//  We Heart It Screensaver
//
//  Created by Jesse Ditson on 12/6/13.
//  Copyright (c) 2013 We Heart It. All rights reserved.
//

#import "ImageGenerator.h"
#import "ApiClient.h"

@interface ImageGenerator()
{
    NSDictionary *settings;
}

@end

@implementation ImageGenerator

- (id)init
{
    self = [super init];
    if (self) {
        [self configure];
    }
    return self;
}

- (void)configure
{
    self.currentEntries = [NSArray array];
    settings = [[NSUserDefaults standardUserDefaults] objectForKey:@"whi-screensaver-settings"];
}

- (NSArray *)currentImageUrls
{
    NSMutableArray *urls = [NSMutableArray array];
    for (NSDictionary *entry in self.currentEntries) {
        for(NSDictionary *mediaInfo in [entry objectForKey:@"media"]){
            if ([[mediaInfo objectForKey:@"type"] isEqualToString:@"large"]) {
                [urls addObject:[mediaInfo objectForKey:@"url"]];
            }
        }
    }
    return urls;
}

- (void)reloadImages
{
    __block ImageGenerator *blockSelf = self;
    callbackHandler entriesLoaded = ^(NSArray *entries,NSError *error){
        [blockSelf updateEntriesWithEntries:entries];
    };
    NSString *source = [settings objectForKey:@"source"];
    NSString *value = [settings objectForKey:@"value"];
    NSString *identifier = [settings objectForKey:@"identifier"];
    if ([source isEqualToString:@"My Hearts"]) {
        if (identifier) {
            [ApiClient getEntriesInCollection:identifier callback:entriesLoaded];
        } else {
            [ApiClient getUserEntries:entriesLoaded];
        }
    } else if([source isEqualToString:@"All Hearts"]) {
        if (value.length > 0) {
            [ApiClient getEntriesForQuery:value callback:entriesLoaded];
        } else {
            [ApiClient getRecentEntries:entriesLoaded];
        }
    }
}

- (void)updateEntriesWithEntries:(NSArray *)entries
{
    NSMutableDictionary *previousEntryIds = [NSMutableDictionary dictionaryWithCapacity:[self.currentEntries count]];
    for (NSDictionary *entry in self.currentEntries) {
        NSString *entryId = [entry objectForKey:@"id"];
        [previousEntryIds setObject:entryId forKey:entryId];
    }
    NSMutableArray *newEntries = [NSMutableArray array];
    for (NSDictionary *entry in entries) {
        NSString *entryId = [entry objectForKey:@"id"];
        if (![previousEntryIds objectForKey:entryId]) {
            [newEntries addObject:entry];
        }
    }
    self.currentEntries = [self.currentEntries arrayByAddingObjectsFromArray:newEntries];
    NSLog(@"Entries now: %@",self.currentEntries);
    [self.delegate imagesLoaded:[self currentImageUrls]];
}

@end

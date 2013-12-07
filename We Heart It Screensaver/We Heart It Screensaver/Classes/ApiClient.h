//
//  ApiClient.h
//  We Heart It Screensaver
//
//  Created by Jesse Ditson on 12/6/13.
//  Copyright (c) 2013 We Heart It. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^callbackHandler)(id response, NSError *error);

@interface ApiClient : NSObject

+ (void)initialize;

+ (void)updateCurrentUser:(callbackHandler)callback;
+ (void)getCurrentUserCollections:(callbackHandler)callback;
+ (void)getRecentEntries:(callbackHandler)callback;
+ (void)getUserEntries:(callbackHandler)callback;
+ (void)getEntriesForQuery:(NSString *)query callback:(callbackHandler)callback;
+ (void)getEntriesInCollection:(NSString *)collectionId callback:(callbackHandler)callback;

@end

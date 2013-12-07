//
//  NSURL+QueryStringAdditions.m
//  We Heart It Screensaver
//
//  Created by Jesse Ditson on 12/6/13.
//  Copyright (c) 2013 We Heart It. All rights reserved.
//

#import "NSURL+QueryStringAdditions.h"

@implementation NSURL (QueryStringAdditions)

- (NSURL *)URLByAppendingQueryString:(NSString *)queryString
{
    if (![queryString length]) {
        return self;
    }
    
    NSString *URLString = [[NSString alloc] initWithFormat:@"%@%@%@", [self absoluteString],
                           [self query] ? @"&" : @"?", queryString];
    NSURL *theURL = [NSURL URLWithString:URLString];
    return theURL;
}

@end

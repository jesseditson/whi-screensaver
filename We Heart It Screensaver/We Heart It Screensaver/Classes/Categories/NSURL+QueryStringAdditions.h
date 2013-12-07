//
//  NSURL+QueryStringAdditions.h
//  We Heart It Screensaver
//
//  Created by Jesse Ditson on 12/6/13.
//  Copyright (c) 2013 We Heart It. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSURL (QueryStringAdditions)

- (NSURL *)URLByAppendingQueryString:(NSString *)queryString;

@end

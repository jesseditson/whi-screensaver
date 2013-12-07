//
//  ImageGenerator.h
//  We Heart It Screensaver
//
//  Created by Jesse Ditson on 12/6/13.
//  Copyright (c) 2013 We Heart It. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ImageGeneratorDelegate <NSObject>

- (void)imagesLoaded:(NSArray *)images;

@end

@interface ImageGenerator : NSObject

@property (strong) id<ImageGeneratorDelegate> delegate;
@property (strong) NSArray *currentEntries;

- (NSArray *)currentImageUrls;

@end

//
//  NSString+addition.h
//  Comparator
//
//  Created by Max on 09/05/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSString (addition)

+ (NSString *)stringWithCFString:(CFStringRef)stringRef;

+ (NSString *)pathForDirectory:(NSSearchPathDirectory)directory;

+ (NSString *)localizedStringForFileSize:(double)fileSize;

- (NSArray *)linesConstraitWithSize:(NSSize)size;
- (NSArray *)linesConstraitWithSize:(NSSize)constraitSize separatedByString:(NSString *)separation;

- (BOOL)isOnMainVolume;

@end

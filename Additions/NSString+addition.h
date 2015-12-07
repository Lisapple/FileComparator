//
//  NSString+addition.h
//  Comparator
//
//  Created by Max on 09/05/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSString (addition)

// CFString helper
+ (NSString *)stringWithCFString:(CFStringRef)stringRef;

// Localisation helper
+ (NSString *)localizedStringForFileSize:(double)fileSize;

// Layout helper
- (NSArray *)linesConstraitWithSize:(NSSize)size;
- (NSArray *)linesConstraitWithSize:(NSSize)constraitSize separatedByString:(NSString *)separation;

// Path helper
+ (NSString *)pathForDirectory:(NSSearchPathDirectory)directory;
@property (NS_NONATOMIC_IOSONLY, getter=isOnMainVolume, readonly) BOOL onMainVolume;

// Case helper
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *firstLetterCapitalized;

@end

//
//  NSFileManager+addition.h
//  Comparator
//
//  Created by Maxime Leroy on 7/10/13.
//  Copyright (c) 2013 Lis@cintosh. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const NSFileManagerAdditionSkipLength; // Number of kB to skip after a fetch
extern NSString * const NSFileManagerAdditionFetchLength; // Number of kB to fetch
extern NSString * const NSFileManagerAdditionSkipSizeComparison; // Boolean to skip or not the file size comparison (not implemented)

@interface NSFileManager (addition)

- (BOOL)contentsEqualAtPath:(NSString *)path1 andPath:(NSString *)path2 withOptions:(NSDictionary *)options;
- (BOOL)contentsEqualAtPath:(NSString *)path1 andPath:(NSString *)path2 skipRatio:(float)skipRatio;

@end

//
//  NSFileManager+addition.h
//  Comparator
//
//  Created by Maxime Leroy on 7/10/13.
//  Copyright (c) 2013 Lis@cintosh. All rights reserved.
//

#import <Foundation/Foundation.h>

#define NSFileManagerAdditionSkipLength @"NSFileManagerAdditionSkipLength" // Number of kB to skip after a fetch
#define NSFileManagerAdditionFetchLength @"NSFileManagerAdditionFetchLength" // Number of kB to fetch

@interface NSFileManager (addition)

- (BOOL)contentsEqualAtPath:(NSString *)path1 andPath:(NSString *)path2 withOptions:(NSDictionary *)options;
- (BOOL)contentsEqualAtPath:(NSString *)path1 andPath:(NSString *)path2 skipRatio:(float)skipRatio;

@end

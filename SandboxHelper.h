//
//  SandboxHelper.h
//  Comparator
//
//  Created by Maxime Leroy on 1/12/13.
//  Copyright (c) 2013 Lis@cintosh. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SandboxHelper : NSObject

+ (BOOL)sandboxActived;

+ (void)addSource:(NSURL *)sourceURL;
+ (void)removeSource:(NSURL *)sourceURL;
+ (void)removeAllSources;

+ (BOOL)startAccessingSecurityScopedSources;
+ (void)stopAccessingSecurityScopedSources;

@end

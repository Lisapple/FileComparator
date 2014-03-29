//
//  SandboxHelper.m
//  Comparator
//
//  Created by Maxime Leroy on 1/12/13.
//  Copyright (c) 2013 Lis@cintosh. All rights reserved.
//

#import "SandboxHelper.h"

@implementation SandboxHelper

static NSMutableArray * _sourcesURL = nil;

+ (BOOL)sandboxActived
{
#if _SANDBOX_ACTIVITED_
	return ([NSURL instancesRespondToSelector:@selector(startAccessingSecurityScopedResource)]);
#else
	return NO;
#endif
}


+ (void)addSource:(NSURL *)sourceURL
{
	if (!_sourcesURL)
		_sourcesURL = [[NSMutableArray alloc] initWithCapacity:3];
	
	if (![_sourcesURL containsObject:sourceURL])
		[_sourcesURL addObject:sourceURL];
}

+ (void)removeSource:(NSURL *)sourceURL
{
	[_sourcesURL removeObject:sourceURL];
}

+ (void)removeAllSources
{
	[_sourcesURL removeAllObjects];
}


+ (BOOL)startAccessingSecurityScopedSources
{
	BOOL started = YES;
	for (NSURL * sourceURL in _sourcesURL)
		started &= [sourceURL startAccessingSecurityScopedResource];
	
	return started;
}

+ (void)stopAccessingSecurityScopedSources
{
	for (NSURL * sourceURL in _sourcesURL)
		[sourceURL stopAccessingSecurityScopedResource];
}

@end

//
//  FileInformations.m
//  Comparator
//
//  Created by Max on 20/12/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "FileInformations.h"

#import "OptionItem.h"

#import "SandboxHelper.h"

@implementation FileInformations

static NSMutableDictionary * _subitemsOfPath = nil;

+ (void)initialize
{
	static BOOL initialized = NO;
	if (!initialized) {
		
		_subitemsOfPath = [[NSMutableDictionary alloc] initWithCapacity:3];
		
		initialized = YES;
	}
}

/*
+ (void)fetchNumberOfItemsForPath:(NSString *)path
{
	__block NSURL * fileURL = [[NSURL alloc] initFileURLWithPath:path];
	
	dispatch_group_t dispatch_group = dispatch_group_create();
	dispatch_queue_t dispatch_queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
	dispatch_group_async(dispatch_group, dispatch_queue, ^{
		NSFileManager * manager = [[NSFileManager alloc] init];
		NSDirectoryEnumerator * enumerator = [manager enumeratorAtURL:fileURL
										   includingPropertiesForKeys:nil
															  options:(NSDirectoryEnumerationSkipsHiddenFiles | NSDirectoryEnumerationSkipsPackageDescendants)// @TODO: change options from search option
														 errorHandler:NULL];
		NSInteger count = 0;
		while (enumerator.nextObject) { count++; }
		
		// @TODO: return "-1" if the count is under a limit (ex: 20000 files)
		
		NSNumber * numberOfItems = [NSNumber numberWithUnsignedInteger:count];
		[_numberOfItems setObject:numberOfItems forKey:fileURL.path];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:@"FileInformationsDidFinishNotification"
															object:[NSDictionary dictionaryWithObject:numberOfItems forKey:fileURL.path]];
		[manager release];
		[fileURL release];
	});
}
*/

+ (void)fetchPropertiesForItemsAtPath:(NSString *)path
{
	dispatch_group_t dispatch_group = dispatch_group_create();
	dispatch_queue_t dispatch_queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
	dispatch_group_async(dispatch_group, dispatch_queue, ^{
		/*
		NSFileManager * manager = [[NSFileManager alloc] init];
		__block NSDirectoryEnumerator * enumerator = [manager enumeratorAtURL:folderURL
										   includingPropertiesForKeys:[NSArray arrayWithObjects:NSURLFileSizeKey, nil]
															  options:(NSDirectoryEnumerationSkipsHiddenFiles | NSDirectoryEnumerationSkipsPackageDescendants)// @TODO: change options from search option
														 errorHandler:NULL];
		unsigned long long totalSize = 0.;
		NSInteger count = 0;
		NSURL * fileURL = nil;
		while (fileURL = enumerator.nextObject) {
			
			NSNumber * fileSize = nil;
			BOOL success = [fileURL getResourceValue:&fileSize forKey:NSURLFileSizeKey error:NULL];
			if (success) {
				totalSize += fileSize.unsignedLongLongValue;
				
				count++;
			}
		}
		
		// @TODO: return "-1" if the count is under a limit (ex: 20000 files)
		*/
		
		if ([SandboxHelper sandboxActived]) {
			BOOL started = [SandboxHelper startAccessingSecurityScopedSources];
			if (!started) NSLog(@"startAccessingSecurityScopedSources failed");
		}
		
		NSInteger count = 0;
		double totalSize = 0.;
		NSArray * subitems = [FileInformations propertiesForSubItemsAtPath:path];
		for (NSDictionary * itemAttributes in subitems) {
			
			totalSize += [[itemAttributes objectForKey:NSURLFileSizeKey] doubleValue];
			
			if ([[itemAttributes objectForKey:NSURLIsDirectoryKey] boolValue])
				count += [[itemAttributes objectForKey:@"numberOfItem"] integerValue];
			else
				count++;
		}
		
		NSURL * folderURL = [[NSURL alloc] initFileURLWithPath:path];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"FileInformationsDidFinishNotification"
															object:[NSDictionary dictionaryWithObjectsAndKeys:folderURL, @"fileURL",
																	[NSNumber numberWithDouble:totalSize], NSURLFileSizeKey,
																	[NSNumber numberWithInteger:count], @"numberOfItem", nil]];
		
		if ([SandboxHelper sandboxActived])
			[SandboxHelper stopAccessingSecurityScopedSources];
	});
}

+ (NSArray *)propertiesForSubItemsAtPath:(NSString *)folderPath
{
	/* Try to fetch the array with all subitems properties with "folderPath" as key */
	NSArray * subitemsProperties = [_subitemsOfPath objectForKey:folderPath];
	if (subitemsProperties)
		return subitemsProperties;
	
	
	BOOL skipsHiddenFiles = ![OptionItem includeHiddenItems];
	BOOL skipsBundle = ![OptionItem includeBundleContent];
	
	NSDirectoryEnumerationOptions options = NSDirectoryEnumerationSkipsSubdirectoryDescendants;
	if (skipsHiddenFiles) options |= NSDirectoryEnumerationSkipsHiddenFiles;
	if (skipsBundle) options |= NSDirectoryEnumerationSkipsPackageDescendants;
	
	NSFileManager * manager = [[NSFileManager alloc] init];
	NSDirectoryEnumerator * enumerator = [manager enumeratorAtURL:[NSURL fileURLWithPath:folderPath]
									   includingPropertiesForKeys:[NSArray arrayWithObjects:NSURLNameKey, NSURLIsDirectoryKey, NSURLFileSizeKey, nil]
														  options:options
													 errorHandler:NULL];
	
	NSMutableArray * itemsAttributes = [NSMutableArray arrayWithCapacity:10];
	
	NSDirectoryEnumerationOptions subitemsOptions = 0;
	if (skipsHiddenFiles) subitemsOptions |= NSDirectoryEnumerationSkipsHiddenFiles;
	if (skipsBundle) subitemsOptions |= NSDirectoryEnumerationSkipsPackageDescendants;
	
	NSURL * fileURL = nil;
	while ((fileURL = enumerator.nextObject)) {
		
		NSString * filename = nil;
		[fileURL getResourceValue:&filename forKey:NSURLNameKey error:NULL];
		
		NSNumber * isDirectory = nil;
		[fileURL getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:NULL];
		if (isDirectory.boolValue) {
			
			NSDirectoryEnumerator * enumerator = [manager enumeratorAtURL:fileURL
											   includingPropertiesForKeys:[NSArray arrayWithObjects:NSURLNameKey, NSURLFileSizeKey, nil]
																  options:subitemsOptions
															 errorHandler:NULL];
			unsigned long long totalSize = 0.;
			NSInteger count = 0;
			NSURL * itemURL = nil;
			while ((itemURL = enumerator.nextObject)) {
				
				NSNumber * fileSize = nil;
				BOOL success = [itemURL getResourceValue:&fileSize forKey:NSURLFileSizeKey error:NULL];
				if (success) {
					totalSize += fileSize.unsignedLongLongValue;
					
					count++;
				}
			}
			
			// @TODO: return "-1" if the count is under a limit (ex: 20000 files)
			
			NSDictionary * attributes = [[NSDictionary alloc] initWithObjectsAndKeys:filename, NSURLNameKey,
										 isDirectory, NSURLIsDirectoryKey,
										 [NSNumber numberWithUnsignedLongLong:totalSize], NSURLFileSizeKey,
										 [NSNumber numberWithUnsignedInteger:count], @"numberOfItem", nil];
			[itemsAttributes addObject:attributes];
			
		} else {
			
			NSString * filesize = nil;
			[fileURL getResourceValue:&filesize forKey:NSURLFileSizeKey error:NULL];
			
			NSDictionary * attributes = [[NSDictionary alloc] initWithObjectsAndKeys:filename, NSURLNameKey, isDirectory, NSURLIsDirectoryKey, filesize, NSURLFileSizeKey, nil];
			[itemsAttributes addObject:attributes];
		}
	}
	
	/* Save the array with all subitems properties with "folderPath" as key */
	[_subitemsOfPath setObject:itemsAttributes forKey:folderPath];
	
	return itemsAttributes;
}

@end

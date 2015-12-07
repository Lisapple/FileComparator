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
		[[NSNotificationCenter defaultCenter] addObserverForName:NSUserDefaultsDidChangeNotification object:nil queue:nil
													  usingBlock:^(NSNotification *note) {
														  [_subitemsOfPath removeAllObjects]; }];
		initialized = YES;
	}
}

+ (void)fetchPropertiesForItemsAtPath:(NSString *)path
{
	dispatch_group_t dispatch_group = dispatch_group_create();
	dispatch_queue_t dispatch_queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
	dispatch_group_async(dispatch_group, dispatch_queue, ^{
		
		if ([SandboxHelper sandboxActived]) {
			BOOL started = [SandboxHelper startAccessingSecurityScopedSources];
			if (!started) NSLog(@"startAccessingSecurityScopedSources failed");
		}
		
		NSInteger count = 0;
		double totalSize = 0.;
		NSArray * subitems = [FileInformations propertiesForSubItemsAtPath:path];
		for (NSDictionary * itemAttributes in subitems) {
			totalSize += [itemAttributes[NSURLFileSizeKey] doubleValue];
			BOOL isDirectory = ([itemAttributes[NSURLIsDirectoryKey] boolValue]);
			count += (isDirectory) ? [itemAttributes[@"numberOfItem"] integerValue] : 1;
		}
		
		NSURL * folderURL = [[NSURL alloc] initFileURLWithPath:path];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"FileInformationsDidFinishNotification"
															object:@{ @"fileURL" : folderURL, NSURLFileSizeKey : @(totalSize), @"numberOfItem" : @(count) }];
		
		if ([SandboxHelper sandboxActived])
			[SandboxHelper stopAccessingSecurityScopedSources];
	});
}

+ (NSArray *)propertiesForSubItemsAtPath:(NSString *)folderPath
{
	/* Try to fetch the array with all subitems properties with "folderPath" as key */
	NSArray * subitemsProperties = _subitemsOfPath[folderPath];
	if (subitemsProperties)
		return subitemsProperties;
	
	NSDirectoryEnumerationOptions options = (NSDirectoryEnumerationSkipsSubdirectoryDescendants | NSDirectoryEnumerationSkipsHiddenFiles);
	NSFileManager * manager = [[NSFileManager alloc] init];
	NSDirectoryEnumerator * enumerator = [manager enumeratorAtURL:[NSURL fileURLWithPath:folderPath]
									   includingPropertiesForKeys:@[ NSURLPathKey, NSURLNameKey, NSURLIsDirectoryKey, NSURLFileSizeKey ]
														  options:options
													 errorHandler:NULL];
	
	NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
	NSMutableArray * excludedSourcePaths = [NSMutableArray arrayWithArray:[userDefaults arrayForKey:@"blacklistPaths"]];
	BOOL excludeSystemAndLibraryFolders = [userDefaults boolForKey:@"Exclude System and Library Folders"];
	
	NSURL * volumeURL = nil;
	[[NSURL fileURLWithPath:folderPath] getResourceValue:&volumeURL forKey:NSURLVolumeURLKey error:NULL];
	NSString * volume = volumeURL.path;
	BOOL isLocalVolume = (volume.length > 1);
	
	if (excludeSystemAndLibraryFolders) {
		/* Add "(/[Volume Name])/System/" and "(/[Volume Name])/Library/" to excluded sources */
		[excludedSourcePaths addObject:[volume stringByAppendingString:@"System/"]];
		[excludedSourcePaths addObject:[volume stringByAppendingString:@"Library/"]];
	}
	/* Check if the number of component for "rootPath" is under
	 * 2 for booted volume ("/Users/[User's Name]")
	 * or under 3 for others volumes ("/[Volume's Name]/Users/[User's Name]")
	 */
	BOOL canContainsUserLibraryFolder = (folderPath.pathComponents.count <= ((isLocalVolume)? 2 : 3));
	
	const NSDirectoryEnumerationOptions subitemsOptions = NSDirectoryEnumerationSkipsHiddenFiles; // Skip only hidden files to get what will be shown on Finder
	NSMutableArray * itemsAttributes = [NSMutableArray arrayWithCapacity:10];
	NSURL * fileURL = nil;
	while ((fileURL = enumerator.nextObject)) {
		
		NSString * path = nil;
		[fileURL getResourceValue:&path forKey:NSURLPathKey error:NULL]; // Maybe faster than |fileURL.path| (?)
		
		// @TODO: try to remove this block
		BOOL exclude = NO;
		for (NSString * excludedPath in excludedSourcePaths) {
			if (path.length >= excludedPath.length
				&& [[path substringToIndex:excludedPath.length] isEqualToString:excludedPath]) {
				exclude = YES;
				break;
			}
		}
		if (exclude) {
			//NSDebugLog(@"excluded path: %@", path);
			continue;
		}
		
		if (excludeSystemAndLibraryFolders && canContainsUserLibraryFolder) {
			NSArray * pathComponents = [path pathComponents];
			NSInteger componentIndex = ((isLocalVolume)? 3 : 4);/* "Users" + "[User's Name]" + "Library" = 3 OR "[Volume's Name]" + "Users" + "[User's Name]" + "Library" = 4 */
			if (pathComponents.count >= componentIndex
				&& [pathComponents[(componentIndex - 1)] isEqualToString:@"Library"]) {
				//NSDebugLog(@"excluded path: %@", path);
				continue;
			}
		}
		
		NSString * filename = nil;
		[fileURL getResourceValue:&filename forKey:NSURLNameKey error:NULL];
		
		NSNumber * isDirectory = nil;
		[fileURL getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:NULL];
		if (isDirectory.boolValue) {
			
			NSDirectoryEnumerator * enumerator = [manager enumeratorAtURL:fileURL
											   includingPropertiesForKeys:@[NSURLNameKey, NSURLFileSizeKey]
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
			
			[itemsAttributes addObject:@{ NSURLNameKey : filename, NSURLIsDirectoryKey : isDirectory, NSURLPathKey : fileURL.path,
										  NSURLFileSizeKey : @(totalSize), @"numberOfItem" : @(count) }];
			
		} else {
			
			NSString * filesize = nil;
			[fileURL getResourceValue:&filesize forKey:NSURLFileSizeKey error:NULL];
			
			NSDictionary * attributes = @{ NSURLNameKey: filename, NSURLIsDirectoryKey: isDirectory,
										   NSURLPathKey : fileURL.path, NSURLFileSizeKey: filesize };
			[itemsAttributes addObject:attributes];
		}
	}
	
	/* Save the array with all subitems properties with "folderPath" as key */
	_subitemsOfPath[folderPath] = itemsAttributes;
	
	return itemsAttributes;
}

@end

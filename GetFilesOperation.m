//
//  GetFilesOperation.m
//  Comparator
//
//  Created by Max on 14/05/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

#import "GetFilesOperation.h"

#import "FileItem.h"
#import "ImageItem.h"
#import "AudioItem.h"

#import "OptionItem.h"

#import "ComparatorAppDelegate.h"

@implementation GetFilesOperation

- (instancetype)initWithRootPath:(NSString *)theRootPath
{
	if ((self = [super init])) {
		rootPath = theRootPath;
		isCancelled = NO;
		isExecuting = NO;
		isFinished = NO;
	}
	
	return self;
}

- (BOOL)isExecuting
{
    return isExecuting;
}

- (BOOL)isFinished
{
    return isFinished;
}

- (void)cancel
{
	if (isExecuting) {
		isCancelled = YES;
		
		[super cancel];
	}
}

- (FileType)typeOfFileAtURL:(NSURL *)fileURL
{
	NSString * type;
	[fileURL getResourceValue:&type forKey:NSURLTypeIdentifierKey error:NULL];
	
	if (UTTypeConformsTo((__bridge CFStringRef)type, CFSTR("public.image"))) {
		return FileTypeImage;
	} else if (UTTypeConformsTo((__bridge CFStringRef)type, CFSTR("public.audio"))) {
		return FileTypeAudio;
	} else {
		return FileTypeFile;
	}
}

- (BOOL)directoryIsEmpty:(NSString *)path
{
	NSDirectoryEnumerationOptions options = 0;// No options
	
	/*
	 NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
	 if ([userDefaults boolForKey:@"includeHiddenItems"] == NO)
	 options |= NSDirectoryEnumerationSkipsHiddenFiles;
	 */
	
	NSArray * properties = @[NSURLIsDirectoryKey];
	NSURL * rootURL = [NSURL fileURLWithPath:path];
	NSDirectoryEnumerator * enumerator = [[NSFileManager defaultManager] enumeratorAtURL:rootURL
															  includingPropertiesForKeys:properties
																				 options:options
																			errorHandler:NULL];
	NSURL * fileURL = nil;
	while ((fileURL = enumerator.nextObject)) {
		NSNumber * isDirectory;
		BOOL success = [fileURL getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:NULL];
		if (success && !isDirectory.boolValue) { // If we find a file, the folder is not empty
			return NO;
		}
	}
	
	return YES;
}

- (BOOL)isHiddenFileAtPath:(NSString *)path
{
	return [self isHiddenWithURL:[NSURL fileURLWithPath:path]];
}

- (BOOL)isHiddenWithURL:(NSURL *)fileURL
{
	NSNumber * isHidden;
	BOOL success = [fileURL getResourceValue:&isHidden forKey:NSURLIsHiddenKey error:NULL];
	return (success && isHidden.boolValue);
}

- (BOOL)isAliasAtPath:(NSString *)path
{
	return [self isAliasWithURL:[NSURL fileURLWithPath:path]];
}

- (BOOL)isAliasWithURL:(NSURL *)fileURL
{
	NSNumber * isAlias;
	BOOL success = [fileURL getResourceValue:&isAlias forKey:NSURLIsAliasFileKey error:NULL];
	return (success && isAlias.boolValue);
}

- (BOOL)isSymbolicLinkAtPath:(NSString *)path
{
	NSURL * rootURL = [NSURL fileURLWithPath:path];
	
	NSNumber * isSymbolicLink;
	[rootURL getResourceValue:&isSymbolicLink forKey:NSURLIsSymbolicLinkKey error:NULL];
	return isSymbolicLink.boolValue;
}

/* Compare (with case insensitive) extension from file at path with excludedExtensions from user defaults */
- (BOOL)isExcluded:(NSString *)path
{
	NSURL * fileURL = [[NSURL alloc] initFileURLWithPath:path];
	return [self isExcludedWithURL:fileURL];
}

- (BOOL)isExcludedWithURL:(NSURL *)fileURL
{
	if (!extensionBlacklistSelected) { // If whilelist have been selected...
		if (excludedFileTypes.count == 0) { // ... and if we don't have any extension to exclure...
			return NO; // ... thread it as no exclusions
		}
	}
	
	NSString * type = nil;
	[fileURL getResourceValue:&type forKey:NSURLTypeIdentifierKey error:NULL];
	
	if ([excludedFileTypes containsObject:type]) {
		return extensionBlacklistSelected;
	}
	return !extensionBlacklistSelected;
}

- (void)main
{
	NSDebugLog(@"GetFilesOperation -- main");
	
	isExecuting = YES;
	
	NSFileManager * fileManager = [[NSFileManager alloc] init];
	NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
	
	NSUInteger options = 0;
	if ([userDefaults boolForKey:@"includeBundleContent"] == NO) {
		options |= NSDirectoryEnumerationSkipsPackageDescendants;
	}
	
	BOOL includeHiddenItems = [userDefaults boolForKey:@"includeHiddenItems"];
	if (includeHiddenItems == NO) {
		options |= NSDirectoryEnumerationSkipsHiddenFiles;
	}
	
	NSURL * rootURL = [NSURL fileURLWithPath:rootPath];
	
	NSError * error = nil;
	NSNumber * isDirectory;
	BOOL success = [rootURL getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:&error];
	if (success && error) {
		[NSException raise:@"GetFilesOperationException" format:@"The root item type can ne be fetched: %@", error.localizedDescription];
	} else if (!isDirectory.boolValue) {
		[NSException raise:@"GetFilesOperationException" format:@"The root item must be a folder (path: %@)", rootURL.path];
	}
	
	BOOL shouldFindBrokenAliases = [OptionItem shouldFindBrokenAliases];
	BOOL shouldFindEmptyItems = [OptionItem shouldFindEmptyItems];
	
	/* Don't use context over threads, create a context for each thread with the persistent store */
	NSPersistentStoreCoordinator * coordinator = [(ComparatorAppDelegate *)[NSApp delegate] persistentStoreCoordinator];
	NSManagedObjectContext * context = [[NSManagedObjectContext alloc] init];
	[context setPersistentStoreCoordinator:coordinator];
	[context setUndoManager:nil];
	
	extensionBlacklistSelected = !([[userDefaults stringForKey:@"extensionTypeList"] isEqualToString:@"extensionWhitelistSelected"]);
	if (extensionBlacklistSelected) {
		excludedFileTypes = [userDefaults arrayForKey:@"extensionBlacklists"];
	} else {
		excludedFileTypes = [userDefaults arrayForKey:@"extensionWhitelists"];
	}
	
	NSMutableArray * checkedOptions = [NSMutableArray arrayWithCapacity:10];
	for (OptionItem * optionItem in [OptionItem checkedItems]) {
		[checkedOptions addObject:optionItem.identifier];
	}
	
	NSMutableArray * excludedSourcePaths = [NSMutableArray arrayWithArray:[userDefaults arrayForKey:@"blacklistPaths"]];
	
	BOOL excludeSystemAndLibraryFolders = [userDefaults boolForKey:@"Exclude System and Library Folders"];
	
	NSURL * volumeURL = nil;
	[rootURL getResourceValue:&volumeURL forKey:NSURLVolumeURLKey error:NULL];
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
	BOOL canContainsUserLibraryFolder = (rootPath.pathComponents.count <= ((isLocalVolume)? 2 : 3));
	
	NSURL * fileURL = nil;
	NSArray * properties = @[ NSURLPathKey, NSURLIsDirectoryKey, NSURLTypeIdentifierKey, NSURLIsSymbolicLinkKey,
							  NSURLFileSizeKey, NSURLCreationDateKey, NSURLContentModificationDateKey ];
	NSDirectoryEnumerator * directoryEnumerator = [fileManager enumeratorAtURL:rootURL
													includingPropertiesForKeys:properties
																	   options:options
																  errorHandler:NULL];
	while ((fileURL = directoryEnumerator.nextObject)) {
		
		if (isCancelled) {
			isExecuting = NO;
			return ;
		}
		
		NSString * path = nil;
		[fileURL getResourceValue:&path forKey:NSURLPathKey error:NULL];
		
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
		
		NSNumber * isDirectory;
		[fileURL getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:NULL];
		
		if (isDirectory.boolValue) {
			if (shouldFindEmptyItems && [self directoryIsEmpty:path]) {
				NSEntityDescription * entity = [NSEntityDescription entityForName:@"FileItem" inManagedObjectContext:context];
				FileItem * item = [[FileItem alloc] initWithEntity:entity insertIntoManagedObjectContext:context];
				item.path = path;
				item.isFile = @NO;
				item.fileSize = @NO;
			}
		} else {
			
			if ([self isSymbolicLinkAtPath:path]) {// Symbolic Link
				
				if (shouldFindBrokenAliases) {
					NSError * error = nil;
					NSString * destination = [fileManager destinationOfSymbolicLinkAtPath:path error:&error];
					
					BOOL reachable = (destination.length >= rootPath.length
									  && [[destination substringToIndex:rootPath.length] isEqualToString:rootPath]);
					
					BOOL exists = YES;
					if (reachable) {
						exists = [fileManager fileExistsAtPath:destination];
					}
					if (!exists) {
						NSEntityDescription * entity = [NSEntityDescription entityForName:@"FileItem" inManagedObjectContext:context];
						FileItem * item = [[FileItem alloc] initWithEntity:entity insertIntoManagedObjectContext:context];
						item.path = path;
						item.isFile = @((BOOL)(!isDirectory.boolValue));
						
						NSDate * creationDate = nil;
						[fileURL getResourceValue:&creationDate forKey:NSURLCreationDateKey error:NULL];
						item.creationDate = creationDate;
						
						NSDate * lastModificationDate = nil;
						[fileURL getResourceValue:&lastModificationDate forKey:NSURLContentModificationDateKey error:NULL];
						item.lastModificationDate = lastModificationDate;
						
						item.isBroken = (id)kCFBooleanTrue;
					}
				}
				
			} else if ([self isAliasWithURL:fileURL]) {// Alias
				
				if (shouldFindBrokenAliases) {
					
					Boolean isStale = NO;
					CFDataRef bookmarkData = CFURLCreateBookmarkDataFromFile(kCFAllocatorDefault, (__bridge CFURLRef)fileURL, NULL);
					CFURLRef aliasURLRef = CFURLCreateByResolvingBookmarkData(kCFAllocatorDefault,
																			  bookmarkData,
																			  (kCFBookmarkResolutionWithoutUIMask | kCFBookmarkResolutionWithoutMountingMask),
																			  NULL, NULL, &isStale, NULL);
					if (bookmarkData) CFRelease(bookmarkData);
					
					if ((aliasURLRef == NULL) || isStale) {// If the alias is broken or stale, create an entry
						NSEntityDescription * entity = [NSEntityDescription entityForName:@"FileItem" inManagedObjectContext:context];
						FileItem * item = [[FileItem alloc] initWithEntity:entity insertIntoManagedObjectContext:context];
						item.path = path;
						item.isFile = @(!isDirectory.boolValue);
						
						NSDate * creationDate = nil;
						[fileURL getResourceValue:&creationDate forKey:NSURLCreationDateKey error:NULL];
						item.creationDate = creationDate;
						
						NSDate * lastModificationDate = nil;
						[fileURL getResourceValue:&lastModificationDate forKey:NSURLContentModificationDateKey error:NULL];
						item.lastModificationDate = lastModificationDate;
						
						item.isBroken = (id)kCFBooleanTrue;
					}
					if (aliasURLRef) CFRelease(aliasURLRef);
				}
				
			} else {// File (Image, Audio, Video, Regular File)
				
				BOOL excluded = [self isExcludedWithURL:fileURL];
				if (excluded) NSDebugLog(@"file at path: %@ is excluded", path);
				
				if (!excluded) {
					
					NSNumber * fileSize = nil;
					[fileURL getResourceValue:&fileSize forKey:NSURLFileSizeKey error:NULL];
					
					switch ([self typeOfFileAtURL:fileURL]) {
						case FileTypeImage: {
							NSEntityDescription * entity = [NSEntityDescription entityForName:@"ImageItem" inManagedObjectContext:context];
							ImageItem * item = [[ImageItem alloc] initWithEntity:entity insertIntoManagedObjectContext:context];
							item.fileSize = fileSize;
							item.path = path;
							item.isFile = @(!isDirectory.boolValue);
							[item getInfoFromOptions:checkedOptions];
						} break;
						case FileTypeAudio: {
							NSEntityDescription * entity = [NSEntityDescription entityForName:@"AudioItem" inManagedObjectContext:context];
							AudioItem * item = [[AudioItem alloc] initWithEntity:entity insertIntoManagedObjectContext:context];
							item.fileSize = fileSize;
							item.path = path;
							item.isFile = @(!isDirectory.boolValue);
							[item getInfoFromOptions:checkedOptions];
						} break;
						case FileTypeFile: {
							NSEntityDescription * entity = [NSEntityDescription entityForName:@"FileItem" inManagedObjectContext:context];
							FileItem * item = [[FileItem alloc] initWithEntity:entity insertIntoManagedObjectContext:context];
							item.fileSize = fileSize;
							item.path = path;
							item.isFile = @(!isDirectory.boolValue);
							[item getInfoFromOptions:checkedOptions];
						} break;
						default: {
							[NSException raise:@"GetFilesOperationException"
										format:@"-[GetFilesOperation typeForExtension:] returns an inexpected FileType (%i) for extension: %@", [self typeOfFileAtURL:fileURL], path.pathExtension];
						}
					}
				}
			}
		}
	}
	
	error = nil;
	if (![context save:&error]) {
		NSDebugLog(@"error save: %@", error.localizedDescription);
	}
	
	isExecuting = NO;
	isFinished = YES;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"GetFilesOperationDidFinishNotification" object:nil];
}

@end

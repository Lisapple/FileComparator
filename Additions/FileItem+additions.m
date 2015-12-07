//
//  FileItem+additions.m
//  Comparator
//
//  Created by Maxime on 10/01/13.
//  Copyright (c) 2013 Lis@cintosh. All rights reserved.
//

#import "FileItem+additions.h"

@implementation FileItem (additions)

- (BOOL)moveToTrash
{
	BOOL success;
	if ([[NSFileManager defaultManager] respondsToSelector:@selector(trashItemAtURL:resultingItemURL:error:)]) { // OS X.8+
		success = (BOOL)[[NSFileManager defaultManager] trashItemAtURL:[NSURL fileURLWithPath:self.path] resultingItemURL:nil error:nil];
	} else {
		const char * folderPath = self.path.UTF8String;
		char * targetPath = NULL;
		FSPathMoveObjectToTrashSync(folderPath, &targetPath, 0);
		success = (targetPath != NULL);
	}
	return success;
}

- (BOOL)moveToFolder:(NSString *)folderPath
{
	/* Add a "/" between "folderPath" and the filename if needed */
	BOOL addSlash = !([[folderPath substringFromIndex:(folderPath.length - 1)] isEqualToString:@"/"]);
	NSString * newPath = [NSString stringWithFormat:@"%@%@%@", folderPath, (addSlash)? @"/" : @"", self.path.lastPathComponent];
	return [[NSFileManager defaultManager] moveItemAtPath:self.path
												   toPath:newPath
													error:NULL];
}

- (BOOL)moveToPath:(NSString *)newPath
{
	return [[NSFileManager defaultManager] moveItemAtPath:self.path toPath:newPath error:NULL];
}

- (BOOL)moveToURL:(NSURL *)newURL
{
	return [self moveToPath:newURL.path];
}

- (void)removeFromContext
{
	[self.managedObjectContext deleteObject:self];
}

@end

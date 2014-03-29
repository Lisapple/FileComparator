//
//  NSFileManager+addition.m
//  Comparator
//
//  Created by Maxime Leroy on 7/10/13.
//  Copyright (c) 2013 Lis@cintosh. All rights reserved.
//

#import "NSFileManager+addition.h"

@implementation NSFileManager (addition)

- (BOOL)contentsEqualAtPath:(NSString *)path1 andPath:(NSString *)path2 withOptions:(NSDictionary *)options
{
	NSAssert(options[NSFileManagerAdditionSkipLength] != nil, @"|options| must contains a value for the key NSFileManagerAdditionSkipLength: %@", options);
	NSUInteger skipLength = [options[NSFileManagerAdditionSkipLength] unsignedIntegerValue] * 1000;
	
	NSAssert(options[NSFileManagerAdditionFetchLength] != nil, @"|options| must contains a value for the key NSFileManagerAdditionFetchLength: %@", options);
	NSUInteger fetchLength = [options[NSFileManagerAdditionFetchLength] unsignedIntegerValue] * 1000;
	
	NSFileHandle * handle1 = [NSFileHandle fileHandleForReadingAtPath:path1];
	NSURL * fileURL1 = [NSURL fileURLWithPath:path1];
	NSNumber * filesize1 = nil;
	[fileURL1 getResourceValue:&filesize1 forKey:NSURLFileSizeKey error:NULL];
	
	NSURL * fileURL2 = [NSURL fileURLWithPath:path1];
	NSNumber * filesize2 = nil;
	[fileURL2 getResourceValue:&filesize2 forKey:NSURLFileSizeKey error:NULL];
	NSFileHandle * handle2 = [NSFileHandle fileHandleForReadingAtPath:path2];
	
	if (filesize1.longLongValue == filesize2.longLongValue) {
		
		unsigned long long filesize = filesize1.unsignedLongLongValue;
		
		BOOL equals = YES;
		unsigned long long offset = 0.;
		while ((offset + fetchLength) < filesize) {
			
			[handle1 seekToFileOffset:offset];
			NSData * data1 = [handle1 readDataOfLength:fetchLength];
			
			[handle2 seekToFileOffset:offset];
			NSData * data2 = [handle2 readDataOfLength:fetchLength];
			
			equals &= [data1 isEqualToData:data2];
			if (!equals) return NO;
			
			offset += (fetchLength + skipLength);
		}
		return equals;
	}
	return NO;
}

- (BOOL)contentsEqualAtPath:(NSString *)path1 andPath:(NSString *)path2 skipRatio:(float)skipRatio
{
	NSFileHandle * handle1 = [NSFileHandle fileHandleForReadingAtPath:path1];
	NSURL * fileURL1 = [NSURL fileURLWithPath:path1];
	NSNumber * filesize1 = nil;
	[fileURL1 getResourceValue:&filesize1 forKey:NSURLFileSizeKey error:NULL];
	
	NSURL * fileURL2 = [NSURL fileURLWithPath:path1];
	NSNumber * filesize2 = nil;
	[fileURL2 getResourceValue:&filesize2 forKey:NSURLFileSizeKey error:NULL];
	NSFileHandle * handle2 = [NSFileHandle fileHandleForReadingAtPath:path2];
	
	if (filesize1.longLongValue == filesize2.longLongValue) {
		
		unsigned long long filesize = filesize1.unsignedLongLongValue;
		unsigned long long skipLength = filesize * skipRatio;
		unsigned long long fetchLength = filesize - skipLength;
		
		BOOL equals = YES;
		unsigned long long offset = 0.;
		while ((offset + fetchLength) < filesize && equals) {
			
			[handle1 seekToFileOffset:offset];
			NSData * data1 = [handle1 readDataOfLength:fetchLength];
			
			[handle2 seekToFileOffset:offset];
			NSData * data2 = [handle2 readDataOfLength:fetchLength];
			
			equals &= [data1 isEqualToData:data2];
			
			offset += (fetchLength + skipLength);
		}
		return equals;
	}
	return NO;
}

@end

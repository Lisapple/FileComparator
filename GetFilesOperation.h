//
//  GetFilesOperation.h
//  Comparator
//
//  Created by Max on 14/05/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import <AudioToolbox/AudioToolbox.h>

enum _FileType {
	FileTypeImage = 1,
	FileTypeAudio,
	/*
	FileTypeVideo,
	FileTypePDF,
	FileTypeText,
	*/
	FileTypeFile,
} /* FileType */;
typedef enum _FileType FileType;

@interface GetFilesOperation : NSOperation
{
	NSString * rootPath;
	
	@private
	BOOL isCancelled, isExecuting, isFinished;
	NSArray * excludedFileTypes;
	BOOL extensionBlacklistSelected;
}

- (id)initWithRootPath:(NSString *)theRootPath;

- (BOOL)isHiddenFileAtPath:(NSString *)path;
- (BOOL)isAliasAtPath:(NSString *)path;
- (BOOL)isSymbolicLinkAtPath:(NSString *)path;

// Private
- (BOOL)isHiddenWithURL:(NSURL *)fileURL;
- (BOOL)isAliasWithURL:(NSURL *)fileURL;
- (BOOL)isExcludedWithURL:(NSURL *)fileURL;

@end

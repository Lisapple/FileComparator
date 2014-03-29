//
//  FileItem.m
//  Comparator
//
//  Created by Max on 09/04/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

#import "FileItem.h"

#import "ImageItem.h"
#import "AudioItem.h"

#import "NSString+addition.h"
#import "NSFileManager+addition.h"

@implementation FileItem

@dynamic filename, extension;

@dynamic isFile;
@dynamic selected;
@dynamic path;
@dynamic fileSize;
@dynamic fileType;
@dynamic type;
@dynamic creationDate, lastModificationDate;
@dynamic lockState;
@dynamic labelColorNumber;
@dynamic isBroken;
@dynamic info;

@dynamic isValid;

static NSArray * _availableOptions = nil;
+ (void)initialize
{
	static BOOL initialized = NO;
	if (!initialized) {
		_availableOptions = [[NSArray alloc] initWithObjects:@"FileItemCompareSize", @"FileItemCompareFilename", @"FileItemCompareUTI", @"FileItemCompareExtension", @"FileItemCompareCreationDate", @"FileItemCompareLastModificationDate", nil];
		
		initialized = YES;
	}
}

+ (NSDictionary *)commonsValuesForItems:(NSArray *)items
{
	NSMutableDictionary * commonValues = nil;
	
	for (FileItem * item in items) {
		if (!commonValues) {
			commonValues = [NSMutableDictionary dictionaryWithDictionary:[item itemValues]];
		} else {
			
			NSArray * commonKeysCopy = [[commonValues allKeys] copy];
			NSDictionary * itemValues = [item itemValues];
			for (NSString * key in commonKeysCopy) {
				id object = [itemValues objectForKey:key];
				id commonObject = [commonValues objectForKey:key];
				if (![object isEqualTo:commonObject]) {
					[commonValues removeObjectForKey:key];
					
					/* Return directly the empty dictionary if no more entries are into */
					if (commonValues.count == 0) {
						return commonValues;
					}
				}
			}
		}
	}
	
	return commonValues;
}

+ (NSArray *)propertiesForOptions:(NSArray *)options
{
	NSMutableArray * properties = [[NSMutableArray alloc] initWithCapacity:options.count];
	
	for (NSString * option in options) {
		
		if ([option isEqualToString:@"FileItemCompareSize"]) {
			[properties addObject:@"fileSize"];
		} else if ([option isEqualToString:@"FileItemCompareFilename"]) {
			[properties addObject:@"filename"];
		} else if ([option isEqualToString:@"FileItemCompareUTI"]) {
			[properties addObject:@"type"];
		} else if ([option isEqualToString:@"FileItemCompareExtension"]) {
			[properties addObject:@"extension"];
		} else if ([option isEqualToString:@"FileItemCompareCreationDate"]) {
			[properties addObject:@"creationDate"];
		} else if ([option isEqualToString:@"FileItemCompareLastModificationDate"]) {
			[properties addObject:@"lastModificationDate"];
		}
	}
	return (NSArray *)properties;
}

+ (NSArray *)availableOptions
{
	return _availableOptions;
}

+ (id)valueForOption:(NSString *)option fromItem:(FileItem *)item
{
	if ([option isEqualToString:@"FileItemCompareSize"]) {
		return item.fileSize;
	} else if ([option isEqualToString:@"FileItemCompareFilename"]) {
		return item.filename;
	} else if ([option isEqualToString:@"FileItemCompareExtension"]) {
		return item.extension;
	} else if ([option isEqualToString:@"FileItemCompareUTI"]) {
		return item.type;
	} else if ([option isEqualToString:@"FileItemCompareCreationDate"]) {
		return item.creationDate;
	} else if ([option isEqualToString:@"FileItemCompareLastModificationDate"]) {
		return item.lastModificationDate;
	} else {
		// @TODO: is option image or audio specific? get value from these classes
		if ([ImageItem canCompareWithOption:option]) {
			return [ImageItem valueForOption:option fromItem:(ImageItem *)item];
		} else if ([AudioItem canCompareWithOption:option]) {
			return [AudioItem valueForOption:option fromItem:(AudioItem *)item];
		}
	}
	
	return nil;
}

+ (void)getOptionInfo:(NSString *)option forItem:(FileItem *)item
{
	if ([option isEqualToString:@"FileItemCompareSize"]) {
		if (!item.fileSize) {
			NSNumber * number;
			[[NSURL fileURLWithPath:item.path] getResourceValue:&number forKey:NSURLFileSizeKey error:NULL];
			item.fileSize = number;
		}
	} else if ([option isEqualToString:@"FileItemCompareFilename"]) {
		if (!item.filename) { item.filename = [[item.path lastPathComponent] stringByDeletingPathExtension]; }
	} else if ([option isEqualToString:@"FileItemCompareExtension"]) {
		if (!item.extension) { item.extension = [item.path pathExtension]; }
	} else if ([option isEqualToString:@"FileItemCompareUTI"]) {
		if (!item.type) {
			NSString * type = nil;
			[[NSURL fileURLWithPath:item.path] getResourceValue:&type forKey:NSURLTypeIdentifierKey error:NULL];
			item.type = type;
		}
	} else if ([option isEqualToString:@"FileItemCompareCreationDate"]) {
		if (!item.lastModificationDate) {
			NSDictionary * attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:item.path error:NULL];
			item.creationDate = [attributes objectForKey:NSFileCreationDate];
		}
	} else if ([option isEqualToString:@"FileItemCompareLastModificationDate"]) {
		if (!item.lastModificationDate) {
			NSDictionary * attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:item.path error:NULL];
			item.lastModificationDate = [attributes objectForKey:NSFileModificationDate];
		}
	} else {
		// Just ignore, it could be for images, audio or movie files, or even doesn't exist, it not matters.
	}
}

- (id)initWithPath:(NSString *)aPath
{
	if ((self = [self init])) {
		self.path = aPath;
	}
	
	return self;
}

- (NSManagedObject *)group
{
	return [self valueForKey:@"fileGroups"];
}

- (void)getOptionItemInfo:(OptionItem *)option
{
	[self getOptionInfo:option.identifier];
}

- (void)getOptionInfo:(NSString *)option
{
	if ([option isEqualToString:@"FileItemCompareSize"]) {
		
		NSURL * fileURL = [[NSURL alloc] initFileURLWithPath:self.path];
		
		NSNumber * number;
		[fileURL getResourceValue:&number forKey:NSURLFileSizeKey error:NULL];
		
		self.fileSize = number;
		
	} else if ([option isEqualToString:@"FileItemCompareFilename"]) {
		
		self.filename = [[self.path lastPathComponent] stringByDeletingPathExtension];
		
	} else if ([option isEqualToString:@"FileItemCompareExtension"]) {
		
		self.extension = [self.path pathExtension];
		
	} else if ([option isEqualToString:@"FileItemCompareUTI"]) {
		
		NSString * type;
		NSURL * fileURL = [[NSURL alloc] initFileURLWithPath:self.path];
		[fileURL getResourceValue:&type forKey:NSURLTypeIdentifierKey error:NULL];
		
		self.type = type;//[[NSWorkspace sharedWorkspace] typeOfFile:self.path error:NULL];
		
	} else if ([option isEqualToString:@"FileItemCompareCreationDate"]) {
		
		/*
		NSDictionary * attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:self.path error:NULL];
		self.creationDate = [attributes objectForKey:NSFileCreationDate];
		*/
		
		NSURL * fileURL = [[NSURL alloc] initFileURLWithPath:self.path];
		
		NSDate * creationDate = nil;
		[fileURL getResourceValue:&creationDate forKey:NSURLCreationDateKey error:NULL];
		
		self.creationDate = creationDate;
		
	} else if ([option isEqualToString:@"FileItemCompareLastModificationDate"]) {
		
		/*
		NSDictionary * attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:self.path error:NULL];
		self.lastModificationDate = [attributes objectForKey:NSFileModificationDate];
		*/
		
		NSURL * fileURL = [[NSURL alloc] initFileURLWithPath:self.path];
		
		NSDate * lastModificationDate = nil;
		[fileURL getResourceValue:&lastModificationDate forKey:NSURLContentModificationDateKey error:NULL];
		
		self.lastModificationDate = lastModificationDate;
		
	} else {
		// Just ignore, it could be for images, audio or movie files, or even doesn't exist, it not matters.
	}
}

- (void)getInfoFromOptionItems:(NSArray *)options
{
	for (OptionItem * option in options) {
		[self getOptionItemInfo:option];
	}
}

- (void)getInfoFromOptions:(NSArray *)options
{
	for (NSString * option in options) {
		[self getOptionInfo:option];
	}
}

- (void)setLocked:(BOOL)locked
{
	[self setLockState:[NSNumber numberWithBool:locked]];
}

- (BOOL)isHidden
{
	NSString * filename = [self.path lastPathComponent];
	return [[filename substringToIndex:1] isEqualToString:@"."];
}

- (NSString *)filename
{
	[self willAccessValueForKey:@"filename"];
	NSString * filename = [self primitiveValueForKey:@"filename"];
	[self didAccessValueForKey:@"filename"];
	
	if (filename) {
		return filename;
	}
	
	filename = [[self.path lastPathComponent] stringByDeletingPathExtension];
	self.filename = filename;
	
	return filename;
}

- (NSString *)extension
{
	[self willAccessValueForKey:@"extension"];
	NSString * extension = [self primitiveValueForKey:@"extension"];
	[self didAccessValueForKey:@"extension"];
	
	if (extension) {
		return extension;
	}
	
	extension = [self.path pathExtension];
	self.extension = extension;
	
	return extension;
}

- (BOOL)isEqualTo:(FileItem *)anotherItem options:(NSArray *)options
{
	if (options.count == 0)// No options
		[NSException raise:@"FileItem Exception" format:@"-[FileItem compare:optionsMask:] called with not option mask."];
	
	for (NSString * option in options) {
		
		if ([option isEqualToString:@"FileItemCompareSize"]) {
			if ([self.fileSize longLongValue] != [anotherItem.fileSize longLongValue])
				return NO;
			/*
			[self willAccessValueForKey:@"fileSize"], [anotherItem willAccessValueForKey:@"fileSize"];
			if ([self.fileSize longLongValue] != [anotherItem.fileSize longLongValue])
				return NO;
			 */
		} else if ([option isEqualToString:@"FileItemCompareFilename"]) {
			if (![self.filename isEqualToString:anotherItem.filename])
				return NO;
		} else if ([option isEqualToString:@"FileItemCompareExtension"]) {
			if (![self.extension isEqualToString:anotherItem.extension])
				return NO;
		} else if ([option isEqualToString:@"FileItemCompareUTI"]) {
			if (![self.type isEqualToString:anotherItem.type])
				return NO;
		} else if ([option isEqualToString:@"FileItemCompareCreationDate"]) {
			if (![self.creationDate isEqualToDate:anotherItem.creationDate])
				return NO;
		} else if ([option isEqualToString:@"FileItemCompareLastModificationDate"]) {
			if (![self.lastModificationDate isEqualToDate:anotherItem.lastModificationDate])
				return NO;
		} else if ([option isEqualToString:@"FileItemCompareData"]) {
			
			if (self.fileSize.longLongValue != anotherItem.fileSize.longLongValue)
				return NO;
			
			BOOL equals;
			if (self.fileSize.unsignedLongLongValue > (50. * 1000. * 1000.)) { // If the size if more than 50MB
				NSDictionary * options = @{ NSFileManagerAdditionFetchLength : @10,
								NSFileManagerAdditionSkipLength : @1000 }; // Compare 10kB every Mb
				equals = [[NSFileManager defaultManager] contentsEqualAtPath:self.path andPath:anotherItem.path withOptions:options];
			} else {
				equals = [[NSFileManager defaultManager] contentsEqualAtPath:self.path andPath:anotherItem.path];
			}
			if (!equals)
				return NO;
		}
		/* Ignore all options that are image, audio or movie specific */
	}
	
	return YES;
}

- (NSComparisonResult)compareByLastModificationDate:(FileItem *)anotherItem
{
	[self willAccessValueForKey:@"lastModificationDate"];
	[anotherItem willAccessValueForKey:@"lastModificationDate"];
	
	NSComparisonResult result = (1 - [self.lastModificationDate compare:anotherItem.lastModificationDate]);// Invert the order to order from younger to older
	
	[self didAccessValueForKey:@"lastModificationDate"];
	[anotherItem didAccessValueForKey:@"lastModificationDate"];
	
	return result;
}

- (NSComparisonResult)compareByCreationDate:(FileItem *)anotherItem
{
	[self willAccessValueForKey:@"creationDate"];
	[anotherItem willAccessValueForKey:@"creationDate"];
	
	NSComparisonResult result = [self.creationDate compare:anotherItem.creationDate];
	
	[self didAccessValueForKey:@"creationDate"];
	[anotherItem didAccessValueForKey:@"creationDate"];
	
	return result;
}

- (NSDictionary *)itemValues
{
	NSMutableDictionary * attributes = [NSMutableDictionary dictionaryWithCapacity:3];
	
	NSArray * availableOptions = [FileItem availableOptions];
	for (NSString * option in availableOptions) {
		[FileItem getOptionInfo:option forItem:self];
		id value = [FileItem valueForOption:option fromItem:self];
		if (value) {
			[attributes setObject:value forKey:option];
		}
	}
	
	return attributes;
}

- (NSDictionary *)commonsValuesWithItem:(FileItem *)anotherItem
{
	NSMutableDictionary * commonValues = [NSMutableDictionary dictionaryWithCapacity:10];
	
	NSDictionary * itemValues = [self itemValues];
	NSDictionary * anotherItemValues = [anotherItem itemValues];
	for (NSString * key in [itemValues allKeys]) {
		id object = [itemValues objectForKey:key];
		id anotherObject = [anotherItemValues objectForKey:key];
		if ([object isEqualTo:anotherObject]) {
			[commonValues setObject:object forKey:key];
		}
	}
	
	return commonValues;
}

- (void)addObject:(id)object// @TODO: remove this
{
	NSDebugLog(@"-[FileItem addObject:] => object = %@", object);
}

- (NSColor *)labelColor
{
	if ([self.labelColorNumber intValue] == -1) {// If no color value, retreive them
		/* Retreive the color of the label on Finder */
		CFNumberRef labelColorNumberRef = NULL;
		CFURLCopyResourcePropertyForKey((__bridge CFURLRef)[NSURL fileURLWithPath:self.path], kCFURLLabelNumberKey, &labelColorNumberRef, NULL);
		self.labelColorNumber = (__bridge NSNumber *)labelColorNumberRef;
	}
	
	/* Color the background for file that have label color on Finder */
	if ([self.labelColorNumber intValue] > 0) {
		NSArray * fileLabelColors = [[NSWorkspace sharedWorkspace] fileLabelColors];
		return [fileLabelColors objectAtIndex:[self.labelColorNumber intValue]];
	}
	
	return nil;
}








- (id)valueForOption:(NSString *)option
{
	if ([option isEqualToString:@"FileItemCompareSize"]) {
		return self.fileSize;
	} else if ([option isEqualToString:@"FileItemCompareFilename"]) {
		return self.filename;
	} else if ([option isEqualToString:@"FileItemCompareExtension"]) {
		return self.extension;
	} else if ([option isEqualToString:@"FileItemCompareUTI"]) {
		return self.type;
	} else if ([option isEqualToString:@"FileItemCompareCreationDate"]) {
		return self.creationDate;
	} else if ([option isEqualToString:@"FileItemCompareLastModificationDate"]) {
		return self.lastModificationDate;
	}
	
	return nil;
}

- (NSDictionary *)localizedItemValues
{
	NSMutableDictionary * attributes = [NSMutableDictionary dictionaryWithCapacity:3];
	
	NSArray * availableOptions = [FileItem availableOptions];
	for (NSString * option in availableOptions) {
		[FileItem getOptionInfo:option forItem:self];
		
		// @TODO: create a class function +[FileItem valueForItem:forOption:]
		id value = [FileItem valueForOption:option fromItem:self];
		id localizedValue = nil;
		
		if ([option isEqualToString:@"FileItemCompareUTI"]) {
			localizedValue = [[NSWorkspace sharedWorkspace] localizedDescriptionForType:value];
		} else if ([option isEqualToString:@"FileItemCompareCreationDate"]) {
			NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
			formatter.dateStyle = NSDateFormatterLongStyle;
			formatter.timeStyle = NSDateFormatterShortStyle;
			localizedValue = [formatter stringFromDate:value];
		} else if ([option isEqualToString:@"FileItemCompareLastModificationDate"]) {
			NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
			formatter.dateStyle = NSDateFormatterLongStyle;
			formatter.timeStyle = NSDateFormatterShortStyle;
			localizedValue = [formatter stringFromDate:value];
		} else if ([option isEqualToString:@"FileItemCompareSize"]) {
			localizedValue = [NSString localizedStringForFileSize:[value doubleValue]];
		} else if ([option isEqualToString:@"FileItemCompareUTI"]) {
			localizedValue = [[NSWorkspace sharedWorkspace] localizedDescriptionForType:value];
		} else {
			localizedValue = [NSString stringWithFormat:@"%@", value];
		}
		
		if (localizedValue) {
			[attributes setObject:localizedValue forKey:option];
		}
	}
	
	return attributes;
}

- (NSImage *)thumbnailForSize:(CGSize)size
{
	// @TODO: create an addition for this
	const void * keys[1] = { (void *)kQLThumbnailOptionIconModeKey };
	const void * values[1] = { (void *)kCFBooleanTrue };
	
	NSURL * fileURL = [NSURL fileURLWithPath:self.path];
	
	/* Set the default size to 128x128px */
	if (CGSizeEqualToSize(size, CGSizeZero)) size = CGSizeMake(128., 128.);
	
	CFDictionaryRef thumbnailAttributes = CFDictionaryCreate(kCFAllocatorDefault, keys, values, 1, NULL, NULL);
	CGImageRef imageRef = QLThumbnailImageCreate(kCFAllocatorDefault, (__bridge CFURLRef)fileURL, size, thumbnailAttributes);
	if (thumbnailAttributes) CFRelease(thumbnailAttributes);
	
	NSImage * image = nil;
	if (imageRef) {
		image = [[NSImage alloc] initWithCGImage:imageRef size:NSZeroSize];
		CGImageRelease(imageRef);
	} else {
		image = [[NSWorkspace sharedWorkspace] iconForFile:self.path];
	}
	
	return image;
}

@end

//
//  ImageItem.m
//  Comparator
//
//  Created by Max on 25/01/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "ImageItem.h"

#import "OptionItem.h"

@implementation ImageItem

@dynamic width, height, depth, orientation, hasAlpha, bitsPerPixel, bytesPerRow;
@dynamic exifExposureTime, exifFNumber, exifISOSpeedRatings, exifFlash, exifFocalLength, exifUserComment, exifContrast, exifSaturation, exifSharpness, exifCameraOwnerName, exifSerialNumber;
@dynamic gifLoopCount, gifDelayTime;
@dynamic gpsLatitude, gpsLongitude, gpsAltitude, gpsDateStamp;
@dynamic pngInterlaceType;
@dynamic tiffCompression, tiffMake, tiffModel, tiffSoftware;

static NSArray * _availableOptions = nil;
+ (void)initialize
{
	static BOOL initialized = NO;
	if (!initialized) {
		_availableOptions = @[@"ImageItemCompareWidthInPixels", @"ImageItemCompareHeightInPixels", @"ImageItemCompareDepth", @"ImageItemCompareOrientation", @"ImageItemCompareHasAlpha", @"ImageItemCompareBitsPerPixel", @"ImageItemCompareBytesPerRow", @"ImageItemCompareExifExposureTime", @"ImageItemCompareExifFNumber", @"ImageItemCompareExifISOSpeedRatings", @"ImageItemCompareExifFlash", @"ImageItemCompareExifFocalLength", @"ImageItemCompareExifUserComment", @"ImageItemCompareExifContrast", @"ImageItemCompareExifSaturation", @"ImageItemCompareExifSharpness", @"ImageItemCompareExifCameraOwnerName", @"ImageItemCompareExifSerialNumber", @"ImageItemCompareGIFLoopCount", @"ImageItemCompareGIFDelayTime", @"ImageItemCompareGPSLatitude", @"ImageItemCompareGPSLongitude", @"ImageItemCompareGPSAltitude", @"ImageItemCompareGPSDateStamp", @"ImageItemComparePNGInterlaceType", @"ImageItemCompareTIFFCompression", @"ImageItemCompareTIFFMake", @"ImageItemCompareTIFFModel", @"ImageItemCompareTIFFSoftware"];
		
		initialized = YES;
	}
}

+ (NSArray *)extensions
{
	return @[@"png", @"tiff", @"tif", @"jpeg", @"jpg", @"gif", @"jp2"];
}

+ (BOOL)canCompareWithOption:(NSString *)option
{
	NSString * baseOptionString = @"ImageItemCompare";
	return (option.length > baseOptionString.length && [[option substringToIndex:baseOptionString.length] isEqualToString:baseOptionString]);
	
	//return ([_availableOptions containsObject:option]);
}

+ (NSArray *)availableOptions
{
	return _availableOptions;
}

+ (NSArray *)propertiesForOptions:(NSArray *)options
{
	NSMutableArray * properties = [[NSMutableArray alloc] initWithCapacity:options.count];
	[properties addObjectsFromArray:[FileItem propertiesForOptions:options]];
	
	for (NSString * option in options) {
		
		if ([option isEqualToString:@"ImageItemCompareWidthInPixels"]) {
			[properties addObject:@"width"];
		} else if ([option isEqualToString:@"ImageItemCompareHeightInPixels"]) {
			[properties addObject:@"height"];
		} else if ([option isEqualToString:@"ImageItemCompareDepth"]) {
			[properties addObject:@"depth"];
		} else if ([option isEqualToString:@"ImageItemCompareOrientation"]) {
			[properties addObject:@"orientation"];
		} else if ([option isEqualToString:@"ImageItemCompareHasAlpha"]) {
			[properties addObject:@"hasAlpha"];
		} else if ([option isEqualToString:@"ImageItemCompareBitsPerPixel"]) {
			[properties addObject:@"bitsPerPixel"];
		} else if ([option isEqualToString:@"ImageItemCompareBytesPerRow"]) {
			[properties addObject:@"bytesPerRow"];
		} else if ([option isEqualToString:@"ImageItemCompareExifExposureTime"]) {
			[properties addObject:@"exifExposureTime"];
		} else if ([option isEqualToString:@"ImageItemCompareExifFNumber"]) {
			[properties addObject:@"exifFNumber"];
		} else if ([option isEqualToString:@"ImageItemCompareExifISOSpeedRatings"]) {
			[properties addObject:@"exifISOSpeedRatings"];
		} else if ([option isEqualToString:@"ImageItemCompareExifFlash"]) {
			[properties addObject:@"exifFlash"];
		} else if ([option isEqualToString:@"ImageItemCompareExifFocalLength"]) {
			[properties addObject:@"exifFocalLength"];
		} else if ([option isEqualToString:@"ImageItemCompareExifUserComment"]) {
			[properties addObject:@"exifUserComment"];
		} else if ([option isEqualToString:@"ImageItemCompareExifContrast"]) {
			[properties addObject:@"exifContrast"];
		} else if ([option isEqualToString:@"ImageItemCompareExifSaturation"]) {
			[properties addObject:@"exifSaturation"];
		} else if ([option isEqualToString:@"ImageItemCompareExifSharpness"]) {
			[properties addObject:@"exifSharpness"];
		} else if ([option isEqualToString:@"ImageItemCompareExifCameraOwnerName"]) {
			[properties addObject:@"exifCameraOwnerName"];
		} else if ([option isEqualToString:@"ImageItemCompareExifSerialNumber"]) {
			[properties addObject:@"exifSerialNumber"];
		} else if ([option isEqualToString:@"ImageItemCompareGIFLoopCount"]) {
			[properties addObject:@"gifLoopCount"];
		} else if ([option isEqualToString:@"ImageItemCompareGIFDelayTime"]) {
			[properties addObject:@"gifDelayTime"];
		} else if ([option isEqualToString:@"ImageItemCompareGPSLatitude"]) {
			[properties addObject:@"gpsLatitude"];
		} else if ([option isEqualToString:@"ImageItemCompareGPSLongitude"]) {
			[properties addObject:@"gpsLongitude"];
		} else if ([option isEqualToString:@"ImageItemCompareGPSAltitude"]) {
			[properties addObject:@"gpsAltitude"];
		} else if ([option isEqualToString:@"ImageItemCompareGPSDateStamp"]) {
			[properties addObject:@"gpsDateStamp"];
		} else if ([option isEqualToString:@"ImageItemComparePNGInterlaceType"]) {
			[properties addObject:@"pngInterlaceType"];
		} else if ([option isEqualToString:@"ImageItemCompareTIFFCompression"]) {
			[properties addObject:@"tiffCompression"];
		} else if ([option isEqualToString:@"ImageItemCompareTIFFMake"]) {
			[properties addObject:@"tiffMake"];
		} else if ([option isEqualToString:@"ImageItemCompareTIFFModel"]) {
			[properties addObject:@"tiffModel"];
		} else if ([option isEqualToString:@"ImageItemCompareTIFFSoftware"]) {
			[properties addObject:@"tiffSoftware"];
		}
	}
	return (NSArray *)properties;
}

+ (id)valueForOption:(NSString *)option fromItem:(ImageItem *)item
{
	if ([option isEqualToString:@"ImageItemCompareWidthInPixels"])
		return item.width;
	else if ([option isEqualToString:@"ImageItemCompareHeightInPixels"])
		return item.height;
	else if ([option isEqualToString:@"ImageItemCompareDepth"])
		return item.depth;
	else if ([option isEqualToString:@"ImageItemCompareOrientation"])
		return item.orientation;
	else if ([option isEqualToString:@"ImageItemCompareHasAlpha"])
		return item.hasAlpha;
	else if ([option isEqualToString:@"ImageItemCompareBitsPerPixel"])
		return item.bytesPerRow;
	else if ([option isEqualToString:@"ImageItemCompareBytesPerRow"])
		return item.bitsPerPixel;
	else if ([option isEqualToString:@"ImageItemCompareExifExposureTime"])
		return item.exifExposureTime;
	else if ([option isEqualToString:@"ImageItemCompareExifFNumber"])
		return item.exifFNumber;
	else if ([option isEqualToString:@"ImageItemCompareExifISOSpeedRatings"])
		return item.exifISOSpeedRatings;
	else if ([option isEqualToString:@"ImageItemCompareExifFlash"])
		return item.exifFlash;
	else if ([option isEqualToString:@"ImageItemCompareExifFocalLength"])
		return item.exifFocalLength;
	else if ([option isEqualToString:@"ImageItemCompareExifUserComment"])
		return item.exifUserComment;
	else if ([option isEqualToString:@"ImageItemCompareExifContrast"])
		return item.exifContrast;
	else if ([option isEqualToString:@"ImageItemCompareExifSaturation"])
		return item.exifSaturation;
	else if ([option isEqualToString:@"ImageItemCompareExifSharpness"])
		return item.exifSharpness;
	else if ([option isEqualToString:@"ImageItemCompareExifCameraOwnerName"])
		return item.exifCameraOwnerName;
	else if ([option isEqualToString:@"ImageItemCompareExifSerialNumber"])
		return item.exifSerialNumber;
	else if ([option isEqualToString:@"ImageItemCompareGIFLoopCount"])
		return item.gifLoopCount;
	else if ([option isEqualToString:@"ImageItemCompareGIFDelayTime"])
		return item.gifDelayTime;
	else if ([option isEqualToString:@"ImageItemCompareGPSLatitude"])
		return item.gpsLatitude;
	else if ([option isEqualToString:@"ImageItemCompareGPSLongitude"])
		return item.gpsLongitude;
	else if ([option isEqualToString:@"ImageItemCompareGPSAltitude"])
		return item.gpsAltitude;
	else if ([option isEqualToString:@"ImageItemCompareGPSDateStamp"])
		return item.gpsDateStamp;
	else if ([option isEqualToString:@"ImageItemComparePNGInterlaceType"])
		return item.pngInterlaceType;
	else if ([option isEqualToString:@"ImageItemCompareTIFFCompression"])
		return item.tiffCompression;
	else if ([option isEqualToString:@"ImageItemCompareTIFFMake"])
		return item.tiffMake;
	else if ([option isEqualToString:@"ImageItemCompareTIFFModel"])
		return item.tiffModel;
	else if ([option isEqualToString:@"ImageItemCompareTIFFSoftware"])
		return item.tiffSoftware;
	
	return nil;
}

- (NSManagedObject *)group
{
	return [self valueForKey:@"imageGroups"];
}

- (void)getAllInfo
{
	
}

- (void)getOptionItemInfo:(OptionItem *)option
{
	[self getOptionInfo:option.identifier];
}

- (void)getOptionInfo:(NSString *)option
{
	// @FIXME: Fix leaks...
	if ([option isEqualToString:@"ImageItemCompareWidthInPixels"]) {
		
		if (imagePropertiesDictionary) {
			CFNumberRef imageWidth = (CFNumberRef)CFDictionaryGetValue(imagePropertiesDictionary, kCGImagePropertyPixelWidth);
			self.width = (__bridge NSNumber *)imageWidth;
		}
	} else if ([option isEqualToString:@"ImageItemCompareHeightInPixels"]) {
		
		if (imagePropertiesDictionary) {
			CFNumberRef imageHeight = (CFNumberRef)CFDictionaryGetValue(imagePropertiesDictionary, kCGImagePropertyPixelHeight);
			self.height = (__bridge NSNumber *)imageHeight;
		}
		
	} else if ([option isEqualToString:@"ImageItemCompareDepth"]) {
		
		if (imagePropertiesDictionary) { self.depth = (NSNumber *)CFDictionaryGetValue(imagePropertiesDictionary, kCGImagePropertyDepth); }
		
	} else if ([option isEqualToString:@"ImageItemCompareOrientation"]) {
		
		if (imagePropertiesDictionary) { self.orientation = (NSNumber *)CFDictionaryGetValue(imagePropertiesDictionary, kCGImagePropertyOrientation); }
		
	} else if ([option isEqualToString:@"ImageItemCompareHasAlpha"]) {
		
		if (imagePropertiesDictionary) {
			NSNumber * hasAlpha = (NSNumber *)CFDictionaryGetValue(imagePropertiesDictionary, kCGImagePropertyHasAlpha);
			if (hasAlpha)
				self.hasAlpha = hasAlpha;
		}
		
	} else if ([option isEqualToString:@"ImageItemCompareBitsPerPixel"]) {
		
		if (!self.bytesPerRow) {
			NSData * data = [[NSData alloc] initWithContentsOfFile:self.path];
			NSBitmapImageRep * imageRep = [[NSBitmapImageRep alloc] initWithData:data];
			
			self.bytesPerRow = @([imageRep bytesPerRow]);
		}
		
	} else if ([option isEqualToString:@"ImageItemCompareBytesPerRow"]) {
		
		if (!self.bitsPerPixel) {
			NSData * data = [[NSData alloc] initWithContentsOfFile:self.path];
			NSBitmapImageRep * imageRep = [[NSBitmapImageRep alloc] initWithData:data];
			
			self.bitsPerPixel = @([imageRep bitsPerPixel]);
		}
		
	} else if ([option isEqualToString:@"ImageItemCompareExifExposureTime"]) {
		
		if (imagePropertiesDictionary) { self.exifExposureTime = (NSString *)CFDictionaryGetValue(imagePropertiesDictionary, kCGImagePropertyExifExposureTime); }
		
	} else if ([option isEqualToString:@"ImageItemCompareExifFNumber"]) {
		
		if (imagePropertiesDictionary) { self.exifFNumber = (NSString *)CFDictionaryGetValue(imagePropertiesDictionary, kCGImagePropertyExifFNumber); }
		
	} else if ([option isEqualToString:@"ImageItemCompareExifISOSpeedRatings"]) {
		
		if (imagePropertiesDictionary) { self.exifISOSpeedRatings = (NSString *)CFDictionaryGetValue(imagePropertiesDictionary, kCGImagePropertyExifISOSpeedRatings); }
		
	} else if ([option isEqualToString:@"ImageItemCompareExifFlash"]) {
		
		if (imagePropertiesDictionary) { self.exifFlash = (NSString *)CFDictionaryGetValue(imagePropertiesDictionary, kCGImagePropertyExifFlash); }
		
	} else if ([option isEqualToString:@"ImageItemCompareExifFocalLength"]) {
		
		if (imagePropertiesDictionary) { self.exifFocalLength = (NSString *)CFDictionaryGetValue(imagePropertiesDictionary, kCGImagePropertyExifFocalLength); }
		
	} else if ([option isEqualToString:@"ImageItemCompareExifUserComment"]) {
		
		if (imagePropertiesDictionary) { self.exifUserComment = (NSString *)CFDictionaryGetValue(imagePropertiesDictionary, kCGImagePropertyExifUserComment); }
		
	} else if ([option isEqualToString:@"ImageItemCompareExifContrast"]) {
		
		if (imagePropertiesDictionary) { self.exifContrast = (NSString *)CFDictionaryGetValue(imagePropertiesDictionary, kCGImagePropertyExifContrast); }
		
	} else if ([option isEqualToString:@"ImageItemCompareExifSaturation"]) {
		
		if (imagePropertiesDictionary) { self.exifSaturation = (NSString *)CFDictionaryGetValue(imagePropertiesDictionary, kCGImagePropertyExifSaturation); }
		
	} else if ([option isEqualToString:@"ImageItemCompareExifSharpness"]) {
		
		if (imagePropertiesDictionary) { self.exifSharpness = (NSString *)CFDictionaryGetValue(imagePropertiesDictionary, kCGImagePropertyExifSharpness); }
		
	} else if ([option isEqualToString:@"ImageItemCompareExifCameraOwnerName"]) {
		
		if (imagePropertiesDictionary) { self.exifCameraOwnerName = (NSString *)CFDictionaryGetValue(imagePropertiesDictionary, kCGImagePropertyExifAuxOwnerName); }
		
	} else if ([option isEqualToString:@"ImageItemCompareExifSerialNumber"]) {
		
		if (imagePropertiesDictionary) { self.exifSerialNumber = (NSString *)CFDictionaryGetValue(imagePropertiesDictionary, kCGImagePropertyExifAuxSerialNumber); }
		
	} else if ([option isEqualToString:@"ImageItemCompareGIFLoopCount"]) {
		
		if (imagePropertiesDictionary) { self.gifLoopCount = (NSString *)CFDictionaryGetValue(imagePropertiesDictionary, kCGImagePropertyGIFLoopCount); }
		
	} else if ([option isEqualToString:@"ImageItemCompareGIFDelayTime"]) {
		
		if (imagePropertiesDictionary) { self.gifDelayTime = (NSString *)CFDictionaryGetValue(imagePropertiesDictionary, kCGImagePropertyGIFDelayTime); }
		
	} else if ([option isEqualToString:@"ImageItemCompareGPSLatitude"]) {
		
		if (imagePropertiesDictionary) { self.gpsLatitude = (NSString *)CFDictionaryGetValue(imagePropertiesDictionary, kCGImagePropertyGPSLatitude); }
		
	} else if ([option isEqualToString:@"ImageItemCompareGPSLongitude"]) {
		
		if (imagePropertiesDictionary) { self.gpsLongitude = (NSString *)CFDictionaryGetValue(imagePropertiesDictionary, kCGImagePropertyGPSLongitude); }
		
	} else if ([option isEqualToString:@"ImageItemCompareGPSAltitude"]) {
		
		if (imagePropertiesDictionary) { self.gpsAltitude = (NSString *)CFDictionaryGetValue(imagePropertiesDictionary, kCGImagePropertyGPSAltitude); }
		
	} else if ([option isEqualToString:@"ImageItemCompareGPSDateStamp"]) {
		
		if (imagePropertiesDictionary) { self.gpsDateStamp = (NSString *)CFDictionaryGetValue(imagePropertiesDictionary, kCGImagePropertyGPSDateStamp); }
		
	} else if ([option isEqualToString:@"ImageItemComparePNGInterlaceType"]) {
		
		if (imagePropertiesDictionary) { self.pngInterlaceType = (NSNumber *)CFDictionaryGetValue(imagePropertiesDictionary, kCGImagePropertyPNGInterlaceType); }
		
	} else if ([option isEqualToString:@"ImageItemCompareTIFFCompression"]) {
		
		if (imagePropertiesDictionary) { self.tiffCompression = (NSString *)CFDictionaryGetValue(imagePropertiesDictionary, kCGImagePropertyTIFFCompression); }
		
	} else if ([option isEqualToString:@"ImageItemCompareTIFFMake"]) {
		
		if (imagePropertiesDictionary) { self.tiffMake = (NSString *)CFDictionaryGetValue(imagePropertiesDictionary, kCGImagePropertyTIFFMake); }
		
	} else if ([option isEqualToString:@"ImageItemCompareTIFFModel"]) {
		
		if (imagePropertiesDictionary) { self.tiffModel = (NSString *)CFDictionaryGetValue(imagePropertiesDictionary, kCGImagePropertyTIFFModel); }
		
	} else if ([option isEqualToString:@"ImageItemCompareTIFFSoftware"]) {
		
		if (imagePropertiesDictionary) { self.tiffSoftware = (NSString *)CFDictionaryGetValue(imagePropertiesDictionary, kCGImagePropertyTIFFSoftware); }
		
	} else {
		[super getOptionInfo:option];
	}
}

- (void)getInfoFromOptionsItems:(NSArray *)options
{
	NSURL * fileURL = [NSURL fileURLWithPath:self.path];
	CGImageSourceRef imageSource = CGImageSourceCreateWithURL((__bridge CFURLRef)fileURL, NULL);
	if (imageSource) {
		if (CGImageSourceGetCount(imageSource) > 0)
			imagePropertiesDictionary = CFRetain(CGImageSourceCopyPropertiesAtIndex(imageSource, 0, NULL));
		CFRelease(imageSource);
	}
	
	for (OptionItem * option in options) {
		[self getOptionItemInfo:option];
	}
	
	if (imagePropertiesDictionary) {
		CFRelease(imagePropertiesDictionary);
		imagePropertiesDictionary = NULL;
	}
}

- (void)getInfoFromOptions:(NSArray *)options
{
	/* Check if "options" has image specific options (before fetching informations from the file) */
	BOOL hasImageOptions = NO;
	for (NSString * option in options) {
		if ([ImageItem canCompareWithOption:option]) {
			hasImageOptions = YES;
			break;
		}
	}
	
	if (hasImageOptions) {
		NSURL * fileURL = [NSURL fileURLWithPath:self.path];
		CGImageSourceRef imageSource = CGImageSourceCreateWithURL((__bridge CFURLRef)fileURL, NULL);
		
		if (CGImageSourceGetCount(imageSource) > 0) {
			
			imagePropertiesDictionary = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, NULL);
			
			for (NSString * option in options) {
				[self getOptionInfo:option];
			}
			
			if (imagePropertiesDictionary) {
				CFRelease(imagePropertiesDictionary);
				imagePropertiesDictionary = NULL;
			}
		} else {
			NSMutableArray * fileOptions = [options mutableCopy];
			[fileOptions removeObjectsInArray:[ImageItem availableOptions]];
			[super getInfoFromOptions:fileOptions];
		}
		
		if (imageSource) CFRelease(imageSource);
	} else {
		/* Just get informations without fetching image properties */
		for (NSString * option in options) {
			[super getOptionInfo:option];
		}
	}
}

- (BOOL)isEqualTo:(ImageItem *)anotherItem option:(NSString *)option
{
	NSArray * options = @[option];
	NSArray * properties = [ImageItem propertiesForOptions:options];
	
	if (properties.count > 0) {
		NSString * key = properties.firstObject;
		return [[self valueForKey:key] isEqualTo:[anotherItem valueForKey:key]];
	}
	
	return NO;
}

- (BOOL)isEqualTo:(ImageItem *)anotherItem options:(NSArray *)options
{
	//if ([anotherItem isKindOfClass:[self class]] || [anotherItem isKindOfClass:[NSClassFromString(@"ImageItemGroup") class]]) {// If we compare only two image files, compare with current options
	
	for (NSString * option in options) { // For each option,
		if ([[self class] canCompareWithOption:option]) { // If option is a ImageItem specific option,// @TODO: cache available options
			if (![self isEqualTo:anotherItem option:option]) { // Compare image items with option
				return NO;
			}
		} else {
			if (![super isEqualTo:anotherItem options:@[option]]) {// Else, compare with FileItem class
				return NO;
			}
		}
	}
	
	/*
	 } else {// Else, compare items as file (mother class)
	 return [super isEqualTo:anotherItem options:options];
	 }
	 */
	
	return YES;
}

- (NSDictionary *)itemValues
{
	NSMutableDictionary * attributes = [NSMutableDictionary dictionaryWithCapacity:30];
	
	NSArray * availableOptions = [FileItem availableOptions];
	for (NSString * option in availableOptions) {
		[[super class] getOptionInfo:option forItem:self];
		id value = [[super class] valueForOption:option fromItem:self];
		if (value) {
			attributes[option] = value;
		}
	}
	
	NSURL * fileURL = [NSURL fileURLWithPath:self.path];
	CGImageSourceRef imageSource = CGImageSourceCreateWithURL((__bridge CFURLRef)fileURL, NULL);
	if (imageSource) {
		if (CGImageSourceGetCount(imageSource) > 0)
			imagePropertiesDictionary = CFRetain(CGImageSourceCopyPropertiesAtIndex(imageSource, 0, NULL));
		CFRelease(imageSource);
	}
	
	if (imagePropertiesDictionary != NULL) {
		availableOptions = [[self class] availableOptions];
		for (NSString * option in availableOptions) {
			[self getOptionInfo:option];
			id value = [self valueForOption:option];
			if (value) {
				attributes[option] = value;
			}
		}
		if (imagePropertiesDictionary) {
			CFRelease(imagePropertiesDictionary);
			imagePropertiesDictionary = NULL;
		}
	}
	
	return attributes;
}

- (NSDictionary *)commonsValuesWithItem:(ImageItem *)anotherItem
{
	NSMutableDictionary * commonValues = [NSMutableDictionary dictionaryWithCapacity:10];
	
	NSDictionary * itemValues = [self itemValues];
	NSDictionary * anotherItemValues = [anotherItem itemValues];
	for (NSString * key in [itemValues allKeys]) {
		id object = itemValues[key];
		id anotherObject = anotherItemValues[key];
		if ([object isEqualTo:anotherObject]) {
			commonValues[key] = object;
		}
	}
	
	return commonValues;
}

- (NSDictionary *)localizedItemValues
{
	NSMutableDictionary * attributes = [NSMutableDictionary dictionaryWithCapacity:3];
	
	NSURL * fileURL = [NSURL fileURLWithPath:self.path];
	CGImageSourceRef imageSource = CGImageSourceCreateWithURL((__bridge CFURLRef)fileURL, NULL);
	if (imageSource) {
		if (CGImageSourceGetCount(imageSource) > 0)
			imagePropertiesDictionary = CFRetain(CGImageSourceCopyPropertiesAtIndex(imageSource, 0, NULL));
		CFRelease(imageSource);
	}
	
	NSArray * availableOptions = [ImageItem availableOptions];
	for (NSString * option in availableOptions) {
		[self getOptionInfo:option];
		
		id value = [self valueForOption:option];
		if (value)
			attributes[option] = value;
	}
	
	if (imagePropertiesDictionary) {
		CFRelease(imagePropertiesDictionary);
		imagePropertiesDictionary = NULL;
	}
	
	/*
	 NSArray * availableOptions = [ImageItem availableOptions];
	 for (NSString * option in availableOptions) {
	 [ImageItem getOptionInfo:option forItem:self];
	 
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
	 [formatter release];
	 } else if ([option isEqualToString:@"FileItemCompareLastModificationDate"]) {
	 NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
	 formatter.dateStyle = NSDateFormatterLongStyle;
	 formatter.timeStyle = NSDateFormatterShortStyle;
	 localizedValue = [formatter stringFromDate:value];
	 [formatter release];
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
	 */
	
	NSDebugLog(@"%@", [super localizedItemValues]);
	[attributes addEntriesFromDictionary:[super localizedItemValues]];
	
	return attributes;
}

- (id)valueForOption:(NSString *)option
{
	if ([option isEqualToString:@"ImageItemCompareWidthInPixels"])
		return self.width;
	else if ([option isEqualToString:@"ImageItemCompareHeightInPixels"])
		return self.height;
	else if ([option isEqualToString:@"ImageItemCompareDepth"])
		return self.depth;
	else if ([option isEqualToString:@"ImageItemCompareOrientation"])
		return self.orientation;
	else if ([option isEqualToString:@"ImageItemCompareHasAlpha"])
		return self.hasAlpha;
	else if ([option isEqualToString:@"ImageItemCompareBitsPerPixel"])
		return self.bytesPerRow;
	else if ([option isEqualToString:@"ImageItemCompareBytesPerRow"])
		return self.bitsPerPixel;
	else if ([option isEqualToString:@"ImageItemCompareExifExposureTime"])
		return self.exifExposureTime;
	else if ([option isEqualToString:@"ImageItemCompareExifFNumber"])
		return self.exifFNumber;
	else if ([option isEqualToString:@"ImageItemCompareExifISOSpeedRatings"])
		return self.exifISOSpeedRatings;
	else if ([option isEqualToString:@"ImageItemCompareExifFlash"])
		return self.exifFlash;
	else if ([option isEqualToString:@"ImageItemCompareExifFocalLength"])
		return self.exifFocalLength;
	else if ([option isEqualToString:@"ImageItemCompareExifUserComment"])
		return self.exifUserComment;
	else if ([option isEqualToString:@"ImageItemCompareExifContrast"])
		return self.exifContrast;
	else if ([option isEqualToString:@"ImageItemCompareExifSaturation"])
		return self.exifSaturation;
	else if ([option isEqualToString:@"ImageItemCompareExifSharpness"])
		return self.exifSharpness;
	else if ([option isEqualToString:@"ImageItemCompareExifCameraOwnerName"])
		return self.exifCameraOwnerName;
	else if ([option isEqualToString:@"ImageItemCompareExifSerialNumber"])
		return self.exifSerialNumber;
	else if ([option isEqualToString:@"ImageItemCompareGIFLoopCount"])
		return self.gifLoopCount;
	else if ([option isEqualToString:@"ImageItemCompareGIFDelayTime"])
		return self.gifDelayTime;
	else if ([option isEqualToString:@"ImageItemCompareGPSLatitude"])
		return self.gpsLatitude;
	else if ([option isEqualToString:@"ImageItemCompareGPSLongitude"])
		return self.gpsLongitude;
	else if ([option isEqualToString:@"ImageItemCompareGPSAltitude"])
		return self.gpsAltitude;
	else if ([option isEqualToString:@"ImageItemCompareGPSDateStamp"])
		return self.gpsDateStamp;
	else if ([option isEqualToString:@"ImageItemComparePNGInterlaceType"])
		return self.pngInterlaceType;
	else if ([option isEqualToString:@"ImageItemCompareTIFFCompression"])
		return self.tiffCompression;
	else if ([option isEqualToString:@"ImageItemCompareTIFFMake"])
		return self.tiffMake;
	else if ([option isEqualToString:@"ImageItemCompareTIFFModel"])
		return self.tiffModel;
	else if ([option isEqualToString:@"ImageItemCompareTIFFSoftware"])
		return self.tiffSoftware;
	else {
		[super valueForOption:option];
	}
	
	return nil;
}

@end

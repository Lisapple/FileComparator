//
//  ImageItem.h
//  Comparator
//
//  Created by Max on 25/01/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "FileItem.h"

@interface ImageItem : FileItem
{
	@private
	CFDictionaryRef imagePropertiesDictionary;
}

@property (nonatomic, strong) NSNumber * width, * height, * depth, * orientation, * hasAlpha, * bitsPerPixel, * bytesPerRow;
@property (nonatomic, strong) NSString * exifExposureTime, * exifFNumber, * exifISOSpeedRatings, * exifFlash, * exifFocalLength, * exifUserComment, * exifContrast, * exifSaturation, * exifSharpness, * exifCameraOwnerName, * exifSerialNumber;
@property (nonatomic, strong) NSString * gifLoopCount, * gifDelayTime;
@property (nonatomic, strong) NSString * gpsLatitude, * gpsLongitude, * gpsAltitude, * gpsDateStamp;
@property (nonatomic, strong) NSNumber * pngInterlaceType;
@property (nonatomic, strong) NSString * tiffCompression, * tiffMake, * tiffModel, * tiffSoftware;


@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSDictionary *localizedItemValues;
- (id)valueForOption:(NSString *)option;


+ (NSArray *)extensions;
+ (BOOL)canCompareWithOption:(NSString *)option;

+ (id)valueForOption:(NSString *)option fromItem:(ImageItem *)item;

+ (NSArray *)propertiesForOptions:(NSArray *)options;

- (void)getInfoFromOptionsItems:(NSArray *)options;
- (void)getInfoFromOptions:(NSArray *)options;

- (BOOL)isEqualTo:(ImageItem *)anotherItem options:(NSArray *)options;

@end

/*
 bitsPerPixel	CGImageGetBitsPerPixel
 bytesPerRow	CGImageGetBytesPerRow
 
 
 depth			kCGImagePropertyDepth depth
 orientation	kCGImagePropertyOrientation orientation
 hasAlpha		kCGImagePropertyHasAlpha 
 
 ExifExposureTime		kCGImagePropertyExifExposureTime
 ExifFNumber			kCGImagePropertyExifFNumber
 ExifISOSpeedRatings	kCGImagePropertyExifISOSpeedRatings
 ExifFlash				kCGImagePropertyExifFlash
 ExifFocalLength		kCGImagePropertyExifFocalLength
 ExifUserComment		kCGImagePropertyExifUserComment
 ExifContrast			kCGImagePropertyExifContrast
 ExifSaturation			kCGImagePropertyExifSaturation
 ExifSharpness			kCGImagePropertyExifSharpness
 ExifCameraOwnerName	kCGImagePropertyExifCameraOwnerName
 ExifSerialNumber		kCGImagePropertyExifAuxSerialNumber
 
 GIFLoopCount			kCGImagePropertyGIFLoopCount
 GIFDelayTime			kCGImagePropertyGIFDelayTime
 
 GPSLatitude			kCGImagePropertyGPSLatitude
 GPSLongitude			kCGImagePropertyGPSLongitude
 GPSAltitude			kCGImagePropertyGPSAltitude
 GPSDateStamp			kCGImagePropertyGPSDateStamp
 
 PNGInterlaceType		kCGImagePropertyPNGInterlaceType
 PNGAuthor				kCGImagePropertyPNGAuthor
 PNGSoftware			kCGImagePropertyPNGSoftware
 PNGTitle				kCGImagePropertyPNGTitle
 
 TIFFCompression		kCGImagePropertyTIFFCompression
 TIFFMake				kCGImagePropertyTIFFMake
 TIFFModel				kCGImagePropertyTIFFModel
 TIFFSoftware			kCGImagePropertyTIFFSoftware

*/
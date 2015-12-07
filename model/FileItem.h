//
//  FileItem.h
//  Comparator
//
//  Created by Max on 09/04/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuickLook/QuickLook.h>

#import "OptionItem.h"

@class ImageItem;
@class AudioItem;

/*
typedef enum {
	FileItemCompareSize = 1 << 0,
	FileItemCompareFilename = 1 << 1,
	FileItemCompareExtension = 1 << 2,
	FileItemCompareUTI = 1 << 3,
	FileItemCompareCreationDate = 1 << 4,
	FileItemCompareLastModificationDate = 1 << 5,
	FileItemCompareData = 1 << 6,
	
	FileItemComparePath = 1 << 7,// For ordering only
} FileItemCompareType;


typedef enum {
	FileItemInfoOriginalReplacedWithAlias = 1 << 0,
} FileItemInfo;
*/

@interface FileItem : NSManagedObject
{
	/*
	BOOL isFile;
	NSNumber * selected;
	NSString * path;
	unsigned long long fileSize;
	NSString * fileType;
	NSString * type;
	NSDate * creationDate, * lastModificationDate;
	BOOL isLocked;
	NSNumber * labelColorNumber;
	BOOL isBroken;
	 
	NSNumber * info;
	 
	BOOL isValid;
	 */
}

@property (nonatomic, strong) NSString * filename, * extension;

@property (nonatomic, strong) NSNumber * isFile;
@property (nonatomic, strong) NSNumber * selected;
@property (nonatomic, strong) NSString * path;
@property (nonatomic, strong) NSNumber * fileSize;
@property (nonatomic, strong) NSString * fileType;
@property (nonatomic, strong) NSString * type;
@property (nonatomic, strong) NSDate * creationDate, * lastModificationDate;
@property (nonatomic, strong) NSNumber * lockState;// -1 => invalid, 0 => no lock file, 1 => file locked
@property (nonatomic, strong) NSNumber * labelColorNumber;// -1 => invalid (default value), 0 => clear color, 1-7 => correct color
@property (nonatomic, strong) NSNumber * isBroken;

@property (nonatomic, strong) NSNumber * info;

@property (nonatomic, strong) NSNumber * isValid;

- (id)valueForOption:(NSString *)option;

+ (NSDictionary *)commonsValuesForItems:(NSArray *)items;

+ (NSArray *)propertiesForOptions:(NSArray *)options;

+ (NSArray *)availableOptions;

+ (id)valueForOption:(NSString *)option fromItem:(FileItem *)item;

+ (void)getOptionInfo:(NSString *)option forItem:(FileItem *)item;


- (instancetype)initWithPath:(NSString *)aPath;

- (void)getOptionItemInfo:(OptionItem *)option;

- (void)getOptionInfo:(NSString *)option;

- (id)valueForOption:(NSString *)option;

- (void)getInfoFromOptionItems:(NSArray *)options;
- (void)getInfoFromOptions:(NSArray *)options;

- (void)setLocked:(BOOL)locked;

@property (NS_NONATOMIC_IOSONLY, getter=isHidden, readonly) BOOL hidden;

- (NSString *)filename;

- (NSString *)extension;

- (BOOL)isEqualTo:(FileItem *)anotherItem options:(NSArray *)options;

- (NSComparisonResult)compareByLastModificationDate:(FileItem *)anotherItem;
- (NSComparisonResult)compareByCreationDate:(FileItem *)anotherItem;

@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSDictionary *itemValues;

- (NSDictionary *)commonsValuesWithItem:(FileItem *)anotherItem;

@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSColor *labelColor;

@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSDictionary *localizedItemValues;

- (NSImage *)thumbnailForSize:(CGSize)size;

@end

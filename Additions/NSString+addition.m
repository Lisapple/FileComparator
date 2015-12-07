//
//  NSString+addition.m
//  Comparator
//
//  Created by Max on 09/05/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

#import "NSString+addition.h"

@implementation NSString (addition)

#pragma mark - CFString helper

+ (NSString *)stringWithCFString:(CFStringRef)stringRef
{
	const char * cString = CFStringGetCStringPtr(stringRef, kCFStringEncodingUTF8);
	return [[NSString alloc] initWithCString:cString encoding:NSUTF8StringEncoding];
}

#pragma mark - Localisation helper

+ (NSString *)localizedStringForFileSize:(double)fileSize
{
#define kKiloByte	1000.
#define kMegaByte	(1000. * kKiloByte)
#define kGigaByte	(1000. * kMegaByte)
#define kTeraByte	(1000. * kGigaByte)
	
	NSString * format = nil;
	if (fileSize >= kTeraByte)
		format = [NSString stringWithFormat:@"%.2f %@", fileSize / kTeraByte, NSLocalizedString(@"TERABYTES", nil)];
	else if (fileSize >= kGigaByte)
		format = [NSString stringWithFormat:@"%.2f %@", fileSize / kGigaByte, NSLocalizedString(@"GIGABYTES", nil)];
	else if (fileSize >= kMegaByte)
		format = [NSString stringWithFormat:@"%.2f %@", fileSize / kMegaByte, NSLocalizedString(@"MEGABYTES", nil)];
	else if (fileSize >= kKiloByte)
		format = [NSString stringWithFormat:@"%.0f %@", fileSize / kKiloByte, NSLocalizedString(@"KILOBYTES", nil)];
	else if (fileSize > 0)
		format = [NSString stringWithFormat:@"%.0f %@", fileSize, NSLocalizedString(@"BYTES", nil)];
	else
		format = NSLocalizedString(@"ZERO_BYTES", nil);
	
	return format;
}

#pragma mark - Layout helper

- (NSArray *)linesConstraitWithSize:(NSSize)constraitSize
{
	return [self linesConstraitWithSize:constraitSize separatedByString:@" "];
}

- (NSArray *)linesConstraitWithSize:(NSSize)constraitSize separatedByString:(NSString *)separation
{
	NSMutableArray * lines = [NSMutableArray arrayWithCapacity:3];
	
	int index = 0;
	NSMutableString * line = [[NSMutableString alloc] initWithCapacity:100];
	NSArray * components = [self componentsSeparatedByString:separation];
	for (NSString * string in components) {
		if (![string isEqualToString:@""]) {
			NSString * _line = nil;
			if (index == 0) _line = string;
			else _line = [NSString stringWithFormat:@"%@%@%@", line, separation, string];// Add "*separator* *string*" to the current line
			
			NSDictionary * attributes = @{ NSFontAttributeName : [NSFont systemFontOfSize:13.] };
			NSSize size = [_line sizeWithAttributes:attributes];
			
			if (size.width <= constraitSize.width) {// If size fit to constraitSize, add string to current line
				
				if (index == 0) [line appendString:string];
				else [line appendFormat:@"%@%@", separation, string];
				
			} else {// Else begin a new line
				[lines addObject:[line stringByAppendingString:separation]];
				line = [[NSMutableString alloc] initWithString:string];
			}
			index++;
		}
	}
	[lines addObject:line];
	
	return lines;
}

#pragma mark - Path helper

+ (NSString *)pathForDirectory:(NSSearchPathDirectory)directory
{
	NSArray * URLs = [[NSFileManager defaultManager] URLsForDirectory:directory inDomains:NSUserDomainMask];
	if (URLs.count > 0) {
		return [[(NSURL *)URLs.firstObject path] stringByAppendingString:@"/"];
	}
	
	return nil;
}

- (BOOL)isOnMainVolume
{
	NSString * string = @"/Volume";
	return [[self substringWithRange:NSMakeRange(0, string.length)] isEqualToString:string];
}

#pragma mark - Case helper

- (NSString *)firstLetterCapitalized
{
	if (self.length > 0) {
		return [[self substringToIndex:1].uppercaseString stringByAppendingString:[self substringFromIndex:1].lowercaseString];
	}
	return @"";
}

@end

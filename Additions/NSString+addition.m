//
//  NSString+addition.m
//  Comparator
//
//  Created by Max on 09/05/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

#import "NSString+addition.h"


@implementation NSString (addition)

+ (NSString *)stringWithCFString:(CFStringRef)stringRef
{
	const char * cString = CFStringGetCStringPtr(stringRef, kCFStringEncodingUTF8);
	return [[NSString alloc] initWithCString:cString encoding:NSUTF8StringEncoding];
}

+ (NSString *)pathForDirectory:(NSSearchPathDirectory)directory
{
	NSArray * URLs = [[NSFileManager defaultManager] URLsForDirectory:directory inDomains:NSUserDomainMask];
	if (URLs.count > 0) {
		return [[(NSURL *)[URLs objectAtIndex:0] path] stringByAppendingString:@"/"];
	}
	
	return nil;
}

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
			
			NSDictionary * attributes = [[NSDictionary alloc] initWithObjectsAndKeys:[NSFont fontWithName:@"Helvetica" size:13.], NSFontAttributeName, nil];
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

- (BOOL)isOnMainVolume
{
	NSString * string = @"/Volume";
	return [[self substringWithRange:NSMakeRange(0, string.length)] isEqualToString:string];
}

@end

//
//  NSDate+addition.m
//  Comparator
//
//  Created by Max on 04/12/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

#import "NSDate+addition.h"

@implementation NSDate (addition)

- (NSString *)string
{
	return [NSDateFormatter localizedStringFromDate:self
										  dateStyle:NSDateFormatterMediumStyle
										  timeStyle:NSDateFormatterShortStyle];
	
	//@:TODO: maybe fix performance(?)
	NSString * dateString = [NSDateFormatter localizedStringFromDate:self
														   dateStyle:NSDateFormatterMediumStyle
														   timeStyle:NSDateFormatterNoStyle];
	NSString * timeString = [NSDateFormatter localizedStringFromDate:self
														   dateStyle:NSDateFormatterNoStyle
														   timeStyle:NSDateFormatterShortStyle];
	return [NSString stringWithFormat:@"%@, %@", dateString, timeString];
}

@end

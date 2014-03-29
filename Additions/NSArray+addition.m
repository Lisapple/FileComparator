//
//  NSArray+addition.m
//  Comparator
//
//  Created by Max on 11/05/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

#import "NSArray+addition.h"


@implementation NSArray (addition)

- (NSComparisonResult)compareFirstObjects:(NSArray *)anotherArray
{
	if (self.count > 0 && anotherArray.count > 0) {
		id object1 = [self objectAtIndex:0];
		id object2 = [anotherArray objectAtIndex:0];
		
		if ([object1 isKindOfClass:[object2 class]])
			return [[self objectAtIndex:0] compare:[anotherArray objectAtIndex:0]];
	}
	
	return -2;
}

- (NSArray *)arrayByAddingNewObjectsFromArray:(NSArray *)otherArray
{
	NSMutableArray * objects = [NSMutableArray arrayWithArray:self];
	for (NSObject * object in otherArray) {
		if (![objects containsObject:object]) {
			[objects addObject:object];
		}
	}
	
	return (NSArray *)objects;
}

@end

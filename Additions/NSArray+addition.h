//
//  NSArray+addition.h
//  Comparator
//
//  Created by Max on 11/05/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSArray (addition)

- (NSComparisonResult)compareFirstObjects:(NSArray *)anotherArray;

- (NSArray *)arrayByAddingNewObjectsFromArray:(NSArray *)otherArray;

@end

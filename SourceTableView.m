//
//  SourceTableView.m
//  Comparator
//
//  Created by Max on 05/05/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

#import "SourceTableView.h"


@implementation SourceTableView

@synthesize sourceDelegate;

- (NSDragOperation)draggingUpdated:(id < NSDraggingInfo >)sender
{
	return [sender draggingSourceOperationMask];
}

- (BOOL)prepareForDragOperation:(id < NSDraggingInfo >)sender
{
	return YES;
}

- (BOOL)performDragOperation:(id < NSDraggingInfo >)sender
{
	BOOL performDragOperation = [super performDragOperation:sender];
	
	NSArray * array = [[sender draggingPasteboard] propertyListForType:NSFilenamesPboardType];
	if (array) {
		if ([sourceDelegate respondsToSelector:@selector(tableView:didReceiveDraggingObjects:)]) {
			return [sourceDelegate tableView:self didReceiveDraggingObjects:array];
		}
	}
	
	return performDragOperation;
}

- (void)draggingExited:(id <NSDraggingInfo>)sender
{
	[super draggingExited:sender];
}

@end

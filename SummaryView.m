//
//  SummaryView.m
//  Comparator
//
//  Created by Max on 20/12/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "SummaryView.h"

@implementation SummaryView

@synthesize numberOfDuplicatesLabel, totalSizeLabel;

- (void)drawRect:(NSRect)dirtyRect
{
	[[NSColor windowBackgroundColor] set];
	NSRectFill(dirtyRect);
}

@end

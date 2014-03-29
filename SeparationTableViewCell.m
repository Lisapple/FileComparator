//
//  SeparationTableViewCell.m
//  Comparator
//
//  Created by Max on 11/04/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "SeparationTableViewCell.h"

@implementation SeparationTableViewCell

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	[[NSColor colorWithDeviceWhite:0.706 alpha:1.] set];
	
	NSRect rect = cellFrame;
	rect.origin.x = 20.;
	rect.origin.y += rect.size.height / 2.;
	rect.size.width -= 40.;
	rect.size.height = 1.;
	NSRectFill(rect);
}

@end

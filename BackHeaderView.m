//
//  BackHeaderView.m
//  Comparator
//
//  Created by Max on 08/04/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "BackHeaderView.h"

@implementation BackHeaderButton

/*
- (void)drawRect:(NSRect)dirtyRect
{
	CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
	
	CGContextBeginPath(context);
	
	CGRect rect = dirtyRect;
	rect.size.height = 24.;
	rect.origin.y += (dirtyRect.size.height - rect.size.height) / 2.;
	
	CGContextMoveToPoint(context, 0., rect.size.height / 2.);
	CGContextAddLineToPoint(context, 16., rect.size.height);
	CGContextAddLineToPoint(context, rect.size.width, rect.size.height);
	CGContextAddLineToPoint(context, rect.size.width, 0.);
	CGContextAddLineToPoint(context, 16., 0.);
	
	[[NSColor darkGrayColor] setFill];
	CGContextFillPath(context);
	
	
	CGContextSelectFont(context, "Helvetica", 18., kCGEncodingMacRoman);
	const char * string = "Back";
	CGContextShowTextAtPoint(context, 20., rect.size.height, string, strlen(string));
}
*/

@end

@implementation BackHeaderView

@synthesize title = _title;

- (void)setTitle:(NSString *)title
{
	_title = title;
	
	titleLabel.stringValue = _title;
}

@end

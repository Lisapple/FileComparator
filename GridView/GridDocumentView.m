//
//  GridDocumentView.m
//  GridView
//
//  Created by Max on 18/03/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "GridDocumentView.h"

@implementation GridDocumentView

- (BOOL)isFlipped
{
	return YES;
}

- (BOOL)acceptsFirstResponder
{
	return YES;
}

- (BOOL)becomeFirstResponder
{
	return YES;
}

- (BOOL)canBecomeKeyView
{
	return YES;
}

- (void)keyDown:(NSEvent *)theEvent
{
	[super keyDown:theEvent];
	//[self.enclosingScrollView keyDown:theEvent];
}

- (void)drawSelectionRect:(NSRect)rect
{
	selectionRect = rect;
	[self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect
{
	[super drawRect:dirtyRect];
	
	CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
	
	[[NSColor darkGrayColor] setStroke];
	CGContextSetLineWidth(context, 1.);
	CGContextStrokeRect(context, NSRectToCGRect(selectionRect));
	
	[[NSColor colorWithCalibratedWhite:1. alpha:0.2] setFill];
	CGContextFillRect(context, NSRectToCGRect(selectionRect));
}

- (void)rightMouseDown:(NSEvent *)theEvent
{
	[self.enclosingScrollView rightMouseDown:theEvent];
}

@end

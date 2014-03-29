//
//  MyWindow.m
//  Comparator
//
//  Created by Max on 17/04/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

#import "MyWindow.h"

@implementation MyContentView

- (void)drawRect:(NSRect)dirtyRect
{
	CGFloat height = 60.;
	NSRect frame = NSMakeRect(0., 0., self.frame.size.width, height);
	
	[[NSColor colorWithCalibratedWhite:0.888 alpha:1.] setFill];
	NSRectFill(frame);
	
	NSRect rect = frame;
	rect.size.height = 1.;
	rect.origin.y = height - 2.;
	[[NSColor whiteColor] setFill];
	NSRectFill(rect);
	
	rect.origin.y = height - 1.;
	[[NSColor lightGrayColor] setFill];
	NSRectFill(rect);
}

@end


@implementation MyWindow
@end

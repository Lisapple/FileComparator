//
//  BlackView.m
//  Comparator
//
//  Created by Max on 22/05/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

#import "TransitionView.h"

@implementation TransitionView

- (void)drawRect:(NSRect)dirtyRect
{
	[[NSColor windowBackgroundColor] set];
	NSRect frame = NSMakeRect(0., 60., self.frame.size.width, self.frame.size.height - 60.);
	NSRectFill(frame);
}

/* Event methods are empty to not send events to super view */
- (void)mouseDown:(NSEvent *)theEvent {}
- (void)mouseUp:(NSEvent *)theEvent {}
- (void)mouseDragged:(NSEvent *)theEvent {}
- (void)mouseEntered:(NSEvent *)theEvent {}
- (void)mouseExited:(NSEvent *)theEvent {}
- (void)mouseMoved:(NSEvent *)theEvent {}

@end

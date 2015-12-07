//
//  CenteredView.m
//  Comparator
//
//  Created by Max on 14/12/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "CenteredView.h"

@implementation CenteredView

@synthesize horizontallyCentered = _horizontallyCentered, verticallyCentered = _verticallyCentered;
@synthesize offsetEdge = _offsetEdge;

RectEdge const RectEdgeZero = { 0., 0., 0., 0. };

RectEdge RectEdgeMake(float top, float left, float bottom, float right)
{
	RectEdge edge;
	edge.top = top; edge.left = left;
	edge.bottom = bottom; edge.right = right;
	return edge;
}

- (instancetype)initWithFrame:(NSRect)frameRect
{
	if ((self = [super initWithFrame:frameRect])) {
		_horizontallyCentered = YES;
		_verticallyCentered = NO;
		_offsetEdge = RectEdgeZero;
	}
	return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
	if ((self = [super initWithCoder:aDecoder])) {
		_horizontallyCentered = YES;
		_verticallyCentered = NO;
		_offsetEdge = RectEdgeZero;
	}
	return self;
}

- (void)setHorizontallyCentered:(BOOL)horizontallyCentered
{
	_horizontallyCentered = horizontallyCentered;
	self.frame = self.frame; // Refresh the layout of the view
}

- (void)setVerticallyCentered:(BOOL)verticallyCentered
{
	_verticallyCentered = verticallyCentered;
	self.frame = self.frame; // Refresh the layout of the view
}

- (void)setOffsetEdge:(RectEdge)offsetEdge
{
	_offsetEdge = offsetEdge;
	self.frame = self.frame; // Refresh the layout of the view
}

- (void)viewWillDraw
{
	[super viewWillDraw];
	
	self.frame = self.frame; // Refresh the layout of the view
}

- (void)setFrame:(NSRect)frame
{
	/* Center the view along the x-axis and y-axis (only if the window has been attach to the view */
	if (self.window) {
		if (_horizontallyCentered) { frame.origin.x = (int)(_offsetEdge.left + (self.window.frame.size.width - (_offsetEdge.right + _offsetEdge.left) - frame.size.width) / 2. - _offsetEdge.right); }
		if (_verticallyCentered) { frame.origin.y = (int)(_offsetEdge.bottom + (self.window.frame.size.height - (_offsetEdge.top + _offsetEdge.bottom) - frame.size.height) / 2. - _offsetEdge.top); }
	}
	
	[super setFrame:frame];
}

@end

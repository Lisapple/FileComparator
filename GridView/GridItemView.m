//
//  GridItemView.m
//  GridView
//
//  Created by Max on 18/03/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "GridItemView.h"

@implementation GridItemImageView

@synthesize selected = _selected, isOriginal = _isOriginal, isGroup = _isGroup;

- (void)setSelected:(BOOL)flag
{
	_selected = flag;
	
	[self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect
{
	@autoreleasepool {
	
		CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
		
		/* Draw image */
		float ratio = self.image.size.width / self.image.size.height;
		int width = self.frame.size.height * ratio;
		
		int height = self.frame.size.height;
		
		int leftMargin = (self.frame.size.width - width) / 2.;
		float margin = 4;
		
		NSRect imageRect = NSMakeRect(leftMargin + margin, margin, width - (2. * margin), height - (2. * margin));
		
		// @TODO: Change the effect of layering
		
		CGImageRef imageRef = [self.image CGImageForProposedRect:&imageRect
														 context:[NSGraphicsContext currentContext]
														   hints:nil];
		if (_isGroup) {
			CGContextSaveGState(context);// Save before context transformations
			
			CGContextSetAlpha(context, 0.666);
			
			// First, 4 deg (0.03490658504 rad) rotation and (3, 0) offset
			CGContextTranslateCTM(context, -2., -5.);
			CGContextRotateCTM(context, 0.06981317008);
			CGContextDrawImage(context, NSRectToCGRect(imageRect), imageRef);
			
			// Then, -4 deg (0.03490658504 rad) rotation and (-3, 0) offset
			CGContextTranslateCTM(context, 4., 15.);// -3 = 3 - 6
			CGContextRotateCTM(context, -0.2094395102);// -4deg = 4deg - 8deg
			CGContextDrawImage(context, NSRectToCGRect(imageRect), imageRef);
			
			/*
			// And, -1 deg (-0.01745329252 rad) rotation and (1, 0) offset
			CGContextRotateCTM(context, 0.01745329252);// -1deg = 1deg - 2deg
			CGContextTranslateCTM(context, 1, 1);// Y: 0 = 1 - 1
			CGContextDrawImage(context, NSRectToCGRect(imageRect), imageRef);
			*/
			
			CGContextRestoreGState(context);
		}
		
		CGContextDrawImage(context, NSRectToCGRect(imageRect), imageRef);
		//CGImageRelease(imageRef);
		
		[[NSColor clearColor] set];
		CGContextFillRect(context, NSRectToCGRect(dirtyRect));
		
		if (_selected) {
			
			float margin = 1.;
			
			float borderWidth = width - 2. * margin;
			float borderHeight = height - 2. * margin;
			float radius = 8.;
			
			CGContextBeginPath(context);
			CGContextMoveToPoint(context, leftMargin + margin, radius);
			CGContextAddArcToPoint(context, leftMargin + margin, margin, leftMargin + radius + margin, margin, radius);
			CGContextAddArcToPoint(context, leftMargin + borderWidth + margin, margin, leftMargin + borderWidth + margin, radius, radius);
			CGContextAddArcToPoint(context, leftMargin + borderWidth + margin, borderHeight + margin, leftMargin + borderWidth - radius, borderHeight + margin, radius);
			CGContextAddArcToPoint(context, leftMargin + margin, borderHeight + margin, leftMargin + margin, borderHeight - radius, radius);
			CGContextClosePath(context);
			
			CGPathRef pathRef = CGContextCopyPath(context);
			
			[[NSColor colorWithDeviceWhite:0. alpha:0.05] setFill];
			CGContextFillPath(context);
			
			
			CGContextAddPath(context, pathRef);
			CGPathRelease(pathRef);
			
			CGContextSetLineWidth(context, margin * 2.);
			[[NSColor darkGrayColor] setStroke];
			
			CGContextStrokePath(context);
		}
		
		if (_isOriginal) {
			
			NSImage * image = [NSImage imageNamed:@"original.pdf"];
			CGImageRef imageRef = [image CGImageForProposedRect:NULL
														context:[NSGraphicsContext currentContext]
														  hints:nil];
			CGRect rect = CGRectMake(imageRect.origin.x - 12., 0., 25., 25.);
			CGContextDrawImage(context, rect, imageRef);
		}
	
	}
}

@end


@implementation GridItemTextField

@synthesize labelColor = _labelColor;

- (void)drawRect:(NSRect)dirtyRect
{
	if (_labelColor) {
		
		[_labelColor setFill];
		
		NSSize size = [[self cell] cellSize];
		
		CGFloat padding = 2.;
		CGFloat radius = size.height / 2.;
		CGFloat width = self.bounds.size.width;
		CGFloat cellWidth = MIN((width - padding * 2.), (size.width + padding * 2.));
		CGFloat offsetX = (width - cellWidth) / 2.;
		
		NSRect frame = NSMakeRect(offsetX, 0., cellWidth, size.height);
		NSBezierPath * path = [NSBezierPath bezierPathWithRoundedRect:frame xRadius:radius yRadius:radius];
		//[path setClip];
		[path fill];
	}
	
	[super drawRect:dirtyRect];
}

@end


@implementation GridItemView

@synthesize image = _image;
@synthesize item = _item;
@synthesize selected = _selected, isOriginal = _isOriginal, isGroup = _isGroup;
@synthesize labelColor = _labelColor;

@synthesize hitFrame = _hitFrame;

- (id)initWithFrame:(NSRect)frameRect
{
	if ((self = [super initWithFrame:frameRect])) {
		
		NSRect rect = NSMakeRect(0., 0., frameRect.size.width, 64.);
		rect.origin.x = (frameRect.size.width - rect.size.width) / 2.;
		imageView = [[GridItemImageView alloc] initWithFrame:rect];
		imageView.imageScaling = NSImageScaleProportionallyUpOrDown;
		imageView.autoresizingMask = (NSViewWidthSizable | NSViewHeightSizable);
		[self addSubview:imageView];
		
		rect = NSMakeRect(0., 64., frameRect.size.width, 16.);
		textField = [[GridItemTextField alloc] initWithFrame:rect];
		[textField setEditable:NO];
		[textField setBordered:NO];
		textField.alignment = NSCenterTextAlignment;
		textField.backgroundColor = [NSColor clearColor];
		textField.autoresizingMask = (NSViewWidthSizable);
		
		[[textField cell] setLineBreakMode:NSLineBreakByTruncatingMiddle];
		
		[self addSubview:textField];
	}
	
	return self;
}

- (BOOL)isFlipped
{
	return YES;
}

- (NSView *)hitTest:(NSPoint)aPoint
{
	return nil;// Don't catch mouse event, let it to the GridView
}

- (NSRect)hitFrame
{
	NSRect frame = imageView.frame;
	frame.origin.x += self.frame.origin.x;
	frame.origin.y += self.frame.origin.y;
	return frame;
}

- (void)setImage:(NSImage *)image
{
	_image = image;
	
	imageView.image = _image;
}

- (void)setLabelColor:(NSColor *)labelColor
{
	_labelColor = labelColor;
	
	textField.labelColor = labelColor;
}

- (void)setItem:(GridItem *)item
{
	_item = item;
	
	[textField setStringValue:(item.title)? item.title: @""];
	[imageView setImage:item.image];
	
	self.labelColor = item.labelColor;
	
	self.selected = item.selected;
	self.isOriginal = item.isOriginal;
	
	self.isGroup = item.isGroup;
}

- (void)setSelected:(BOOL)selected
{
	_selected = selected;
	imageView.selected = selected;
	
	[imageView setNeedsDisplay];
}

- (void)setIsOriginal:(BOOL)isOriginal
{
	_isOriginal = isOriginal;
	imageView.isOriginal = isOriginal;
	
	[imageView setNeedsDisplay];
}

- (void)setIsGroup:(BOOL)isGroup
{
	_isGroup = isGroup;
	imageView.isGroup = isGroup;
	
	[imageView setNeedsDisplay];
}

@end

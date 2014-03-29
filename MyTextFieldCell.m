//
//  MyTextFieldCell.m
//  Comparator
//
//  Created by Max on 07/05/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

#import "MyTextFieldCell.h"

#import "NSColor+addition.h"

@implementation MyTextFieldCell

- (id)copyWithZone:(NSZone*)zone
{
    MyTextFieldCell * cell = (MyTextFieldCell *)[super copyWithZone:zone];
	
    return cell;
}

- (id)initTextCell:(NSString *)aString
{
	if ((self = [super initTextCell:aString])) {
		self.title = aString;
	}
	
	return self;
}

- (void)setTitle:(NSString *)aTitle
{
	[title release];
	title = [aTitle retain];
}

- (void)setTextBackgroundColor:(NSColor *)color
{
	[textBackgroundColor release];
	textBackgroundColor = [color retain];
}

- (NSImage *)_textBackgroundImageWithSize:(NSSize)size
{
	CGFloat x = 0.;
	CGFloat y = 0.;
	
	CGFloat width = size.width;
	CGFloat height = (size.height - 2.);
	
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGContextRef contextRef = CGBitmapContextCreate(NULL,
													(size_t)size.width,
													(size_t)size.height,
													8,
													0,
													colorSpace,
													kCGImageAlphaPremultipliedLast);
	CGColorSpaceRelease(colorSpace);
	
	CGContextSetLineWidth(contextRef, 1.);
	
	CGFloat radius = height / 2.;
	
	/*  pt1 ---------- pt2  *
	 * (                  ) *
	 *  pt3 ---------- pt4  */
	
	CGPoint pt1 = CGPointMake(x + radius, y + height);
	CGPoint pt2 = CGPointMake(x + width - radius, y + height);
	CGPoint pt3 = CGPointMake(x + radius, y);
	CGPoint pt4 = CGPointMake(x + width - radius, y);
	
	CGContextBeginPath(contextRef);
	CGContextMoveToPoint(contextRef, pt1.x, pt1.y);
	CGContextAddLineToPoint(contextRef, pt2.x, pt2.y);
	
	CGContextAddArcToPoint(contextRef, pt2.x + radius, pt2.y, pt4.x + radius, pt4.y, radius);
	CGContextAddArcToPoint(contextRef, pt4.x + radius, pt4.y, pt4.x, pt4.y, radius);
	
	CGContextAddLineToPoint(contextRef, pt3.x, pt3.y);
	
	CGContextAddArcToPoint(contextRef, pt3.x - radius, pt3.y, pt1.x - radius, pt1.y, radius);
	CGContextAddArcToPoint(contextRef, pt1.x - radius, pt1.y, pt1.x, pt1.y, radius);
	
	CGContextClosePath(contextRef);
	
	CGContextClip(contextRef);
	
	//[textBackgroundColor setStroke];
	
	//CGContextStrokePath(contextRef);
	
	//[[NSColor redColor] setFill];
	
	CGFloat components[4];
	[[textBackgroundColor colorUsingColorSpaceName:NSCalibratedRGBColorSpace] getComponents:components];
	CGColorRef colorStart = CGColorCreateGenericRGB(components[0] + 0.2, components[1] + 0.2, components[2] + 0.2, components[3]);
	CGColorRef colorEnd = CGColorCreateGenericRGB(components[0] - 0.1, components[1] - 0.1, components[2] - 0.1, components[3]);
	CGColorRef values[2] = { colorStart, colorEnd };
	
	CFArrayRef colors = CFArrayCreate(kCFAllocatorDefault, (const void **)values, 2, NULL);
	
	CGGradientRef gradientRef = CGGradientCreateWithColors(NULL, colors, NULL);// No specified colorSpace and gradient locations are by defaults
	if (colors) CFRelease(colors);
	
	CGContextDrawLinearGradient(contextRef, gradientRef, pt1, pt3, kCGGradientDrawsBeforeStartLocation);
	CGGradientRelease(gradientRef);
	
	//CGColorRef colorRef = CGColorCreateGenericRGB(0., 0., 1., 1.);
	//CGContextSetFillColorWithColor(contextRef, colorRef);
	//CGContextFillPath(contextRef);
	
	CGImageRef imageRef = CGBitmapContextCreateImage(contextRef);
	NSImage * _image = [[[NSImage alloc] initWithCGImage:imageRef size:size] autorelease];
	CGImageRelease(imageRef);
	
	CGContextRelease(contextRef);
	
	return _image;
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	if (textBackgroundColor) {
		
		NSSize size = cellFrame.size;
		
		if ([self stringValue]) {
			NSSize textSize = [[self attributedStringValue] size];
			
			size.width = MIN(textSize.width + 6., size.width);
			size.height = MIN(textSize.height, size.width);
		}
		
		NSImage * image = [self _textBackgroundImageWithSize:size];
		NSImageCell * anImageCell = [[NSImageCell alloc] initImageCell:image];
		NSRect frame = NSMakeRect(cellFrame.origin.x, cellFrame.origin.y, size.width, size.height);
		[anImageCell setImageScaling:NSImageScaleAxesIndependently];
		[anImageCell drawWithFrame:frame inView:controlView];
		[anImageCell release];
	}
	
	[super drawWithFrame:cellFrame inView:controlView];
}

@end

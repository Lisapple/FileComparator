//
//  PlaceholderLabel.m
//  PlaceholderText
//
//  Created by Max on 27/11/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "PlaceholderLabel.h"

@implementation PlaceholderLabel

@synthesize title = _title;
@synthesize backgroundColor = _backgroundColor;

- (void)setTitle:(NSString *)title
{
	_title = [title copy];
	[self setNeedsDisplay:YES];
}

- (void)setBackgroundColor:(NSColor *)backgroundColor
{
	_backgroundColor = [backgroundColor copy];
	[self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect
{
	if (_title.length == 0)
		return;
	
	// @TODO: cache the generated images
	
	NSSize size = [_title sizeWithAttributes:@{NSFontAttributeName: [NSFont boldSystemFontOfSize:24.]}];
	
	CGContextRef context = [NSGraphicsContext currentContext].graphicsPort;
	
	NSColor * backgroundColor = _backgroundColor;
	if (!backgroundColor) { backgroundColor = self.window.backgroundColor; }
	[backgroundColor setFill];
	
	CGFloat width = ceilf(size.width),
			height = ceilf(size.height),
			x = (self.frame.size.width - width) / 2.,
			y = (self.frame.size.height - height) / 2.;
	CGRect frame = CGRectMake((int)x, (int)y, width, height);
	
	CGContextClipToRect(context, frame);
	
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	
	/* Draw the gradient to the background */
	
	CGColorRef startColorRef = CGColorCreateGenericRGB(0.4, 1.0, 0.4, 1.);
	CGColorRef endColorRef = CGColorCreateGenericRGB(0.7, 0.7, 0., 1.);
	
	CGColorRef values[2] = { startColorRef, endColorRef };
	CFArrayRef colors = CFArrayCreate(kCFAllocatorDefault, (const void **)values, 2, NULL);
	CGColorRelease(startColorRef);
	CGColorRelease(endColorRef);
	
	CGFloat components[8] = {
		0.8, 0.8, 0.8, 1., // Start color (Top color)
		0.666, 0.666, 0.666, 1. }; // End color (Bottom color)
	
	CGGradientRef gradient = CGGradientCreateWithColorComponents(colorSpace, components, NULL, 2);
	CFRelease(colors);
	
	CGContextDrawLinearGradient(context, gradient, frame.origin, CGPointMake(frame.origin.x, frame.origin.y + frame.size.height), 0);
	if (gradient) CGGradientRelease(gradient);
	
	/* Draw the text into a mask image */
	CGContextRef textContextRef = CGBitmapContextCreate(NULL, (size_t)width, (size_t)height,
														8, 0,
														colorSpace, kCGImageAlphaPremultipliedLast);
	CGFloat fontHeight = 20.;
	
#define USE_CORE_TEXT 1
#if USE_CORE_TEXT
	NSFont * font = [NSFont systemFontOfSize:fontHeight];
	NSDictionary * attributes = @{ NSFontAttributeName : font, NSForegroundColorAttributeName : [NSColor whiteColor] };
	NSAttributedString * string = [[NSAttributedString alloc] initWithString:_title attributes:attributes];
	CTLineRef line = CTLineCreateWithAttributedString((__bridge CFAttributedStringRef)string);
	
	CGRect bounds = CTLineGetBoundsWithOptions(line, 0);
	CGContextTranslateCTM(textContextRef,
						  ceilf((width - bounds.size.width) / 2),
						  ceilf((height - bounds.size.height) / 2) + 2);
	CTLineDraw(line, textContextRef);
	CFRelease(line);
#else
	const CGFloat text_components[4] = { 1., 1., 1., 1. };
	CGColorRef color = CGColorCreate(colorSpace, text_components);
	CGContextSetFillColorWithColor(textContextRef, color);
	CGColorRelease(color);
	CGColorSpaceRelease(colorSpace);
	
	NSString * systemFontName = [NSFont systemFontOfSize:10.].fontName;
	CGContextSelectFont(textContextRef, systemFontName.UTF8String, fontHeight, kCGEncodingMacRoman);
	
	const char * string = _title.UTF8String;
	unsigned long length = strlen(string);
	
	CGPoint oldPosition = CGContextGetTextPosition(textContextRef);
	CGContextSetTextDrawingMode(textContextRef, kCGTextInvisible);// Draw the text invisible to get the position
	CGContextShowTextAtPoint(textContextRef, oldPosition.x, oldPosition.y, string, length);
	CGPoint newPosition = CGContextGetTextPosition(textContextRef);// Get the position
	
	CGSize textSize = CGSizeMake(newPosition.x - oldPosition.x, newPosition.y - oldPosition.y);
	
	CGFloat textX = width / 2. - textSize.width / 2.;
	CGFloat textY = height / 2. - fontHeight / 3.;
	
	CGContextSetTextDrawingMode(textContextRef, kCGTextFill);
	
	CGContextShowTextAtPoint(textContextRef, textX, textY, string, length);
#endif
	
	CGImageRef textImageRef = CGBitmapContextCreateImage(textContextRef);
	if (textContextRef) CGContextRelease(textContextRef);
	
	
	CGDataProviderRef provider = CGImageGetDataProvider(textImageRef);
	CGImageRef maskTextImageRef = CGImageMaskCreate((size_t)width, (size_t)height,
													CGImageGetBitsPerComponent(textImageRef),
													CGImageGetBitsPerPixel(textImageRef),
													CGImageGetBytesPerRow(textImageRef),
													provider, NULL, false);
	if (textImageRef) CGImageRelease(textImageRef);
	
	CGColorRef shadowColor = CGColorCreateGenericRGB(0., 0., 0., 0.5);
	CGContextSetShadowWithColor(context, CGSizeMake(0., -1.), 1.5, shadowColor);
	CGColorRelease(shadowColor);
	
	CGContextDrawImage(context, frame, maskTextImageRef);
	if (maskTextImageRef) CGImageRelease(maskTextImageRef);
	
	CGColorSpaceRelease(colorSpace);
}

@end

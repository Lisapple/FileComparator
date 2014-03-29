//
//  SourceTableViewCell.m
//  Comparator
//
//  Created by Max on 20/04/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

#import "SourceTableViewCell.h"

#import "NSColor+addition.h"

@implementation SourceTableViewCellHelper

@synthesize defaultHeight;

- (void)_updateDefaultHeight:(NSNotification *)notification
{
	[self updateDefaultHeight];
}

- (void)updateDefaultHeight
{
	NSUserDefaults * userDefault = [NSUserDefaults standardUserDefaults];
	if ([userDefault boolForKey:@"useSmallSourceIcons"]) {
		defaultHeight = 26.;
	} else {
		defaultHeight = 42.;
	}
}

@end

@implementation SourceTableViewCell

@synthesize image;
@synthesize title;
@synthesize badgeCount;
@synthesize disabled = _disabled;

@synthesize imageCell;
@synthesize textFieldCell, textFieldCellShadow;

static SourceTableViewCellHelper * helper;

+ (void)initialize
{
	static BOOL initialized = NO;
	if (!initialized) {
		initialized = YES;
		
		helper = [[SourceTableViewCellHelper alloc] init];
		[helper updateDefaultHeight];
		[[NSNotificationCenter defaultCenter] addObserver:helper
												 selector:@selector(_updateDefaultHeight:)
													 name:NSUserDefaultsDidChangeNotification
												   object:nil];
	}
}

+ (CGFloat)defaultHeight
{
	return helper.defaultHeight;
}

- (id)init
{
	if ((self = [super init])) {
		self.title = @"--";
	}
	
	return self;
}

- (id)initTextCell:(NSString *)aString
{
	if ((self = [super initTextCell:aString])) {
		self.title = aString;
	}
	
	return self;
}

- (id)initWithCoder:(NSCoder *)decoder
{
	if ((self = [super initWithCoder:decoder])) {
		self.title = @"---";
	}
	
	return self;
}

- (id)copyWithZone:(NSZone*)zone
{
    SourceTableViewCell * cell = (SourceTableViewCell *)[super copyWithZone:zone];
	cell->image = [image copyWithZone:zone];
	cell->title = [title copyWithZone:zone];
	
	cell->imageCell = [imageCell copyWithZone:zone];
	cell->textFieldCell = [textFieldCell copyWithZone:zone];
	cell->textFieldCellShadow = [textFieldCellShadow copyWithZone:zone];
	
    return cell;
}

- (void)setTitle:(NSString *)aTitle
{
	[title release];
	title = [aTitle retain];
}

- (void)setBadgeCount:(NSInteger)count
{
	if (badgeCount != count) {
		[badgeCountImage release];
		badgeCountImage = nil;
	}
	
	badgeCount = count;
}

// @TODO: create a class for that
- (CGFloat)screenScale
{
	CGFloat width = 100.;
	CGContextRef context = [NSGraphicsContext currentContext].graphicsPort;
	CGRect deviceRect = CGContextConvertRectToDeviceSpace(context, CGRectMake(0., 0., width, 0.));
	return deviceRect.size.width / width;
}

- (NSImage *)_backgroundBadgeCountImage
{
	// @TODO: draw text in white if non highlighted
	
	CGFloat scale = [self screenScale];
	if (badgeCountImageScale != scale) {
		[badgeCountImage release];
		badgeCountImage = nil;
	}
	
	if (!badgeCountImage) {
		CGFloat x = 0.;
		CGFloat y = 0.;
		CGFloat width = (((int)log10(badgeCount) + 2) * 8.) + 8.;
		if (width > 40.)
			width = 40.;
		
		CGFloat height = 18.;
		
		width *= scale;
		height *= scale;
		
		CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
		CGContextRef contextRef = CGBitmapContextCreate(NULL,
														(size_t)width, (size_t)height,
														8, 0,
														colorSpace,
														kCGImageAlphaPremultipliedLast);
		
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
		
		CGColorRef colorRef = ([self isHighlighted])? CGColorCreateGenericGray(1., 1.) : CGColorCreateGenericGray(0.5, 1.);
		CGContextSetFillColorWithColor(contextRef, colorRef);
		CGColorRelease(colorRef);
		
		CGContextFillPath(contextRef);
		
		CGImageRef imageRef = CGBitmapContextCreateImage(contextRef);
		CGContextRelease(contextRef);
		
		
		CGContextRef textContextRef = CGBitmapContextCreate(NULL,
															(size_t)width,
															(size_t)height,
															8,
															0,
															colorSpace,
															kCGImageAlphaPremultipliedLast);
		
		const CGFloat text_components[4] = {1., 1., 1., 1.};
		CGColorRef color = CGColorCreate(colorSpace, text_components);
		CGContextSetFillColorWithColor(textContextRef, color);
		CGColorRelease(color);
		
		
		CGFloat fontHeight = 14. * scale;
		CGContextSelectFont(textContextRef, "Helvetica-Bold", fontHeight, kCGEncodingMacRoman);
		
		const char * string = [[NSString stringWithFormat:@"%ld", badgeCount] cStringUsingEncoding:NSUTF8StringEncoding];
		int length = strlen(string);
		
		CGPoint oldPosition = CGContextGetTextPosition(textContextRef);
		CGContextSetTextDrawingMode(textContextRef, kCGTextInvisible);// Draw the text invisible to get the position
		CGContextShowTextAtPoint(textContextRef, oldPosition.x, oldPosition.y, string, length);
		CGPoint newPosition = CGContextGetTextPosition(textContextRef);// Get the position
		
		CGSize size = CGSizeMake(newPosition.x - oldPosition.x, newPosition.y - oldPosition.y);
		
		CGFloat textX = width / 2. - size.width / 2.;
		CGFloat textY = height / 2. - fontHeight / 3.;
		
		
		CGContextSetTextDrawingMode(textContextRef, kCGTextFill);
		
		CGContextShowTextAtPoint(textContextRef, textX, textY, string, length);
		
		CGImageRef textImageRef = CGBitmapContextCreateImage(textContextRef);
		CGContextRelease(textContextRef);
		
		CGColorSpaceRelease(colorSpace);
		
		
		CGDataProviderRef provider = CGImageGetDataProvider(textImageRef);
		CGImageRef maskImageRef = CGImageMaskCreate((size_t)width,
													(size_t)height,
													CGImageGetBitsPerComponent(textImageRef),
													CGImageGetBitsPerPixel(textImageRef),
													CGImageGetBytesPerRow(textImageRef),
													provider,
													NULL,
													false);
		
		CGImageRelease(textImageRef);
		
		CGImageRef finalImageRef = CGImageCreateWithMask(imageRef, maskImageRef);
		CGImageRelease(imageRef);
		CGImageRelease(maskImageRef);
		
		badgeCountImage = [[NSImage alloc] initWithCGImage:finalImageRef size:NSMakeSize(width, height)];
		CGImageRelease(finalImageRef);
		
		badgeCountImageSize = CGSizeMake(width, height);
		badgeCountImageScale = scale;
	}
	
	return badgeCountImage;
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	/*
	 NSRect frame = NSMakeRect(cellFrame.origin.x - 1., cellFrame.origin.y - 1., cellFrame.size.width + 2, cellFrame.size.height + 2);
	 NSImageCell * anImageCell = [[NSImageCell alloc] initImageCell:[NSImage imageNamed:@"background_source_cell.png"]];
	 [anImageCell setImageScaling:NSImageScaleAxesIndependently];
	 [anImageCell drawWithFrame:frame inView:controlView];
	 //self.imageCell = anImageCell;
	 [anImageCell release];
	 */
	
	CGFloat imageHeight = cellFrame.size.height - 10.;
	NSRect frame = NSMakeRect(cellFrame.origin.x + 5., cellFrame.origin.y + 5., imageHeight, imageHeight);
	NSImageCell * anImageCell = [[NSImageCell alloc] initImageCell:image];
	[anImageCell drawWithFrame:frame inView:controlView];
	self.imageCell = anImageCell;
	[anImageCell release];
	
	/*
	 One line of text: NSMakeRect(25. + 32. + 8., cellFrame.origin.y + 12., 90., 32.);
	 Two line of text: NSMakeRect(25. + 32. + 8., cellFrame.origin.y, 90., cellFrame.size.height);
	 */
	
	/* Duplicate textFieldCell for label shadow */
	//frame = NSMakeRect(cellFrame.origin.x + 5. + 32. + 6., cellFrame.origin.y + 13., cellFrame.size.width - 5. - 25. - 10., 26.);
	
	if (!textFieldCellShadow) {
		NSTextFieldCell * aTextFieldCell = [[NSTextFieldCell alloc] initTextCell:(title)? title: @""];
		[aTextFieldCell setFont:[NSFont systemFontOfSize:12.]];
		
		[aTextFieldCell setLineBreakMode:NSLineBreakByTruncatingMiddle];
		[aTextFieldCell setTruncatesLastVisibleLine:YES];
		
		[aTextFieldCell drawWithFrame:frame inView:controlView];
		self.textFieldCellShadow = aTextFieldCell;
		[aTextFieldCell release];
	}
	
	textFieldCellShadow.title = title;
	
	float y = (cellFrame.size.height - 15.) / 2.;//cellFrame.origin.y + (imageHeigth / 2.) + 2.;
	frame = NSMakeRect(cellFrame.origin.x + 5. + imageHeight + 6., cellFrame.origin.y + y, cellFrame.size.width - 5. - 25. - 10., 26.);
	
	NSColor * color = [NSColor whiteColor];
	if (!_disabled && [self isHighlighted]) {
		color = [NSColor colorWithDeviceWhite:0. alpha:0.4];
	}
	[textFieldCellShadow setTextColor:color];
	[textFieldCellShadow drawWithFrame:frame inView:controlView];
	
	if (!textFieldCell) {
		NSTextFieldCell * aTextFieldCell = [[NSTextFieldCell alloc] initTextCell:(title)? title: @""];
		[aTextFieldCell setFont:[NSFont systemFontOfSize:12.]];
		
		[aTextFieldCell setLineBreakMode:NSLineBreakByTruncatingMiddle];
		[aTextFieldCell setTruncatesLastVisibleLine:YES];
		
		self.textFieldCell = aTextFieldCell;
		[aTextFieldCell release];
	}
	
	textFieldCell.title = title;
	
	frame = NSOffsetRect(frame, 0., -1.);
	
	if (_disabled) {
		color = [NSColor grayColor];
	} else {
		color = ([self isHighlighted])? [NSColor whiteColor]: [NSColor blackColor];
	}
	[textFieldCell setTextColor:color];
	[textFieldCell drawWithFrame:frame inView:controlView];
	
	
	/* Badge for Count */
	if (badgeCount > 0) {
		
		NSTextFieldCell * aTextFieldCell = [[NSTextFieldCell alloc] initTextCell:@""];
		
		NSImage * background = [self _backgroundBadgeCountImage];
		NSSize imageSize = NSSizeFromCGSize(badgeCountImageSize);
		NSRect frame = NSMakeRect(cellFrame.origin.x + cellFrame.size.width - imageSize.width - 5., cellFrame.origin.y + (cellFrame.size.height / 2. - 9.), imageSize.width, imageSize.height);
		NSImageCell * anImageCell = [[NSImageCell alloc] initImageCell:background];
		[anImageCell setImageAlignment:NSImageAlignCenter];
		[anImageCell drawWithFrame:frame inView:controlView];
		[anImageCell release];
		
		
		frame = NSMakeRect(cellFrame.origin.x + cellFrame.size.width - 38. - 5., cellFrame.origin.y + (cellFrame.size.height / 2. - 8.), 36., 32.);
		[aTextFieldCell drawWithFrame:frame inView:controlView];
		[aTextFieldCell release];
	}
	
	//[super drawWithFrame:cellFrame inView:controlView];
}

@end

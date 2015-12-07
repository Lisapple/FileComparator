//
//  FolderDetailsWindow.m
//  FolderSlice
//
//  Created by Maxime on 02/01/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "FolderDetailsWindow.h"

#import "FileInformations.h"

#import "NSString+addition.h"

#define CLIP(value, min) ({ (value) < (min) ? (min) : (value); })

@implementation _PopUpWindowContentView

- (BOOL)isOpaque
{
	return NO;
}

- (void)drawRect:(NSRect)dirtyRect
{
	[[NSColor clearColor] setFill];
	NSRectFill(dirtyRect);
	
	CGContextRef context = [NSGraphicsContext currentContext].graphicsPort;
	
	float arrowHeight = 14.;
	float cornerRadius = 4.;
	float x = dirtyRect.origin.x, y = dirtyRect.origin.y + arrowHeight, width = dirtyRect.size.width, height = dirtyRect.size.height - arrowHeight;
	CGContextBeginPath(context);
	CGContextMoveToPoint(context, x, y + cornerRadius);
	CGContextAddArcToPoint(context, x, y, x + cornerRadius, y, cornerRadius);
	
	CGContextAddLineToPoint(context, x + (width / 2.) + arrowHeight, y);
	CGContextAddLineToPoint(context, x + (width / 2.), 0.);
	CGContextAddLineToPoint(context, x + (width / 2.) - arrowHeight, y);
	
	CGContextAddArcToPoint(context, x + width, y, x + width, y + cornerRadius, cornerRadius);
	CGContextAddArcToPoint(context, x + width, y + height, x + width - cornerRadius, y + height, cornerRadius);
	CGContextAddArcToPoint(context, x, y + height, x, y + height - cornerRadius, cornerRadius);
	CGContextClosePath(context);
	
	CGContextClip(context);
	
	
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
	
	CGFloat locations[3] = { 0., 0.9, 1. };
	
	CGColorRef values[3] = {
		CGColorCreateGenericGray(0.1, 1.),
		CGColorCreateGenericGray(0.15, 1.),
		CGColorCreateGenericGray(0.333, 1.),
	};
	CFArrayRef colors = CFArrayCreate(kCFAllocatorDefault, (const void **)values, 3, NULL);
	
	CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, colors, locations);
	CFRelease(colors);
	CGColorSpaceRelease(colorSpace);
	
	CGContextDrawLinearGradient(context, gradient, CGPointZero, CGPointMake(0., self.frame.size.height), 0);
	CGGradientRelease(gradient);
}

@end


@implementation ItemsListWindow

@synthesize items = _items;

- (instancetype)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag
{
	if ([NSWindow instancesRespondToSelector:@selector(contentViewController)] /* OS X.10 and later */) { // Fix shadow since X.10
		aStyle = NSFullSizeContentViewWindowMask;
	}
	if ((self = [super initWithContentRect:contentRect styleMask:aStyle backing:bufferingType defer:flag])) {
		
		_PopUpWindowContentView * contentView = [[_PopUpWindowContentView alloc] initWithFrame:contentRect];
		self.contentView = contentView;
		contentView.alphaValue = 0.96;
		
		[self setOpaque:NO];
		self.backgroundColor = [NSColor clearColor];
	}
	return self;
}

- (void)setItems:(NSArray *)items
{
	_items = [items copy];
	
	/* Remove the last textField */
	NSArray * subviewsCopy = [[self.contentView subviews] copy];
	for (NSView * subview in subviewsCopy)
		[subview removeFromSuperview];
	
	const CGFloat margin = 8.;
	const int numberOfLines = 5;// Number max of lines
	
	NSInteger count = (_items.count > (numberOfLines - 1))? (numberOfLines - 1) : _items.count;
	NSArray * itemsToShow = [_items subarrayWithRange:NSMakeRange(0, count)];
	NSMutableAttributedString * attributedString = [[NSMutableAttributedString alloc] init];
	
	NSMutableParagraphStyle * paragrapheStyle = [[NSMutableParagraphStyle alloc] init];
	paragrapheStyle.alignment = NSCenterTextAlignment;
	paragrapheStyle.lineBreakMode = NSLineBreakByTruncatingMiddle;
	
	NSDictionary * regularAttributes = @{ NSForegroundColorAttributeName : [NSColor whiteColor],
										  NSParagraphStyleAttributeName : paragrapheStyle };
	
	NSMutableDictionary * boldAttributes = regularAttributes.mutableCopy;
	boldAttributes[NSFontAttributeName] = [NSFont boldSystemFontOfSize:12.];
	
	int index = 0;
	for (NSDictionary * item in itemsToShow) {
		NSString * filename = item[NSURLNameKey];
		double filesize = [item[NSURLFileSizeKey] doubleValue];
		
		NSMutableAttributedString * mAttrString = [[NSMutableAttributedString alloc] init];
		{
			NSAttributedString * attributedFilename = [[NSAttributedString alloc] initWithString:filename attributes:boldAttributes];
			[mAttrString appendAttributedString:attributedFilename];
			
			NSString * lineBreakString = @"\n";
			if (index == (itemsToShow.count - 1))// For the last row, don't add the line break
				lineBreakString = @"";
			
			NSString * string = [NSString stringWithFormat:@" (%@)%@", [NSString localizedStringForFileSize:filesize], lineBreakString];
			NSAttributedString * attributedFilesize = [[NSAttributedString alloc] initWithString:string attributes:regularAttributes];
			[mAttrString appendAttributedString:attributedFilesize];
		}
		[attributedString appendAttributedString:mAttrString];
		
		index++;
	}
	
	if ((items.count - itemsToShow.count) > 0) {
		NSAttributedString * moreItemsAttributedString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:NSLocalizedString(@"\nand %ld more items", nil), (items.count - itemsToShow.count)]
																						 attributes:regularAttributes];
		[attributedString appendAttributedString:moreItemsAttributedString];
	}
	
	/* Reckon the size of the textField */
	NSSize size = [attributedString size];
	
	/* Add the textField */
	NSTextField * textField = [[NSTextField alloc] initWithFrame:NSMakeRect(margin, 14. + margin, (int)size.width, (int)size.height)];
	[textField setBordered:NO];
	[textField setEditable:NO];
	[textField setSelectable:NO];
	[textField setBackgroundColor:[NSColor clearColor]];
	textField.attributedStringValue = attributedString;
	[self.contentView addSubview:textField];
	
	
	/* Reckon the size of the window */
	NSRect frame = self.frame;
	frame.size = NSMakeSize((int)(size.width + 2 * margin), (int)(size.height + 14. + 2 * margin));
	[self setFrame:frame display:YES];
}

@end


@implementation _ExcludeButton

- (instancetype)initWithFrame:(NSRect)frameRect
{
	if ((self = [super initWithFrame:frameRect])) {
		[self setButtonType:NSMomentaryLightButton];
	}
	return self;
}

- (BOOL)isOpaque
{
	return NO;
}

- (void)drawRect:(NSRect)dirtyRect
{
	const float radius = self.frame.size.height / 2.;
	
	CGContextRef context = [NSGraphicsContext currentContext].graphicsPort;
	[[NSColor clearColor] setFill];
	CGContextFillRect(context, dirtyRect);
	
	NSBezierPath * path = [NSBezierPath bezierPathWithRoundedRect:dirtyRect xRadius:radius yRadius:radius];
	[path setClip];
	
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
	CGColorRef startColorRef = NULL, endColorRef = NULL;
	NSCell * cell = self.cell;
	if (cell.isHighlighted) {
		startColorRef = CGColorCreateGenericGray(0.15, 1.);
		endColorRef = CGColorCreateGenericGray(0.05, 1.);
	} else {
		startColorRef = CGColorCreateGenericGray(0.2, 1.);
		endColorRef = CGColorCreateGenericGray(0.1, 1.);
	}
	CGFloat locations[2] = { 0., 1. };
	
	CGColorRef values[2] = { startColorRef, endColorRef };
	CFArrayRef colors = CFArrayCreate(kCFAllocatorDefault, (const void **)values, 2, NULL);
	
	CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, colors, locations);
	CGColorRelease(startColorRef), CGColorRelease(endColorRef);
	CFRelease(colors);
	CGColorSpaceRelease(colorSpace);
	
	CGContextDrawLinearGradient(context, gradient, CGPointZero, CGPointMake(0., self.frame.size.height), 0);
	CGGradientRelease(gradient);
	
	[[NSColor darkGrayColor] setStroke];
	[path stroke];
	
	// Set the color of the title
	
	CGContextSetTextMatrix(context, CGAffineTransformMakeScale(1., -1.));// Flip the text from the actual not flipped view setting (flipping by the y axis)
	
	CGFloat fontHeight = 12.;// 12 pt
	NSFont * font = [NSFont systemFontOfSize:fontHeight];
	NSDictionary * attributes = @{ NSFontAttributeName : font, NSForegroundColorAttributeName : [NSColor whiteColor] };
	NSAttributedString * string = [[NSAttributedString alloc] initWithString:self.title attributes:attributes];
	CTLineRef line = CTLineCreateWithAttributedString((__bridge CFAttributedStringRef)string);
	
	CGRect bounds = CTLineGetBoundsWithOptions(line, 0);
	CGContextTranslateCTM(context,
						  ceilf((dirtyRect.size.width - bounds.size.width) / 2),
						  ceilf(bounds.size.height));
	CTLineDraw(line, context);
	CFRelease(line);
	
	/*
	CGFloat fontHeight = 12.;// 12 pt
	NSString * systemFontName = [NSFont systemFontOfSize:10.].fontName;
	CGContextSelectFont(context, systemFontName.UTF8String, fontHeight, kCGEncodingMacRoman);
	
	const char * string = [self.title UTF8String];
	unsigned long length = strlen(string);
	
	CGPoint oldPosition = CGContextGetTextPosition(context);
	CGContextSetTextDrawingMode(context, kCGTextInvisible);// Draw the text invisible to get the position
	CGContextShowTextAtPoint(context, oldPosition.x, oldPosition.y, string, length);
	CGPoint newPosition = CGContextGetTextPosition(context);// Get the position
	
	CGSize textSize = CGSizeMake(newPosition.x - oldPosition.x, newPosition.y - oldPosition.y);
	
	CGFloat textX = self.bounds.size.width / 2. - textSize.width / 2.;
	CGFloat textY = self.bounds.size.height / 1.5;
	
	CGContextSetTextDrawingMode(context, kCGTextFill);
	
	CGContextShowTextAtPoint(context, textX, textY, string, length);
	 */
}

@end


@interface ExcludePopUpWindow ()

@property (strong) _ExcludeButton * button;

@end

@implementation ExcludePopUpWindow

- (instancetype)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag
{
	if ([NSWindow instancesRespondToSelector:@selector(contentViewController)] /* OS X.10 and later */) { // Fix shadow since X.10
		aStyle = NSFullSizeContentViewWindowMask;
	}
	if ((self = [super initWithContentRect:contentRect styleMask:aStyle backing:bufferingType defer:flag])) {
		
		_PopUpWindowContentView * contentView = [[_PopUpWindowContentView alloc] initWithFrame:contentRect];
		self.contentView = contentView;
		contentView.alphaValue = 0.96;
		
		const CGFloat margin = 8.;
		_button = [[_ExcludeButton alloc] initWithFrame:NSMakeRect(margin, margin + 14., 0., 0.)];
		_button.title = NSLocalizedString(@"Exclude", nil);
		_button.target = self;
		_button.action = @selector(excludeAction:);
		[_button sizeToFit];
		[self.contentView addSubview:_button];
		
		[self setOpaque:NO];
		self.backgroundColor = [NSColor clearColor];
	}
	return self;
}

- (void)setURL:(NSURL *)URL
{
	_URL = URL;
	
	const CGFloat margin = 8.;
	
	/* Reckon the size of the window */
	NSRect frame = self.frame;
	frame.size = NSMakeSize((int)(_button.frame.size.width + 2 * margin), (int)(_button.frame.size.height + 14. + 2 * margin));
	[self setFrame:frame display:YES];
}

- (void)excludeAction:(id)sender
{
	NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
	if ([[userDefaults arrayForKey:@"Alerts to Hide"] containsObject:@"Exclude Item from Details Window"]) {
		[self.excludeDelegate excludePopUpWindow:self didExcludeURL:_URL];
	} else {
		NSAlert * alert = [[NSAlert alloc] init];
		alert.messageText = [NSString stringWithFormat:NSLocalizedString(@"Would you like to exclude \"%@\"?", nil), _URL.path.lastPathComponent];
		alert.informativeText = NSLocalizedString(@"It will be added to blacklist, you can edit this list into application preferences.", nil);
		[alert addButtonWithTitle:NSLocalizedString(@"Exclude", nil)];
		[alert addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
		alert.showsSuppressionButton = YES;
		[alert beginSheetModalForWindow:[NSApp keyWindow] completionHandler:^(NSModalResponse returnCode) {
			if (returnCode == NSAlertFirstButtonReturn) { // Exclude
				[self.excludeDelegate excludePopUpWindow:self didExcludeURL:_URL];
				
				if (alert.suppressionButton.state == NSOnState) { // Don't show this alert again
					NSArray * alertsToHide = [[userDefaults arrayForKey:@"Alerts to Hide"] arrayByAddingObject:@"Exclude Item from Details Window"];
					[userDefaults setObject:alertsToHide forKey:@"Alerts to Hide"];
				}
			}
		}];
	}
}

@end


@implementation DetailsSection

- (instancetype)initWithFileURL:(NSURL *)fileURL areaPath:(CGPathRef)path center:(NSPoint)center
{
	if ((self = [super init])) {
		_URL = fileURL;
		_path = CGPathCreateCopy(path);
		_center = center;
	}
	return self;
}

- (void)dealloc
{
	if (_path)
		CGPathRelease(_path);
}

@end


@implementation FolderDetailsView

@synthesize items = _items;

- (instancetype)initWithFrame:(NSRect)frameRect
{
	if ((self = [super initWithFrame:frameRect])) {
		
		moreItemsWindow = [[ItemsListWindow alloc] init];
		moreItemsWindow.styleMask = NSBorderlessWindowMask;
		[self.window addChildWindow:moreItemsWindow ordered:NSWindowAbove];
		moreItemsWindow.level = NSPopUpMenuWindowLevel;
		
		excludePopUpWindow = [[ExcludePopUpWindow alloc] init];
		excludePopUpWindow.styleMask = NSBorderlessWindowMask;
		excludePopUpWindow.excludeDelegate = self;
		[self.window addChildWindow:excludePopUpWindow ordered:NSWindowAbove];
		excludePopUpWindow.level = NSPopUpMenuWindowLevel;
		
		detailsSections = [[NSMutableArray alloc] initWithCapacity:10];
		
		[self addTrackingRect:self.bounds owner:self userData:NULL assumeInside:NO];
	}
	
	return self;
}

- (void)setItems:(NSArray *)items
{
	/* Remove last textFields */
	NSArray * subviewsCopy = [self.subviews copy];
	for (NSView * subview in subviewsCopy)
		[subview removeFromSuperview];
	
	_items = [items sortedArrayUsingComparator: ^(id obj1, id obj2) {
		
		double fileSize1 = [((NSDictionary *)obj1)[NSURLFileSizeKey] doubleValue];
		double fileSize2 = [((NSDictionary *)obj2)[NSURLFileSizeKey] doubleValue];
		
		if (fileSize1 > fileSize2) {
			return (NSComparisonResult)NSOrderedAscending;
		} else if (fileSize1 < fileSize2) {
			return (NSComparisonResult)NSOrderedDescending;
		}
		return (NSComparisonResult)NSOrderedSame;
	}];
	
	[self setNeedsDisplay:YES];
}

- (NSArray *)itemsToShow
{
	NSInteger count = 0;
	for (count = 1; count <= _items.count; count++) {
		
		NSArray * subarray = [_items subarrayWithRange:NSMakeRange(0, count)];
		
		double subarrayItemsSize = 0.;
		for (NSDictionary * itemAttributes in subarray) {
			subarrayItemsSize += [itemAttributes[NSURLFileSizeKey] doubleValue];
		}
		
		NSDictionary * lastItemAttributes = (NSDictionary *)[subarray lastObject];
		double filesize = [lastItemAttributes[NSURLFileSizeKey] doubleValue];
		
		if ((filesize / (float)subarrayItemsSize) < (10. / 90.)) {// Stop when an item represents under of 11,11% (10% on a 90% scale, i.e. 10/90)
			count--;
			return [_items subarrayWithRange:NSMakeRange(0, count)];
		}
	}
	
	return _items;
}

- (void)update
{
	NSArray * subviewsCopy = [self.subviews copy];
	for (NSView * subview in subviewsCopy)
		[subview removeFromSuperviewWithoutNeedingDisplay];
	
	float border = 12.;
	
	CGContextRef context = [NSGraphicsContext currentContext].graphicsPort;
	
	CGPoint center = CGPointMake(self.frame.size.height / 2., self.frame.size.width / 2.);
	
	CGContextBeginPath(context);
	CGContextAddArc(context, center.x, center.y, self.frame.size.width / 2., 0., 2 * M_PI, 0);
	CGContextAddLineToPoint(context, center.x, center.y);
	CGContextClosePath(context);
	
	[[NSColor darkGrayColor] setFill];
	CGContextFillPath(context);
	
	NSArray * subarray = [self itemsToShow];
	float current = 0.;
	if (_items.count > 1) {
		
		float size = 0.1;
		CGFloat offset = MIN(size / 2., 0.333);
		CGFloat radius = (self.frame.size.width / 2.) * (3. / 4. - offset);
		
		CGFloat angle = -(2 * M_PI * current + 2 * M_PI * (size / 2.));
		CGFloat x = center.x + sinf(angle) * radius;
		CGFloat y = center.y + cosf(angle) * radius;
		
		NSArray * groupItems = [_items subarrayWithRange:NSMakeRange(subarray.count, _items.count - subarray.count)];
		moreItemsWindow.items = groupItems;
		lastSectionLocation = [self convertPointToBase:NSMakePoint(x, y)];
		
		/* Draw last section */
		CGContextBeginPath(context);
		CGContextAddArc(context, center.x, center.y, (self.frame.size.width - border) / 2., 2 * M_PI * current + M_PI_2, 2 * M_PI * (current + size) + M_PI_2, 0);
		CGContextAddLineToPoint(context, center.x, center.y);
		CGContextClosePath(context);
		
		if (lastSectionPath) CGPathRelease(lastSectionPath);
		lastSectionPath = CGContextCopyPath(context);
		[[NSColor colorWithPatternImage:[NSImage imageNamed:@"background-last-group"]] setFill];
		CGContextAddPath(context, lastSectionPath);
		CGContextFillPath(context);
		
		if (lastSectionAndPopupWindowPath) CGPathRelease(lastSectionAndPopupWindowPath);
		CGMutablePathRef mPath = CGPathCreateMutableCopy(lastSectionPath);
		CGPathAddRect(mPath, NULL, CGRectMake(x - (moreItemsWindow.frame.size.width / 2.), y - 20.,
											  moreItemsWindow.frame.size.width, moreItemsWindow.frame.size.height));
		lastSectionAndPopupWindowPath = mPath;
		CGContextFillPath(context);
		
		/* Draw the filename label */
		float circleRadius = self.frame.size.width / 2.;
		float r1 = sinf((size / 2.) * M_PI * 2.) * radius;
		float r2 = circleRadius - radius;
		float r = MAX(MIN(r1, r2), 32.);
		
		
		NSRect frame = NSMakeRect((int)(x - r), (int)(y - (30. / 2.)), (int)(r * 2.), 30.);
		NSTextField * textField = [[NSTextField alloc] initWithFrame:frame];
		[textField setAlignment:NSCenterTextAlignment];
		[textField.cell setLineBreakMode:NSLineBreakByTruncatingMiddle];
		[textField setBordered:NO];
		[textField setEditable:NO];
		[textField setBackgroundColor:[NSColor clearColor]];
		[textField setTextColor:[NSColor darkGrayColor]];
		
		double groupFilesize = 0.;
		for (NSDictionary * itemAttributes in groupItems) {
			groupFilesize += [itemAttributes[NSURLFileSizeKey] doubleValue];
		}
		
		textField.stringValue = [NSString stringWithFormat:@"%ld %@\n%@", (_items.count - subarray.count), NSLocalizedString(@"items", nil), [NSString localizedStringForFileSize:groupFilesize]];
		
		[self addSubview:textField];
		
		current += size;
	}
	
	double subarrayItemsSize = 0.;
	for (NSDictionary * itemAttributes in subarray) {
		subarrayItemsSize += [itemAttributes[NSURLFileSizeKey] doubleValue];
	}
	
	[detailsSections removeAllObjects];
	
	int index = 0;
	for (NSDictionary * item in subarray.reverseObjectEnumerator) {
		double fileSize = [item[NSURLFileSizeKey] doubleValue];
		float size = (fileSize / (float)subarrayItemsSize) * ((_items.count > 1) ? 0.9 : 1.);
		
		CGContextBeginPath(context);
		CGContextAddArc(context, center.x, center.y, (self.frame.size.width - border) / 2., 2 * M_PI * current + M_PI_2, 2 * M_PI * (current + size) + M_PI_2, 0);
		CGContextAddLineToPoint(context, center.x, center.y);
		CGContextClosePath(context);
		
		CGPathRef path = CGContextCopyPath(context);
		
		NSColor * foregroundColor = (index % 2)? [NSColor darkGrayColor] : [NSColor windowBackgroundColor];
		NSColor * backgroundColor = (index % 2)? [NSColor windowBackgroundColor] : [NSColor darkGrayColor];
		
		[backgroundColor setFill];
		CGContextFillPath(context);
		
		// Draw the filename label
		CGFloat offset = MIN(size / 2., 0.333);
		CGFloat radius = (self.frame.size.width / 2.) * (3. / 4. - offset); // Distance from center to text position
		
		CGFloat angle = -(2 * M_PI * current + 2 * M_PI * (size / 2.));
		CGPoint textCenterPosition = CGPointMake(center.x + sinf(angle) * radius,
												 center.y + cosf(angle) * radius);
		
		[detailsSections addObject:[[DetailsSection alloc] initWithFileURL:[NSURL fileURLWithPath:item[NSURLPathKey]]
																  areaPath:path center:[self convertPointToBase:textCenterPosition]]];
		CGPathRelease(path);
		/*
		CGFloat r = self.frame.size.width / 2.;
		CGFloat beta = acosf((textCenterPosition.x - center.x) / r);
		CGFloat l = r * sinf(beta) - (textCenterPosition.y - center.y);
		*/
		float circleRadius = self.frame.size.width / 2.;
		float r1 = sinf((size / 2.) * M_PI * 2.) * radius;
		float r2 = circleRadius - radius;
		float r = MAX(MIN(r1, r2), 32.); // Maximum width (>= 32) for the filename label
		
		NSRect frame = NSMakeRect((int)(textCenterPosition.x - r), (int)(textCenterPosition.y - (30. / 2.)),
								  (int)(r * 2), 30.);
		NSTextField * textField = [[NSTextField alloc] initWithFrame:frame];
		textField.alignment = NSCenterTextAlignment;
		[textField.cell setLineBreakMode:NSLineBreakByTruncatingMiddle];
		textField.bordered = NO;;
		textField.editable = NO;
		textField.backgroundColor = [NSColor clearColor];
		textField.textColor = foregroundColor;
		
		textField.stringValue = [NSString stringWithFormat:@"%@\n%@", item[NSURLNameKey], [NSString localizedStringForFileSize:fileSize]];
		
		[self addSubview:textField];
		
		[self addToolTipRect:frame owner:self userData:(__bridge void *)(item[NSURLNameKey])];
		
		/*
		 CGContextBeginPath(context);
		 CGContextAddArc(context, x, y, r, 0., 2 * M_PI, 0);
		 CGContextClosePath(context);
		 */
		/*
		CGContextSetLineWidth(context, 3.);
		[[NSColor redColor] setStroke];
		CGContextStrokePath(context);
		*/
		
		current += size;
		index++;
	}
}

- (NSString *)view:(NSView *)view stringForToolTip:(NSToolTipTag)tag point:(NSPoint)point userData:(void *)userData
{
	return (__bridge NSString *)userData;
}

- (void)excludePopUpWindow:(ExcludePopUpWindow *)window didExcludeURL:(NSURL *)excludedURL
{
	// Add to blacklist
	NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
	NSMutableArray * blacklistPaths = [[userDefaults arrayForKey:@"blacklistPaths"] mutableCopy];
	if (!blacklistPaths)
		blacklistPaths = [[NSMutableArray alloc] initWithCapacity:1];
	[blacklistPaths addObject:excludedURL.path];
	[userDefaults setObject:blacklistPaths forKey:@"blacklistPaths"];
	
	// Reload the graph
	self.items = [_items filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSDictionary * item, NSDictionary * bindings) {
		return !([item[NSURLPathKey] isEqualToString:excludedURL.path]);
	}]];
}

- (void)drawRect:(NSRect)dirtyRect
{
	if (_items.count > 0)
		[self update];
}

- (void)mouseEntered:(NSEvent *)theEvent
{
	[super mouseEntered:theEvent];
	// Implemented but not used to enable tracking rect
}

- (void)mouseMoved:(NSEvent *)theEvent
{
	NSPoint position = theEvent.locationInWindow;
	position = [self convertPointFromBase:position];
	
	if (lastSectionPath) {
		BOOL containsEnterRect = (BOOL)CGPathContainsPoint(lastSectionPath, NULL, NSPointToCGPoint(position), false);
		BOOL containsExitRect = (BOOL)CGPathContainsPoint(lastSectionAndPopupWindowPath, NULL, NSPointToCGPoint(position), false);
		// The mouse must enter by the [last section area] and exit by the [last section area + the popup window area]
		if (containsEnterRect && !moreItemsWindow.isVisible) {
			NSPoint origin = [self.window convertBaseToScreen:lastSectionLocation];
			origin.x -= (int)(moreItemsWindow.frame.size.width / 2.);
			origin.y -= 20.;
			[moreItemsWindow setFrameOrigin:origin];
			[moreItemsWindow orderFront:nil];
			[excludePopUpWindow orderOut:nil];
		} else if (!containsExitRect) {
			[moreItemsWindow orderOut:nil];
		}
	}
	
	for (DetailsSection * section in detailsSections) {
		BOOL containsEnterRect = (BOOL)CGPathContainsPoint(section.path, NULL, NSPointToCGPoint(position), false);
		if (containsEnterRect && (![excludePopUpWindow.URL isEqualTo:section.URL] || !excludePopUpWindow.isVisible)) {
			
			NSPoint origin = [self.window convertBaseToScreen:section.center];
			origin.x -= (int)(excludePopUpWindow.frame.size.width / 2.);
			origin.y -= 20.;
			[excludePopUpWindow setFrameOrigin:origin];
			excludePopUpWindow.URL = section.URL;
			
			[moreItemsWindow orderOut:nil];
			[excludePopUpWindow orderFront:nil];
			break;
		}
	}
	
	[super mouseMoved:theEvent];
}

- (void)mouseExited:(NSEvent *)theEvent
{
	if (!CGRectContainsPoint(self.bounds, [self convertPoint:theEvent.locationInWindow fromView:self.window.contentView])
		|| !self.window.isKeyWindow) {
		[self dismissAllPopUpWindows];
	}
}

- (void)dismissAllPopUpWindows
{
	[moreItemsWindow orderOut:nil];
	[excludePopUpWindow orderOut:nil];
}

@end


@interface FolderDetailsWindow ()

@property (strong) IBOutlet NSTextField * titleLabel;

@end

@implementation FolderDetailsWindow

@synthesize detailsView = _detailsView;

- (void)reloadWithFolderURLs:(NSArray *)folderURLs
{
	_folderURLs = folderURLs;
	
	if (folderURLs.count > 1) {
		_titleLabel.stringValue = [NSString stringWithFormat:NSLocalizedString(@"%ld folders", nil), (long)folderURLs.count];
	} else if (folderURLs.count == 1) {
		NSURL * sourceURL = folderURLs.firstObject;
		_titleLabel.stringValue = sourceURL.path.lastPathComponent;
	}
	
	NSMutableArray * items = [[NSMutableArray alloc] initWithCapacity:folderURLs.count];
	for (NSURL * folderURL in folderURLs) {
		[items addObjectsFromArray:[FileInformations propertiesForSubItemsAtPath:folderURL.path]];
	}
	_detailsView.items = items;
	
	self.acceptsMouseMovedEvents = YES;
	[self makeFirstResponder:_detailsView];
}

- (void)resignKeyWindow
{
	[_detailsView dismissAllPopUpWindows];
	[super resignKeyWindow];
}

- (IBAction)showInFinderAction:(id)sender
{
#if _SANDBOX_SUPPORTED_
	[_folderURL startAccessingSecurityScopedResource];
#endif
	
	[[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:_folderURLs];
	
#if _SANDBOX_SUPPORTED_
	[_folderURL stopAccessingSecurityScopedResource];
#endif
	
	[NSApp endSheet:self];
	[self orderOut:sender];
}

- (IBAction)okAction:(id)sender
{
	[NSApp endSheet:self];
	[self orderOut:sender];
}

@end

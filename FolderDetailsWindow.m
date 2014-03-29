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

@implementation ItemsListContentView

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
	float radius = 4.;
	float x = dirtyRect.origin.x, y = dirtyRect.origin.y + arrowHeight, width = dirtyRect.size.width, height = dirtyRect.size.height - arrowHeight;
	CGContextBeginPath(context);
	CGContextMoveToPoint(context, x, y + radius);
	CGContextAddArcToPoint(context, x, y, x + radius, y, radius);
	
	CGContextAddLineToPoint(context, x + (width / 2.) + arrowHeight, y);
	CGContextAddLineToPoint(context, x + (width / 2.), 0.);
	CGContextAddLineToPoint(context, x + (width / 2.) - arrowHeight, y);
	
	CGContextAddArcToPoint(context, x + width, y, x + width, y + radius, radius);
	CGContextAddArcToPoint(context, x + width, y + height, x + width - radius, y + height, radius);
	CGContextAddArcToPoint(context, x, y + height, x, y + height - radius, radius);
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

- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag
{
	if ((self = [super initWithContentRect:contentRect styleMask:aStyle backing:bufferingType defer:flag])) {
		
		ItemsListContentView * contentView = [[ItemsListContentView alloc] initWithFrame:contentRect];
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
	
	CGFloat margin = 8.;
	int numberOfLines = 5;// Number max of lines
	
	NSInteger count = (_items.count > (numberOfLines - 1))? (numberOfLines - 1) : _items.count;
	NSArray * itemsToShow = [_items subarrayWithRange:NSMakeRange(0, count)];
	NSMutableAttributedString * attributedString = [[NSMutableAttributedString alloc] init];
	
	NSMutableParagraphStyle * paragrapheStyle = [[NSMutableParagraphStyle alloc] init];
	paragrapheStyle.alignment = NSCenterTextAlignment;
	paragrapheStyle.lineBreakMode = NSLineBreakByTruncatingMiddle;
	
	NSDictionary * boldAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont boldSystemFontOfSize:12.], NSFontAttributeName, [NSColor whiteColor], NSForegroundColorAttributeName, paragrapheStyle, NSParagraphStyleAttributeName, nil];
	NSDictionary * regularAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[NSColor whiteColor], NSForegroundColorAttributeName, paragrapheStyle, NSParagraphStyleAttributeName, nil];
	
	
	int index = 0;
	for (NSDictionary * item in itemsToShow) {
		NSString * filename = [item objectForKey:NSURLNameKey];
		double filesize = [[item objectForKey:NSURLFileSizeKey] doubleValue];
		
		NSMutableAttributedString * string = [[NSMutableAttributedString alloc] init];
		{
			NSAttributedString * attributedFilename = [[NSAttributedString alloc] initWithString:filename attributes:boldAttributes];
			[string appendAttributedString:attributedFilename];
			
			NSString * lineBreakString = @"\n";
			if (index == (itemsToShow.count - 1))// For the last row, don't add the line break
				lineBreakString = @"";
			
			NSAttributedString * attributedFilesize = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@" (%@)%@", [NSString localizedStringForFileSize:filesize], lineBreakString]
																					  attributes:regularAttributes];
			[string appendAttributedString:attributedFilesize];
		}
		[attributedString appendAttributedString:string];
		
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

@implementation FolderDetailsView

@synthesize items = _items;

- (id)initWithFrame:(NSRect)frameRect
{
	if ((self = [super initWithFrame:frameRect])) {
		
		itemsListWindow = [[ItemsListWindow alloc] init];
		itemsListWindow.styleMask = NSBorderlessWindowMask;
		[self.window addChildWindow:itemsListWindow ordered:NSWindowAbove];
		itemsListWindow.level = NSPopUpMenuWindowLevel;
		[itemsListWindow orderFront:nil];
		itemsListWindow.alphaValue = 0.;
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
		
		double fileSize1 = [[(NSDictionary *)obj1 objectForKey:NSURLFileSizeKey] doubleValue];
		double fileSize2 = [[(NSDictionary *)obj2 objectForKey:NSURLFileSizeKey] doubleValue];
		
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
			subarrayItemsSize += [[itemAttributes objectForKey:NSURLFileSizeKey] doubleValue];
		}
		
		NSDictionary * lastItemAttributes = (NSDictionary *)[subarray lastObject];
		double filesize = [[lastItemAttributes objectForKey:NSURLFileSizeKey] doubleValue];
		
		if ((filesize / (float)subarrayItemsSize) < (10. / 90.)) {// Stop when an item represents under of 11,11% (10% on a 90% scale, i.e. 10/90)
			count--;
			return [_items subarrayWithRange:NSMakeRange(0, count)];
		}
	}
	
	return _items;
}

void DrawTextAtPoint(CGContextRef context, const char * string, float x, float y);
void DrawTextAtPoint(CGContextRef context, const char * string, float x, float y)
{
	CGFloat fontHeight = 12.;// 12 pt
	CGContextSelectFont(context, "Helvetica", fontHeight, kCGEncodingMacRoman);
	
	unsigned long length = strlen(string);
	
	CGPoint oldPosition = CGContextGetTextPosition(context);
	CGContextSetTextDrawingMode(context, kCGTextInvisible);// Draw the text invisible to get the position
	CGContextShowTextAtPoint(context, oldPosition.x, oldPosition.y, string, length);
	CGPoint newPosition = CGContextGetTextPosition(context);// Get the position
	
	CGSize textSize = CGSizeMake(newPosition.x - oldPosition.x, newPosition.y - oldPosition.y);
	
	CGFloat textX = x - textSize.width / 2.;
	CGFloat textY = y;
	
	CGContextSetTextDrawingMode(context, kCGTextFill);
	
	CGContextShowTextAtPoint(context, textX, textY, string, length);
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
	
	NSEnumerator * enumerator = [subarray reverseObjectEnumerator];
	NSMutableArray * reverseSubarray = [NSMutableArray arrayWithCapacity:subarray.count];
	
	id object = nil;
	while ((object = enumerator.nextObject)) {
		[reverseSubarray addObject:object];
	}
	
	float current = 0.;
	{
		float size = 0.1;
		CGContextBeginPath(context);
		CGContextAddArc(context, center.x, center.y, (self.frame.size.width - border) / 2., 2 * M_PI * current + M_PI_2, 2 * M_PI * (current + size) + M_PI_2, 0);
		CGContextAddLineToPoint(context, center.x, center.y);
		CGContextClosePath(context);
		
		if (lastSectionPath) CGPathRelease(lastSectionPath);
		lastSectionPath = CGContextCopyPath(context);
		
		[[NSColor colorWithPatternImage:[NSImage imageNamed:@"background-last-group"]] setFill];
		CGContextFillPath(context);
		
		/* Draw the filename label */
		CGFloat offset = MIN(size / 2., 0.333);
		CGFloat radius = (self.frame.size.width / 2.) * (3. / 4. - offset);
		
		CGFloat angle = -(2 * M_PI * current + 2 * M_PI * (size / 2.));
		CGFloat x = center.x + sinf(angle) * radius;
		CGFloat y = center.y + cosf(angle) * radius;
		
		
		NSArray * groupItems = [_items subarrayWithRange:NSMakeRange(subarray.count - 1, _items.count - subarray.count)];
		itemsListWindow.items = groupItems;
		lastSectionLocation = [self convertPointToBase:NSMakePoint(x, y)];
		
		
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
			groupFilesize += [[itemAttributes objectForKey:NSURLFileSizeKey] doubleValue];
		}
		
		textField.stringValue = [NSString stringWithFormat:@"%ld %@\n%@", (_items.count - subarray.count), NSLocalizedString(@"items", nil), [NSString localizedStringForFileSize:groupFilesize]];
		
		[self addSubview:textField];
		
		current += size;
	}
	
	
	double subarrayItemsSize = 0.;
	for (NSDictionary * itemAttributes in subarray) {
		subarrayItemsSize += [[itemAttributes objectForKey:NSURLFileSizeKey] doubleValue];
	}
	
	int index = 0;
	for (NSDictionary * item in reverseSubarray) {
		double fileSize = [[item objectForKey:NSURLFileSizeKey] doubleValue];
		
		float size = fileSize / (float)subarrayItemsSize * 0.9;
		
		CGContextBeginPath(context);
		CGContextAddArc(context, center.x, center.y, (self.frame.size.width - border) / 2., 2 * M_PI * current + M_PI_2, 2 * M_PI * (current + size) + M_PI_2, 0);
		CGContextAddLineToPoint(context, center.x, center.y);
		CGContextClosePath(context);
		
		NSColor * foregroundColor = (index % 2)? [NSColor darkGrayColor] : [NSColor windowBackgroundColor];
		NSColor * backgroundColor = (index % 2)? [NSColor windowBackgroundColor] : [NSColor darkGrayColor];
		
		[backgroundColor setFill];
		CGContextFillPath(context);
		
		/* Draw the filename label */
		
		CGFloat offset = MIN(size / 2., 0.333);
		CGFloat radius = (self.frame.size.width / 2.) * (3. / 4. - offset);
		
		CGFloat angle = -(2 * M_PI * current + 2 * M_PI * (size / 2.));
		CGFloat x = center.x + sinf(angle) * radius;
		CGFloat y = center.y + cosf(angle) * radius;
		
		
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
		[textField setTextColor:foregroundColor];
		
		textField.stringValue = [NSString stringWithFormat:@"%@\n%@", [item objectForKey:NSURLNameKey], [NSString localizedStringForFileSize:fileSize]];
		
		[self addSubview:textField];
		
		[self addToolTipRect:frame owner:self userData:(__bridge void *)([item objectForKey:NSURLNameKey])];
		
		/*
		 CGContextBeginPath(context);
		 CGContextAddArc(context, x, y, r, 0., 2 * M_PI, 0);
		 CGContextClosePath(context);
		 */
		
		CGContextSetLineWidth(context, 3.);
		[[NSColor redColor] setStroke];
		CGContextStrokePath(context);
		
		current += size;
		index++;
	}
}

- (NSString *)view:(NSView *)view stringForToolTip:(NSToolTipTag)tag point:(NSPoint)point userData:(void *)userData
{
	return (__bridge NSString *)userData;
}

- (void)drawRect:(NSRect)dirtyRect
{
	if (_items.count > 0)
		[self update];
}

- (void)mouseMoved:(NSEvent *)theEvent
{
	NSPoint position = theEvent.locationInWindow;
	position = [self convertPointFromBase:position];
	
	if (lastSectionPath) {
		CGContextRef context = [NSGraphicsContext currentContext].graphicsPort;
		CGContextAddPath(context, lastSectionPath);
		
		BOOL contains = (BOOL)CGContextPathContainsPoint(context, NSPointToCGPoint(position), kCGPathFill);
		
		if (contains != intoLastSection) {
			
			if (contains) {
				
				NSPoint origin = [self.window convertBaseToScreen:lastSectionLocation];
				origin.x -= (int)(itemsListWindow.frame.size.width / 2.);
				origin.y -= 20.;
				[itemsListWindow setFrameOrigin:origin];
				
				itemsListWindow.alphaValue = 1.;
			} else {
				itemsListWindow.alphaValue = 0.;
			}
			
			intoLastSection = contains;
		}
	}
	
	[super mouseMoved:theEvent];
}

@end

@implementation FolderDetailsWindow

@synthesize detailsView = _detailsView;

- (void)reloadWithFolderURL:(NSURL *)folderURL
{
	_detailsView.items = [FileInformations propertiesForSubItemsAtPath:folderURL.path];
	[self setAcceptsMouseMovedEvents:YES];
	[self makeFirstResponder:_detailsView];
}

- (IBAction)okAction:(id)sender
{
	[NSApp endSheet:self];
	[self orderOut:sender];
}

@end

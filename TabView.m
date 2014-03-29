//
//  TabView.m
//  CustomTabs
//
//  Created by Maxime on 03/01/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "TabView.h"

@implementation TabItemButton

CGPathRef CreateRoundedPath(CGContextRef context, CGRect rect, float radius);
CGPathRef CreateRoundedPath(CGContextRef context, CGRect rect, float radius)
{
	float x = rect.origin.x, y = rect.origin.y, width = rect.size.width, height = rect.size. height;
	CGContextBeginPath(context);
	CGContextMoveToPoint(context, x, radius);
	CGContextAddArcToPoint(context, x, y, x + radius, y, radius);
	CGContextAddArcToPoint(context, x + width, y, x + width, radius, radius);
	CGContextAddArcToPoint(context, x + width, height + y, x + width - radius, height + y, radius);
	CGContextAddArcToPoint(context, x, height + y, x, height - radius, radius);
	CGContextClosePath(context);
	return CGContextCopyPath(context);
}

void FillRoundedRect(CGContextRef context, CGRect rect, float radius);
void FillRoundedRect(CGContextRef context, CGRect rect, float radius)
{
	CGPathRef path = CreateRoundedPath(context, rect, radius);
	CGContextFillPath(context);
	CGPathRelease(path);
}

- (void)drawRect:(NSRect)dirtyRect
{
	CGContextRef context = [NSGraphicsContext currentContext].graphicsPort;
	float radius = self.frame.size.height / 2.;
	
	NSCell * cell = self.cell;
	if (cell.isHighlighted) {
		
		CGPathRef path = CreateRoundedPath(context, NSRectToCGRect(dirtyRect), radius);
		
		CGContextClip(context);
		CGPathRelease(path);
		
		CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
		CGColorRef startColorRef = CGColorCreateGenericGray(0.333, 1.);
		CGColorRef endColorRef = CGColorCreateGenericGray(0.666, 1.);
		
		CGFloat locations[2] = { 0., 1. };
		
		CGColorRef values[2] = { startColorRef, endColorRef };
		CFArrayRef colors = CFArrayCreate(kCFAllocatorDefault, (const void **)values, 2, NULL);
		
		CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, colors, locations);
		CGColorRelease(startColorRef), CGColorRelease(endColorRef);
		CFRelease(colors);
		CGColorSpaceRelease(colorSpace);
		
		CGContextDrawLinearGradient(context, gradient, CGPointZero, CGPointMake(0., self.frame.size.height), 0);
		CGGradientRelease(gradient);
		
		
		path = CreateRoundedPath(context, NSRectToCGRect(dirtyRect), radius);
		[[NSColor darkGrayColor] setStroke];
		CGContextSetLineWidth(context, 2.);
		CGContextStrokePath(context);
		CGPathRelease(path);
		
		
	} else if ([cell state] == NSOnState) {
		
		CGPathRef path = CreateRoundedPath(context, NSRectToCGRect(dirtyRect), radius);
		
		CGContextClip(context);
		CGPathRelease(path);
		
		CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
		CGColorRef startColorRef = CGColorCreateGenericGray(0.75, 1.);
		CGColorRef endColorRef = CGColorCreateGenericGray(0.85, 1.);
		
		CGFloat locations[2] = { 0., 1. };
		
		CGColorRef values[2] = { startColorRef, endColorRef };
		CFArrayRef colors = CFArrayCreate(kCFAllocatorDefault, (const void **)values, 2, NULL);
		
		CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, colors, locations);
		CGColorRelease(startColorRef), CGColorRelease(endColorRef);
		CFRelease(colors);
		CGColorSpaceRelease(colorSpace);
		
		CGContextDrawLinearGradient(context, gradient, CGPointZero, CGPointMake(0., self.frame.size.height), 0);
		CGGradientRelease(gradient);
		
		
		path = CreateRoundedPath(context, NSRectToCGRect(dirtyRect), radius);
		[[NSColor lightGrayColor] setStroke];
		CGContextSetLineWidth(context, 2.);
		CGContextStrokePath(context);
		CGPathRelease(path);
		
	} else {
	}
	
	/* Add shadow on text */
	NSShadow * shadow = [[NSShadow alloc] init];
	shadow.shadowColor = (cell.isHighlighted)? [NSColor colorWithDeviceWhite:0. alpha:0.5] : [NSColor whiteColor];
	shadow.shadowBlurRadius = 0.;
	shadow.shadowOffset = NSMakeSize(0., -1.);
	[shadow set];
	
	/* Set the color of the title (dark gray for normal state, white when highlighted) */
	NSColor * textColor = (cell.isHighlighted)? [NSColor whiteColor] : [NSColor colorWithCalibratedWhite:0.1 alpha:1.];
	[textColor setFill];
	
	CGContextSetTextMatrix(context, CGAffineTransformMakeScale(1., -1.));// Flip the text from the actual not flipped view setting (flipping by the y axis)
	
	CGFloat fontHeight = 12.;// 12 pt
	CGContextSelectFont(context, "Helvetica-Bold", fontHeight, kCGEncodingMacRoman);
	
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
	
	// @TODO: draw the two arrows here (near the title)
	// @TODO: add "popupTarget" and "popupAction" to fire the target when clicking on arrows
}

@end


@implementation TabItemPopupButton

- (void)drawRect:(NSRect)dirtyRect
{
	CGContextRef context = [NSGraphicsContext currentContext].graphicsPort;
	
	CGContextSetTextMatrix(context, CGAffineTransformMakeScale(1., -1.));
	//if ([(NSCell *)self.cell isHighlighted]) CGContextSetAlpha(context, 0.8);
	CGContextDrawImage(context, NSRectToCGRect(dirtyRect), [[NSImage imageNamed:@"popup-button"] CGImageForProposedRect:NULL
																								context:[NSGraphicsContext currentContext]
																								  hints:nil]);
}

@end


@implementation TabItem

@synthesize title = _title;
@synthesize menu = _menu;
@synthesize width = _width;

+ (id)itemWithTitle:(NSString *)title
{
	TabItem * item = [[TabItem alloc] initWithTitle:title];
	return item;
}

+ (id)itemWithMenu:(NSMenu *)menu
{
	TabItem * item = [[TabItem alloc] initWithMenu:menu];
	return item;
}

+ (id)itemWithMenu:(NSMenu *)menu selectedIndex:(NSInteger)index
{
	TabItem * item = [[TabItem alloc] initWithMenu:menu selectedIndex:index];
	return item;
}


- (id)initWithTitle:(NSString *)title
{
	if ((self = [super init])) {
		_title = [title copy];
		
		[self invalidateLayout];
	}
	return self;
}

- (id)initWithMenu:(NSMenu *)menu
{
	if ((self = [super init])) {
		_title = [[menu itemAtIndex:0].title copy];
		_menu = [menu copy];
		
		[self invalidateLayout];
	}
	return self;
}

- (id)initWithMenu:(NSMenu *)menu selectedIndex:(NSInteger)index
{
	if ((self = [super init])) {
		_title = [[menu itemAtIndex:index].title copy];
		_menu = [menu copy];
		
		[self invalidateLayout];
	}
	return self;
}

- (void)invalidateLayout
{
	CGFloat buttonMargin = 18.;
	
	if (_menu) {
		for (NSMenuItem * menuItem in _menu.itemArray) {
			CGFloat width = [menuItem.title sizeWithAttributes:nil].width + (2 * buttonMargin);
			if (width > _width) _width = width;
		}
	} else {
		_width = [_title sizeWithAttributes:nil].width + (2 * buttonMargin);
	}
}

@end


@implementation TabView

@synthesize items = _items;
@synthesize delegate = _delegate;

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)setItems:(NSArray *)items
{
	_items = [items copy];
	
	[self invalidateLayout];
	
	TabItemButton * itemButton = [buttons objectAtIndex:0];
	if (selectedButton != itemButton) {
		itemButton.state = NSOffState;
		selectedButton = itemButton;
	}
	
	selectedButton.state = NSOnState;
}

- (void)invalidateLayout
{
	/* Remove all subviews */
	NSArray * subviewsCopy = self.subviews.mutableCopy;
	for (NSView * subview in subviewsCopy)
		[subview removeFromSuperview];
	
	CGFloat margin = 10.;
	CGFloat bottomMargin = (int)((self.frame.size.height - 20.) / 2.);
	
	CGFloat totalWidth = 0;
	int index = 0;
	for (TabItem * item in _items) {
		totalWidth += item.width;
	}
	totalWidth += (_items.count - 1) * margin;
	CGFloat leftMargin = (int)((self.frame.size.width - totalWidth) / 2.);
	if (leftMargin < 0.) leftMargin = 0.;// clip to zero
	
	NSMutableArray * mutableButtons = [[NSMutableArray alloc] initWithCapacity:_items.count];
	
	CGFloat currentX = leftMargin;
	index = 0;
	for (TabItem * item in _items) {
		
		CGFloat width = item.width;
		
		NSRect frame = NSMakeRect(currentX, bottomMargin, width, 20.);
		TabItemButton * button = [[TabItemButton alloc] initWithFrame:frame];
		button.tag = index;
		button.title = item.title;
		button.target = self;
		button.action = @selector(tabDidSelectedAction:);
		[self addSubview:button];
		[mutableButtons addObject:button];
		
		if (item.menu) {
			NSRect rect = NSMakeRect(7., 4., 7., 12.);
			TabItemPopupButton * popupButton = [[TabItemPopupButton alloc] initWithFrame:rect];
			popupButton.tag = index;
			popupButton.target = self;
			popupButton.action = @selector(popupButtonMenuDidSelectedAction:);
			[button addSubview:popupButton];
		}
		
		
		currentX += width + margin;
		index++;
	}
	
	buttons = (NSArray *)mutableButtons;
	
	[self setNeedsDisplay:YES];
}

- (void)updateLayout
{
	CGFloat totalWidth = 0., margin = 10.;
	for (TabItemButton * button in buttons) {
		totalWidth += button.frame.size.width;
	}
	totalWidth += (buttons.count - 1) * margin;
	CGFloat leftMargin = (int)((self.frame.size.width - totalWidth) / 2.);
	if (leftMargin < 0.) leftMargin = 0.;// clip to zero
	
	CGFloat currentX = leftMargin;
	for (TabItemButton * button in buttons) {
		
		NSRect frame = button.frame;
		frame.origin.x = currentX;
		button.frame = frame;
		
		currentX += button.frame.size.width + margin;
	}
}

- (IBAction)popupButtonMenuDidSelectedAction:(id)sender
{
	NSButton * button = (NSButton *)sender;
	
	NSInteger index = button.tag;
	NSMenu * menu = [(TabItem *)[_items objectAtIndex:index] menu];
	
	NSMenuItem * onItem = nil;
	for (NSMenuItem * item in menu.itemArray) {
		item.target = self;
		item.action = @selector(tabItemMenuDidSelected:);
		
		if (item.state == NSOnState) { onItem = item; };
	}
	if (!onItem) {
		onItem = [menu itemAtIndex:0];
		onItem.state = NSOnState;
	}
	
	NSRect frame = button.superview.frame;
	[menu popUpMenuPositioningItem:onItem
						atLocation:NSMakePoint(frame.origin.x, frame.origin.y + frame.size.height)
							inView:self];
}

- (IBAction)tabItemMenuDidSelected:(id)sender
{
	NSMenuItem * menuItem = (NSMenuItem *)sender;
	
	NSInteger selectedItem = -1, index = 0;
	for (TabItem * item in _items) {
		if (item.menu == menuItem.menu) { selectedItem = index; break; }
		index++;
	}
	
	if (selectedItem == -1)
		return ;
	
	for (NSMenuItem * item in menuItem.menu.itemArray) {
		item.state = NSOffState;
	}
	menuItem.state = NSOnState;
	
	TabItemButton * itemButton = [buttons objectAtIndex:selectedItem];
	itemButton.title = menuItem.title;
	[self tabDidSelectedAction:itemButton];// Select the item from the menu
	
	if ([self.delegate respondsToSelector:@selector(tabView:didSelectMenuItem:fromItem:)]) {
		TabItem * item = [_items objectAtIndex:selectedItem];
		[self.delegate tabView:self didSelectMenuItem:menuItem fromItem:item];
	}
}

- (IBAction)tabDidSelectedAction:(id)sender
{
	if (selectedButton != sender) {
		selectedButton.state = NSOffState;
		
		selectedButton = (NSButton *)sender;
	}
	
	selectedButton.state = NSOnState;
	
	if ([self.delegate respondsToSelector:@selector(tabView:didSelectItem:)])
		[self.delegate tabView:self didSelectItem:[_items objectAtIndex:((NSButton *)sender).tag]];
}

- (void)setFrame:(NSRect)frameRect
{
	[super setFrame:frameRect];
	
	[self updateLayout];
}

@end

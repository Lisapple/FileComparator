//
//  GridView.m
//  GridView
//
//  Created by Max on 18/03/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "GridView.h"

@implementation SelectionView

- (void)drawRect:(NSRect)dirtyRect
{
	CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
	
	[[NSColor colorWithCalibratedWhite:0.5 alpha:1.] setStroke];
	CGContextSetLineWidth(context, 1.);
	CGContextStrokeRect(context, NSRectToCGRect(self.bounds));
	
	[[NSColor colorWithCalibratedWhite:1. alpha:0.3] setFill];
	CGContextFillRect(context, NSRectToCGRect(self.bounds));
}

@end

@implementation GridItem

@synthesize title, image;

@synthesize itemView;

@synthesize info;

@synthesize selected = _selected, deleted = _deleted, isOriginal = _isOriginal, becameAlias = _becameAlias, isGroup = _isGroup;
@synthesize visible = _visible;

@synthesize frame;

@synthesize labelColor = _labelColor;

- (instancetype)init
{
	if ((self = [super init])) {
		info = [[NSMutableDictionary alloc] initWithCapacity:3];
	}
	
	return self;
}

- (void)setIsGroup:(BOOL)isGroup
{
	_isGroup = isGroup;
}

- (id)copyWithZone:(NSZone *)zone
{
	GridItem * newItem = [[GridItem allocWithZone:zone] init];
	newItem.title = self.title;
	newItem.image = self.image;
	
	newItem.selected = self.selected;
	newItem.deleted = self.deleted;
	newItem.isOriginal = self.isOriginal;
	newItem.becameAlias = self.becameAlias;
	
	newItem.isGroup = self.isGroup;
	
	newItem.visible = self.visible;
	
	[newItem.info addEntriesFromDictionary:self.info];
	
	return newItem;
}

- (void)setItemView:(GridItemView *)anItemView
{
	itemView = anItemView;
	
	if (!anItemView) _visible = NO;
}

- (void)setImage:(NSImage *)anImage
{
	image = anImage;
	
	dispatch_async(dispatch_get_main_queue(), ^{ self.itemView.image = image; });
}

- (void)setLabelColor:(NSColor *)labelColor
{
	_labelColor = labelColor;
	
	dispatch_async(dispatch_get_main_queue(), ^{ self.itemView.labelColor = labelColor; });
}

- (void)reload
{
	dispatch_async(dispatch_get_main_queue(), ^{
		if (self.labelColor)
			self.itemView.labelColor = self.labelColor;
		
		self.itemView.selected = self.selected;
		self.itemView.isOriginal = self.isOriginal;
		
		self.itemView.isGroup = self.isGroup;
	});
}

- (void)setSelected:(BOOL)selected
{
	_selected = selected;
	dispatch_async(dispatch_get_main_queue(), ^{ self.itemView.selected = selected; });
}

@end


@interface GridView (PrivateMethods)

- (void)update;
- (NSRect)frameForItemAtRow:(int)row column:(int)column section:(NSInteger)section;

@end


@implementation GridView

@synthesize delegate, dataSource;

@synthesize headerView;

@synthesize placeholder;

NSRect RectPositive(NSRect aRect);
NSRect RectPositive(NSRect aRect)
{
	NSRect rect = aRect;
	if (rect.size.width < 0.) {
		rect.size.width = ABS(rect.size.width);
		rect.origin.x -= rect.size.width;
	}
	
	if (rect.size.height < 0.) {
		rect.size.height = ABS(rect.size.height);
		rect.origin.y -= rect.size.height;
	}
	
	return rect;
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
	if ((self = [super initWithCoder:decoder])) {
		topMargin = 20.;
		itemsPerRow = 3;
		itemWidth = 110;
		
		selectionView = [[SelectionView alloc] initWithFrame:NSZeroRect];
		[self addSubview:selectionView];
		
		_reusableItems = [[NSMutableArray alloc] initWithCapacity:10];
	}
	
	return self;
}

- (BOOL)isFlipped
{
	return YES;
}

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
	return YES;
}

- (void)setHeaderView:(NSView *)aView
{
	if (aView != headerView) {
		[headerView removeFromSuperview];
		
		headerView = aView;
		
		
		NSRect frame = headerView.frame;
		frame.size.width = ((NSView *)self.documentView).frame.size.width;
		frame.origin.x = 0.;
		frame.origin.y = 0.;
		headerView.frame = frame;
		
		headerView.autoresizingMask = (NSViewMaxYMargin | NSViewWidthSizable);
		
		[self.contentView addSubview:headerView];
	}
	
	[headerView setHidden:(aView == nil)];
}

- (void)setPlaceholder:(NSString *)string
{
	placeholder = string;
	
	NSRect frame = self.bounds;
	frame.origin.y = (int)((frame.size.height - 30.) / 2.);
	frame.size.height = 30.;
	
	if (string.length > 0) {
		
		if (!placeholderLabel) {
			placeholderLabel = [[PlaceholderLabel alloc] initWithFrame:frame];
			[self addSubview:placeholderLabel];
		}
		
		placeholderLabel.title = string;
	}
	
	placeholderLabel.frame = frame;
	[placeholderLabel setHidden:!(string && string.length > 0)];
}

- (BOOL)itemIsVisible:(GridItem *)item
{
	/* Compute the offset of the scrollView */
	NSRect frame = self.frame;
	NSPoint offset = [[self contentView] bounds].origin;
	frame = NSOffsetRect(frame, offset.x, offset.y);
	
	return NSIntersectsRect(frame, item.itemView.frame);
}

- (NSArray *)itemsForSection:(NSInteger)section
{
	NSArray * itemsViews = _itemsSection[section];
	NSMutableArray * items = [NSMutableArray arrayWithCapacity:itemsViews.count];
	for (GridItemView * itemView in itemsViews) {
		if (itemView.item)
			[items addObject:itemView.item];
	}
	
	return items;
}

- (void)unselectAll
{
	[self deselectAll];
}

- (void)selectAll
{
	NSMutableArray * allSelectedItems = [[NSMutableArray alloc] initWithCapacity:100];
	
	for (int section = 0; section < numberOfSections; section++) {
		NSArray * sectionItems = allItemsArrays[section];
		for (GridItem * item in sectionItems) {
			item.selected = YES;
			
			/* Add items to "selectedItems" array */
			[allSelectedItems addObject:item];
		}
	}
	
	selectedItems = allSelectedItems;
}

- (void)deselectAll
{
	for (int section = 0; section < numberOfSections; section++) {
		NSArray * sectionItems = allItemsArrays[section];
		for (GridItem * item in sectionItems) {
			item.selected = NO;
		}
	}
	
	/* Clear selectedItems array */
	[selectedItems removeAllObjects];
}

- (void)deselectFirstItem
{
	int count = 0;
	for (int section = 0; section < numberOfSections; section++) {
		NSArray * sectionItems = allItemsArrays[section];
		for (GridItem * item in sectionItems) {
			if (count > 0) {
				item.selected = NO;
				[selectedItems removeObject:item];
			}
			count++;
		}
	}
}

- (void)selectAllNonOriginalsItems
{
	for (int section = 0; section < numberOfSections; section++) {
		NSArray * sectionItems = allItemsArrays[section];
		for (GridItem * item in sectionItems) {
			if (item.isOriginal) {
				item.selected = NO;
				[selectedItems removeObject:item];
			} else {
				item.selected = YES;
			}
		}
	}
}

- (GridItem *)selectedItem
{
	return selectedItems.firstObject;
}

- (NSArray *)selectedItems
{
	return selectedItems;
}

- (void)selectItems:(NSArray *)items
{
	for (GridItem * item in items) {
		item.selected = YES;
		[item reload];
	}
}

- (void)unselectItems:(NSArray *)items
{
	for (GridItem * item in items) {
		item.selected = NO;
		[item reload];
	}
	
	[selectedItems removeObjectsInArray:items];
}

- (void)unselectOriginalItem
{
	for (int section = 0; section < numberOfSections; section++) {
		
		NSArray * itemsViews = _itemsSection[section];
		for (GridItemView * itemView in itemsViews) {
			if (itemView.isOriginal) {
				itemView.selected = NO;
				
				/* Remove from selected items the original item */
				[selectedItems removeObject:itemView.item];
				break;
			}
		}
	}
}

- (void)deleteItems:(NSArray *)items
{
	for (GridItem * item in items) {
		item.deleted = YES;
		[item reload];
	}
}

- (void)undeleteItems:(NSArray *)items
{
	for (GridItem * item in items) {
		item.deleted = NO;
		[item reload];
	}
}

- (NSArray *)gridItems
{
	NSMutableArray * allItems = [NSMutableArray arrayWithCapacity:100];
	for (int section = 0; section < numberOfSections; section++) {
		NSArray * items= allItemsArrays[section];
		for (GridItem * item in items) {
			[allItems addObject:item];
		}
	}
	return allItems;
}

- (NSArray *)gridItemsViews
{
	NSMutableArray * itemsViews = [NSMutableArray arrayWithCapacity:100];
	for (int section = 0; section < numberOfSections; section++) {
		[itemsViews addObjectsFromArray:_itemsSection[section]];
	}
	return itemsViews;
}

- (void)reloadData
{
	/* Fetch items from the data source */
	
	[_reusableItems removeAllObjects];
	
	numberOfSections = [dataSource numberOfSectionsInGridView:self];
	
	BOOL showPlaceholder = YES;
	allItemsArrays = [[NSMutableArray alloc] initWithCapacity:numberOfSections];
	for (int section = 0; section < numberOfSections; section++) {
		NSArray * allSectionItems = [dataSource gridView:self itemsForSection:section];
		if (allSectionItems.count > 0) {
			[allItemsArrays addObject:allSectionItems];
			showPlaceholder = NO;
		} else {
			[allItemsArrays addObject:@[]];
		}
	}
	
	if (showPlaceholder)// If we show the placeholder, set the number of section to zero
		numberOfSections = 0;
	
	/* Remove all GridItems */
	NSArray * subviewCopy = [[self.documentView subviews] copy];
	for (NSView * subview in subviewCopy) {
		if ([subview isKindOfClass:[GridItemView class]]) {
			[subview removeFromSuperview];
		}
	}
	
	NSArray * sectionTitles = [dataSource titlesForSectionsInGridView:self];
	_sectionTitles = [[NSArray alloc] initWithArray:sectionTitles copyItems:YES];
	
	/* If we don't have content, show the placeholder */
	if (showPlaceholder) {
		self.placeholder = [dataSource placeholderInGridView:self];
		
		NSSize size = ((NSView *)self.documentView).frame.size;
		size.height = 380.;
		[self.documentView setFrameSize:size];
		return;
	} else {
		self.placeholder = nil;
	}
	
	for (int section = 0; section < numberOfSections; section++) {
		int index = 0;
		NSArray * items = (NSArray *)allItemsArrays[section];
		for (GridItem * item in items) {
			
			int col = (index % itemsPerRow);
			int row = (index / itemsPerRow);
			CGRect frame = NSRectToCGRect([self frameForItemAtRow:row column:col section:section]);
			frame.size = CGSizeMake(80., 80.);
			item.frame = frame;
			index++;
		}
		
		/*
		 NSString * title = [_sectionTitles objectAtIndex:section];
		 
		 // Shadows
		 NSTextField * sectionShadow = [[NSTextField alloc] initWithFrame:NSZeroRect];
		 [sectionShadow setEditable:NO];
		 [sectionShadow setBordered:NO];
		 sectionShadow.backgroundColor = self.backgroundColor;
		 sectionShadow.font = [NSFont boldSystemFontOfSize:18.];
		 sectionShadow.textColor = [NSColor colorWithCalibratedWhite:0.333 alpha:0.666];
		 
		 [sectionShadow setStringValue:title];
		 
		 [sectionTitlesShadows addObject:sectionShadow];
		 [self.documentView addSubview:sectionShadow];
		 [sectionShadow release];
		 
		 // Labels
		 NSTextField * sectionLabel = [[NSTextField alloc] initWithFrame:NSZeroRect];
		 [sectionLabel setEditable:NO];
		 [sectionLabel setBordered:NO];
		 sectionLabel.backgroundColor = self.backgroundColor;
		 sectionLabel.font = [NSFont boldSystemFontOfSize:18.];
		 sectionLabel.textColor = [NSColor colorWithCalibratedWhite:0.75 alpha:1.];
		 
		 [sectionLabel setStringValue:title];
		 
		 [sectionTitlesViews addObject:sectionLabel];
		 [self.documentView addSubview:sectionLabel];
		 [sectionLabel release];
		 */
	}
	
	/*
	 [_sectionTitlesViews release];
	 _sectionTitlesViews = sectionTitlesViews;
	 
	 [_sectionTitlesViews release];
	 _sectionTitlesShadows = sectionTitlesShadows;
	 */
	
	NSInteger count = selectedItems.count;
	[selectedItems removeAllObjects];
	if (count > 0) {
		if ([delegate respondsToSelector:@selector(gridViewSelectionDidChange:)]) {
			[delegate gridViewSelectionDidChange:self];
		}
	}
	
	[self update];
	[self reflectScrolledClipView:self.contentView];// Force items position
}

- (NSSize)sizeForSection:(NSInteger)section
{
	NSArray * items = _itemsSection[section];
	int numberOfRows = (int)ceilf(items.count / (float)itemsPerRow);
	
	NSSize viewSize = ((GridItemView *)items.firstObject).frame.size;
	
#define kSectionTitleHeight 40.
	float height = numberOfRows * (viewSize.height + 20.) + 2. * topMargin + kSectionTitleHeight;
	
	return NSMakeSize(self.frame.size.width, height);
}

- (NSRect)frameForItemAtRow:(int)row column:(int)column section:(NSInteger)section
{
	CGFloat headerHeight = self.headerView.frame.size.height;
	
	NSSize size = ((NSView *)self.documentView).frame.size;
	
	float separator = (int)(size.width - itemsPerRow * itemWidth) / itemsPerRow;
	separator = ((separator * itemsPerRow) - (separator / 2.)) / itemsPerRow;
	
	int width = itemWidth + (separator / 2.);
	
	float height = 0.;
	for (int i = 0; i < section; i++) {
		NSSize size = [self sizeForSection:i];
		height += size.height;
	}
	
#define kSectionTitleHeight 40.
	return NSMakeRect((int)((separator / 2.) + itemWidth * column + separator * column),
					  (int)(headerHeight + height + (itemWidth + 20.) * row + topMargin + kSectionTitleHeight),
					  (int)width, (int)itemWidth);
}

- (void)reflectScrolledClipView:(NSClipView *)aClipView
{
	[super reflectScrolledClipView:aClipView];
	
	/*** Using "GridItem" protocol as datasource ***/
	/*	- Create a range with the first itemView shown and the number of shown itemViews
	 *	- Reckon the frame of all the next itemViews (with the number of items as limit)...
	 *	- ...If an hidden itemView is going to be visible (hidden before the scroll, visible after), ask the datasource to get the item (of type "id <GridItem>")...
	 *	- ...Get a free itemView (or create it if no itemViews free), add it to documentView and set the itemView with the protocol of the item
	 */
	
	/* Compute the offset of the scrollView */
	NSRect frame = self.frame;
	NSPoint offset = self.contentView.bounds.origin;
	frame = NSOffsetRect(frame, offset.x, offset.y);
	
	for (int section = 0; section < numberOfSections; section++) {
		NSArray * items = (NSArray *)allItemsArrays[section];
		for (GridItem * item in items) {
			
			NSRect rect = NSRectFromCGRect(item.frame);
			BOOL isVisible = NSIntersectsRect(frame, rect);
			
			if (isVisible != item.isVisible) {// Compare the new item visibility with the old one (from the isVisible value of the item)
				
				if (isVisible == YES) {// If the item is going to be visible
					
					GridItemView * itemView = nil;
					if (_reusableItems.count > 0) {// If we can re-use view, re-show it
						itemView = _reusableItems.firstObject;
						
						[itemView setHidden:NO];// View was hidden, re-show it
						[_reusableItems removeObjectAtIndex:0];
						
						itemView.frame = rect;
						
					} else {// Else, re-create a view
						itemView = [[GridItemView alloc] initWithFrame:rect];
						[self.documentView addSubview:itemView];
					}
					
					itemView.item = item;
					item.itemView = itemView;
					
				} else {// If the item is going to be hidden
					GridItemView * view = item.itemView;
					[view setHidden:YES];// Hide the view, we don't need it now
					[_reusableItems addObject:view];// And keep it to re-use it
					item.itemView = nil;
				}
				item.visible = isVisible;
			}
		}
	}
}

- (void)update
{
	NSSize size = ((NSView *)self.documentView).frame.size;
	
	float separator = (int)(size.width - itemsPerRow * itemWidth) / itemsPerRow;
	separator = ((separator * itemsPerRow) - (separator / 2.)) / itemsPerRow;
	
	float separatorMin = 40.;// 20px minimum beetween two items
	float remainingSpace = size.width - (itemsPerRow * itemWidth + itemsPerRow * separatorMin + (separator / 2.));
	if (remainingSpace >= (2 * separatorMin + itemWidth)) {
		itemsPerRow++;
		[self update];
		return;
	} else if (remainingSpace < separatorMin) {
		if (itemsPerRow > 1) {
			itemsPerRow--;
			[self update];
			return;
		}
	}
	
#define kSectionTitleHeight 40.
	
	NSSize viewSize = NSMakeSize(80., 80.);
	
	float newHeight = 0.;
	for (int section = 0; section < numberOfSections; section++) {
		
		/*
		 // @TODO: remove section titles
		 NSTextField * sectionLabel = [_sectionTitlesViews objectAtIndex:section];
		 NSRect frame = NSMakeRect(20., newHeight + 10., size.width - 40., 30.);
		 sectionLabel.frame = frame;
		 
		 NSTextField * sectionShadow = [_sectionTitlesShadows objectAtIndex:section];
		 frame = NSMakeRect(20., newHeight + 8., size.width - 40., 30.);
		 sectionShadow.frame = frame;
		 */
		
		float sectionTopMargin = topMargin;
		/* If the header view is shown, add margin on top */
		if (headerView && headerView.isHidden == NO)
			sectionTopMargin += headerView.frame.size.height;
		
		if (((NSString *)_sectionTitles[section]).length > 0) {
			sectionTopMargin += kSectionTitleHeight;
		}
		
		NSInteger count = 0;
		
		if (allItemsArrays.count > section) {
			NSArray * items = allItemsArrays[section];
			count = items.count;
			
			int index = 0;
			for (GridItem * item in items) {
				
				int col = (index % itemsPerRow);
				int row = (index / itemsPerRow);
				
				/* Compute the new frame value */
				int width = itemWidth + (separator / 2.);
				NSRect frame = NSMakeRect((int)((separator / 2.) + itemWidth * col + separator * col), (int)(newHeight + (viewSize.height + 20.) * row + sectionTopMargin), (int)width, (int)itemWidth);
				item.frame = NSRectToCGRect(frame);
				
				if (item.itemView) item.itemView.frame = frame;
				
				index++;
			}
		}
		
		int numberOfRows = (int)ceilf(count / (float)itemsPerRow);
		newHeight += numberOfRows * (viewSize.height + 20.) + 2. * sectionTopMargin;// Add to margin (from topMargin) at the top and the bottom
	}
	
	/* Fix the height of the inner scroll view */
	[self.documentView setFrameSize:NSMakeSize(size.width, newHeight)];
}

- (void)setItemsSize:(int)pixels
{
	itemWidth = pixels;
	
	[self update];
}

- (void)setFrameSize:(NSSize)newSize
{
	NSRect frame = placeholderLabel.frame;
	frame.size.width = newSize.width;
	frame.origin.y = (int)((newSize.height - frame.size.height) / 2.);
	placeholderLabel.frame = frame;
	
	[super setFrameSize:newSize];
	
	[self update];
}

- (void)mouseDown:(NSEvent *)theEvent
{
	selectionView.frame = NSZeroRect;
	
	NSPoint aPoint = [theEvent locationInWindow];
	NSPoint point = [[[NSApp mainWindow] contentView] convertPoint:aPoint toView:self];
	
	NSPoint offset = [[self contentView] bounds].origin;
	point.x += offset.x;
	point.y += offset.y;
	
	_startMouseDownPosition = point;
	
	if (!selectedItems)
		selectedItems = [[NSMutableArray alloc] initWithCapacity:5];
	
	if (!([NSEvent modifierFlags] & NSCommandKeyMask)) {
		selectedItems = [[NSMutableArray alloc] initWithCapacity:5];
	}
	
	for (GridItem * item in selectedItems) {
		item.selected = NO;
		[item reload];
	}
	
	for (int section = 0; section < numberOfSections; section++) {
		
		int index = 0;
		for (GridItem * item in (NSArray *)allItemsArrays[section]) {
			if (NSPointInRect(point, item.itemView.hitFrame)) {
				
				[selectedItems addObject:item];
				
				NSInteger clickCount = [theEvent clickCount];
				if (clickCount == 1) {
					
					if (![selectedItems isEqualToArray:_oldSelectedItems]) {
						
						if ([delegate respondsToSelector:@selector(gridView:didSelectItems:indexPaths:)]) {
							[delegate gridView:self didSelectItems:selectedItems indexPaths:nil];
						}
						
						if ([delegate respondsToSelector:@selector(gridViewSelectionDidChange:)]) {
							[delegate gridViewSelectionDidChange:self];
						}
					}
					
				} else {
					if ([delegate respondsToSelector:@selector(gridView:didDoubleClickOnItem:indexPath:)]) {
						NSUInteger indexes[2] = { section, index };
						NSIndexPath * indexPath = [NSIndexPath indexPathWithIndexes:indexes length:2];
						[delegate gridView:self didDoubleClickOnItem:item indexPath:indexPath];
					}
				}
				
				_oldSelectedItems = [selectedItems copy];
				
			} else {
				item.selected = NO;
			}
			
			index++;
		}
	}
	
	if (selectedItems.count == 0) {
		if ([delegate respondsToSelector:@selector(gridViewSelectionDidChange:)]) {
			[delegate gridViewSelectionDidChange:self];
		}
		
		_oldItemView = nil;
		_oldSelectedItems = nil;
	} else {
		for (GridItem * item in selectedItems) {
			item.selected = YES;
			[item reload];
		}
	}
	
	[self setNeedsDisplay:YES];
}

- (void)mouseExited:(NSEvent *)theEvent
{
	NSDebugLog(@"mouseExited:");
}

- (void)mouseDragged:(NSEvent *)theEvent
{
	// @TODO: fix autoscroll
	/* Autoscroll if cursor go out of the view */
	[self setScrollsDynamically:YES];
	[[self contentView] autoscroll:theEvent];
	
	NSPoint aPoint = [theEvent locationInWindow];
	NSPoint point = [[[NSApp mainWindow] contentView] convertPoint:aPoint toView:self];
	
	NSPoint offset = [[self contentView] bounds].origin;
	point.x += offset.x;
	point.y += offset.y;
	
	selectionRect = RectPositive(NSMakeRect(_startMouseDownPosition.x, _startMouseDownPosition.y, point.x - _startMouseDownPosition.x, point.y - _startMouseDownPosition.y));
	/* Clip the minimum size of the selection frame to 1px to not see it disapper */
	selectionRect.size.width = (selectionRect.size.width == 0)? 1.: selectionRect.size.width;
	selectionRect.size.height = (selectionRect.size.height == 0)? 1.: selectionRect.size.height;
	selectionView.frame = NSOffsetRect(selectionRect, -offset.x, -offset.y);
	
	NSMutableArray * allSelectedItems = [[NSMutableArray alloc] initWithCapacity:10];
	NSMutableArray * indexPaths = [[NSMutableArray alloc] initWithCapacity:10];
	
	/* Selection items into selection rect */
	for (int section = 0; section < numberOfSections; section++) {
		int index = 0;
		for (GridItem * item in (NSArray *)allItemsArrays[section]) {
			NSRect sectionRect = NSIntersectionRect(selectionRect, item.itemView.hitFrame);
			if (sectionRect.size.width > 0. && sectionRect.size.height > 0.) {
				[allSelectedItems addObject:item];
				
				NSUInteger indexes[2] = { section, index };
				NSIndexPath * indexPath = [[NSIndexPath alloc] initWithIndexes:indexes length:2];
				[indexPaths addObject:indexPath];
				
				item.selected = YES;
			} else {
				item.selected = NO;
			}
			index++;
		}
	}
	
	BOOL hasChanges = (![selectedItems isEqualToArray:allSelectedItems]);
	selectedItems = allSelectedItems;
	
	if (hasChanges) {
		if (allSelectedItems.count > 0) {
			if ([delegate respondsToSelector:@selector(gridView:didSelectItems:indexPaths:)]) {
				[delegate gridView:self didSelectItems:allSelectedItems indexPaths:indexPaths];
			}
		}
		
		if ([delegate respondsToSelector:@selector(gridViewSelectionDidChange:)]) {
			[delegate gridViewSelectionDidChange:self];
		}
	}
	
}

- (void)mouseUp:(NSEvent *)theEvent
{
	selectionView.frame = NSZeroRect;
}

- (void)rightMouseDown:(NSEvent *)theEvent
{
	NSPoint aPoint = [theEvent locationInWindow];
	NSPoint point = [[[NSApp mainWindow] contentView] convertPoint:aPoint toView:self];
	
	NSPoint offset = [[self contentView] bounds].origin;
	point.x += offset.x;
	point.y += offset.y;
	
	BOOL containsSelectedItem = NO;
	for (GridItem * item in selectedItems) {
		NSRect sectionRect = NSIntersectionRect(selectionRect, item.itemView.hitFrame);
		if (sectionRect.size.width > 0. && sectionRect.size.height > 0.) { containsSelectedItem = YES; break; }
	}
	
	if (!containsSelectedItem) {// If we have only one item or no items, re-get the selection
		[self mouseDown:theEvent];
	}
	
	if ([delegate respondsToSelector:@selector(menuForGridView:selectedItems:)]) {
		NSMenu * menu = [delegate menuForGridView:self selectedItems:selectedItems];
		
		if (menu) {
			NSPoint location = [[[NSApp mainWindow] contentView] convertPoint:[theEvent locationInWindow]
																	   toView:self];
			[menu popUpMenuPositioningItem:nil
								atLocation:location
									inView:self];
		}
	}
}

#pragma mark - Key Event

- (BOOL)performKeyEquivalent:(NSEvent *)theEvent
{
	/* Get the index path of the selected cell
	 * Increment (Down) or decrement (Up) the row part of the indexPath
	 * Check if the new selected cell can be selected or if this is the last row of the section, in this case, jump to the next selectable cell
	 */
	
	/* @FIXME: "performKeyEquivalent" is called many times (2-3 times per key pressed)
	 if (theEvent.charactersIgnoringModifiers.length == 1) {
	 unichar keyChar = [theEvent.charactersIgnoringModifiers characterAtIndex:0];
	 NSInteger offset = 0;
	 
	 if (keyChar == NSUpArrowFunctionKey) { offset--; }
	 else if (keyChar == NSDownArrowFunctionKey) { offset++; }
	 
	 if (offset != 0) {
	 NSInteger rows = numberOfRows[selectedIndexPath.section];
	 NSInteger newSection = selectedIndexPath.section;
	 NSInteger newRow = selectedIndexPath.row + offset;// @TODO: jump unselectable rows
	 
	 if (newRow < 0) { newSection--; newRow = (numberOfRows[newSection] - 1); }
	 else if (newRow >= rows) { newSection++; newRow = 0; }
	 
	 if (newSection < 0) { newSection = 0; }
	 else if (newSection >= numberOfSections) { newSection = (numberOfSections - 1); }
	 
	 NSIndexPath * newIndexPath = [NSIndexPath indexPathWithSection:newSection row:newRow];
	 [self selectCellAtIndexPath:newIndexPath];
	 }
	 }
	 */
	
	if ([delegate respondsToSelector:@selector(gridView:didReceiveKeyString:)]) {
		[delegate gridView:self didReceiveKeyString:theEvent.charactersIgnoringModifiers];
	}
	
	return [super performKeyEquivalent:theEvent];
}

@end

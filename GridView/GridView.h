//
//  GridView.h
//  GridView
//
//  Created by Max on 18/03/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import <AppKit/AppKit.h>

#import "GridItemView.h"
#import "GridDocumentView.h"

#import "PlaceholderLabel.h"

@interface SelectionView : NSView
@end


@class GridItemView;

@interface GridItem : NSObject
{
	NSString * title;
	NSImage * image;
	
	GridItemView * itemView;
	
	NSMutableDictionary * info;
	
	//NSInteger _section, _index; => Used?
	
	BOOL _selected, _deleted, _isOriginal, _becameAlias, _isGroup;
	BOOL _visible;
	
	CGRect frame;
	
	NSColor * _labelColor;
}
@property (nonatomic, copy) NSString * title;
@property (nonatomic, copy) NSImage * image;

@property (nonatomic, strong) GridItemView * itemView;

@property (nonatomic, readonly) NSMutableDictionary * info;

//@property (nonatomic, readonly) NSInteger section, index;

@property (nonatomic, assign) BOOL selected, deleted, isOriginal, becameAlias, isGroup;
@property (nonatomic, assign, getter = isVisible) BOOL visible;

@property (nonatomic, assign) CGRect frame;

@property (nonatomic, strong) NSColor * labelColor;

- (void)reload;

@end


@protocol GridItem <NSObject>

- (NSString *)path;
- (NSColor *)labelColor;

@end


@class GridView;
@protocol GridViewDelegate <NSObject>

@optional
- (void)gridView:(GridView *)gridView didSelectItem:(GridItem *)item indexPath:(NSIndexPath *)indexPath;
- (void)gridView:(GridView *)gridView didSelectItems:(NSArray *)items indexPaths:(NSArray *)indexPaths;

- (void)gridView:(GridView *)gridView didDoubleClickOnItem:(GridItem *)item indexPath:(NSIndexPath *)indexPath;

- (void)gridView:(GridView *)gridView didUnselectItems:(NSArray *)items;
- (void)gridViewSelectionDidChange:(GridView *)gridView;

- (NSMenu *)menuForGridView:(GridView *)gridView selectedItems:(NSArray *)items;

- (void)gridView:(GridView *)gridView didReceiveKeyString:(NSString *)keyString;

@end

@protocol GridViewDataSource

@optional
- (NSString *)placeholderInGridView:(GridView *)gridView;
- (NSInteger)numberOfSectionsInGridView:(GridView *)gridView;
- (NSArray *)titlesForSectionsInGridView:(GridView *)gridView;

- (NSInteger)gridView:(GridView *)gridView numberOfItemsInSection:(NSInteger)section;
- (NSArray *)gridView:(GridView *)gridView itemsForSection:(NSInteger)section;

@end

@interface GridView : NSScrollView <NSAnimationDelegate>
{
	id <GridViewDelegate> delegate;
	id <GridViewDataSource> dataSource;
	
	NSString * placeholder;
	
	@private
	
	// @TODO: clean up unused ivar
	
	NSInteger numberOfSections;
	
	NSMutableArray * allItemsArrays;
	
	NSArray * _itemsSection;
	NSArray * _sectionTitles;
	
	NSArray * _oldSelectedItems;
	
	GridItemView * _oldItemView;
	NSMutableArray * selectedItems;
	
	NSPoint _startMouseDownPosition;
	NSRect selectionRect;
	
	int itemsPerRow;
	float topMargin;
	int itemWidth;
	
	SelectionView * selectionView;
	
	NSView * headerView;
	//NSView * placeholderView;
	PlaceholderLabel * placeholderLabel;
	
	
	NSMutableArray * _reusableItems;
}

@property (nonatomic, strong) id <GridViewDelegate> delegate;
@property (nonatomic, strong) id <GridViewDataSource> dataSource;

@property (nonatomic, strong) NSView * headerView;

@property (nonatomic, strong) NSString * placeholder;

- (void)setPlaceholder:(NSString *)string;

- (BOOL)itemIsVisible:(GridItem *)item;

- (NSArray *)itemsForSection:(NSInteger)section;

- (void)unselectAll;
- (void)selectAll;
- (void)deselectAll;
- (void)deselectFirstItem;
- (void)selectAllNonOriginalsItems;

- (GridItem *)selectedItem;
- (NSArray *)selectedItems;

- (void)selectItems:(NSArray *)items;
- (void)unselectItems:(NSArray *)items;
- (void)unselectOriginalItem;
- (void)deleteItems:(NSArray *)items;
- (void)undeleteItems:(NSArray *)items;

- (NSArray *)gridItems;
- (NSArray *)gridItemsViews;

- (void)reloadData;

- (void)setItemsSize:(int)pixels;

- (NSArray *)gridItems;
- (NSArray *)gridItemsViews;

- (NSSize)sizeForSection:(NSInteger)section;

- (BOOL)itemIsVisible:(GridItem *)item;

// Private
- (void)update;
- (void)rightMouseDown:(NSEvent *)theEvent;

@end

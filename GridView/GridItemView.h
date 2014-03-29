//
//  GridItemView.h
//  GridView
//
//  Created by Max on 18/03/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GridView.h"

@interface GridItemImageView : NSImageView
{
	BOOL _selected, _isOriginal, _isGroup;
}

@property (nonatomic, assign) BOOL selected, isOriginal, isGroup;

@end

@interface GridItemTextField : NSTextField
{
	NSColor * __strong _labelColor;
}

@property (nonatomic, strong) NSColor * labelColor;

@end

@class GridItem;

@interface GridItemView : NSView
{
@private
	GridItemImageView * imageView;
	GridItemTextField * textField;
	
	NSImage * _image;
	GridItem * _item;
	BOOL _selected, _isOriginal, _isGroup;
	NSColor *  _labelColor;
	
	NSRect _hitFrame;
}

@property (nonatomic, strong) NSImage * image;
@property (nonatomic, strong) GridItem * item;
@property (nonatomic, assign) BOOL selected, isOriginal, isGroup;
@property (nonatomic, strong) NSColor * labelColor;

@property (nonatomic, readonly) NSRect hitFrame;

@end

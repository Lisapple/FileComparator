//
//  GridDocumentView.h
//  GridView
//
//  Created by Max on 18/03/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface GridDocumentView : NSView
{
	NSRect selectionRect;
}

- (void)drawSelectionRect:(NSRect)rect;

@end

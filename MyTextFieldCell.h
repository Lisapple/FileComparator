//
//  MyTextFieldCell.h
//  Comparator
//
//  Created by Max on 07/05/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MyTextFieldCell : NSTextFieldCell
{
	NSString * title;
	NSColor * textBackgroundColor;
}

- (void)setTextBackgroundColor:(NSColor *)color;

- (NSImage *)_textBackgroundImageWithSize:(NSSize)size;

@end

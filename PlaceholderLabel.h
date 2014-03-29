//
//  PlaceholderLabel.h
//  PlaceholderText
//
//  Created by Max on 27/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <AppKit/AppKit.h>

@interface PlaceholderLabel : NSView
{
	NSString * _title;
	NSColor * _backgroundColor;
	CGFloat _fontHeight;
}

@property (nonatomic, copy) NSString * title;
@property (nonatomic, copy) NSColor * backgroundColor;
@property (nonatomic, assign) CGFloat fontHeight;

@end

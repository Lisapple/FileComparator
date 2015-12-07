//
//  PlaceholderLabel.h
//  PlaceholderText
//
//  Created by Max on 27/11/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import <AppKit/AppKit.h>

#define USE_CORE_TEXT 1
#if USE_CORE_TEXT
#  import <CoreText/CoreText.h>
#endif

@interface PlaceholderLabel : NSView

@property (nonatomic, copy) NSString * title;
@property (nonatomic, copy) NSColor * backgroundColor;

@end

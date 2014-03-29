//
//  SourceTableViewCell.h
//  Comparator
//
//  Created by Max on 20/04/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SourceTableViewCellHelper : NSObject
{
	CGFloat defaultHeight;
}

@property (nonatomic, readonly) CGFloat defaultHeight;

- (void)updateDefaultHeight;

@end

@interface SourceTableViewCell : NSCell
{
	NSImage * image;
	NSString * title;
	NSInteger badgeCount;
	
@private
	NSImageCell * imageCell;
	NSTextFieldCell * textFieldCell, * textFieldCellShadow;
	
	NSImage * badgeCountImage;
	CGSize badgeCountImageSize;
	CGFloat badgeCountImageScale;
	
	BOOL _disabled;
}

@property (nonatomic, retain) NSImage * image;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, assign) NSInteger badgeCount;
@property (nonatomic, assign, getter = isDisabled) BOOL disabled;

@property (nonatomic, retain) NSImageCell * imageCell;
@property (nonatomic, retain) NSTextFieldCell * textFieldCell, * textFieldCellShadow;

+ (CGFloat)defaultHeight;
- (CGFloat)screenScale;

@end

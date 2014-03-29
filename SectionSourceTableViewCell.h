//
//  SectionSourceTableViewCell.h
//  Comparator
//
//  Created by Max on 11/05/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SectionSourceTableViewCell : NSTextFieldCell
{
	NSString * title;
	
	BOOL animated;
}

@property (nonatomic, retain) NSString * title;

- (void)startAnimation;

@end

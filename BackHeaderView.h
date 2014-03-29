//
//  BackHeaderView.h
//  Comparator
//
//  Created by Max on 08/04/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface BackHeaderButton : NSButton
{
}

@end

@interface BackHeaderView : NSView
{
	IBOutlet BackHeaderButton * backButton;
	IBOutlet NSTextField * titleLabel;
	
	@private
	NSString * _title;
}

@property (nonatomic, strong) NSString * title;

@end

//
//  SectionSourceTableViewCell.m
//  Comparator
//
//  Created by Max on 11/05/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

#import "SectionSourceTableViewCell.h"

#import "NSColor+addition.h"

@implementation SectionSourceTableViewCell

@synthesize title;

- (id)init
{
	if ((self = [super init])) {
		self.title = @"--";
	}
	
	return self;
}

- (id)initTextCell:(NSString *)aString
{
	if ((self = [super initTextCell:aString])) {
		self.title = aString;
	}
	
	return self;
}

- (id)initWithCoder:(NSCoder *)decoder
{
	if ((self = [super initWithCoder:decoder])) {
		self.title = @"---";
	}
	
	return self;
}

- (id)copyWithZone:(NSZone*)zone
{
    SectionSourceTableViewCell * cell = (SectionSourceTableViewCell *)[super copyWithZone:zone];
	cell->title = [title copyWithZone:zone];
	
    return cell;
}

- (void)setTitle:(NSString *)aTitle
{
	[title release];
	title = [aTitle retain];
}

- (void)startAnimation
{
	animated = YES;
}

- (void)stopAnimation
{
	animated = NO;
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	NSProgressIndicator * indicator = nil;
	for (NSView * subview in [controlView subviews]) {
		if ([subview isKindOfClass:[NSProgressIndicator class]]) {
			indicator = (NSProgressIndicator * )subview;
		}
	}
	
	NSRect frame = NSMakeRect(cellFrame.origin.x + cellFrame.size.width - 19. - 5., cellFrame.origin.y + 2., 16., 16.);
	if (animated) {// Create the indicator only if "animated" is enabled
		if (!indicator) {
			NSProgressIndicator * indicator = [[NSProgressIndicator alloc] initWithFrame:frame];
			[indicator setControlSize:NSSmallControlSize];
			[indicator setStyle:NSProgressIndicatorSpinningStyle];
			[indicator setDisplayedWhenStopped:NO];
			
			[indicator startAnimation:nil];
			
			[[self controlView] addSubview:indicator];
			[indicator release];
		} else {
			
			[indicator startAnimation:nil];
			
			[indicator setFrame:frame];
		}
	} else {
		[indicator stopAnimation:nil];
	}
	
	
	[self setFont:[NSFont boldSystemFontOfSize:11.]];
	//[self setTextColor:[NSColor selectedMenuItemColor]];
	[self setAlignment:NSLeftTextAlignment];
	[self setLineBreakMode:NSLineBreakByTruncatingTail];
	[self setWraps:YES];
	
	[self setEditable:NO];
	[self setSelectable:NO];
	
	frame = NSOffsetRect(cellFrame, 5., 0.);
	[super drawWithFrame:frame inView:controlView];
}

@end

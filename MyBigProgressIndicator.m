//
//  MyBigProgressIndicator.m
//  MegaCustomProgressIndicator
//
//  Created by Max on 15/01/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "MyBigProgressIndicator.h"

@implementation MyBigProgressIndicator

@synthesize indeterminate = _indeterminate;

- (void)awakeFromNib
{
	_indeterminate = YES;
}

- (void)setIndeterminate:(BOOL)indeterminate
{
	_indeterminate = indeterminate;
	
	if (indeterminate) {
		[self startAnimation:nil];
	} else {
		[self stopAnimation:nil];
	}
	
	[self setNeedsDisplay:YES];
}

- (void)startAnimation:(id)sender
{
	[self stopAnimation:sender];
	
	// @TODO: release resources
	if (!timer) {
		dispatch_queue_t queue = dispatch_get_main_queue();
		timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue); //run event handler on the default global queue
		dispatch_time_t now = dispatch_walltime(DISPATCH_TIME_NOW, 0);
		dispatch_source_set_timer(timer, now, (100. / 3.) * USEC_PER_SEC, 5000ull);// Fire timer 30 times a second, with 5 ms delay, "in case the system wants to align it with other events to minimize power consumption"
		dispatch_source_set_event_handler(timer, ^{
			[self setNeedsDisplay:YES];
		});
	}
	
	dispatch_resume(timer);
}

- (void)stopAnimation:(id)sender
{
	if (timer) {
		dispatch_suspend(timer);
		dispatch_source_cancel(timer);
		//dispatch_release(timer);
		timer = NULL;
	}
}

- (void)drawRect:(NSRect)dirtyRect
{
	NSRect frame = dirtyRect;
	if (frame.size.width > 200.)
		frame.size.width = 200.;
	
	if (frame.size.height > 200.)
		frame.size.height = 200.;
	
	CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
	
	if (_indeterminate) {
		
		progressValue += 0.0333333;
		
		float borderWidth = 10.;
		
		NSRect rect = frame;
		rect.origin.x = borderWidth;
		rect.origin.y = borderWidth;
		rect.size.width -= 2. * borderWidth;
		rect.size.height -= 2. * borderWidth;
		
		float radius = rect.size.width / 2.;
		
		int numberOfLines = 12;
		
		float interiorRadius = radius / 2.;
		
		CGContextSetLineCap(context, kCGLineCapRound);
		CGContextSetLineWidth(context, 12.);
		
		CGPoint center = CGPointMake((int)(dirtyRect.origin.x + dirtyRect.size.width / 2.), (int)(dirtyRect.origin.y + dirtyRect.size.height / 2.));
		
		for (int line = 0; line < numberOfLines; line++) {
			float angle = 2. * M_PI * line / (float)numberOfLines;
			
			CGContextBeginPath(context);
			
			CGContextMoveToPoint(context, center.x + (interiorRadius * cosf(angle)), center.y + (interiorRadius * sinf(angle)));
			CGContextAddLineToPoint(context, center.x + (radius * cosf(angle)), center.y + (radius * sinf(angle)));
			
			float alpha = line / (float)numberOfLines + progressValue;
			int intPart = (int)alpha;
			
#define kMinimumAlpha 0.25
			[[NSColor colorWithCalibratedWhite:0.33 alpha:(kMinimumAlpha + (1. - (alpha - intPart)) * (1. - kMinimumAlpha))] setStroke];
			CGContextStrokePath(context);
		}
		
	} else {
		
		float borderWidth = 10.;
		float radius = frame.size.width / 2.;
		
		CGPoint center = CGPointMake((int)(dirtyRect.origin.x + dirtyRect.size.width / 2.), (int)(dirtyRect.origin.y + dirtyRect.size.height / 2.));
		
		// Draw the outer circle
		CGContextAddArc(context, center.x, center.y, radius, 0., 2 * M_PI, 0);
		
		CGContextClosePath(context);
		CGContextClip(context);
		
		[[NSColor darkGrayColor] setFill];
		CGContextFillRect(context, NSRectToCGRect(dirtyRect));
		
		
		NSRect rect = frame;
		rect.origin.x = borderWidth;
		rect.origin.y = borderWidth;
		rect.size.width -= 2. * borderWidth;
		rect.size.height -= 2. * borderWidth;
		
		radius = rect.size.width / 2.;
		
		// Draw the inner progression circle
		CGContextAddArc(context, center.x, center.y, radius, M_PI_2, 2 * M_PI * (currentValue / 100.) + M_PI_2, 0);
		CGContextAddLineToPoint(context, center.x, center.y);
		
		CGContextClosePath(context);
		CGContextClip(context);
		
		[[NSColor windowBackgroundColor] setFill];
		CGContextFillRect(context, NSRectToCGRect(dirtyRect));
	}
}

- (IBAction)changeState:(id)sender
{
	NSButton * button = (NSButton *)sender;
	self.indeterminate = ([button state] == 1);
	
	if (self.indeterminate) {
		[self startAnimation:nil];
	} else {
		[self stopAnimation:nil];
	}
}

- (void)setDoubleValue:(double)doubleValue
{
	currentValue = 100. - doubleValue;
	[self setNeedsDisplay:YES];
}

- (void)incrementBy:(double)delta
{
	currentValue -= delta;
	[self setNeedsDisplay:YES];
}

@end

//
//  MyBigProgressIndicator.h
//  MegaCustomProgressIndicator
//
//  Created by Max on 15/01/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import <AppKit/AppKit.h>

@interface MyBigProgressIndicator : NSView
{
	float currentValue;
	
@private
	float progressValue;
	//NSTimer * _animationTimer;
	dispatch_source_t timer;
	
	BOOL _indeterminate;
}

@property (nonatomic, assign) BOOL indeterminate;

- (void)startAnimation:(id)sender;
- (void)stopAnimation:(id)sender;

- (IBAction)changeState:(id)sender;
- (void)setDoubleValue:(double)doubleValue;

- (void)incrementBy:(double)delta;

@end

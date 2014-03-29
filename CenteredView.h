//
//  CenteredView.h
//  Comparator
//
//  Created by Max on 14/12/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef struct {
	float left, right;
	float top, bottom;
} RectEdge;

RectEdge RectEdgeZero();
RectEdge RectEdgeMake(float top, float left, float bottom, float right);

@interface CenteredView : NSView
{
	@private
	BOOL _horizontallyCentered, _verticallyCentered;
	RectEdge _offsetEdge;
}

@property (nonatomic, assign) BOOL horizontallyCentered, verticallyCentered;
@property (nonatomic, assign) RectEdge offsetEdge;

@end

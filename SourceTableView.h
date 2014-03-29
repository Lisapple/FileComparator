//
//  SourceTableView.h
//  Comparator
//
//  Created by Max on 05/05/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class SourceTableView;

@protocol SourceTableViewDelegate

/* Returns YES if outlineView accept dragging objects, else return NO (to show the reverse dragging animation) */
- (BOOL)tableView:(SourceTableView *)tableView didReceiveDraggingObjects:(NSArray *)objects;

@end


@interface SourceTableView : NSTableView
{
	NSObject <SourceTableViewDelegate> * sourceDelegate;
}

@property (nonatomic, retain) NSObject <SourceTableViewDelegate> * sourceDelegate;

@end

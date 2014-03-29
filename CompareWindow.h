//
//  CompareViewController.h
//  Comparator
//
//  Created by Max on 29/03/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "FileItem.h"

@interface CompareWindow : NSWindow <NSTableViewDelegate, NSTableViewDataSource>
{
	IBOutlet NSImageView * itemPreview1, * itemPreview2;
	IBOutlet NSTextField * itemFilename1, * itemFilename2;
	IBOutlet NSTextField * itemPath1, * itemPath2;
	
	IBOutlet NSTableView * tableView;
	
	FileItem * _item1, * _item2;
	NSDictionary * _item1Attributes, * _item2Attributes;
	
	NSArray * keys;
}

- (IBAction)close:(id)sender;

- (void)compareItem:(FileItem *)item1 withItem:(FileItem *)item2;

@end

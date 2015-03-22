//
//  FolderDetailsWindow.h
//  FolderSlice
//
//  Created by Maxime on 02/01/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import <AppKit/AppKit.h>

@interface ItemsListContentView : NSView
@end


@interface ItemsListWindow : NSWindow
{
	NSArray * _items;
}

@property (nonatomic, copy) NSArray * items;

@end


@interface FolderDetailsView : NSView
{
	NSArray * _items;
	
	CGPathRef lastSectionPath;
	NSPoint lastSectionLocation;
	
	BOOL intoLastSection;
	ItemsListWindow * itemsListWindow;
}

@property (nonatomic, strong) NSArray * items;

- (NSArray *)itemsToShow;

@end


@interface FolderDetailsWindow : NSWindow
{
	IBOutlet FolderDetailsView * _detailsView;
}

@property (nonatomic, strong) IBOutlet FolderDetailsView * detailsView;
@property (nonatomic, strong) NSURL * folderURL;

- (void)reloadWithFolderURL:(NSURL *)folderURL;

- (IBAction)showInFinderAction:(id)sender;
- (IBAction)okAction:(id)sender;

@end
//
//  ApplicationPreferencesWindow.h
//  Comparator
//
//  Created by Max on 03/05/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class BlacklistTableView;
@protocol BlacklistTableViewDelegate

/* Returns YES if outlineView accept dragging objects, else return NO (to show the reverse dragging animation) */
- (BOOL)tableView:(BlacklistTableView *)tableView didReceiveDraggingObjects:(NSArray *)objects;

@end

@interface BlacklistTableView : NSTableView
{
	NSObject <BlacklistTableViewDelegate> * _draggingDelegate;
}

@property (nonatomic, strong) NSObject <BlacklistTableViewDelegate> * draggingDelegate;

@end


@interface ApplicationPreferencesContentView : NSView
{
	CGFloat _topSectionHeight;
}

@property (nonatomic, assign) CGFloat topSectionHeight;

@end


@interface ApplicationPreferencesWindow : NSWindow <NSWindowDelegate, NSTableViewDelegate, NSTableViewDataSource, BlacklistTableViewDelegate>
{
	IBOutlet NSMatrix * __strong originalTypeMatrix;
	
	IBOutlet NSBox * __strong contentBox;
	IBOutlet NSView * __strong generalView, * __strong blacklistView;
	IBOutlet BlacklistTableView * __strong blacklistTableView;
	IBOutlet NSTableView * __strong extensionTableView;
	
	IBOutlet NSPopUpButton * __strong typeListPopUpButton;
	
	IBOutlet NSTextField * __strong extensionListLabel;
	IBOutlet NSButton * __strong excludeSystemFoldersButton;
	
	NSMutableArray * blacklistPaths, * extensionBlacklists, * extensionWhitelists;
}

@property (strong) IBOutlet NSMatrix * originalTypeMatrix;

@property (strong) IBOutlet NSBox * contentBox;
@property (strong) IBOutlet NSView * generalView, * blacklistView;
@property (strong) IBOutlet BlacklistTableView * blacklistTableView;
@property (strong) IBOutlet NSTableView * extensionTableView;

@property (strong) IBOutlet NSPopUpButton * typeListPopUpButton;

@property (strong) IBOutlet NSTextField * extensionListLabel;
@property (strong) IBOutlet NSButton * excludeSystemFoldersButton;

- (void)updateContent;

- (IBAction)extensionListDidChange:(id)sender;

- (IBAction)excludeSystemFoldersAction:(id)sender;

- (IBAction)toolbarDidChangeSelectedTab:(id)sender;

- (IBAction)resetAlertsAction:(id)sender;

- (IBAction)showHelp:(id)sender;

- (IBAction)addPath:(id)sender;
- (IBAction)removePath:(id)sender;


#pragma mark File Blacklist Management

- (IBAction)addExtension:(id)sender;
- (IBAction)removeExtension:(id)sender;

@end

//
//  ApplicationPreferencesWindow.m
//  Comparator
//
//  Created by Max on 03/05/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

#import "ApplicationPreferencesWindow.h"

#define kExtensionBlacklistSelected @"extensionBlacklistSelected"
#define kExtensionWhitelistSelected @"extensionWhitelistSelected"

@implementation BlacklistTableView

@synthesize draggingDelegate = _draggingDelegate;

- (BOOL)performDragOperation:(id < NSDraggingInfo >)sender
{
	BOOL performDragOperation = [super performDragOperation:sender];
	
	NSArray * array = [[sender draggingPasteboard] propertyListForType:NSFilenamesPboardType];
	if (array) {
		if ([_draggingDelegate respondsToSelector:@selector(tableView:didReceiveDraggingObjects:)]) {
			return [_draggingDelegate tableView:self didReceiveDraggingObjects:array];
		}
	}
	
	return performDragOperation;
}

@end


@implementation ApplicationPreferencesContentView

@synthesize topSectionHeight = _topSectionHeight;

- (void)setTopSectionHeight:(CGFloat)topSectionHeight
{
	_topSectionHeight = topSectionHeight;
	[self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect
{
	if (_topSectionHeight >= 0.) {
		CGFloat height = self.frame.size.height - _topSectionHeight;
		NSRect frame = NSMakeRect(0., 0., self.frame.size.width, height);
		
		[[NSColor colorWithCalibratedWhite:0.888 alpha:1.] setFill];
		NSRectFill(frame);
		
		NSRect rect = frame;
		rect.size.height = 1.;
		rect.origin.y = height - 2.;
		[[NSColor whiteColor] setFill];
		NSRectFill(rect);
		
		rect.origin.y = height - 1.;
		[[NSColor lightGrayColor] setFill];
		NSRectFill(rect);
	}
}

@end


@implementation ApplicationPreferencesWindow

@synthesize originalTypeMatrix;

@synthesize contentBox;
@synthesize generalView, blacklistView;
@synthesize blacklistTableView;
@synthesize extensionTableView;
@synthesize excludeSystemFoldersButton;

@synthesize typeListPopUpButton;

@synthesize extensionListLabel;

- (instancetype)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)windowStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)deferCreation
{
	if ((self = [super initWithContentRect:contentRect styleMask:windowStyle backing:bufferingType defer:deferCreation])) {
		[self setDelegate:self];
		[self center];
	}
	
	return self;
}

- (void)awakeFromNib
{
	self.toolbar.selectedItemIdentifier = @"general";
	[self toolbarDidChangeSelectedTab:nil];
	
	blacklistTableView.delegate = self;
	blacklistTableView.dataSource = self;
	[blacklistTableView registerForDraggedTypes:@[NSFilenamesPboardType]];
	blacklistTableView.draggingDelegate = self;
	
	extensionTableView.delegate = self;
	extensionTableView.dataSource = self;
	
	[self updateContent];
}

- (void)windowDidBecomeKey:(NSNotification *)notification
{
	[self updateContent];
}

- (void)updateContent
{
	NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
	NSInteger row = ([[userDefaults stringForKey:@"OriginalSortedKey"] isEqualToString:@"lastModificationDate"])? 1: 0;// Look if "OriginalSortedKey" is equal to "lastModificationDate" and not if it equal to "creationDate" because "creationDate" is the default choice and "OriginalSortedKey" can be nil.
	[originalTypeMatrix selectCellAtRow:row column:0];
	
	[typeListPopUpButton selectItemAtIndex:(([[userDefaults stringForKey:@"extensionTypeList"] isEqualToString:kExtensionBlacklistSelected])? 0: 1)];
	
	excludeSystemFoldersButton.state = ([userDefaults boolForKey:@"Exclude System and Library Folders"])? NSOnState : NSOffState;
	
	blacklistPaths = [[userDefaults arrayForKey:@"blacklistPaths"] mutableCopy];
	if (!blacklistPaths)
		blacklistPaths = [[NSMutableArray alloc] initWithCapacity:3];
	
	[blacklistTableView reloadData];
	[self extensionListDidChange:nil];
}

- (IBAction)extensionListDidChange:(id)sender
{
	if (typeListPopUpButton.indexOfSelectedItem == 0) {
		extensionListLabel.stringValue = NSLocalizedString(@"All files with these extensions will be excluded from comparaison", nil);
	} else {
		extensionListLabel.stringValue = NSLocalizedString(@"Only files with these extensions will be included from comparaison", nil);
	}
	
	[extensionTableView reloadData];
}

- (IBAction)excludeSystemFoldersAction:(id)sender
{
	NSButton * button = (NSButton *)sender;
	NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
	[userDefaults setBool:(button.state == NSOnState) forKey:@"Exclude System and Library Folders"];
}

- (IBAction)toolbarDidChangeSelectedTab:(id)sender
{
	NSSize currentSize = [[contentBox contentView] bounds].size;
	NSSize newSize = NSMakeSize(0., 0.);
	NSView * newView = nil;
	
	CGFloat topSectionHeight = -1.;
	
	NSString * identifier = self.toolbar.selectedItemIdentifier;
	if ([identifier isEqualToString:@"general"]) {
		newView = generalView;
		newSize = generalView.bounds.size;
		
		topSectionHeight = 98.;
		
	} else if ([identifier isEqualToString:@"backlist"]) {
		newView = blacklistView;
		newSize = blacklistView.bounds.size;
		
		topSectionHeight = 210.;
	}
	
	[(ApplicationPreferencesContentView *)self.contentView setTopSectionHeight:topSectionHeight];
	
	float deltaWidth = newSize.width - currentSize.width;
	float deltaHeight = newSize.height - currentSize.height;
	
	NSRect windowFrame = self.frame;
	windowFrame.size.width += deltaWidth;
	windowFrame.origin.y -= deltaHeight;
	windowFrame.size.height += deltaHeight;
	
	[contentBox setContentView:nil];
	[self setFrame:windowFrame
		   display:YES
		   animate:YES];
	[contentBox setContentView:newView];
}

- (IBAction)resetAlertsAction:(id)sender
{
	NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
	[userDefaults removeObjectForKey:@"Alerts to Hide"];
	[userDefaults synchronize];
}

- (void)save
{
	NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
	
	NSInteger row = [originalTypeMatrix selectedRow];
	NSString * keyValue = (row == 0)? @"creationDate": @"lastModificationDate";
	[userDefaults setObject:keyValue forKey:@"OriginalSortedKey"];
	
	[userDefaults setObject:(typeListPopUpButton.indexOfSelectedItem == 0)? kExtensionBlacklistSelected: kExtensionWhitelistSelected
					 forKey:@"extensionTypeList"];
	
	/* Save blacklistPaths changes */
	[userDefaults setObject:blacklistPaths forKey:@"blacklistPaths"];
	
	/* Save extensionBlacklists changes */
	[userDefaults setObject:extensionBlacklists forKey:@"extensionBlacklists"];
	
	/* Save extensionWhitelists changes */
	[userDefaults setObject:extensionWhitelists forKey:@"extensionWhitelists"];
	
	[userDefaults synchronize];
}

- (void)windowWillClose:(NSNotification *)notification
{
	[self save];
}

- (void)windowDidResignKey:(NSNotification *)notification
{
	[self save];
}

- (IBAction)showHelp:(id)sender
{
	NSString * helpBookName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleHelpBookName"];
	[[NSHelpManager sharedHelpManager] openHelpAnchor:@"interface_settings" inBook:helpBookName];
}

#pragma mark - File Blacklist Management

- (IBAction)addPath:(id)sender
{
	NSOpenPanel * openPanel = [NSOpenPanel openPanel];
	[openPanel setCanChooseDirectories:YES];
	[openPanel setCanChooseFiles:YES];
	[openPanel setAllowsMultipleSelection:YES];
	
	[openPanel beginSheetModalForWindow:self
					  completionHandler:^(NSInteger result) {
						  if (result == NSFileHandlingPanelOKButton) {
							  for (NSURL * url in [openPanel URLs]) {
								  NSString * path = [url path];
								  if (![blacklistPaths containsObject:path]) {
									  [blacklistPaths addObject:path];
								  }
							  }
							  [blacklistTableView reloadData];
							  
							  /* Save blacklistPaths changes */
							  NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
							  [userDefaults setObject:blacklistPaths forKey:@"blacklistPaths"];
							  [userDefaults synchronize];
						  }
					  }];
}

- (IBAction)removePath:(id)sender
{
	NSMutableArray * blacklistPathsCopy = [[NSMutableArray alloc] initWithCapacity:blacklistPaths.count];
	[[blacklistTableView selectedRowIndexes] enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
		[blacklistPathsCopy addObject:blacklistPaths[idx]];
	}];
	
	for (NSString * path in blacklistPathsCopy) {
		[blacklistPaths removeObject:path];
	}
	
	/* Save blacklistPaths changes */
	NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
	[userDefaults setObject:blacklistPaths forKey:@"blacklistPaths"];
	[userDefaults synchronize];
	
	[blacklistTableView reloadData];
}

#pragma mark - File Blacklist Management

- (NSMutableArray *)extensionSourceArray
{
	if (typeListPopUpButton.indexOfSelectedItem == 0) {// Blacklist
		if (!extensionBlacklists) {
			NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
			extensionBlacklists = [[userDefaults arrayForKey:@"extensionBlacklists"] mutableCopy];
			
			if (!extensionBlacklists)
				extensionBlacklists = [[NSMutableArray alloc] initWithCapacity:3];
		}
		return extensionBlacklists;
	} else {// Whitelist
		if (!extensionWhitelists) {
			NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
			extensionWhitelists = [[userDefaults arrayForKey:@"extensionWhitelists"] mutableCopy];
			
			if (!extensionWhitelists)
				extensionWhitelists = [[NSMutableArray alloc] initWithCapacity:3];
		}
		return extensionWhitelists;
	}
}

- (IBAction)addExtension:(id)sender
{
	[[self extensionSourceArray] addObject:@""];
	
	[extensionTableView reloadData];
	
	NSIndexSet * indexes = [NSIndexSet indexSetWithIndex:([self extensionSourceArray].count - 1)];
	[extensionTableView selectRowIndexes:indexes byExtendingSelection:NO];
	
	[extensionTableView editColumn:1 row:([self extensionSourceArray].count - 1) withEvent:nil select:YES];
}

- (IBAction)removeExtension:(id)sender
{
	NSInteger selectedRow = [extensionTableView selectedRow];
	if (selectedRow != -1) {
		[[self extensionSourceArray] removeObjectAtIndex:selectedRow];
		[extensionTableView reloadData];
	}
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	if (aTableView == blacklistTableView) {
		return blacklistPaths.count;
	} else {
		return [self extensionSourceArray].count;
	}
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	if (aTableView == blacklistTableView) {
		NSString * path = blacklistPaths[rowIndex];
		if ([aTableColumn.identifier isEqualToString:@"icon"]) {
			return [[NSWorkspace sharedWorkspace] iconForFile:path];
		} else {
			return blacklistPaths[rowIndex];
		}
	} else {
		NSString * type = [self extensionSourceArray][rowIndex];
		if ([aTableColumn.identifier isEqualToString:@"icon"]) {
			return [[NSWorkspace sharedWorkspace] iconForFileType:type];
		} else {
			return [[NSWorkspace sharedWorkspace] localizedDescriptionForType:type];
		}
	}
	
	return nil;
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	if (aTableView == extensionTableView) {
		if (((NSString *)anObject).length > 0) {
			CFStringRef identifier = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)anObject, NULL);
			self.extensionSourceArray[rowIndex] = (__bridge NSString *)identifier;
			if (identifier) CFRelease(identifier);
		} else {
			[[self extensionSourceArray] removeObjectAtIndex:rowIndex];
			[extensionTableView reloadData];
		}
	}
}

#pragma mark - NSTableView Drag & Drop

- (NSDragOperation)tableView:(NSTableView *)aTableView validateDrop:(id < NSDraggingInfo >)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)operation
{
	NSArray * paths = [[info draggingPasteboard] propertyListForType:NSFilenamesPboardType];
	for (NSString * path in paths) {
		if (![blacklistPaths containsObject:path]) {
			[aTableView setDropRow:blacklistPaths.count
					 dropOperation:[info draggingSourceOperationMask]];
			return [info draggingSourceOperationMask];
		}
	}
	
	return NSDragOperationNone;
}

#pragma mark - BlacklistTableViewDelegate

- (BOOL)tableView:(BlacklistTableView *)tableView didReceiveDraggingObjects:(NSArray *)objects
{
	NSArray * objectsCopy = [objects copy];
	for (NSString * path in objectsCopy) {
		if (![blacklistPaths containsObject:path])
			[blacklistPaths addObject:path];
	}
	
	/* Save blacklistPaths changes */
	NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
	[userDefaults setObject:blacklistPaths forKey:@"blacklistPaths"];
	[userDefaults synchronize];
	
	[blacklistTableView reloadData];
	
	return YES;
}

@end

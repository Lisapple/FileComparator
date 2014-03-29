//
//  OptionsViewController.m
//  Comparator
//
//  Created by Max on 18/04/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

#import "OptionsViewController.h"

#import "ExcludedExtensionsWindow.h"
#import "FileSizeSettingsWindow.h"

#import "SectionSourceTableViewCell.h"

#import "SourceItem.h"

#import "NSMutableArray+addition.h"
#import "NSIndexSet+addition.h"
#import "NSString+addition.h"

#import "SandboxHelper.h"


@interface OptionsViewController (PrivateMethods)

- (NSString *)pathForDirectory:(NSSearchPathDirectory)directory;

- (void)_insertUserSource:(SourceItem *)item atIndex:(NSInteger)index;

- (BOOL)tableView:(NSTableView *)tableView rowIsGroupRow:(NSInteger)row;

@end


@implementation OptionsViewController

#define sourceTableViewDataType @"sourceTableViewDataType"

@synthesize excludedExtensionsWindow;
@synthesize fileSizeSettingsWindow;

@synthesize sourceTableView;
@synthesize deleteSourceButton, editSourceButton;

@synthesize optionsTableView;
@synthesize optionsOutlineView;

@synthesize noSourcesView;

- (void)awakeFromNib
{
	if (!sourceTableView)
		return;
	
	userSourceArray = [[NSMutableArray alloc] initWithCapacity:5];
	
	NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
	NSArray * userSourceArrayCopy = [userDefaults arrayForKey:@"userSourceArray"];
	/* Restore user's sources from userDefaults */
	for (NSString * path in userSourceArrayCopy) {
		SourceItem * sourceItem = [[SourceItem alloc] init];
		
		/* Check file availablity */
		BOOL exist = NO, isDirectory = NO;
#if _SANDBOX_ACTIVITED_
		if ([SandboxHelper sandboxActivated]) {
			NSDictionary * sandboxBookmarks = [userDefaults dictionaryForKey:@"sandboxBookmarks"];
			NSData * bookmarkData = [sandboxBookmarks objectForKey:path];
			
			BOOL isStale = NO;
			NSURL * fileURL = [NSURL URLByResolvingBookmarkData:bookmarkData
														options:NSURLBookmarkResolutionWithSecurityScope
												  relativeToURL:nil// Use nil for an app-scoped bookmark (and not for a document-scoped bookmark)
											bookmarkDataIsStale:&isStale
														  error:NULL];
			exist = (!isStale && (fileURL != nil));
			if (exist) {
				[fileURL startAccessingSecurityScopedResource];
				
				NSString * newPath = fileURL.path;
				[[NSFileManager defaultManager] fileExistsAtPath:newPath isDirectory:&isDirectory];
				if (isDirectory)
					newPath = [newPath stringByAppendingString:@"/"];
				
				sourceItem.path = newPath;
				
				[fileURL stopAccessingSecurityScopedResource];
			}
		} else
#endif
		{
			exist = [[NSFileManager defaultManager] fileExistsAtPath:sourceItem.path isDirectory:&isDirectory];
			if (exist) sourceItem.path = path;
		}
		
		if (exist) {
			sourceItem.isFile = !(isDirectory);
			
			[userSourceArray addObject:sourceItem];
			
			[sourceItem addObserver:self forKeyPath:@"name" options:NSKeyValueObservingOptionOld context:NULL];
			[sourceItem addObserver:self forKeyPath:@"path" options:NSKeyValueObservingOptionOld context:NULL];
			[sourceItem addObserver:self forKeyPath:@"selected" options:NSKeyValueObservingOptionOld context:NULL];
		} else {// If source doesn't exists...
			if ([sourceItem.path isOnMainVolume]) {// ...and is on main volumen (the system volume mounted)
				
				NSMutableArray * newUserSourceArray = [[userDefaults arrayForKey:@"userSourceArray"] mutableCopy];
				[newUserSourceArray removeObject:sourceItem.path];// ...delete it
				[userDefaults setObject:newUserSourceArray forKey:@"userSourceArray"];
				[newUserSourceArray release];
			}
		}
		
		[sourceItem release];
	}
	
	privateFolders = [[NSArray alloc] initWithObjects:@"/System/", @"/Library/", [@"~/Library/" stringByExpandingTildeInPath], nil];
	
	[sourceTableView setDelegate:self];
	[sourceTableView setDataSource:self];
	[sourceTableView setSourceDelegate:self];
	
	[sourceTableView setAllowsEmptySelection:YES];
	
	[sourceTableView setFocusRingType:NSFocusRingTypeNone];
	
	[sourceTableView registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, nil]];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(applicationWillTerminate:)
												 name:NSApplicationWillTerminateNotification
											   object:nil];
	
	[self reloadSourceTableView];
	
#define kGroupSeparatorString @"separator"
	NSMutableArray * array = [[NSMutableArray alloc] initWithCapacity:10];
	for (Section * section in [Section sections]) {
		[section allOptions];
		
		[array addObject:section];
		
		NSArray * groups = [section groups];
		for (Group * group in groups) {
			
			if (groups.count > 1)// Add the name of the group to tableView only if we have many groups into the section
				[array addObject:group.name];
			
			for (int row = 0; row < [group numberOfRow]; row++) {
				[array addObject:[group optionsAtRow:row]];
			}
		}
	}
	
	optionItems = (NSArray *)array;
	
	[optionsTableView setDelegate:self];
	[optionsTableView setDataSource:self];
	
	[optionsTableView setFocusRingType:NSFocusRingTypeNone];
	
	[optionsTableView reloadData];
	
	splitView.delegate = self;
	
	[[NSNotificationCenter defaultCenter] addObserver:sourceTableView
											 selector:@selector(reloadData)
												 name:@"PreferencesWindowDidChangeUseSmallIconsState"
											   object:nil];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
	[self save:nil];
}

- (IBAction)showHelp:(id)sender
{
	NSString * helpBookName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleHelpBookName"];
	[[NSHelpManager sharedHelpManager] openHelpAnchor:@"interface_options" inBook:helpBookName];
}

#pragma mark -
#pragma mark Source Actions

- (IBAction)addNewSource:(id)sender
{
	NSOpenPanel * openPanel = [NSOpenPanel openPanel];
	[openPanel setCanChooseDirectories:YES];
	[openPanel setCanChooseFiles:YES];
	[openPanel setAllowsMultipleSelection:NO];
	
	[openPanel setMessage:NSLocalizedString(@"Choose a directory or a file.", nil)];
	[openPanel setPrompt:NSLocalizedString(@"Add", nil)];
	
	[openPanel beginSheetModalForWindow:[NSApp mainWindow]
					  completionHandler:^(NSInteger result) {
						  if (result == NSFileHandlingPanelOKButton) {
							  
							  NSURL * fileURL = [openPanel.URLs objectAtIndex:0];
							  
							  SourceItem * sourceItem = [[SourceItem alloc] init];
							  
							  BOOL isDirectory = NO;
							  [[NSFileManager defaultManager] fileExistsAtPath:[fileURL relativePath] isDirectory:&isDirectory];
							  sourceItem.isFile = !isDirectory;
							  
							  NSString * path = [fileURL relativePath];
							  if (isDirectory)
								  path = [path stringByAppendingString:@"/"];
							  
							  sourceItem.name = [path lastPathComponent];
							  sourceItem.path = path;
							  
							  [self insertUserSource:sourceItem atIndex:-1];
							  [sourceItem release];
						  }
					  }];
}

- (void)insertUserSource:(SourceItem *)item atIndex:(NSInteger)index
{
	[self insertUserSources:[NSArray arrayWithObject:item] atIndexes:[NSIndexSet indexSetWithIndex:index]];
}

- (void)insertUserSources:(NSArray *)sources atIndexes:(NSIndexSet *)indexes
{
	// @FIXME: indexes argument is ignored
	NSMutableArray * privateSources = [[NSMutableArray alloc] initWithCapacity:3];
	NSMutableArray * dropboxSources = [[NSMutableArray alloc] initWithCapacity:3];
	
	NSInteger index = 0;
	for (SourceItem * sourceItem in sources) {
		if ([self isDropboxFolder:sourceItem.path]) {
			[dropboxSources addObject:sourceItem];
		} else if ([self folderIsPrivate:sourceItem.path]) {
			[privateSources addObject:sourceItem];
		} else {
			[self _insertUserSource:sourceItem atIndex:[indexes indexAtIndex:index]];
		}
		
		index++;
	}
	
	if (dropboxSources.count > 0) {
		NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
		NSInteger integer = [userDefaults integerForKey:@"addingDropboxFolders"];
		if (integer == 0) {// Ask What to Do
			NSAlert * alert = [NSAlert alertWithMessageText:NSLocalizedString(@"You have added a Dropbox folder content.", nil)
											  defaultButton:NSLocalizedString(@"Cancel", nil)
											alternateButton:NSLocalizedString(@"Ignore", nil)
												otherButton:nil
								  informativeTextWithFormat:NSLocalizedString(@"Dropbox is a service to backup files on server, this data could only be removed manually. If you really want to add this folder, click ignore.", nil)];
			
			[alert setAlertStyle:NSWarningAlertStyle];
			[alert setShowsSuppressionButton:YES];
			
			NSInteger result = [alert runModal];
			
			if ([[alert suppressionButton] state] == NSOnState) {
				if (result == NSAlertDefaultReturn) {// Cancel
					[userDefaults setInteger:2 forKey:@"addingDropboxFolders"];// Set Always Cancel
				} else if (result == NSAlertAlternateReturn) {// Ignore
					[userDefaults setInteger:1 forKey:@"addingDropboxFolders"];// Set Always Ignore and Add
				}
			}
			
			if (result == NSAlertDefaultReturn) {// Cancel
				// Do Nothing
			} else if (result == NSAlertAlternateReturn) {// Ignore
				for (SourceItem * sourceItem in dropboxSources) {
					NSInteger index = [sources indexOfObject:sourceItem];
					[self _insertUserSource:sourceItem atIndex:[indexes indexAtIndex:index]];
				}
			}
		} else if (integer == 1) {// Always Ignore and Add
			for (SourceItem * sourceItem in dropboxSources) {
				NSInteger index = [sources indexOfObject:sourceItem];
				[self _insertUserSource:sourceItem atIndex:[indexes indexAtIndex:index]];
			}
		} else {// Cancel
			// Do Nothing
		}
	}
	
	if (privateSources.count > 0) {
		NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
		NSInteger integer = [userDefaults integerForKey:@"addingPrivateFolders"];
		if (integer == 0) {// Ask What to Do
			NSAlert * alert = [NSAlert alertWithMessageText:NSLocalizedString(@"You have added a System folder.", nil)
											  defaultButton:NSLocalizedString(@"Cancel", nil)
											alternateButton:NSLocalizedString(@"Ignore", nil)
												otherButton:nil
								  informativeTextWithFormat:NSLocalizedString(@"You have selected a folder that contains system folder, they may contains very important essantial to Mac OS system. If you really want to add this folder, click ignore.", nil)];
			
			[alert setAlertStyle:NSWarningAlertStyle];
			[alert setShowsSuppressionButton:YES];
			
			NSInteger result = [alert runModal];
			
			if ([[alert suppressionButton] state] == NSOnState) {
				if (result == NSAlertDefaultReturn) {// Cancel
					[userDefaults setInteger:2 forKey:@"addingPrivateFolders"];// Set Always Cancel
				} else if (result == NSAlertAlternateReturn) {// Ignore
					[userDefaults setInteger:1 forKey:@"addingPrivateFolders"];// Set Always Ignore and Add
				}
			}
			
			if (result == NSAlertDefaultReturn) {// Cancel
				// Do Nothing
			} else if (result == NSAlertAlternateReturn) {// Ignore
				for (SourceItem * sourceItem in privateSources) {
					NSInteger index = [sources indexOfObject:sourceItem];
					[self _insertUserSource:sourceItem atIndex:index];
				}
			}
		} else if (integer == 1) {// Always Ignore and Add
			for (SourceItem * sourceItem in privateSources) {
				NSInteger index = [sources indexOfObject:sourceItem];
				[self _insertUserSource:sourceItem atIndex:index];
			}
		} else {// Cancel
			// Do Nothing
		}
	}
	
	[privateSources release];
	[dropboxSources release];
	
	[self reloadSourceTableView];
	
	[self synchronizeUserDefaults];
}

- (void)_insertUserSource:(SourceItem *)item atIndex:(NSInteger)index
{
#if _SANDBOX_ACTIVITED_
	if ([SandboxHelper sandboxActivated]) {
		NSError * error = nil;
		NSURL * sourceURL = [NSURL fileURLWithPath:item.path];
		NSData * bookmarkData = [sourceURL bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope
									includingResourceValuesForKeys:nil
													 relativeToURL:nil// Use nil for app-scoped bookmark
															 error:&error];
		if (error) {
			NSDebugLog(@"error: %@", [error localizedDescription]);
		}
		
		NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
		NSMutableDictionary * sandboxBookmarks = [[userDefaults dictionaryForKey:@"sandboxBookmarks"] mutableCopy];
		if (!sandboxBookmarks)
			sandboxBookmarks = [[NSMutableDictionary alloc] initWithCapacity:1];
		
		[sandboxBookmarks setObject:bookmarkData forKey:item.path];
		[userDefaults setObject:sandboxBookmarks forKey:@"sandboxBookmarks"];
		[sandboxBookmarks release];
		[userDefaults synchronize];
	}
#endif
	
	item.selected = YES;
	
	/* Add observer to new item */
	[item addObserver:self forKeyPath:@"name" options:NSKeyValueObservingOptionOld context:NULL];
	[item addObserver:self forKeyPath:@"path" options:NSKeyValueObservingOptionOld context:NULL];
	[item addObserver:self forKeyPath:@"selected" options:NSKeyValueObservingOptionOld context:NULL];
	
	NSInteger newIndex = (index >= 0)? index: userSourceArray.count;
	[userSourceArray insertObject:item atIndex:newIndex];
	
	[[[sourceTableView undoManager] prepareWithInvocationTarget:self] deleteUserSourceAtIndex:newIndex];
}

- (IBAction)editSource:(id)sender
{
	NSInteger selectedRow = [sourceTableView selectedRow];
	if (selectedRow >= 1) {
		
		NSOpenPanel * openPanel = [NSOpenPanel openPanel];
		[openPanel setCanChooseDirectories:YES];
		[openPanel setCanChooseFiles:YES];
		[openPanel setAllowsMultipleSelection:NO];
		
		[openPanel setMessage:NSLocalizedString(@"Choose a directory or a file.", nil)];
		[openPanel setPrompt:NSLocalizedString(@"Choose", nil)];
		
		[openPanel beginSheetModalForWindow:[NSApp mainWindow] completionHandler:^(NSInteger result) {
			if (result == NSFileHandlingPanelOKButton) {
				
				SourceItem * sourceItem = [userSourceArray objectAtIndex:(selectedRow - 1)];
				
				NSURL * fileURL = [openPanel.URLs objectAtIndex:0];
				
#if _SANDBOX_ACTIVITED_
				if ([SandboxHelper sandboxActivated]) {
					NSError * error = nil;
					NSData * bookmarkData = [fileURL bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope
											  includingResourceValuesForKeys:nil
															   relativeToURL:nil// Use nil for app-scoped bookmark
																	   error:&error];
					if (error) {
						NSDebugLog(@"error: %@", [error localizedDescription]);
					}
					
					NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
					NSMutableDictionary * sandboxBookmarks = [[userDefaults dictionaryForKey:@"sandboxBookmarks"] mutableCopy];
					if (!sandboxBookmarks)
						sandboxBookmarks = [[NSMutableDictionary alloc] initWithCapacity:1];
					
					[sandboxBookmarks setObject:bookmarkData forKey:[fileURL path]];
					[userDefaults setObject:sandboxBookmarks forKey:@"sandboxBookmarks"];
					[sandboxBookmarks release];
					[userDefaults synchronize];
					
					BOOL isStale = NO;
					fileURL = [NSURL URLByResolvingBookmarkData:bookmarkData
														options:NSURLBookmarkResolutionWithSecurityScope
												  relativeToURL:nil// Use nil for an app-scoped bookmark (and not for a document-scoped bookmark)
											bookmarkDataIsStale:&isStale
														  error:NULL];
					[fileURL startAccessingSecurityScopedResource];
				}
#endif
				
				BOOL isDirectory = NO;
				[[NSFileManager defaultManager] fileExistsAtPath:[fileURL relativePath] isDirectory:&isDirectory];
				sourceItem.isFile = !isDirectory;
				
				NSString * path = [fileURL relativePath];
				if (isDirectory)
					path = [path stringByAppendingString:@"/"];
				
				[self setPath:path forItem:sourceItem];
				
				if ([SandboxHelper sandboxActivated]) {
					[fileURL stopAccessingSecurityScopedResource];
				}
			}
		}];
	}
}

- (void)synchronizeUserDefaults
{
	NSMutableArray * userSources = [[NSMutableArray alloc] initWithCapacity:userSourceArray.count];
	
	for (SourceItem * sourceItem in userSourceArray) {
		[userSources addObject:sourceItem.path];
	}
	
	NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
	[userDefaults setObject:userSources forKey:@"userSourceArray"];
	[userDefaults synchronize];
	
	[userSources release];
}

- (BOOL)folderIsPrivate:(NSString *)path
{
	/* Remove /Volumes/External HD/ subpath for non started volume */
	NSMutableArray * components = [[path componentsSeparatedByString:@"/"] mutableCopy];// components = { "", "Folder1", "Folder2", "Folder3" }
	if (components.count > 1 && [[components objectAtIndex:1] isEqualToString:@"Volumes"]) {// Other Mac OS X partition Volume
		[components removeObjectsInRange:NSMakeRange(1, 2)];// Remove "Volumes/" and "External HD/"
	}
	
	path = @"";
	for (NSString * subpath in components)
		if (subpath.length > 0) path = [path stringByAppendingFormat:@"/%@",subpath];
	
	[components release];
	
	/* For each privateFolder, check the first characters of privateFolder with path*/
	for (NSString * privateFolder in privateFolders) {
		if (path.length >= privateFolder.length) {
			NSRange range = NSMakeRange(0, privateFolder.length);
			if ([[path substringWithRange:range] isEqualToString:privateFolder])
				return YES;
		}
	}
	return NO;
}

- (BOOL)isDropboxFolder:(NSString *)path
{
	/*
	 Returns YES if path begins by:
	 /Users/Max/Dropbox
	 /Volumes/Macintosh HD (Lion)/Users/Max/Dropbox
	 */
	
	NSArray * components = [path componentsSeparatedByString:@"/"];// components = { "", "Folder1", "Folder2", "Folder3" }
	if (components.count > 1 && [[components objectAtIndex:1] isEqualToString:@"Users"]) {// Started Volume
		if (components.count > 3 && [[components objectAtIndex:3] isEqualToString:@"Dropbox"])
			return YES;
		
	} else if (components.count > 3 && [[components objectAtIndex:3] isEqualToString:@"Users"]) {// Other Mac OS X partition Volume
		if (components.count > 5 && [[components objectAtIndex:5] isEqualToString:@"Dropbox"])
			return YES;
	}
	
	return NO;
}

- (BOOL)path:(NSString *)path1 containsFolder:(NSString *)path2
{
	// @TODO: test it!
	NSMutableArray * components1 = [[path1 componentsSeparatedByString:@"/"] mutableCopy];// components1 = { "", "Volumes", "Macintosh HD (Lion)", "Users", ...}
	[components1 removeObjectsWithValue:@""];// Remove all "" string (like the first one)
	
	if (components1.count > 3 && [[components1 objectAtIndex:1] isEqualToString:@"Volumes"]) {// If path is like Volumes/Macintosh HD (Lion)/Users/Max/Folder1/
		[components1 removeObjectAtIndex:1];// Remove "Macintosh HD (Lion)"
		[components1 removeObjectAtIndex:0];// Remove "Volumes"
		// Path is now like /Users/Max/Folder1/
	}
	
	NSMutableArray * components2 = [[path2 componentsSeparatedByString:@"/"] mutableCopy];
	[components2 removeObjectsWithValue:@""];
	
	if (components1.count > 3 && [[components1 objectAtIndex:1] isEqualToString:@"Volumes"]) {// If path is like Volumes/Macintosh HD (Lion)/Users/Max/Folder1/
		[components1 removeObjectAtIndex:1];// Remove "Macintosh HD (Lion)"
		[components1 removeObjectAtIndex:0];// Remove "Volumes"
		// Path is now like /Users/Max/Folder1/
	}
	
	BOOL isEqual = YES;
	int indexLimit = MIN(components1.count, components2.count);
	for (int index = 0; index < indexLimit; index++) {
		NSString * string1 = [components1 objectAtIndex:index];
		NSString * string2 = [components2 objectAtIndex:index];
		isEqual &= [string1 isEqualToString:string2];
	}
	
	[components1 release];
	[components2 release];
	
	return isEqual;
}

- (BOOL)pathContainsPrivateFolders:(NSString *)path
{
	BOOL contains = NO;
	for (NSString * privateFolder in privateFolders) {
		/* contains == YES if path contains one of private folders */
		contains |= [self path:path containsFolder:privateFolder];
	}
	
	return contains;
}

#pragma mark -
#pragma mark sourceOutlineView Delegate

- (BOOL)tableView:(SourceTableView *)tableView didReceiveDraggingObjects:(NSArray *)objects
{
	NSMutableArray * paths = [objects mutableCopy];
	
	NSMutableArray * existingPaths = [[NSMutableArray alloc] initWithCapacity:(defaultSourceArray.count + userSourceArray.count)];
	
	for (SourceItem * item in defaultSourceArray) {
		[existingPaths addObject:item.path];
	}
	
	for (SourceItem * item in userSourceArray) {
		[existingPaths addObject:item.path];
	}
	
	NSMutableArray * items = [[NSMutableArray alloc] initWithCapacity:paths.count];
	/* Add others paths to sources */
	for (NSString * path in paths) {
		
		BOOL isDirectory = NO;
		[[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory];
		
		if (isDirectory)
			path = [path stringByAppendingString:@"/"];
		
		if (![existingPaths containsObject:path]) {
			SourceItem * sourceItem = [[SourceItem alloc] init];
			sourceItem.isFile = !isDirectory;
			
			sourceItem.name = [path lastPathComponent];
			sourceItem.path = path;
			
			sourceItem.selected = YES;
			
			[items addObject:sourceItem];
			
			[sourceItem release];
		}
	}
	
	[paths release];
	[existingPaths release];
	
	[self insertUserSources:items atIndexes:[NSIndexSet indexSetWithIndex:-1]];
	[items release];
	
	[self reloadSourceTableView];
	
	return YES;
}

#pragma mark -
- (void)reloadSourceTableView
{
	if (userSourceArray.count == 0) {// Show the placeholder if no sources
		[noSourcesView removeFromSuperview];
		[sourceTableView addSubview:noSourcesView];
		noSourcesView.autoresizingMask = (NSViewMaxYMargin | NSViewMinXMargin | NSViewWidthSizable);
	} else {
		[noSourcesView removeFromSuperview];
	}
	
	[deleteSourceButton setEnabled:(userSourceArray.count > 0)];
	[editSourceButton setEnabled:(userSourceArray.count > 0)];
	
	[sourceTableView reloadData];
}

#pragma mark -
#pragma mark NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	if (aTableView == sourceTableView) {
		if (userSourceArray.count > 0)
			return (userSourceArray.count + 1);
		
		return 0;
		
	} else {
		return optionItems.count;
	}
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
	if (tableView == sourceTableView) {
		if (row == 0)// 20px for sections
			return 20.;
		
		return [SourceTableViewCell defaultHeight];
	} else {
		if ([self tableView:tableView rowIsGroupRow:row]) {
			return 32.;
		} if ([[optionItems objectAtIndex:row] isKindOfClass:[NSString class]]) {
			return 14.;
		} else {
			return 17.;
		}
	}
}

- (BOOL)tableView:(NSTableView *)tableView rowIsGroupRow:(NSInteger)row
{
	if (tableView == sourceTableView) {
		return (row == 0);
	} else {
		return ([[optionItems objectAtIndex:row] isKindOfClass:[Section class]]);
	}
}

- (BOOL)tableView:(NSTableView *)aTableView isGroupRow:(NSInteger)row
{
	return [self tableView:aTableView rowIsGroupRow:row];
}

- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(NSInteger)rowIndex
{
	if (aTableView == sourceTableView) {
		if (rowIndex >= 1) {
			SourceItem * item = (SourceItem *)[userSourceArray objectAtIndex:(rowIndex - 1)];
			return (![self tableView:aTableView rowIsGroupRow:rowIndex] && ![self sourcePathIsBlacklisted:item.path]);
		}
	} else {
		return NO;
		//return ![self tableView:aTableView rowIsGroupRow:rowIndex];
	}
	return NO;
}

- (NSCell *)tableView:(NSTableView *)aTableView dataCellForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)row
{
	NSCell * cell = [aTableColumn dataCellForRow:row];
	if (aTableView == sourceTableView) {
		if ([self tableView:aTableView rowIsGroupRow:row]) {
			if (!cell) {
				cell = [[[SectionSourceTableViewCell alloc] init] autorelease];
			}
			
		} else {
			if ([[aTableColumn identifier] isEqualToString:@"title"]) {
				SourceItem * item = (SourceItem *)[userSourceArray objectAtIndex:(row - 1)];
				[cell setTitle:item.name];
				[cell setImage:item.image];
				
				SourceTableViewCell * cell = [aTableColumn dataCellForRow:row];
				cell.disabled = ([self sourcePathIsBlacklisted:item.path]);
			}
		}
	} else {
		if ([[optionItems objectAtIndex:row] isKindOfClass:[Section class]]) {
			
			/* Hide check box for Section and title for left part */
			if ([aTableColumn.identifier isEqualToString:@"descriptionLeft-check"]) {
				return [[[NSCell alloc] init] autorelease];
			} else if ([aTableColumn.identifier isEqualToString:@"descriptionRight-check"]) {
				return [[[NSCell alloc] init] autorelease];
			} else if ([aTableColumn.identifier isEqualToString:@"descriptionRight"]) {
				return nil;
			}
			
		} else if ([[optionItems objectAtIndex:row] isKindOfClass:[NSString class]]) {
			NSTextFieldCell * textFieldCell = [[[NSTextFieldCell alloc] init] autorelease];
			textFieldCell.font = [NSFont systemFontOfSize:10.];
			textFieldCell.textColor = [NSColor grayColor];
			return textFieldCell;
		} else {
			NSArray * items = [optionItems objectAtIndex:row];
			
			if (items.count == 1) {
				if ([aTableColumn.identifier isEqualToString:@"descriptionRight-check"]) {
					return [[[NSCell alloc] init] autorelease];
				} else if ([aTableColumn.identifier isEqualToString:@"descriptionRight"]) {
					return nil;
				}
			}
		}
	}
	
	return cell;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	if (aTableView == sourceTableView) {
		/* Return Sections Title */
		if (rowIndex == 0)
			return NSLocalizedString(@"SOURCES_SECTION_TITLE", nil);
		
		id object = nil;
		if ([[aTableColumn identifier] isEqualToString:@"check"]) {
			SourceItem * item = [userSourceArray objectAtIndex:(rowIndex - 1)];
			if ([self sourcePathIsBlacklisted:item.path]) {
				NSCell * cell = [aTableColumn dataCellForRow:rowIndex];
				[(NSButtonCell *)cell setEnabled:NO];
			} else {
				object = [NSNumber numberWithBool:item.selected];
			}
		} else if ([[aTableColumn identifier] isEqualToString:@"title"]) {
		}
		return object;
		
	} else {
		
		if ([[optionItems objectAtIndex:rowIndex] isKindOfClass:[Section class]]) {
			
			if ([aTableColumn.identifier isEqualToString:@"descriptionLeft-check"]) {
				return nil;
			} else if ([aTableColumn.identifier isEqualToString:@"descriptionLeft"]) {
				return [(Section *)[optionItems objectAtIndex:rowIndex] localizedDescriptionString];
			}
			
		} else if ([[optionItems objectAtIndex:rowIndex] isKindOfClass:[NSString class]]) {
			NSString * string = [optionItems objectAtIndex:rowIndex];
			return string;
		} else {
			NSArray * items = [optionItems objectAtIndex:rowIndex];
			
			if (items.count > 0) {
				OptionItem * item = [items objectAtIndex:0];
				if ([aTableColumn.identifier isEqualToString:@"descriptionLeft-check"]) {
					return item.selected;
				} else if ([aTableColumn.identifier isEqualToString:@"descriptionLeft"]) {
					return [item localizedDescription];
				} else {
					if (items.count > 1) {
						OptionItem * item = [items objectAtIndex:1];
						if ([aTableColumn.identifier isEqualToString:@"descriptionRight-check"]) {
							return item.selected;
						} else if ([aTableColumn.identifier isEqualToString:@"descriptionRight"]) {
							return [item localizedDescription];
						}
					}
				}
			}
		}
	}
	
	return nil;
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	if (aTableView == sourceTableView) {
		if ([[aTableColumn identifier] isEqualToString:@"check"]) {
			SourceItem * item = [userSourceArray objectAtIndex:(rowIndex - 1)];
			item.selected = [anObject boolValue];
		}
		
		[aTableView reloadData];
		
	} else {
		if ([[optionItems objectAtIndex:rowIndex] isKindOfClass:[Section class]]) {
			
			if ([aTableColumn.identifier isEqualToString:@"descriptionLeft-check"]) {
				
			}
			
		} else {
			NSArray * items = [optionItems objectAtIndex:rowIndex];
			
			OptionItem * item = [items objectAtIndex:0];
			if ([aTableColumn.identifier isEqualToString:@"descriptionLeft-check"]) {
				item.selected = anObject;
			} else if ([aTableColumn.identifier isEqualToString:@"descriptionLeft"]) {
			} else if (items.count > 1) {
				OptionItem * item = [items objectAtIndex:1];
				if ([aTableColumn.identifier isEqualToString:@"descriptionRight-check"]) {
					item.selected = anObject;
				} else if ([aTableColumn.identifier isEqualToString:@"descriptionRight"]) {
				}
			}
		}
	}
}

#pragma mark NSTableViewDelegate

- (BOOL)tableView:(NSTableView *)tableView shouldTrackCell:(NSCell *)cell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	return YES;// Tracks button's cell because cell are not selectable so by default button's cell can't be selected as well
}

#pragma mark NSTableView Drag & Drop

- (BOOL)tableView:(NSTableView *)aTableView acceptDrop:(id < NSDraggingInfo >)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)operation
{
	return NO;
}

- (NSDragOperation)tableView:(NSTableView *)aTableView validateDrop:(id < NSDraggingInfo >)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)operation
{
	return NSDragOperationNone;
}

- (BOOL)tableView:(NSTableView *)aTableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard
{
	return NO;
}

#pragma mark NSTableView Tooltips

- (NSString *)tableView:(NSTableView *)aTableView toolTipForCell:(NSCell *)aCell rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)row mouseLocation:(NSPoint)mouseLocation
{
	NSString * tooltip = nil;
	if (aTableView == sourceTableView) {
		if (0 <= (row - 1) && (row - 1) < userSourceArray.count) {
			SourceItem * item = [userSourceArray objectAtIndex:(row - 1)];
			tooltip = item.path;
		}
	} else {
		
	}
	
	return tooltip;
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	NSTableView * tableView = [aNotification object];
	if (tableView == sourceTableView) {
		NSInteger rowIndex = [sourceTableView selectedRow];
		if (0 < rowIndex) {
			[deleteSourceButton setEnabled:YES];
			[editSourceButton setEnabled:YES];
		} else {
			[deleteSourceButton setEnabled:NO];
			[editSourceButton setEnabled:NO];
		}
	} else {
		
	}
}

@end

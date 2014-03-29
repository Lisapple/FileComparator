//
//  OptionsViewController.h
//  Comparator
//
//  Created by Max on 18/04/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "SourceTableView.h"
#import "SourceTableViewCell.h"

#import "OptionItem.h"

@class SourceItem;

@class ExcludedExtensionsWindow;
@class FileSizeSettingsWindow;

@interface OptionsViewController : NSViewController <NSTableViewDelegate, NSTableViewDataSource, SourceTableViewDelegate, NSOutlineViewDelegate, NSOutlineViewDataSource, NSSplitViewDelegate>
{
	IBOutlet NSButton * sizeCheckBox, * filenameCheckBox, * extensionCheckBox, * typeCheckBox, * creationDateCheckBox, * lastModificationDateCheckBox, * dataCheckBox;
	
	IBOutlet NSButton * includeFoldersComparaison, * includeHiddenItemsCheckBox, * includeBundleContentCheckBox;
	
	IBOutlet ExcludedExtensionsWindow * excludedExtensionsWindow;
	IBOutlet FileSizeSettingsWindow * fileSizeSettingsWindow;
	
	IBOutlet SourceTableView * sourceTableView;
	IBOutlet NSButton * deleteSourceButton, * editSourceButton;
	
	IBOutlet NSTableView * optionsTableView;
	IBOutlet NSOutlineView * optionsOutlineView;
	
	IBOutlet NSSplitView * splitView;
	
	IBOutlet NSView * noSourcesView;
	
@private
	NSMutableArray * defaultSourceArray, * userSourceArray;
	NSArray * privateFolders;
	
	NSArray * optionItems;
}

@property (assign) IBOutlet ExcludedExtensionsWindow * excludedExtensionsWindow;
@property (assign) IBOutlet FileSizeSettingsWindow * fileSizeSettingsWindow;

@property (assign) IBOutlet SourceTableView * sourceTableView;
@property (assign) IBOutlet NSButton * deleteSourceButton, * editSourceButton;

@property (assign) IBOutlet NSTableView * optionsTableView;
@property (assign) IBOutlet NSOutlineView * optionsOutlineView;

@property (assign) IBOutlet NSView * noSourcesView;

- (IBAction)showHelp:(id)sender;

- (IBAction)save:(id)sender;

#pragma mark KVO compliant

- (void)changeKeyPath:(NSString *)keyPath ofObject:(id)object toValue:(id)newValue;

#pragma mark Source Actions

- (IBAction)addNewSource:(id)sender;
- (void)insertUserSource:(SourceItem *)item atIndex:(NSInteger)index;
- (void)insertUserSources:(NSArray *)sources atIndexes:(NSIndexSet *)indexes;

- (IBAction)editSource:(id)sender;
- (void)setPath:(NSString *)path forItem:(SourceItem *)item;

- (IBAction)deleteSource:(id)sender;
- (void)deleteSourceAtIndex:(NSInteger)index;

- (void)synchronizeUserDefaults;

- (BOOL)folderIsPrivate:(NSString *)path;
- (BOOL)isDropboxFolder:(NSString *)path;

- (BOOL)pathContainsPrivateFolders:(NSString *)path;

#pragma mark Spotlight Search List

- (void)stopSearching;


- (void)deleteUserSourceAtIndex:(NSInteger)index;


#pragma mark -
- (void)reloadSourceTableView;

@end

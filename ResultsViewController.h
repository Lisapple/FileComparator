//
//  ResultsViewController.h
//  Comparator
//
//  Created by Max on 18/04/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>

#import "CompareWindow.h"

#import "SummaryView.h"
#import "CenteredView.h"

#import "GridView.h"
#import "BackHeaderView.h"

#import "TabView.h"

#import "FileItem.h"
#import "ImageItem.h"
#import "AudioItem.h"
#import "OptionItem.h"

@interface RightPanelScrollView : NSScrollView
@end

@interface GridItem (addition)

@property (nonatomic, assign) NSManagedObject * managedObject;
@property (nonatomic, assign) NSManagedObject * group;

@end

@interface FileItem (QLPreviewItem) <QLPreviewItem>

@end


@class SourceTableView;
@class ResultsViewControllerSourceList;

@protocol ResultsViewControllerSourceListDelegate

@optional
- (NSInteger)tableView:(SourceTableView *)aTableView badgeCountForRow:(NSInteger)row;

@end

@interface ResultsViewControllerSourceList : NSObject <NSTableViewDelegate, NSTableViewDataSource, ResultsViewControllerSourceListDelegate>
{
	NSObject <ResultsViewControllerSourceListDelegate> * sourceDelegate;
}

@property (nonatomic, retain) NSObject * sourceDelegate;

+ (id)sharedInstance;

@end


typedef enum {
	SourceTypeDuplicates = 0,
	SourceTypeEmptyItems,
	SourceTypeBrokenAliases,
} SourceType;

typedef enum {
	DuplicateTypeAll = 0,
	DuplicateTypeFiles = 2,/* Start at two to skip the separator between "All Duplicates" and "File Duplicates" */
	DuplicateTypeImages,
	DuplicateTypeAudioFiles
} DuplicateType;

@interface ResultsViewController : NSViewController <NSTabViewDelegate, QLPreviewPanelDelegate, QLPreviewPanelDataSource, GridViewDelegate, GridViewDataSource, NSSplitViewDelegate, NSTableViewDelegate, NSTableViewDataSource, TabViewDelegate>
{
	IBOutlet TabView * __strong _tabView;
	
	/* Buttons at bottom */
	IBOutlet NSButton * __strong moveButton, * __strong replaceButton;
	IBOutlet NSButton * __strong moveToTrashButton, * __strong deleteButton;
	
	IBOutlet NSTableView * __strong panelTableView;
	
	IBOutlet NSView * __strong previewPanelView;
	IBOutlet NSImageView * __strong previewImageView;
	IBOutlet NSButton * __strong compareButton;
	IBOutlet NSButton * __strong moveToTrash;
	IBOutlet NSButton * __strong replaceWithAliasButton, * __strong setAsOriginalButton;
	
	IBOutlet NSSplitView * splitView;
	
	IBOutlet GridView * __strong gridView;
	
	IBOutlet CompareWindow * compareWindow;
	
	IBOutlet NSButton * __strong keepHierarchyCheckbox;
	IBOutlet NSView * __strong movedPanelAccessoryView;
	
	NSMutableArray * duplicatesArrays;
	NSMutableArray * emptyItems;
	NSMutableArray * brokenAliases;
	
	SourceType selectedSourceType;
	DuplicateType selectedDuplicateType;
	
	NSMutableArray * _items;
	
@private
	NSMutableArray * sourceArray;
	
	NSManagedObject * currentGroup;
	
	NSDictionary * itemsPanelAttributes;
	NSArray * panelRows;
	
	IBOutlet BackHeaderView * backHeaderView;
	
	NSMutableArray * duplicatesToDelete, * emptyItemsToDelete, * brokenAliasesToDelete;
	NSMutableArray * itemsToReplace;
	
	BOOL showSummaryView;
	
	SummaryView * __strong _summaryResultsView;
	CenteredView * __strong _summaryCenteredView;
	
	NSSplitView * __strong _splitView;
}

@property (strong) IBOutlet TabView * tabView;

/* Buttons at bottom */
@property (strong) IBOutlet NSButton * moveButton, * replaceButton;
@property (strong) IBOutlet NSButton * moveToTrashButton, * deleteButton;

@property (strong) IBOutlet NSTableView * panelTableView;

@property (strong) IBOutlet NSView * previewPanelView;
@property (strong) IBOutlet NSImageView * previewImageView;
@property (strong) IBOutlet NSButton * compareButton;
@property (strong) IBOutlet NSButton * moveToTrash;
@property (strong) IBOutlet NSButton * replaceWithAliasButton, * setAsOriginalButton;

@property (strong) IBOutlet SummaryView * summaryResultsView;
@property (strong) IBOutlet CenteredView * summaryCenteredView;

@property (strong) IBOutlet NSSplitView * splitView;

@property (strong) IBOutlet GridView * gridView;

@property (strong) IBOutlet NSButton * keepHierarchyCheckbox;
@property (strong) IBOutlet NSView * movedPanelAccessoryView;

@property (nonatomic, strong) NSMutableArray * duplicatesArrays;
@property (nonatomic, strong) NSMutableArray * emptyItems;
@property (nonatomic, strong) NSMutableArray * brokenAliases;

@property (nonatomic, strong, readonly) NSMutableArray * items;

// Private
@property (nonatomic, strong) NSMutableArray * sourceArray;





#pragma mark Items
- (NSEntityDescription *)entityForDuplicateType:(DuplicateType)type context:(NSManagedObjectContext *)context;
- (NSInteger)numberOfItemsForDuplicateType:(DuplicateType)type;
- (NSArray *)groupsForDuplicateType:(DuplicateType)type;
- (NSArray *)allItemsForDuplicateType:(DuplicateType)type;
- (NSArray *)duplicatesForDuplicateType:(DuplicateType)type;
- (NSInteger)numberOfDuplicatesForDuplicateType:(DuplicateType)type;
- (unsigned long long)sizeOfDuplicatesForDuplicateType:(DuplicateType)type;

#pragma mark Core Data Items Management
- (void)deleteItems:(NSArray *)items;

#pragma mark Summary View
- (void)reloadSummaryView;
- (IBAction)dismissSummaryResultsView:(id)sender;

#pragma mark Bottom Buttons Actions
- (IBAction)moveAction:(id)sender;
- (IBAction)replaceAction:(id)sender;
- (IBAction)moveToTrashAction:(id)sender;
- (IBAction)deleteAction:(id)sender;



// Private
- (IBAction)doneAction:(id)sender;

- (IBAction)showHelpAction:(id)sender;

- (void)reloadData;
- (void)updateContent;

- (void)selectSourceType:(SourceType)type;
- (void)selectDuplicateType:(DuplicateType)type;

- (IBAction)duplicateTypeDidChangeAction:(id)sender;



- (IBAction)moveToAction:(id)sender;
- (void)moveItems:(NSArray *)items toPath:(NSString *)path;
- (BOOL)moveItems:(NSArray *)items toFolder:(NSString *)folder keepHierarchy:(BOOL)keepHierarchy movedItems:(NSArray **)movedItems;

- (NSString *)rootPathForPaths:(NSArray *)paths;

- (BOOL)moveItemToTrash:(FileItem *)item;
- (BOOL)moveItemsToTrash:(NSArray *)array;

//- (IBAction)checkAll:(id)sender;
//- (IBAction)uncheckAll:(id)sender;
//- (IBAction)checkAllSelected:(id)sender;
//- (IBAction)uncheckAllSelected:(id)sender;
//- (IBAction)checkAllDuplicates:(id)sender;
//- (IBAction)refresh:(id)sender;

//- (IBAction)replaceByAliasToOriginal:(id)sender;
- (BOOL)createAlias:(NSString *)originalPath toPath:(NSString *)toPath;
- (void)deleteAlias:(NSString *)path;

- (IBAction)revealInFinder:(id)sender;

//- (BOOL)rowIsGroupRow:(NSInteger)row;

- (IBAction)compareSelectedItems:(id)sender;

- (IBAction)gridBackButtonAction:(id)sender;


- (BOOL)replaceItemsWithAliasToOriginalItem:(NSArray *)items replacedItems:(NSArray **)replacedItems;

//- (IBAction)moveToTrashAllItems:(id)sender;
//- (IBAction)replaceAllItems:(id)sender;


- (NSInteger)currentTaskCount;

- (FileItem *)originalItemForGroup:(NSManagedObject *)group;

- (IBAction)setAsOriginalAction:(id)sender;


- (IBAction)selectAll:(id)sender;
- (IBAction)selectDuplicates:(id)sender;
- (IBAction)deselectAll:(id)sender;
- (IBAction)deleteSelected:(id)sender;

//- (NSArray *)gridItemsForSection:(NSInteger)section;
//- (IBAction)changeTrashStateAction:(id)sender;
//- (IBAction)changeAliasStateAction:(id)sender;
- (void)reloadRightPanelWithItems:(NSArray *)gridItems;

#pragma mark Right Panel
- (void)reloadRightPanel;


- (IBAction)dismissSummaryResultsView:(id)sender;

@end

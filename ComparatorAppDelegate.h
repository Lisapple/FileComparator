//
//  ComparatorAppDelegate.h
//  Comparator
//
//  Created by Max on 3/21/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CoreData/CoreData.h>

#import <IOKit/pwr_mgt/IOPMLib.h> /* For "IOPMAssertionCreateWithName(...)" */

#import "MainViewController.h"
#import "ResultsViewController.h"

#import "MyWindow.h"
#import "MyBigProgressIndicator.h"

@class FileItem;

@class OptionsViewController;
@class ResultsViewController;
@class ApplicationPreferencesWindow;

@class TransitionView;

typedef NS_ENUM(NSUInteger, ContentViewType) {
	ContentViewTypeStart,
	ContentViewTypeAnalysing,
	ContentViewTypeResults
};

@interface ComparatorAppDelegate : NSObject <NSApplicationDelegate, NSTableViewDelegate, NSTableViewDataSource, NSSplitViewDelegate, NSWindowDelegate>
{
    IBOutlet NSWindow * __strong window;
	
	IBOutlet NSTextField * progressLabel;
	IBOutlet TransitionView * analysingView;
	
	IBOutlet ApplicationPreferencesWindow * preferencesWindow;
	
	/*** Main Menu Items ***/
	/* "File" Items  */
	IBOutlet NSMenuItem * __strong chooseSourceMenuItem;
	IBOutlet NSMenuItem * __strong exportAsTextMenuItem, * __strong exportAsXMLMenuItem;
	
	/* "Edit" Items */
	IBOutlet NSMenuItem * __strong selectAllMenuItem, * __strong selectAllDuplicatesMenuItem, * __strong deselectAllMenuItem, * __strong deleteSelectedMenuItem;
	
	/* "View" Items */
	IBOutlet NSMenuItem * __strong quickLookMenuItem;
	
	/* "Window" Items */
	IBOutlet NSMenuItem * __strong mainWindowMenuItem;
	
	NSOperationQueue * queue;
	
	NSMutableArray * items;
	
	NSMutableArray * fileURLs;
	NSArray * sourceURLs;
	
	//NSMutableArray * emptyFoldersURLs;
	NSMutableArray * emptyFilesURLs;
	
	NSMutableArray * duplicatesArrays;
	NSMutableArray * emptyItems;
	NSMutableArray * brokenAliasItems;
	
	@private
	
	//NSInteger _notificationCount;
	
	ContentViewType contentViewType;
	
	BOOL _cancelled, _working;
	
	IOPMAssertionID preventSleepID;
	
	/*** Transition View Outlets ***/
	NSTextField * __strong _progressLabel, * __strong _currentFileLabel;
	CenteredView * __strong _transitionCenteredView;
	MyBigProgressIndicator * __strong progressIndicator;
	
	/*** View's Controllers ***/
	MainViewController * __strong _mainViewController;
	ResultsViewController * __strong _resultsViewController;
}

@property (nonatomic, strong, readonly) NSPersistentStoreCoordinator * persistentStoreCoordinator;
@property (nonatomic, strong, readonly) NSManagedObjectModel * managedObjectModel;
@property (nonatomic, strong, readonly) NSManagedObjectContext * managedObjectContext;

@property (strong) IBOutlet NSWindow * window;

/* Main Menu Items */
@property (strong) IBOutlet NSMenuItem * chooseSourceMenuItem;
@property (strong) IBOutlet NSMenuItem * exportAsTextMenuItem, * exportAsXMLMenuItem;
@property (strong) IBOutlet NSMenuItem * selectAllMenuItem, * selectAllDuplicatesMenuItem, * deselectAllMenuItem, * deleteSelectedMenuItem;
@property (strong) IBOutlet NSMenuItem * quickLookMenuItem;
@property (strong) IBOutlet NSMenuItem * mainWindowMenuItem;

/*** Transition View Outlets ***/
@property (strong) IBOutlet NSTextField * progressLabel, * currentFileLabel;
@property (strong) IBOutlet CenteredView * transitionCenteredView;
@property (strong) IBOutlet MyBigProgressIndicator * progressIndicator;

/*** View's Controllers ***/
@property (strong) IBOutlet MainViewController * mainViewController;
@property (strong) IBOutlet ResultsViewController * resultsViewController;


@property (nonatomic, strong) NSOperationQueue * queue;

//@property (nonatomic, strong) NSMutableArray * fileURLs;

@property (nonatomic, assign) BOOL working;

#pragma mark IBAction

- (IBAction)startAction:(id)sender;
- (IBAction)stopAction:(id)sender;

- (IBAction)backToMainView:(id)sender;
- (IBAction)reopenMainWindow:(id)sender;
- (IBAction)openWebsiteAction:(id)sender;
- (IBAction)openSupportAction:(id)sender;

- (IBAction)showPreferences:(id)sender;

- (IBAction)toggleQuickLook:(id)sender;

/*
- (IBAction)runAnalysing:(id)sender;
- (IBAction)cancelOperation:(id)sender;
*/

//- (IBAction)showOptions:(id)sender;

#pragma mark Export to File
- (IBAction)exportAsText:(id)sender;
- (IBAction)exportAsXML:(id)sender;

#pragma mark Box content
- (void)setContentViewType:(ContentViewType)type;

#pragma mark Comparing Items
- (void)compareType:(NSString *)type forGroup:(NSString *)groupType withOptions:(NSArray *)options;
- (void)compareAllItems;

#pragma mark Automatically Comparing Items
- (void)automaticallyCompare:(NSString *)type;
- (void)automaticallyCompareType:(NSString *)type forGroup:(NSString *)groupType;

@end

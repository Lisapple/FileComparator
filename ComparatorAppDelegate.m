//
//  ComparatorAppDelegate.m
//  Comparator
//
//  Created by Max on 3/21/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

#import "ComparatorAppDelegate.h"

#import "ApplicationPreferencesWindow.h"

#import "FileItem.h"
#import "ImageItem.h"
#import "AudioItem.h"

#import "TransitionView.h"

#import "GetFilesOperation.h"

#import "SandboxHelper.h"

@interface ComparatorAppDelegate ()
{
	NSInteger numberOfFinishedGetFilesOperations;
}

@property (atomic, strong) NSPersistentStoreCoordinator * persistentStoreCoordinator;
@property (atomic, strong) NSManagedObjectModel * managedObjectModel;
@property (atomic, strong) NSManagedObjectContext * managedObjectContext;

- (BOOL)startPreventingFromSleeping;
- (void)stopPreventingFromSleeping;

@end


@implementation ComparatorAppDelegate

@synthesize window;

@synthesize chooseSourceMenuItem;
@synthesize exportAsTextMenuItem, exportAsXMLMenuItem;
@synthesize selectAllMenuItem, selectAllDuplicatesMenuItem, deselectAllMenuItem, deleteSelectedMenuItem;
@synthesize quickLookMenuItem;
@synthesize mainWindowMenuItem;

@synthesize progressLabel = _progressLabel, currentFileLabel = _currentFileLabel;
@synthesize transitionCenteredView = _transitionCenteredView;
@synthesize progressIndicator;

@synthesize mainViewController = _mainViewController;
@synthesize resultsViewController = _resultsViewController;

@synthesize queue;

@synthesize working = _working;

const double kBackgroundPriority = 1;

#pragma mark -
#pragma mark NSApplicationDelegate

- (void)applicationWillFinishLaunching:(NSNotification *)notification
{
	[OptionItem managedObjectContext];// Call this into the main thread to be sure that the context will be accessible from the main thread
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(operationDidFinish:)
												 name:@"GetFilesOperationDidFinishNotification"
											   object:nil];
	
	[[NSHelpManager sharedHelpManager] registerBooksInBundle:[NSBundle mainBundle]];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	_transitionCenteredView.verticallyCentered = YES;
	_transitionCenteredView.offsetEdge = RectEdgeMake(0., 0., 60., 0.);
	[self setContentViewType:ContentViewTypeStart];
	
	[window setExcludedFromWindowsMenu:YES];
	
	window.delegate = self;
	[window makeKeyAndOrderFront:nil];
	
	/* Exclude System and Library Folders by default */
	NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
	if (![userDefaults objectForKey:@"Exclude System and Library Folders"]) {// If no entry of the key, set to "YES"
		[userDefaults setBool:YES forKey:@"Exclude System and Library Folders"];
	}
}

- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename
{
	NSDebugLog(@"openFile: %@", filename);
	
	return YES;
}

- (void)application:(NSApplication *)sender openFiles:(NSArray *)filenames
{
	NSDebugLog(@"openFiles: %@", filenames);
}

- (void)updateDockTitleProgression:(float)progression
{
	if ([self.window isMiniaturized]) {
		NSSize size = [NSApp dockTile].size;
		NSRect frame = NSMakeRect(0., 0., size.width, size.height);
		NSImageView * imageView = [[NSImageView alloc] initWithFrame:frame];
		[imageView setImage:[NSApp applicationIconImage]];
		
		frame = NSMakeRect(0., size.height / 2., size.width / 2., size.height / 2.);
		NSProgressIndicator * aProgressIndicator = [[NSProgressIndicator alloc] initWithFrame:frame];
		[aProgressIndicator setIndeterminate:NO];
		[aProgressIndicator setDoubleValue:(double)(progression * 100.)];
		[aProgressIndicator setStyle:NSProgressIndicatorSpinningStyle];
		[imageView addSubview:aProgressIndicator];
		
		[[NSApp dockTile] setContentView:imageView];
		[[NSApp dockTile] display];
	}
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)hasVisibleWindows
{
	[window makeKeyAndOrderFront:nil];
	return YES;
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
	NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
	NSDebugLog(@"applicationShouldTerminateAfterLastWindowClosed: %@", ([userDefaults boolForKey:@"shouldTerminateAfterLastWindowClosed"])? @"YES": @"NO");
	return [userDefaults boolForKey:@"shouldTerminateAfterLastWindowClosed"];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
}

- (IBAction)backToMainView:(id)sender
{
	[self setContentViewType:ContentViewTypeStart];
}

- (IBAction)reopenMainWindow:(id)sender
{
	[window makeKeyAndOrderFront:sender];
}

- (IBAction)openWebsiteAction:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://lisacintosh.com/file-comparator/"]];
}

- (IBAction)openSupportAction:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://support.lisacintosh.com/file-comparator/"]];
}

#pragma mark -
#pragma mark Core Data

/**
 Creates, retains, and returns the managed object model for the application
 by merging all of the models found in the application bundle.
 */

- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel)
		return _managedObjectModel;
	
    _managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
    return _managedObjectModel;
}


/**
 Returns the persistent store coordinator for the application.  This
 implementation will create and return a coordinator, having added the
 store for the application to it.  (The directory for the store is created,
 if necessary.)
 */

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator)
		return _persistentStoreCoordinator;
	
    NSManagedObjectModel * model = [self managedObjectModel];
    if (!model) {
		[NSException raise:@"NSComparatorAppDelegate"
					format:@"%@:%@ No model to generate a store from", [self class], NSStringFromSelector(_cmd)];
        return nil;
    }
	
	_persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
	if (!_persistentStoreCoordinator) {
		[NSException raise:@"NSComparatorAppDelegate"
					format:@"Persitistent store coordinator can't be created from model: %@", model];
		return nil;
	}
	
	NSError *error = nil;
	NSString * storeType = NSInMemoryStoreType;
	NSPersistentStore * persistentStore = [_persistentStoreCoordinator addPersistentStoreWithType:storeType
																				   configuration:nil
																							 URL:nil
																						 options:nil
																						   error:&error];
    if (!persistentStore){
        [[NSApplication sharedApplication] presentError:error];
		_persistentStoreCoordinator = nil;
		
        return nil;
    }
	
    return _persistentStoreCoordinator;
}

/**
 Returns the managed object context for the application (which is already
 bound to the persistent store coordinator for the application.)
 */

// @TODO: Create a global class to get and save the managedObjectContext
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext)
		return _managedObjectContext;
	
    NSPersistentStoreCoordinator * coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        NSMutableDictionary * dict = [NSMutableDictionary dictionary];
        [dict setValue:@"Failed to initialize the store" forKey:NSLocalizedDescriptionKey];
        [dict setValue:@"There was an error building up the data file." forKey:NSLocalizedFailureReasonErrorKey];
		// @TODO: Change code and error domain
        NSError *error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        [[NSApplication sharedApplication] presentError:error];
		
        return nil;
    }
	
    _managedObjectContext = [[NSManagedObjectContext alloc] init];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];
	
	[_managedObjectContext setUndoManager:nil];
	
    return _managedObjectContext;
}

/**
 Returns the NSUndoManager for the application.  In this case, the manager
 returned is that of the managed object context for the application.
 */

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window
{
    return [[self managedObjectContext] undoManager];
}


/**
 Performs the save action for the application, which is to send the save:
 message to the application's managed object context.  Any encountered errors
 are presented to the user.
 */

- (IBAction)saveAction:(id)sender
{
    NSError *error = nil;
    
    if (![[self managedObjectContext] commitEditing]) {
        NSDebugLog(@"%@:%@ unable to commit editing before saving", [self class], NSStringFromSelector(_cmd));
    }
	
    if (![[self managedObjectContext] save:&error]) {
        [[NSApplication sharedApplication] presentError:error];
    }
}


/**
 Implementation of the applicationShouldTerminate: method, used here to
 handle the saving of changes in the application managed object context
 before the application terminates.
 */


- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
	dispatch_async(dispatch_get_main_queue(), ^{
		for (NSPersistentStore * persistentStore in _persistentStoreCoordinator.persistentStores) {
			[_persistentStoreCoordinator removePersistentStore:persistentStore error:NULL];
			NSURL * url = [persistentStore URL];
			[[NSFileManager defaultManager] removeItemAtURL:url error:NULL];
		}
		
		[OptionItem save];
		[sender replyToApplicationShouldTerminate:YES];
	});
	return NSTerminateLater;
}

#pragma mark -
#pragma mark NSWindowDelegate

- (void)windowDidBecomeKey:(NSNotification *)notification
{
	self.mainWindowMenuItem.state = NSOnState;
}

- (void)windowDidResignKey:(NSNotification *)notification
{
	self.mainWindowMenuItem.state = NSOffState;
}

- (void)windowWillClose:(NSNotification *)notification
{
	NSWindow * notifWindow = notification.object;
	if (notifWindow == window) {
		NSArray * childWindowsCopy = [[window childWindows] copy];
		for (NSWindow * childWindow in childWindowsCopy) {
			[window removeChildWindow:childWindow];
			[childWindow close];
		}
	}
}

#pragma mark -
#pragma mark IBAction

- (IBAction)showPreferences:(id)sender
{
	[preferencesWindow makeKeyAndOrderFront:nil];
	[preferencesWindow updateContent];
}

- (IBAction)toggleQuickLook:(id)sender
{
    QLPreviewPanel * previewPanel = [QLPreviewPanel sharedPreviewPanel];
    
    if ([QLPreviewPanel sharedPreviewPanelExists] && [previewPanel isVisible]) {
        [previewPanel orderOut:nil];
    } else {
        [previewPanel makeKeyAndOrderFront:nil];
    }
}

- (IBAction)startAction:(id)sender
{
	sourceURLs = _mainViewController.resolvedSourceURLs;
	NSDebugLog(@"sourcesURLs: %@", [[sourceURLs valueForKey:@"path"] componentsJoinedByString:@", "]);
	if (sourceURLs.count == 0) {
		[[NSAlert alertWithMessageText:NSLocalizedString(@"No files selected.", nil)
						 defaultButton:NSLocalizedString(@"OK", nil)
					   alternateButton:nil
						   otherButton:nil
			 informativeTextWithFormat:NSLocalizedString(@"Drag the folder you want to analyze into the main window.", nil)] runModal];
		return ;
	}
	
	// Delete the managed context
	[_managedObjectContext reset];
	_managedObjectContext = nil;
	
	for (NSPersistentStore * persistentStore in _persistentStoreCoordinator.persistentStores) {
		[_persistentStoreCoordinator removePersistentStore:persistentStore error:NULL];
		NSURL * url = [persistentStore URL];
		[[NSFileManager defaultManager] removeItemAtURL:url error:NULL];
	}
	_persistentStoreCoordinator = nil;
	
	[self managedObjectContext];
	
	_cancelled = NO;
	
	// Start the file operation
	self.queue = [[NSOperationQueue alloc] init];
	
	if ([SandboxHelper sandboxActived]) {
		BOOL started = [SandboxHelper startAccessingSecurityScopedSources];
		if (!started) NSDebugLog(@"startAccessingSecurityScopedSources failed");
	}
	
	numberOfFinishedGetFilesOperations = 0;
	for (NSURL * resolvedSourceURL in sourceURLs) {
		GetFilesOperation * filesOperation = [[GetFilesOperation alloc] initWithRootPath:resolvedSourceURL.path];
		[queue addOperation:filesOperation];
	}
	
	[progressIndicator startAnimation:nil];
	
	_progressLabel.stringValue = NSLocalizedString(@"Analyzing Files...", nil);
	_currentFileLabel.stringValue = @"";
	[self setContentViewType:ContentViewTypeAnalysing];
	
	// Disable the close button from the main window
	NSUInteger styleMask = window.styleMask;
	styleMask &= ~NSClosableWindowMask;
	[window setStyleMask:styleMask];
}

- (IBAction)stopAction:(id)sender
{
	NSDebugLog(@"stoping...");
	
	for (NSOperation * operation in queue.operations) {
		if ([(GetFilesOperation *)operation isExecuting]) [operation cancel];
	}
	
	if ([SandboxHelper sandboxActived])
		[SandboxHelper stopAccessingSecurityScopedSources];
	
	_cancelled = YES;
	[progressIndicator setIndeterminate:YES];
	[progressIndicator startAnimation:self];
	
	[self stopPreventingFromSleeping];
	
	[self setContentViewType:ContentViewTypeStart];
	
	NSUInteger styleMask = window.styleMask;
	styleMask |= NSClosableWindowMask;// Re-add the close button
	[window setStyleMask:styleMask];
}

- (void)operationDidFinish:(NSNotification *)aNotification
{
	++numberOfFinishedGetFilesOperations;
	if (numberOfFinishedGetFilesOperations == sourceURLs.count) {
		if ([SandboxHelper sandboxActived])
			[SandboxHelper stopAccessingSecurityScopedSources];
		[self compareAllItems];
	}
}

#pragma mark -
#pragma mark Export to File

- (IBAction)exportAsText:(id)sender
{
	NSSavePanel * savePanel = [NSSavePanel savePanel];
	[savePanel setNameFieldStringValue:NSLocalizedString(@"Untitled.txt", nil)];
	[savePanel setAllowedFileTypes:@[@"txt"]];
	[savePanel setPrompt:NSLocalizedString(@"Export", nil)];
	
	[savePanel beginWithCompletionHandler:^(NSInteger result) {
		
		NSMutableString * string = [[NSMutableString alloc] initWithCapacity:1000];
		if (duplicatesArrays.count > 0) [string appendString:@"Duplicates Items:\n"];
		
		for (NSArray * array in duplicatesArrays) {
			if (array.count > 0) {
				for (FileItem * item in array) [string appendFormat:@"%@\n", item.path];
				[string appendString:@"\n"];
			}
		}
		
		if (emptyItems.count > 0) [string appendString:@"Empty Items:\n"];
		for (FileItem * item in emptyItems) [string appendFormat:@"%@\n", item.path];
		
		if (brokenAliasItems.count > 0) [string appendString:@"\nBroken Aliases:\n"];
		for (FileItem * item in brokenAliasItems) [string appendFormat:@"%@\n", item.path];
		
		[string writeToURL:[savePanel URL] atomically:YES encoding:NSUTF8StringEncoding error:NULL];
	}];
}

- (IBAction)exportAsXML:(id)sender
{
	NSSavePanel * savePanel = [NSSavePanel savePanel];
	[savePanel setNameFieldStringValue:NSLocalizedString(@"Untitled.xml", nil)];
	[savePanel setAllowedFileTypes:@[@"xml"]];
	[savePanel setPrompt:NSLocalizedString(@"Export", nil)];
	
	[savePanel beginWithCompletionHandler:^(NSInteger result) {
		
		NSXMLElement * root = (NSXMLElement *)[NSXMLNode elementWithName:@"items"];
		NSXMLDocument * xmlDocument = [[NSXMLDocument alloc] initWithRootElement:root];
		[xmlDocument setVersion:@"1.0"];
		[xmlDocument setCharacterEncoding:@"UTF-8"];
		
		/* Duplicates Items */
		if (duplicatesArrays.count > 0) {
			NSXMLElement * duplicateElement = (NSXMLElement *)[NSXMLNode elementWithName:@"duplicates_items"];
			[root addChild:duplicateElement];
			
			for (NSArray * array in duplicatesArrays) {
				
				int index = 0;
				for (FileItem * fileItem in array) {
					
					NSString * name = (index == 0)? @"item_original": @"item";
					NSXMLElement * item = (NSXMLElement *)[NSXMLNode elementWithName:name];
					
					NSXMLElement * path = [[NSXMLElement alloc] initWithName:@"path"];
					[path setStringValue:fileItem.path];
					[item addChild:path];
					
					NSXMLElement * size = [[NSXMLElement alloc] initWithName:@"size"];
					[size setStringValue:[fileItem.fileSize stringValue]];
					[item addChild:size];
					
					NSXMLElement * type = [[NSXMLElement alloc] initWithName:@"type"];
					[type setStringValue:fileItem.type];
					[item addChild:type];
					
					NSXMLElement * creationDate = [[NSXMLElement alloc] initWithName:@"creation_date"];
					[creationDate setStringValue:[fileItem.creationDate description]];
					[item addChild:creationDate];
					
					NSXMLElement * lastModificationDate = [[NSXMLElement alloc] initWithName:@"last_modification_date"];
					[lastModificationDate setStringValue:[fileItem.lastModificationDate description]];
					[item addChild:lastModificationDate];
					
					[duplicateElement addChild:item];
					
					index++;
				}
			}
		}
		
		/* Empty Items */
		if (emptyItems.count > 0) {
			NSXMLElement * emptyElement = (NSXMLElement *)[NSXMLNode elementWithName:@"empty_items"];
			[root addChild:emptyElement];
			
			for (FileItem * fileItem in emptyItems) {
				
				NSXMLElement * item = (NSXMLElement *)[NSXMLNode elementWithName:@"item"];
				
				NSXMLElement * path = [[NSXMLElement alloc] initWithName:@"path"];
				[path setStringValue:fileItem.path];
				[item addChild:path];
				
				NSXMLElement * type = [[NSXMLElement alloc] initWithName:@"type"];
				[type setStringValue:fileItem.type];
				[item addChild:type];
				
				NSXMLElement * creationDate = [[NSXMLElement alloc] initWithName:@"creation_date"];
				[creationDate setStringValue:[fileItem.creationDate description]];
				[item addChild:creationDate];
				
				NSXMLElement * lastModificationDate = [[NSXMLElement alloc] initWithName:@"last_modification_date"];
				[lastModificationDate setStringValue:[fileItem.lastModificationDate description]];
				[item addChild:lastModificationDate];
				
				[emptyElement addChild:item];
			}
		}
		
		/* Brokens Alias */
		if (brokenAliasItems.count > 0) {
			NSXMLElement * emptyElement = (NSXMLElement *)[NSXMLNode elementWithName:@"brokens_aliases"];
			[root addChild:emptyElement];
			
			for (FileItem * fileItem in brokenAliasItems) {
				
				NSXMLElement * item = (NSXMLElement *)[NSXMLNode elementWithName:@"item"];
				
				NSXMLElement * path = [[NSXMLElement alloc] initWithName:@"path"];
				[path setStringValue:fileItem.path];
				[item addChild:path];
				
				NSXMLElement * creationDate = [[NSXMLElement alloc] initWithName:@"creation_date"];
				[creationDate setStringValue:[fileItem.creationDate description]];
				[item addChild:creationDate];
				
				NSXMLElement * lastModificationDate = [[NSXMLElement alloc] initWithName:@"last_modification_date"];
				[lastModificationDate setStringValue:[fileItem.lastModificationDate description]];
				[item addChild:lastModificationDate];
				
				[emptyElement addChild:item];
			}
		}
		
		if (![[xmlDocument XMLDataWithOptions:NSXMLNodePrettyPrint] writeToURL:[savePanel URL] atomically:YES]) {
			NSDebugLog(@"writeToURL:atomically: failed");
		}
		
	}];
}

#pragma mark -
#pragma mark Working Management

- (void)setWorking:(BOOL)working
{
	_working = working;
	if (working) {
		NSUInteger windowMask = self.window.styleMask;
		windowMask &= ~NSClosableWindowMask;
		self.window.styleMask = windowMask;
	} else {
		self.window.styleMask |= NSClosableWindowMask;
	}
}

#pragma mark -
#pragma mark Power Activity

- (BOOL)startPreventingFromSleeping
{
#ifdef kIOPMAssertionTypePreventSystemSleep
	preventSleepID = 0;
	IOReturn success = IOPMAssertionCreateWithName(kIOPMAssertionTypePreventSystemSleep,
												   kIOPMAssertionLevelOn,
												   CFSTR("Running Analysis and Comparaison"),
												   &preventSleepID);
	return (success == kIOReturnSuccess);
#else
	return NO;
#endif
}

- (void)stopPreventingFromSleeping
{
	if (preventSleepID) {
		IOPMAssertionRelease(preventSleepID);// The system will be able to sleep again.
		preventSleepID = 0;
	}
}

#pragma mark -
#pragma mark Box content

- (void)activeMainMenuItemFromType:(ContentViewType)type
{
	[chooseSourceMenuItem setEnabled:(type == ContentViewTypeStart)];
	[exportAsTextMenuItem setEnabled:(type == ContentViewTypeResults)];
	[exportAsXMLMenuItem setEnabled:(type == ContentViewTypeResults)];
	
	[selectAllMenuItem setEnabled:(type == ContentViewTypeResults)];// @TODO: Active only if we show the gridView
	[selectAllDuplicatesMenuItem setEnabled:(type == ContentViewTypeResults)];// @TODO: Active only if we show the gridView, the duplicates tab is selected and items are selected
	[deselectAllMenuItem setEnabled:(type == ContentViewTypeResults)];// @TODO: Active only if we show the gridView
	[deleteSelectedMenuItem setEnabled:(type == ContentViewTypeResults)];// @TODO: Active only if we show the grdiView and items are selected
	
	[quickLookMenuItem setEnabled:((type == ContentViewTypeStart && _mainViewController.resolvedSourceURLs.count) || type == ContentViewTypeResults)];
}

- (void)setContentViewType:(ContentViewType)type
{
	contentViewType = type;
	
	/* Change the main menu */
	[self activeMainMenuItemFromType:type];
	
	NSView * contentView = nil;
	switch (type) {
		case ContentViewTypeStart:
			contentView = _mainViewController.view;
			break;
		case ContentViewTypeAnalysing:
			contentView = analysingView;
			break;
		case ContentViewTypeResults:
			contentView = _resultsViewController.view;
			break;
		default:
			break;
	}
	
	NSArray * subviews = [(NSView *)window.contentView subviews];
	
	/* Remove the current view */
	for (NSView * subview in subviews)
		[subview removeFromSuperview];
	
	contentView.autoresizingMask = (NSViewWidthSizable | NSViewHeightSizable);
	contentView.frame = [window.contentView frame];
	[window.contentView addSubview:contentView];
}

#pragma mark -
#pragma mark QLPreviewPanelController

- (BOOL)acceptsPreviewPanelControl:(QLPreviewPanel *)panel;
{
	return ((contentViewType == ContentViewTypeStart && _mainViewController.resolvedSourceURLs.count)
			|| contentViewType == ContentViewTypeResults);
}

- (void)beginPreviewPanelControl:(QLPreviewPanel *)panel
{
	if (contentViewType == ContentViewTypeStart) {
		panel.delegate = _mainViewController;
		panel.dataSource = _mainViewController;
	} else {
		panel.delegate = _resultsViewController;
		panel.dataSource = _resultsViewController;
	}
	[panel reloadData];
}

- (void)endPreviewPanelControl:(QLPreviewPanel *)panel
{
}

#pragma mark -
#pragma mark Comparing Items

- (void)compare:(NSString *)type withOptions:(NSArray *)options
{
	if (options.count > 0) {
		NSString * groupType = [NSString stringWithFormat:@"%@Group", type];
		[self compareType:type forGroup:groupType withOptions:options];
	}
}

- (void)compareType:(NSString *)type forGroup:(NSString *)groupType withOptions:(NSArray *)options
{
	/* Don't use the same context over threads, create a context for each thread with the same persistent store */
	NSManagedObjectContext * context = [[NSManagedObjectContext alloc] init];
	[context setPersistentStoreCoordinator:self.persistentStoreCoordinator];
	[context setUndoManager:nil];
	
	NSDebugLog(@"start %@ comparaison (with options: %@)...", type, [options componentsJoinedByString:@", "]);
	
	NSMutableArray * groups = [[NSMutableArray alloc] initWithCapacity:1000];
	
	NSArray * properties = [NSClassFromString(type) propertiesForOptions:options];// All CoreData properties names for the current type
	
	/* Create a predicate to exclude empty items and broken items */
	NSPredicate * predicate = [NSPredicate predicateWithFormat:@"isBroken == NO && fileSize > 0"];
	
	/* Get the count for the progress indicator */
	NSEntityDescription * entity = [NSEntityDescription entityForName:type inManagedObjectContext:context];
	NSFetchRequest * request = [[NSFetchRequest alloc] init];
	[request setEntity:entity];
	[request setPredicate:predicate];
	NSUInteger count = [context countForFetchRequest:request error:NULL];// Fetch the request to execute the block's predicate (countForFetchRequest may be faster, objects are not unfaulted)
	
	[progressIndicator stopAnimation:nil];
	[progressIndicator setIndeterminate:NO];
	
	[progressIndicator setDoubleValue:0.];
	[self updateDockTitleProgression:0.];
	
	__block float delta = 100./(float)count;
	__block float progression = 0.;
	void (^updateIndex)(void) = ^{
		[progressIndicator incrementBy:delta];
		[self updateDockTitleProgression:progression];
		progression += delta;
	};
	
	void (^updateFilenameLabel)(NSString *) = ^(NSString * path) {
		_currentFileLabel.stringValue = path.lastPathComponent;
	};
	
	NSPredicate * excludingPredicate = [NSPredicate predicateWithFormat:@"isBroken == YES || fileSize == 0"];
	predicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
		
		if (_cancelled)
			return YES;
		
		if (![[evaluatedObject entity].name isEqualToString:type])
			return NO;
		
		if ([excludingPredicate evaluateWithObject:evaluatedObject])
			return NO;
		
		NSError * error = nil;
		FileItem * object = (FileItem *)[context existingObjectWithID:[evaluatedObject objectID]
																error:&error];
		if (error) {
			NSDebugLog(@"existingObjectWithID: with error: %@", [error localizedDescription]);
		}
		
		if (object) {
			
			updateIndex();
			updateFilenameLabel(object.path);
			
			/*
			 Get the current group (the group where informations are same as the input object
			 If we find the current group, add input object at the end of the array of the group content (from the groupsContent)
			 Else, create a new group and a new array content into the groupsContent array, then add the input object into groupsContent
			 */
			
			for (FileItem * item in groups) {
				if ([object isEqualTo:item options:options]) {
					[[item primitiveValueForKey:@"items"] addObject:object];
					return YES;// If we can find a group, return YES...
				}
			}
			
			// ... else create a new group
			NSEntityDescription * _entity = [NSEntityDescription entityForName:groupType inManagedObjectContext:context];
			NSManagedObject * group = [[NSManagedObject alloc] initWithEntity:_entity insertIntoManagedObjectContext:context];
			
			for (NSString * property in properties) {
				id value = [object valueForKey:property];
				[group setValue:value forKey:property];
			}
			
			[[group primitiveValueForKey:@"items"] addObject:object];
			
			[groups addObject:group];
		}
		
		return YES;
	}];
	
	request = [[NSFetchRequest alloc] init];
	[request setEntity:entity];
	[request setPredicate:predicate];
	[context countForFetchRequest:request error:NULL];// Fetch the request to execute the block's predicate (countForFetchRequest may be faster, objects are not unfaulted)
	
	if (_cancelled) {
		NSDebugLog(@"...cancel!");
		return ;
	}
	
	[[NSApp dockTile] setContentView:nil];
	[[NSApp dockTile] display];
	
	[progressIndicator setIndeterminate:YES];
	[progressIndicator startAnimation:nil];
	
	
	[self.persistentStoreCoordinator performBlockAndWait:^{
		NSError * error = nil;
		if (![context save:&error]) {
			NSLog(@"context save error: %@", [error localizedDescription]);
		}
	}];
	
	NSDebugLog(@"...end! %lu groups", groups.count);
}


- (void)automaticallyCompare:(NSString *)type
{
	NSString * groupType = [NSString stringWithFormat:@"%@Group", type];
	[self automaticallyCompareType:type forGroup:groupType];
}

- (void)automaticallyCompareType:(NSString *)type forGroup:(NSString *)groupType
{
	NSArray * options = @[@"FileItemCompareSize", @"FileItemCompareData"];
	
	/* Don't use the same context over threads, create a context for each thread with the same persistent store */
	NSManagedObjectContext * context = [[NSManagedObjectContext alloc] init];
	[context setPersistentStoreCoordinator:self.persistentStoreCoordinator];
	[context setUndoManager:nil];
	
	NSDebugLog(@"start %@ comparaison (with options: %@)...", type, [options componentsJoinedByString:@", "]);
	
	NSMutableArray * groups = [[NSMutableArray alloc] initWithCapacity:1000];
	
	NSArray * properties = [NSClassFromString(type) propertiesForOptions:options];// All CoreData properties names for the current type
	
	/* Create a predicate to exclude empty items and broken items */
	NSPredicate * predicate = [NSPredicate predicateWithFormat:@"isBroken == NO && fileSize > 0"];
	
	/* Get the count for the progress indicator */
	NSEntityDescription * entity = [NSEntityDescription entityForName:type inManagedObjectContext:context];
	NSFetchRequest * request = [[NSFetchRequest alloc] init];
	[request setEntity:entity];
	[request setPredicate:predicate];
	NSUInteger count = [context countForFetchRequest:request error:NULL];// Fetch the request to execute the block's predicate (countForFetchRequest may be faster, objects are not unfaulted)
	
	[progressIndicator stopAnimation:nil];
	[progressIndicator setIndeterminate:NO];
	
	[progressIndicator setDoubleValue:0.];
	[self updateDockTitleProgression:0.];
	
	__block float delta = 100./(float)count;
	__block float progression = 0.;
	void (^updateIndex)(void) = ^{
		[progressIndicator incrementBy:delta];
		[self updateDockTitleProgression:progression];
		progression += delta;
	};
	
	void (^updateFilenameLabel)(NSString *) = ^(NSString * path) {
		_currentFileLabel.stringValue = path.lastPathComponent;
	};
	
	NSPredicate * excludingPredicate = [NSPredicate predicateWithFormat:@"isBroken == YES || fileSize == 0"];
	predicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
		
		if (_cancelled)
			return YES;
		
		if (![[evaluatedObject entity].name isEqualToString:type])
			return NO;
		
		if ([excludingPredicate evaluateWithObject:evaluatedObject])
			return NO;
		
		NSError * error = nil;
		FileItem * object = (FileItem *)[context existingObjectWithID:[evaluatedObject objectID]
																error:&error];
		if (error) {
			NSDebugLog(@"existingObjectWithID: with error: %@", [error localizedDescription]);
		}
		
		if (object) {
			
			dispatch_async(dispatch_get_main_queue(), ^{
				updateIndex();
				if (object.path) {
					updateFilenameLabel(object.path);
				}
			});
			
			/*
			 Get the current group (the group where informations are same as the input object
			 If we find the current group, add input object at the end of the array of the group content (from the groupsContent)
			 Else, create a new group and a new array content into the groupsContent array, then add the input object into groupsContent
			 */
			for (NSManagedObject * group in groups) {
				// Don't call "mutableSetValueForKey:" to avoid useless KVO allocations
				NSMutableSet * set = (NSMutableSet *)[group primitiveValueForKey:@"items"];
				FileItem * firstItem = set.anyObject;
				if (firstItem && [object isEqualTo:firstItem options:options]) {
					[set addObject:object];
					return YES;// If we can find a group, return YES...
				}
			}
			
			// ... else create a new group
			NSEntityDescription * _entity = [NSEntityDescription entityForName:groupType inManagedObjectContext:context];
			NSManagedObject * group = [[NSManagedObject alloc] initWithEntity:_entity insertIntoManagedObjectContext:context];
			
			for (NSString * property in properties) {
				id value = [object valueForKey:property];
				[group setValue:value forKey:property];
			}
			
			[[group primitiveValueForKey:@"items"] addObject:object];
			
			[groups addObject:group];
		}
		
		return YES;
	}];
	
	request = [[NSFetchRequest alloc] init];
	[request setEntity:entity];
	[request setPredicate:predicate];
	[context countForFetchRequest:request error:NULL];// Fetch the request to execute the block's predicate (countForFetchRequest may be faster, objects are not unfaulted)
	
	if (_cancelled) {
		NSDebugLog(@"...cancel!");
		return ;
	}
	
	[[NSApp dockTile] setContentView:nil];
	[[NSApp dockTile] display];
	
	[progressIndicator setIndeterminate:YES];
	[progressIndicator startAnimation:nil];
	
	[self.persistentStoreCoordinator performBlockAndWait:^{
		NSError * error = nil;
		if (![context save:&error]) {
			NSLog(@"context save error: %@", [error localizedDescription]);
		}
	}];
	
	NSDebugLog(@"...end! %lu groups", groups.count);
}

- (void)compareAllItems
{
	/* Disable the run button (to avoid double run) */
	dispatch_async(dispatch_get_main_queue(), ^{ [_mainViewController.runButton setEnabled:NO]; });
	
	if ([OptionItem useAutomaticComparaison]) {
		
		/* Automatic mode need to read data from file, allow it with sandbox */
		if ([SandboxHelper sandboxActived]) {
			BOOL started = [SandboxHelper startAccessingSecurityScopedSources];
			if (!started) NSLog(@"startAccessingSecurityScopedSources failed");
		}
		
		dispatch_group_t group = dispatch_group_create();
		dispatch_queue_t dispatch_queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
		
		dispatch_group_async(group, dispatch_queue, ^{
			_progressLabel.stringValue = @"Comparing Files";
			[self automaticallyCompare:@"FileItem"];
			
			_progressLabel.stringValue = @"Comparing Image";
			[self automaticallyCompare:@"ImageItem"];
			
			_progressLabel.stringValue = @"Comparing Audio Files";
			[self automaticallyCompare:@"AudioItem"];
		});
		
		dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
		
		if ([SandboxHelper sandboxActived])
			[SandboxHelper stopAccessingSecurityScopedSources];
		
	} else {
		
		NSArray * options = [OptionItem checkedItems];
		NSMutableArray * fileOptions = [[NSMutableArray alloc] initWithCapacity:options.count];
		NSMutableArray * imageOptions = [[NSMutableArray alloc] initWithCapacity:options.count];
		NSMutableArray * audioOptions = [[NSMutableArray alloc] initWithCapacity:options.count];
		
		for (OptionItem * option in options) {
			if ([ImageItem canCompareWithOption:option.identifier]) {
				[imageOptions addObject:option.identifier];
			} else if ([AudioItem canCompareWithOption:option.identifier]) {
				[audioOptions addObject:option.identifier];
			} else {
				NSDebugLog(@"adding %@", option.identifier);
				[fileOptions addObject:option.identifier];
			}
		}
		
		// Compare images and audio files only if we have some specifics options checked
		if (imageOptions.count > 0) [imageOptions addObjectsFromArray:fileOptions];
		if (audioOptions.count > 0) [audioOptions addObjectsFromArray:fileOptions];
		
		dispatch_group_t group = dispatch_group_create();
		dispatch_queue_t dispatch_queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
		
		dispatch_group_async(group, dispatch_queue, ^{
			if (fileOptions.count > 0) {
				_progressLabel.stringValue = NSLocalizedString(@"Comparing Files...", nil);
				[self compare:@"FileItem" withOptions:fileOptions];
			}
			
			_progressLabel.stringValue = NSLocalizedString(@"Comparing Images...", nil);
			if (imageOptions.count > 0) {// If we have images specific's options, compare ImageItem separately...
				[self compare:@"ImageItem" withOptions:imageOptions];
			} else {// ... else, compare image and add groups to file item's groups
				if (fileOptions.count > 0)
					[self compareType:@"ImageItem" forGroup:@"FileItemGroup" withOptions:fileOptions];
			}
			
			_progressLabel.stringValue = NSLocalizedString(@"Comparing Audio Files...", nil);
			if (audioOptions.count > 0) {// *Same as image items*
				[self compare:@"AudioItem" withOptions:audioOptions];
			} else {
				if (fileOptions.count > 0)
					[self compareType:@"AudioItem" forGroup:@"FileItemGroup" withOptions:fileOptions];
			}
		});
		
		dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
	}
	
	dispatch_async(dispatch_get_main_queue(), ^{ _currentFileLabel.stringValue = @""; });
	
	if (_cancelled) {
		dispatch_async(dispatch_get_main_queue(), ^{
			[_mainViewController.runButton setEnabled:YES];
			
			NSDebugLog(@"comparaison cancelled!");
			
			NSUInteger styleMask = window.styleMask;
			styleMask |= NSClosableWindowMask;// Re-add the close button
			[window setStyleMask:styleMask];
		});
		return ;
	}
	
	/* Don't use the same context over threads, create a context for each thread with the same persistent store */
	NSManagedObjectContext * context = [[NSManagedObjectContext alloc] init];
	context.persistentStoreCoordinator = self.persistentStoreCoordinator;
	context.undoManager = nil;
	
	NSFetchRequest * request = [[NSFetchRequest alloc] init];
	request.entity = [NSEntityDescription entityForName:@"FileItem" inManagedObjectContext:context];
	
	dispatch_async(dispatch_get_main_queue(), ^{
		/* Find empty items */
		if ([OptionItem shouldFindEmptyItems]) {
			_progressLabel.stringValue = NSLocalizedString(@"Finding Empty Items...", nil);
			
			request.predicate = [NSPredicate predicateWithFormat:@"fileSize == 0 && isBroken == NO && path != NULL"];
			NSMutableArray * emptyItemsCopy = [[NSMutableArray alloc] initWithArray:[context executeFetchRequest:request error:NULL]];
			_resultsViewController.emptyItems = emptyItemsCopy;
		} else {
			_resultsViewController.emptyItems = nil;
		}
		
		/* Find broken aliases  */
		if ([OptionItem shouldFindBrokenAliases]) {
			_progressLabel.stringValue = NSLocalizedString(@"Finding Broken Aliases...", nil);
			
			request.predicate = [NSPredicate predicateWithFormat:@"isBroken == YES"];
			NSMutableArray * brokenAliasesCopy = [[NSMutableArray alloc] initWithArray:[context executeFetchRequest:request error:NULL]];
			_resultsViewController.brokenAliases = brokenAliasesCopy;
		} else {
			_resultsViewController.brokenAliases = nil;
		}
		_progressLabel.stringValue = @"";
		NSDebugLog(@"comparaison ended!");
		
		[self setContentViewType:ContentViewTypeResults];
		[_resultsViewController reloadData];
		
		[self performSelectorOnMainThread:@selector(stopPreventingFromSleeping) withObject:nil waitUntilDone:NO];
		
		NSUInteger styleMask = window.styleMask;
		styleMask |= NSClosableWindowMask;// Re-add the close button
		[window setStyleMask:styleMask];
		
		/* If the application is in background, bounce the Dock icon (just one time) */
		if (![NSApp isActive]) {
			NSInteger request = [NSApp requestUserAttention:NSInformationalRequest];// Bounce one time a second...
			
			double delayInSeconds = 1.;// ... during one second
			dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
			dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
				[NSApp cancelUserAttentionRequest:request];
			});
		}
		
		[_mainViewController.runButton setEnabled:YES];
	});
}

@end

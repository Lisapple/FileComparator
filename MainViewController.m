//
//  MainViewController.m
//  Comparator
//
//  Created by Max on 13/12/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "MainViewController.h"

#import "FileInformations.h"
#import "FolderDetailsWindow.h"

#import "SandboxHelper.h"

#import "NSString+addition.h"

#import "ComparatorAppDelegate.h"

@implementation NSURL (QLPreviewItem)

- (NSURL *)previewItemURL
{
	return self;
}

- (NSString *)previewItemTitle
{
	return self.path;
}

@end

@implementation DraggingView

@synthesize delegate = _delegate;

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
	NSArray * paths = [[sender draggingPasteboard] propertyListForType:NSFilenamesPboardType];
	if (paths.count > 0) {
		NSURL * fileURL = [NSURL fileURLWithPath:paths.firstObject];
		NSNumber * isDirectory = nil;
		BOOL success = [fileURL getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:NULL];
		if (success && isDirectory.boolValue) {
			return ([sender draggingSourceOperationMask] == NSDragOperationCopy) ? NSDragOperationCopy : NSDragOperationGeneric;
		}
	}
	
	return NSDragOperationNone;
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
	NSArray * paths = [[sender draggingPasteboard] propertyListForType:NSFilenamesPboardType];
	if (paths.count > 0) {
		NSURL * fileURL = [NSURL fileURLWithPath:paths.firstObject];
		NSNumber * isDirectory = nil;
		BOOL success = [fileURL getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:NULL];
		
		return (success && isDirectory.boolValue);
	}
	return NO;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
	if ([_delegate respondsToSelector:@selector(draggingView:didDragSourceURLs:)] &&
		[_delegate respondsToSelector:@selector(draggingView:didDragAdditionalSourceURLs:)]) {
		BOOL sourceDragged = NO;
		NSArray * paths = [[sender draggingPasteboard] propertyListForType:NSFilenamesPboardType];
		NSMutableArray * sources = [[NSMutableArray alloc] initWithCapacity:paths.count];
		for (NSString * path in paths) {
			NSURL * fileURL = [NSURL fileURLWithPath:path];
			NSNumber * isDirectory = nil;
			BOOL success = [fileURL getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:NULL];
			if (success && isDirectory.boolValue) {
				[sources addObject:fileURL];
				sourceDragged = YES; // If we have directory dragged, set "performs" to YES
			}
		}
		if (sourceDragged) {
			if ([sender draggingSourceOperationMask] == NSDragOperationCopy) {
				[_delegate draggingView:self didDragAdditionalSourceURLs:sources];
			} else {
				[_delegate draggingView:self didDragSourceURLs:sources];
			}
		}
		return sourceDragged;
	}
	
	return NO;
}

- (void)draggingExited:(id <NSDraggingInfo>)sender
{
	
}

@end


@interface MainViewController ()
{
	NSMutableDictionary * sourceURLsAndResolvedURLs; // @{ sourceURL1 : resolvedURL1, sourceURL2 : resolvedURL2, ... }
	NSUInteger sourcesFetchedCount, totalNumberOfItems;
	double totalSourcesSize;
}

@end

@implementation MainViewController

- (instancetype)initWithCoder:(NSCoder *)coder
{
	if ((self = [super initWithCoder:coder])) {
		sourceURLsAndResolvedURLs = [[NSMutableDictionary alloc] initWithCapacity:3];
	}
	return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
		sourceURLsAndResolvedURLs = [[NSMutableDictionary alloc] initWithCapacity:3];
	}
	return self;
}

- (void)setURL:(NSURL *)URL
{
	if (URL) {
		self.sourceURLs = @[ URL ];
	}
}

- (void)addSourcesURLs:(NSArray *)newSourcesURLs
{
	self.sourceURLs = [sourceURLsAndResolvedURLs.allKeys arrayByAddingObjectsFromArray:newSourcesURLs];
}

- (void)setSourceURLs:(NSArray *)sourceURLs
{
	NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
	NSMutableDictionary * savedBookmarks = [userDefaults dictionaryForKey:@"sources-bookmarks"].mutableCopy;
	if (!savedBookmarks) {
		savedBookmarks = [[NSMutableDictionary alloc] initWithCapacity:sourceURLs.count];
	}
	
	NSMutableSet * sourcesToRemove = [NSMutableSet setWithArray:sourceURLsAndResolvedURLs.allKeys];
	[sourcesToRemove minusSet:[NSSet setWithArray:sourceURLs]];
	if ([SandboxHelper sandboxActived]) {
		// Remove old source from sandbox
		for (NSURL * sourceToRemove in sourcesToRemove)
			[SandboxHelper removeSource:sourceToRemove];
	}
	// Remove old source from user defaults
	for (NSURL * sourceToRemove in sourcesToRemove)
		[savedBookmarks removeObjectForKey:sourceToRemove.path];
	
	[sourceURLsAndResolvedURLs removeObjectsForKeys:sourcesToRemove.allObjects];
	[savedBookmarks removeObjectsForKeys:sourcesToRemove.allObjects];
	
	NSMutableSet * newSourceURLs = [NSMutableSet setWithArray:sourceURLs];
	[newSourceURLs minusSet:[NSSet setWithArray:sourceURLsAndResolvedURLs.allKeys]];
	
	for (NSURL * sourceURL in newSourceURLs) {
		
		NSURLBookmarkCreationOptions creationOptions = 0;
#if _SANDBOX_ACTIVITED_
		creationOptions = NSURLBookmarkResolutionWithSecurityScope;
#endif
		NSError * error = nil;
		NSData * bookmarkData = [sourceURL bookmarkDataWithOptions:creationOptions
									includingResourceValuesForKeys:nil
													 relativeToURL:nil
															 error:&error];
		if (error)
			NSLog(@"error: %@", error.localizedDescription);
		
		if (bookmarkData) {
			savedBookmarks[sourceURL.path] = bookmarkData;
			
			NSURLBookmarkResolutionOptions resolutionOptions = 0;
#if _SANDBOX_ACTIVITED_
			resolutionOptions = NSURLBookmarkResolutionWithSecurityScope;
#endif
			NSURL * resolvedURL = [NSURL URLByResolvingBookmarkData:bookmarkData
										options:resolutionOptions
									relativeToURL:nil
							bookmarkDataIsStale:NULL
											error:NULL];
			if (error)
				NSLog(@"error: %@", error.localizedDescription);
			
			if (resolvedURL) {
				sourceURLsAndResolvedURLs[sourceURL] = resolvedURL;
				if ([SandboxHelper sandboxActived]) {
					[SandboxHelper addSource:resolvedURL];
					BOOL started = [SandboxHelper startAccessingSecurityScopedSources];
					if (!started) NSLog(@"startAccessingSecurityScopedSources failed");
				}
			}
		}
	}
	_resolvedSourceURLs = sourceURLsAndResolvedURLs.allValues;
	
	[userDefaults setObject:savedBookmarks forKey:@"sources-bookmarks"];
	[userDefaults synchronize];
	
	[self updateUI];
	/*
	if (sourceURLsAndResolvedURLs.count > 1) {
		_pathLabel.stringValue = [NSString stringWithFormat:NSLocalizedString(@"%ld folders", nil), (long)sourceURLsAndResolvedURLs.count];
	} else if (sourceURLsAndResolvedURLs.count == 1) {
		NSURL * sourceURL = sourceURLsAndResolvedURLs.allKeys.firstObject;
		_pathLabel.stringValue = sourceURL.path.lastPathComponent;
	}
	
	NSImage * image = [[NSWorkspace sharedWorkspace] iconForFile:[sourceURLs.firstObject path]];
	[image setSize:NSMakeSize(324., 324.)];
	_imageView.image = image;
	
	[_showSourceInfoButton setHidden:YES];
	[_numberOfitemsLabel setHidden:YES];
	
	[_progressIndicator startAnimation:nil];
	for (NSURL * resolvedSourceURL in sourceURLsAndResolvedURLs.allValues) {
		[FileInformations fetchPropertiesForItemsAtPath:resolvedSourceURL.path];
	}
	
	NSMenu * mainMenu = [NSApp mainMenu];
	[[[[mainMenu itemAtIndex:3] submenu] itemAtIndex:0] setEnabled:YES];
	*/
}

- (void)loadView
{
	[super loadView];
	
	[_draggingView registerForDraggedTypes:@[NSFilenamesPboardType]];
	_draggingView.delegate = self;
	
	_centeredView.verticallyCentered = YES;
	_centeredView.offsetEdge = RectEdgeMake(0., 0., 60., 0.);
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(fileInformationsDidFinish:)
												 name:@"FileInformationsDidFinishNotification"
											   object:nil];
	[self updateUI];
}

- (void)updateUI
{
	/* Restore bookmark's data from last used source URL */
	NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
	NSDictionary * savedBookmarks = [userDefaults dictionaryForKey:@"sources-bookmarks"];
	for (NSData * bookmarkData in savedBookmarks.allValues) {
		
		NSURLBookmarkResolutionOptions options = 0;
#if _SANDBOX_ACTIVITED_
		options = NSURLBookmarkResolutionWithSecurityScope;
#endif
		BOOL isStale;
		NSURL * resolvedURL = [NSURL URLByResolvingBookmarkData:bookmarkData
														options:options
												  relativeToURL:nil
											bookmarkDataIsStale:&isStale
														  error:NULL];
		if (resolvedURL && !isStale) {
			sourceURLsAndResolvedURLs[resolvedURL] = resolvedURL;
		}
	}
	_resolvedSourceURLs = sourceURLsAndResolvedURLs.allValues;
	
	if (sourceURLsAndResolvedURLs.count > 1) {
		_pathLabel.stringValue = [NSString stringWithFormat:NSLocalizedString(@"%ld folders", nil), (long)sourceURLsAndResolvedURLs.count];
	} else if (sourceURLsAndResolvedURLs.count == 1) {
		NSURL * aSourceURL = sourceURLsAndResolvedURLs.allKeys.firstObject;
		_pathLabel.stringValue = aSourceURL.path.lastPathComponent;
	}
	
	NSURL * aSourceURL = sourceURLsAndResolvedURLs.allKeys.firstObject;
	if (aSourceURL) {
		NSImage * image = [[NSWorkspace sharedWorkspace] iconForFile:aSourceURL.path];
		[image setSize:NSMakeSize(324., 324.)];
		_imageView.image = image;
	}
	
	[_showSourceInfoButton setHidden:YES];
	[_numberOfitemsLabel setHidden:YES];
	
	[_progressIndicator startAnimation:nil];
	for (NSURL * resolvedSourceURL in sourceURLsAndResolvedURLs.allValues) {
		[FileInformations fetchPropertiesForItemsAtPath:resolvedSourceURL.path];
	}
	
	/* Enable "QuickLook Item" from main menu*/
	NSMenu * mainMenu = [NSApp mainMenu];
	[[[[mainMenu itemAtIndex:3] submenu] itemAtIndex:0] setEnabled:YES];
}

- (void)fileInformationsDidFinish:(NSNotification *)notification
{
	NSDictionary * attributes = (NSDictionary *)notification.object;
	NSURL * fileURL = attributes[@"fileURL"];
	
	if (sourceURLsAndResolvedURLs[fileURL] || [sourceURLsAndResolvedURLs.allValues containsObject:fileURL]) {
		sourcesFetchedCount++;
		totalNumberOfItems += [attributes[@"numberOfItem"] integerValue];
		totalSourcesSize += [attributes[NSURLFileSizeKey] doubleValue];
	}
	
	if (sourcesFetchedCount == sourceURLsAndResolvedURLs.count) {
		dispatch_async(dispatch_get_main_queue(), ^{
			if (totalNumberOfItems == 0 || totalSourcesSize == 0.) {
				_numberOfitemsLabel.stringValue = [NSString stringWithFormat:NSLocalizedString(@"No items - %@", nil), [NSString localizedStringForFileSize:0]];
				_runButton.enabled = NO;
				
				_showSourceInfoButton.hidden = YES;
			} else {
				_numberOfitemsLabel.stringValue = [NSString stringWithFormat:NSLocalizedString(@"%ld Items - %@", nil), totalNumberOfItems, [NSString localizedStringForFileSize:totalSourcesSize]];
				
				_showSourceInfoButton.hidden = NO;
				_runButton.enabled = YES;
			}
			[_numberOfitemsLabel setHidden:NO];
			[_progressIndicator stopAnimation:nil];
			
			if ([SandboxHelper sandboxActived]) {
				[SandboxHelper stopAccessingSecurityScopedSources];
			}
			sourcesFetchedCount = 0;
			totalNumberOfItems = 0;
			totalSourcesSize = 0;
		});
	}
}

- (void)draggingView:(DraggingView *)draggingView didDragSourceURLs:(NSArray *)sourceURLs
{
	// @TODO: Check that sources are not included in each other
	
	self.sourceURLs = sourceURLs;
}

- (void)draggingView:(DraggingView *)draggingView didDragAdditionalSourceURLs:(NSArray *)sourceURLs
{
	[self addSourcesURLs:sourceURLs];
}

- (IBAction)startAction:(id)sender
{
	/* Call the method on the application delegate */
	[(ComparatorAppDelegate *)[NSApp delegate] startAction:nil];
}

- (IBAction)showOptionsAction:(id)sender
{
	[NSApp beginSheet:_optionsWindow modalForWindow:self.view.window modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
}

- (IBAction)openFolderAction:(id)sender
{
	NSOpenPanel * openPanel = [NSOpenPanel openPanel];
	openPanel.canChooseDirectories = YES;
	openPanel.canChooseFiles = NO;
	openPanel.allowsMultipleSelection = NO;
	[openPanel beginSheetModalForWindow:self.view.window
					  completionHandler:^(NSInteger result) { self.URL = openPanel.URL; }];
}

- (IBAction)showSourceDetailsAction:(id)sender
{
	[NSApp beginSheet:_folderDetailsWindow modalForWindow:self.view.window modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:NULL];
	[_folderDetailsWindow reloadWithFolderURLs:sourceURLsAndResolvedURLs.allValues];
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	if (sheet == _folderDetailsWindow) {
		[self updateUI];
	}
}

- (IBAction)openHelpAction:(id)sender
{
	// @TODO: Open the help page for this view
	
	NSString * helpBookName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleHelpBookName"];
	[[NSHelpManager sharedHelpManager] openHelpAnchor:@"main_interface" inBook:helpBookName];
}

#pragma mark - QLPreviewPanelDelegate

- (NSRect)previewPanel:(QLPreviewPanel *)panel sourceFrameOnScreenForPreviewItem:(id <QLPreviewItem>)item
{
	NSRect frame = _imageView.frame;
	frame.origin = [[NSApp mainWindow] convertBaseToScreen:[self.view convertPoint:frame.origin fromView:_imageView]];
	return frame;
}

- (NSImage *)previewPanel:(QLPreviewPanel *)panel transitionImageForPreviewItem:(id <QLPreviewItem>)item contentRect:(NSRect *)contentRect
{
	NSURL * aSourceURL = sourceURLsAndResolvedURLs.allKeys.firstObject;
	if (aSourceURL) {
		return [[NSWorkspace sharedWorkspace] iconForFile:aSourceURL.path];
	}
	return nil;
}

#pragma mark - QLPreviewPanelDataSource

- (NSInteger)numberOfPreviewItemsInPreviewPanel:(QLPreviewPanel *)panel
{
	return 1;
}

- (id <QLPreviewItem>)previewPanel:(QLPreviewPanel *)panel previewItemAtIndex:(NSInteger)index
{
	return sourceURLsAndResolvedURLs.allKeys.firstObject;
}

@end

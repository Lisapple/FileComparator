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

- (NSDragOperation)draggingEntered:(id < NSDraggingInfo >)sender
{
	NSArray * paths = [[sender draggingPasteboard] propertyListForType:NSFilenamesPboardType];
	if (paths.count > 0) {
		NSURL * fileURL = [NSURL fileURLWithPath:[paths objectAtIndex:0]];
		NSNumber * isDirectory = nil;
		BOOL success = [fileURL getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:NULL];
		
		return (success && isDirectory.boolValue)? NSDragOperationCopy : NSDragOperationNone;
	}
	
	return NSDragOperationNone;
}

- (BOOL)prepareForDragOperation:(id < NSDraggingInfo >)sender
{
	NSArray * paths = [[sender draggingPasteboard] propertyListForType:NSFilenamesPboardType];
	if (paths.count > 0) {
		NSURL * fileURL = [NSURL fileURLWithPath:[paths objectAtIndex:0]];
		NSNumber * isDirectory = nil;
		BOOL success = [fileURL getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:NULL];
		
		return (success && isDirectory.boolValue);
	}
	return NO;
}

- (BOOL)performDragOperation:(id < NSDraggingInfo >)sender
{
	BOOL canResponds = [_delegate respondsToSelector:@selector(draggingView:didDragURL:)];
	
	BOOL performs = NO;
	NSArray * paths = [[sender draggingPasteboard] propertyListForType:NSFilenamesPboardType];
	for (NSString * path in paths) {
		NSURL * fileURL = [NSURL fileURLWithPath:path];
		
		NSNumber * isDirectory = nil;
		BOOL success = [fileURL getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:NULL];
		
		if (success && isDirectory.boolValue) {
			performs = YES;// If we have directory dragged, set "performs" to YES
			if (canResponds) [_delegate draggingView:self didDragURL:fileURL];
		}
	}
	
	return performs;
}

- (void)draggingExited:(id < NSDraggingInfo >)sender
{
	
}

@end


@implementation MainViewController

@synthesize optionsWindow = _optionsWindow;
@synthesize folderDetailsWindow = _folderDetailsWindow;

@synthesize draggingView = _draggingView;
@synthesize pathLabel = _pathLabel;
@synthesize numberOfitemsLabel = _numberOfitemsLabel;
@synthesize progressIndicator = _progressIndicator;
@synthesize imageView = _imageView;
@synthesize showSourceInfoButton = _showSourceInfoButton;
@synthesize centeredView = _centeredView;

@synthesize URL = _URL;

- (void)setURL:(NSURL *)URL
{
	if ([SandboxHelper sandboxActived])
		[SandboxHelper removeSource:_URL];
	
	
	NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
	
	NSURLBookmarkCreationOptions options = 0;
#if _SANDBOX_ACTIVITED_
	options = NSURLBookmarkCreationWithSecurityScope;
#endif
	
	NSError * error = nil;
	NSData * bookmarkData = [URL bookmarkDataWithOptions:options
						   includingResourceValuesForKeys:nil
											relativeToURL:nil
													error:&error];
	if (error)
		NSLog(@"error: %@", error.localizedDescription);
	
	[userDefaults setObject:bookmarkData forKey:@"Last Used Source Bookmarks Data"];
	[userDefaults synchronize];
	
	NSURLBookmarkResolutionOptions resolutionOptions = 0;
#if _SANDBOX_ACTIVITED_
	resolutionOptions = NSURLBookmarkResolutionWithSecurityScope;
#endif
	_URL = [[NSURL URLByResolvingBookmarkData:bookmarkData
									  options:resolutionOptions
								relativeToURL:nil
						  bookmarkDataIsStale:NULL
										error:NULL] copy];
	
	if ([SandboxHelper sandboxActived]) {
		[SandboxHelper addSource:_URL];
		BOOL started = [SandboxHelper startAccessingSecurityScopedSources];
		if (!started) NSLog(@"startAccessingSecurityScopedSources failed");
	}
	
	
	_pathLabel.stringValue = _URL.path.lastPathComponent;
	
	NSImage * image = [[NSWorkspace sharedWorkspace] iconForFile:_URL.path];
	[image setSize:NSMakeSize(324., 324.)];
	_imageView.image = image;
	
	[_showSourceInfoButton setHidden:YES];
	[_numberOfitemsLabel setHidden:YES];
	
	[_progressIndicator startAnimation:nil];
	[FileInformations fetchPropertiesForItemsAtPath:_URL.path];
	
	/* Enable "QuickLook Item" from main menu*/
	NSMenu * mainMenu = [NSApp mainMenu];
	[[[[mainMenu itemAtIndex:3] submenu] itemAtIndex:0] setEnabled:YES];
}

- (void)loadView
{
	[super loadView];
	
	[_draggingView registerForDraggedTypes:[NSArray arrayWithObject:NSFilenamesPboardType]];
	_draggingView.delegate = self;
	
	_centeredView.verticallyCentered = YES;
	_centeredView.offsetEdge = RectEdgeMake(0., 0., 60., 0.);
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(fileInformationsDidFinish:)
												 name:@"FileInformationsDidFinishNotification"
											   object:nil];
	
	/* Restore bookmark's data from last used source URL */
	NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
	
	NSURLBookmarkResolutionOptions options = 0;
#if _SANDBOX_ACTIVITED_
	options = NSURLBookmarkResolutionWithSecurityScope;
#endif
	
	BOOL isStale;
	NSData * bookmarkData = [userDefaults dataForKey:@"Last Used Source Bookmarks Data"];
	NSURL * lastUsedSourceURL = [NSURL URLByResolvingBookmarkData:bookmarkData
														  options:options
													relativeToURL:nil
											  bookmarkDataIsStale:&isStale
															error:NULL];
	if (lastUsedSourceURL && !isStale) {
		
		_URL = [lastUsedSourceURL copy];
		
		if ([SandboxHelper sandboxActived]) {
			[SandboxHelper addSource:_URL];
			BOOL started = [SandboxHelper startAccessingSecurityScopedSources];
			if (!started) NSLog(@"startAccessingSecurityScopedSources failed");
		}
		
		_pathLabel.stringValue = _URL.path.lastPathComponent;
		
		NSImage * image = [[NSWorkspace sharedWorkspace] iconForFile:_URL.path];
		[image setSize:NSMakeSize(324., 324.)];
		_imageView.image = image;
		
		[_showSourceInfoButton setHidden:YES];
		[_numberOfitemsLabel setHidden:YES];
		
		[_progressIndicator startAnimation:nil];
		[FileInformations fetchPropertiesForItemsAtPath:_URL.path];
		
		/* Enable "QuickLook Item" from main menu*/
		NSMenu * mainMenu = [NSApp mainMenu];
		[[[[mainMenu itemAtIndex:3] submenu] itemAtIndex:0] setEnabled:YES];
	}
}

- (void)fileInformationsDidFinish:(NSNotification *)notification
{
	// @TODO: hide the "info" button until the fetching is finished
	
	NSDictionary * attributes = (NSDictionary *)notification.object;
	NSURL * fileURL = [attributes objectForKey:@"fileURL"];
	
	if ([fileURL.path isEqualToString:_URL.path]) {/* Compare paths and not URL to remove all Sandbox stuff */
		double fileSize = [[attributes objectForKey:NSURLFileSizeKey] doubleValue];
		_numberOfitemsLabel.stringValue = [NSString stringWithFormat:@"%ld Items - %@", [[attributes objectForKey:@"numberOfItem"] integerValue], [NSString localizedStringForFileSize:fileSize]];
		[_numberOfitemsLabel setHidden:NO];
		
		[_showSourceInfoButton setHidden:NO];
		
		[_progressIndicator stopAnimation:nil];
		
		if ([SandboxHelper sandboxActived])
			[SandboxHelper stopAccessingSecurityScopedSources];
	}
}

- (void)draggingView:(id)draggingView didDragURL:(NSURL *)fileURL
{
	self.URL = fileURL;
	
	/*
	 [_pathLabel setHidden:NO];
	 _pathLabel.stringValue = fileURL.path.lastPathComponent;
	 
	 NSImage * image = [[NSWorkspace sharedWorkspace] iconForFile:fileURL.path];
	 [image setSize:NSMakeSize(324., 324.)];
	 _imageView.image = image;
	 
	 [_numberOfitemsLabel setHidden:YES];
	 [_progressIndicator startAnimation:nil];
	 [FileInformations fetchPropertiesForItemsAtPath:fileURL.path];
	 */
}

- (IBAction)startAction:(id)sender
{
	/* Call the method on the application delegate */
	[[NSApp delegate] startAction:nil];
}

- (IBAction)showOptionsAction:(id)sender
{
	[NSApp beginSheet:_optionsWindow
	   modalForWindow:self.view.window
		modalDelegate:nil
	   didEndSelector:NULL
		  contextInfo:NULL];
}

- (IBAction)openFolderAction:(id)sender
{
	NSOpenPanel * openPanel = [NSOpenPanel openPanel];
	openPanel.canChooseDirectories = YES;
	openPanel.canChooseFiles = NO;
	openPanel.allowsMultipleSelection = NO;
	[openPanel beginSheetModalForWindow:self.view.window
					  completionHandler:^(NSInteger result) {
						  self.URL = openPanel.URL;
					  }];
}

- (IBAction)showSourceDetailsAction:(id)sender
{
	[NSApp beginSheet:_folderDetailsWindow
	   modalForWindow:self.view.window
		modalDelegate:nil
	   didEndSelector:NULL
		  contextInfo:NULL];
	[_folderDetailsWindow reloadWithFolderURL:_URL];
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
	if (_URL)
		return [[NSWorkspace sharedWorkspace] iconForFile:_URL.path];
	
	return nil;
}

#pragma mark - QLPreviewPanelDataSource

- (NSInteger)numberOfPreviewItemsInPreviewPanel:(QLPreviewPanel *)panel
{
	return 1;
}

- (id <QLPreviewItem>)previewPanel:(QLPreviewPanel *)panel previewItemAtIndex:(NSInteger)index
{
	return _URL;
}

@end

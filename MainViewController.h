//
//  MainViewController.h
//  Comparator
//
//  Created by Max on 13/12/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuickLook/QuickLook.h>
#import <Quartz/Quartz.h>

#import "CenteredView.h"

#import "FolderDetailsWindow.h"

@class DraggingView;
@protocol DraggingViewDelegate <NSObject>

- (void)draggingView:(DraggingView *)draggingView didDragURL:(NSURL *)fileURL;

@end

@interface DraggingView : NSView
{
	id <DraggingViewDelegate> _delegate;
}

@property (nonatomic, strong) id <DraggingViewDelegate> delegate;

@end

@interface MainViewController : NSViewController <DraggingViewDelegate, QLPreviewPanelDelegate, QLPreviewPanelDataSource> {
	
	@private
	NSWindow * __strong _optionsWindow;
	FolderDetailsWindow * __strong _folderDetailsWindow;
	
	DraggingView * __strong _draggingView;
	NSTextField * __strong _pathLabel, * __strong _numberOfitemsLabel;
	NSProgressIndicator * __strong _progressIndicator;
	NSImageView * __strong _imageView;
	NSButton * __strong _showSourceInfoButton;
	CenteredView * __strong _centeredView;
	
	NSURL * _URL;
}


@property (strong) IBOutlet NSWindow * optionsWindow;
@property (strong) IBOutlet FolderDetailsWindow * folderDetailsWindow;

@property (strong) IBOutlet DraggingView * draggingView;
@property (strong) IBOutlet NSTextField * pathLabel, * numberOfitemsLabel;
@property (strong) IBOutlet NSProgressIndicator * progressIndicator;
@property (strong) IBOutlet NSImageView * imageView;
@property (strong) IBOutlet NSButton * showSourceInfoButton;
@property (strong) IBOutlet CenteredView * centeredView;

@property (strong) IBOutlet NSButton * runButton;

@property (nonatomic, copy) NSURL * URL;

- (IBAction)startAction:(id)sender;
- (IBAction)showOptionsAction:(id)sender;
- (IBAction)openFolderAction:(id)sender;
- (IBAction)showSourceDetailsAction:(id)sender;

- (IBAction)openHelpAction:(id)sender;

@end

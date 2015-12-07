//
//  FolderDetailsWindow.h
//  FolderSlice
//
//  Created by Maxime on 02/01/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import <AppKit/AppKit.h>

@interface _PopUpWindowContentView : NSView
@end


@interface ItemsListWindow : NSWindow
{
	NSArray * _items;
}

@property (nonatomic, copy) NSArray * items;

@end


@interface _ExcludeButton : NSButton

@end


@class ExcludePopUpWindow;
@protocol ExcludePopUpWindowDelegate <NSObject>

- (void)excludePopUpWindow:(ExcludePopUpWindow *)window didExcludeURL:(NSURL *)excludedURL;

@end

@interface ExcludePopUpWindow : NSWindow

@property (nonatomic, copy) NSURL * URL;
@property (nonatomic, assign) id <ExcludePopUpWindowDelegate> excludeDelegate;

@end


@interface DetailsSection : NSObject

@property (assign /* the path if copied into "-init" method */, readonly) CGPathRef path;
@property (strong, readonly) NSURL * URL;
@property (assign, readonly) NSPoint center;

- (instancetype)initWithFileURL:(NSURL *)fileURL areaPath:(CGPathRef)path center:(NSPoint)center;

@end


@interface FolderDetailsView : NSView <ExcludePopUpWindowDelegate>
{
	NSArray * _items;
	
	CGPathRef lastSectionPath, lastSectionAndPopupWindowPath;
	NSPoint lastSectionLocation;
	
	NSMutableArray * detailsSections;
	
	BOOL intoLastSection;
	ItemsListWindow * moreItemsWindow;
	ExcludePopUpWindow * excludePopUpWindow;
}

@property (nonatomic, strong) NSArray * items;

@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSArray *itemsToShow;

- (void)dismissAllPopUpWindows;

@end


@interface FolderDetailsWindow : NSWindow
{
	IBOutlet FolderDetailsView * _detailsView;
}

@property (nonatomic, strong) IBOutlet FolderDetailsView * detailsView;
@property (nonatomic, strong, readonly) NSArray * folderURLs;

- (void)reloadWithFolderURLs:(NSArray *)folderURLs;

- (IBAction)showInFinderAction:(id)sender;
- (IBAction)okAction:(id)sender;

@end
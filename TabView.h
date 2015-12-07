//
//  TabView.h
//  CustomTabs
//
//  Created by Maxime on 03/01/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CoreText/CoreText.h>

@interface TabItemButton : NSButton
@end

@interface TabItemPopupButton : NSButton
@end

@interface TabItem : NSObject
{
	NSString * _title;
	NSMenu * _menu;
	CGFloat _width;
}

@property (nonatomic, readonly) NSString * title;
@property (nonatomic, readonly) NSMenu * menu;
@property (nonatomic, readonly) CGFloat width;

+ (instancetype)itemWithTitle:(NSString *)title;
+ (instancetype)itemWithMenu:(NSMenu *)menu;
+ (instancetype)itemWithMenu:(NSMenu *)menu selectedIndex:(NSInteger)index;

- (instancetype)initWithTitle:(NSString *)title NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithMenu:(NSMenu *)menu NS_DESIGNATED_INITIALIZER;// The title of the item is the title of the first item 
- (instancetype)initWithMenu:(NSMenu *)menu selectedIndex:(NSInteger)index NS_DESIGNATED_INITIALIZER;// The title of the item is the title of the item a index "index"

- (void)invalidateLayout;

@end

@class TabView;
@protocol TabViewDelegate <NSObject>

@optional
- (void)tabView:(TabView *)tabView didSelectItem:(TabItem *)item;
- (void)tabView:(id)tabView didSelectMenuItem:(NSMenuItem *)menuItem fromItem:(TabItem *)item;

@end

@interface TabView : NSView
{
	NSArray * _items;
	id <TabViewDelegate> _delegate;
	
	NSArray * buttons;
	NSButton * selectedButton;
}
@property (nonatomic, copy) NSArray * items;

@property (nonatomic, strong) id <TabViewDelegate> delegate;

- (void)invalidateLayout;
- (void)updateLayout;

// Private
- (IBAction)tabDidSelectedAction:(id)sender;

@end

//
//  OptionsWindow.h
//  Comparator
//
//  Created by Max on 13/12/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import <AppKit/AppKit.h>

#import "OptionItem.h"

@interface OptionsWindow : NSWindow <NSTableViewDelegate, NSTableViewDataSource>
{
	NSArray * optionItems;
	
	@private
	NSButton * __strong _useCustomOptionsCheckBox;
	NSTableView * __strong _tableView;
	NSButton * __strong _okButton;
}

@property (strong) IBOutlet NSButton * useCustomOptionsCheckBox;
@property (strong) IBOutlet NSTableView * tableView;
@property (strong) IBOutlet NSButton * okButton;

- (void)reloadData;

- (IBAction)useCustomOptionsDidChecked:(id)sender;

- (IBAction)okAction:(id)sender;
- (IBAction)cancelAction:(id)sender;

// Private
- (BOOL)allOptionsAreUnselected;

- (BOOL)tableView:(NSTableView *)tableView rowIsGroupRow:(NSInteger)row;

@end

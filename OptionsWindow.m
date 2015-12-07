//
//  OptionsWindow.m
//  Comparator
//
//  Created by Max on 13/12/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "OptionsWindow.h"

@implementation OptionsWindow

@synthesize useCustomOptionsCheckBox = _useCustomOptionsCheckBox;
@synthesize tableView = _tableView;
@synthesize okButton = _okButton;

- (void)awakeFromNib
{
	_tableView.delegate = self;
	_tableView.dataSource = self;
	
	_tableView.focusRingType = NSFocusRingTypeNone;
	
	[self reloadData];
}

- (void)reloadData
{
#define kGroupSeparatorString @"separator"
	NSMutableArray * array = [[NSMutableArray alloc] initWithCapacity:10];
	
	NSArray * sections = [Section sections];
	for (Section * section in sections) {
		[section allOptions];// Fetch all options from store to get groups and options
		
		[array addObject:section];
		
		NSArray * groups = [section groups];
		for (Group * group in groups) {
			
			if (groups.count > 1)// Add the name of the group to tableView only if we have many groups into the section
				[array addObject:group.name];
			
			for (int row = 0; row < [group numberOfRow]; row++) {
				[array addObject:[group optionsAtRow:row]];
			}
		}
	}
	
	optionItems = (NSArray *)array;
	
	[_tableView reloadData];
	
	BOOL isAutomatic = ([OptionItem useAutomaticComparaison]);
	_useCustomOptionsCheckBox.state = (isAutomatic)? NSOffState : NSOnState;// The "Custom Options" checkbox is checked if "isAutomatic" is false
	[_tableView setEnabled:!isAutomatic];// Enable the "Custom Options" checkbox if the automatic settings is disabled
	
	BOOL enabled = (isAutomatic || !([self allOptionsAreUnselected]));// Enable is "OK" button we use automatic option or if options are not all unselected
	[_okButton setEnabled:enabled];
}

- (BOOL)allOptionsAreUnselected
{
	NSArray * sections = [Section sections];
	for (Section * section in sections) {
		[section allOptions];// Fetch all options from store to get groups and options
		
		NSArray * groups = [section groups];
		for (Group * group in groups) {
			for (int row = 0; row < [group numberOfRow]; row++) {
				NSArray * options = [group optionsAtRow:row];
				for (OptionItem * option in options) {
					if (option.selected.boolValue == YES) return NO;
				}
			}
		}
	}
	return YES;
}

- (IBAction)useCustomOptionsDidChecked:(id)sender
{
	BOOL useAutomaticComparaison = (_useCustomOptionsCheckBox.state == NSOnState);
	
	/* Disable/enable the tableView */
	[_tableView setEnabled:useAutomaticComparaison];
	
	BOOL enabled = (useAutomaticComparaison || !([self allOptionsAreUnselected]));// Enable is "OK" button we use automatic option or if options are not all unselected
	[_okButton setEnabled:enabled];
}

- (IBAction)okAction:(id)sender
{
	NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
	[userDefaults setBool:(_useCustomOptionsCheckBox.state == NSOnState) forKey:@"UsingCustomOptions"];
	[userDefaults synchronize];
	
	[OptionItem save];
	
	[NSApp endSheet:self returnCode:NSOKButton];
	[self orderOut:nil];
}

- (IBAction)cancelAction:(id)sender
{
	_useCustomOptionsCheckBox.state = NSOffState;
	
	[OptionItem rollback];
	
	[NSApp endSheet:self returnCode:NSCancelButton];
	[self orderOut:nil];
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return optionItems.count;
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
	if ([self tableView:tableView rowIsGroupRow:row]) {// For sections
		return 32.;
	} if ([optionItems[row] isKindOfClass:[NSString class]]) {// For description text
		return 14.;
	} else {
		return 17.;// For regular cells
	}
}

- (BOOL)tableView:(NSTableView *)tableView rowIsGroupRow:(NSInteger)row
{
	return ([optionItems[row] isKindOfClass:[Section class]]);
}

- (BOOL)tableView:(NSTableView *)aTableView isGroupRow:(NSInteger)row
{
	return [self tableView:aTableView rowIsGroupRow:row];
}

- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(NSInteger)rowIndex
{
	return NO;
}

- (NSCell *)tableView:(NSTableView *)aTableView dataCellForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)row
{
	NSCell * cell = [aTableColumn dataCellForRow:row];
	
	if ([optionItems[row] isKindOfClass:[Section class]]) {
		
		/* Hide check box for Section and title for left part */
		if ([aTableColumn.identifier isEqualToString:@"descriptionLeft-check"]) {
			return [[NSCell alloc] init];
		} else if ([aTableColumn.identifier isEqualToString:@"descriptionRight-check"]) {
			return [[NSCell alloc] init];
		} else if ([aTableColumn.identifier isEqualToString:@"descriptionRight"]) {
			return nil;
		}
		
	} else if ([optionItems[row] isKindOfClass:[NSString class]]) {
		NSTextFieldCell * textFieldCell = [[NSTextFieldCell alloc] init];
		textFieldCell.font = [NSFont systemFontOfSize:10.];
		textFieldCell.textColor = [NSColor grayColor];
		return textFieldCell;
	} else {
		NSArray * items = optionItems[row];
		
		if (items.count == 1) {
			if ([aTableColumn.identifier isEqualToString:@"descriptionRight-check"]) {
				return [[NSCell alloc] init];
			} else if ([aTableColumn.identifier isEqualToString:@"descriptionRight"]) {
				return nil;
			}
		}
	}
	
	return cell;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	if ([optionItems[rowIndex] isKindOfClass:[Section class]]) {
		
		if ([aTableColumn.identifier isEqualToString:@"descriptionLeft-check"]) {
			return nil;
		} else if ([aTableColumn.identifier isEqualToString:@"descriptionLeft"]) {
			return [(Section *)optionItems[rowIndex] localizedDescriptionString];
		}
		
	} else if ([optionItems[rowIndex] isKindOfClass:[NSString class]]) {
		NSString * string = optionItems[rowIndex];
		return string;
	} else {
		NSArray * items = optionItems[rowIndex];
		
		if (items.count > 0) {
			OptionItem * item = items.firstObject;
			if ([aTableColumn.identifier isEqualToString:@"descriptionLeft-check"]) {
				return item.selected;
			} else if ([aTableColumn.identifier isEqualToString:@"descriptionLeft"]) {
				return [item localizedDescription];
			} else {
				if (items.count > 1) {
					OptionItem * item = items[1];
					if ([aTableColumn.identifier isEqualToString:@"descriptionRight-check"]) {
						return item.selected;
					} else if ([aTableColumn.identifier isEqualToString:@"descriptionRight"]) {
						return [item localizedDescription];
					}
				}
			}
		}
	}
	
	return nil;
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	if ([optionItems[rowIndex] isKindOfClass:[Section class]]) {
		
	} else {
		NSArray * items = optionItems[rowIndex];
		
		OptionItem * item = items.firstObject;
		if ([aTableColumn.identifier isEqualToString:@"descriptionLeft-check"]) {
			item.selected = anObject;
		} else if ([aTableColumn.identifier isEqualToString:@"descriptionLeft"]) {
		} else if (items.count > 1) {
			OptionItem * item = items[1];
			if ([aTableColumn.identifier isEqualToString:@"descriptionRight-check"]) {
				item.selected = anObject;
			} else if ([aTableColumn.identifier isEqualToString:@"descriptionRight"]) {
			}
		}
		
		BOOL useAutomaticComparaison = (_useCustomOptionsCheckBox.state == NSOnState);
		BOOL enabled = (useAutomaticComparaison || !([self allOptionsAreUnselected]));// Enable is "OK" button we use automatic option or if options are not all unselected
		[_okButton setEnabled:enabled];
	}
}

#pragma mark NSTableViewDelegate

- (BOOL)tableView:(NSTableView *)tableView shouldTrackCell:(NSCell *)cell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	return YES;// Tracks button's cell because cell are not selectable so by default button's cell can't be selected as well
}

@end

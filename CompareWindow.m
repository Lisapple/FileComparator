//
//  CompareViewController.m
//  Comparator
//
//  Created by Max on 29/03/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "CompareWindow.h"

#import "NSArray+addition.h"

@implementation CompareWindow

- (void)awakeFromNib
{
	// @TODO: find an automatic way to fix the layout from the middle cell's content's size
	// @TODO: allow user to enlarge the window
	tableView.delegate = self;
	tableView.dataSource = self;
}

- (IBAction)close:(id)sender
{
	[NSApp endSheet:self];
}

- (void)compareItem:(FileItem *)item1 withItem:(FileItem *)item2
{
	_item1 = item1;
	
	_item1Attributes = [_item1 localizedItemValues];
	
	_item2 = item2;
	
	_item2Attributes = [_item2 localizedItemValues];
	
	NSMutableArray * _keys = [[NSMutableArray alloc] initWithCapacity:10];
	[_keys addObjectsFromArray:[[_item1Attributes allKeys] arrayByAddingNewObjectsFromArray:[_item2Attributes allKeys]]];
	[_keys removeObject:@"FileItemCompareFilename"];// Remove filename and
	[_keys removeObject:@"FileItemCompareExtension"];// Revome extension from tableView
	
	[_keys sortUsingSelector:@selector(caseInsensitiveCompare:)];
	
	keys = _keys;
	
	//itemPreview1
	itemFilename1.stringValue = [item1.path lastPathComponent];
	NSString * folderPath = [item1.path stringByDeletingLastPathComponent];
	itemPath1.stringValue = [folderPath stringByAbbreviatingWithTildeInPath];// Replace "/Users/Jo/Desktop/FolderName/" by "~/Desktop/FolderName/" to save space
	
	//itemPreview2;
	itemFilename2.stringValue = [item2.path lastPathComponent];
	folderPath = [item2.path stringByDeletingLastPathComponent];
	itemPath2.stringValue = [folderPath stringByAbbreviatingWithTildeInPath];
	
	itemPreview1.image = [item1 thumbnailForSize:CGSizeMake(48., 48.)];
	itemPreview2.image = [item2 thumbnailForSize:CGSizeMake(48., 48.)];
	
	[tableView reloadData];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return keys.count;
}

- (NSCell *)tableView:(NSTableView *)tableView dataCellForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	NSCell * cell = [tableColumn dataCellForRow:row];
	
	CGFloat size = cell.font.pointSize;
	cell.font = [NSFont systemFontOfSize:size];
	
	if (row < keys.count) {
		NSString * key = [keys objectAtIndex:row];
		
		if ([tableColumn.identifier isEqualToString:@"item1"]) {
			
			if ([_item2Attributes valueForKey:key]) {
				BOOL bold = ([[_item1Attributes valueForKey:key] compare:[_item2Attributes valueForKey:key]] == NSOrderedDescending);// Bold the greater value
				if (bold) {
					CGFloat size = cell.font.pointSize;
					[cell setFont:[NSFont boldSystemFontOfSize:size]];
				}
			}
		} else if ([tableColumn.identifier isEqualToString:@"item2"]) {
			
			if ([_item1Attributes valueForKey:key]) {
				BOOL bold = ([[_item2Attributes valueForKey:key] compare:[_item1Attributes valueForKey:key]] == NSOrderedDescending);
				if (bold) {
					CGFloat size = cell.font.pointSize;
					[cell setFont:[NSFont boldSystemFontOfSize:size]];
				}
			}
		} else { // Description
			
		}
	}
	
	return cell;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	NSString * key = [keys objectAtIndex:rowIndex];
	
	if ([aTableColumn.identifier isEqualToString:@"item1"]) {
		return [_item1Attributes valueForKey:key];
	} else if ([aTableColumn.identifier isEqualToString:@"item2"]) {
		return [_item2Attributes valueForKey:key];
	} else {
		return [[OptionItem localizedShortDescriptionForOption:key] capitalizedString];
	}
	
	return nil;
}

@end

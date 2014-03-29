//
//  ResultsViewController.m
//  Comparator
//
//  Created by Max on 18/04/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

#import "ResultsViewController.h"

#import "ComparatorAppDelegate.h"

#import "NSString+addition.h"
#import "NSDate+addition.h"
#import "NSMenu+additions.h"
#import "FileItem+additions.h"

#import "MyWindow.h"

#import "OptionItem.h"

#import "SandboxHelper.h"

@implementation RightPanelScrollView

- (BOOL)isFlipped
{
	return YES;
}

@end


@implementation GridItem (addition)

- (NSManagedObject *)managedObject
{
	return [self.info objectForKey:@"managedObject"];
}

- (void)setManagedObject:(NSManagedObject *)object
{
	[self.info setObject:object forKey:@"managedObject"];
}

- (NSManagedObject *)group
{
	return [self.info objectForKey:@"group"];
}

- (void)setGroup:(NSManagedObject *)group
{
	[self.info setObject:group forKey:@"group"];
}

@end


@implementation FileItem (QLPreviewItem)

- (NSURL *)previewItemURL
{
	return [NSURL fileURLWithPath:self.path];
}

- (NSString *)previewItemTitle
{
	/* Show the entire path as title to differenciate item with path */
	return self.path;
}

@end


@implementation FileItem (GridItem)

@end


@interface ResultsViewController (PrivateMethods)

- (void)revertTableColumns;
- (void)saveTableColumns;

- (void)showOriginalReplaceWithAliasWarning;

- (void)moveTo:(id)sender;

- (void)setOriginalItem:(FileItem *)item forGroup:(NSManagedObject * )group;

@end


@implementation ResultsViewController

@synthesize tabView = _tabView;

@synthesize moveButton, replaceButton;
@synthesize moveToTrashButton, deleteButton;

@synthesize panelTableView;

@synthesize previewPanelView;
@synthesize previewImageView;
@synthesize compareButton;
@synthesize moveToTrash;
@synthesize replaceWithAliasButton, setAsOriginalButton;

@synthesize summaryResultsView = _summaryResultsView;
@synthesize summaryCenteredView = _summaryCenteredView;

@synthesize splitView = _splitView;

@synthesize gridView;

@synthesize keepHierarchyCheckbox, movedPanelAccessoryView;

@synthesize duplicatesArrays;
@synthesize emptyItems;
@synthesize brokenAliases;

@synthesize items = _items;

@synthesize sourceArray;


- (void)awakeFromNib
{
	gridView.delegate = self;
	gridView.dataSource = self;
	
	[panelTableView setDelegate:self];
	[panelTableView setDataSource:self];
	[panelTableView setFocusRingType:NSFocusRingTypeNone];
	[panelTableView reloadData];
	
	[panelTableView addSubview:previewPanelView];
	previewPanelView.autoresizingMask = (NSViewMaxYMargin | NSViewWidthSizable);
	
	_splitView.delegate = self;
	
	showSummaryView = YES;
	[_summaryResultsView setHidden:YES];
}

- (void)update// => used???
{
	currentGroup = nil;
	
	[gridView.headerView setHidden:YES];
	[gridView deselectAll];
	
	[self reloadData];
}

- (NSInteger)allItemsToDeleteCount
{
	return duplicatesToDelete.count + emptyItemsToDelete.count + brokenAliasesToDelete.count;
}

- (NSArray *)allItemsToDelete
{
	NSMutableArray * allItems = [NSMutableArray arrayWithArray:duplicatesToDelete];
	[allItems addObjectsFromArray:emptyItemsToDelete];
	[allItems addObjectsFromArray:brokenAliasesToDelete];
	return allItems;
}

- (NSInteger)currentTaskCount
{
	return ([self allItemsToDeleteCount] + itemsToReplace.count);
}

#pragma mark - Items

- (NSEntityDescription *)entityForDuplicateType:(DuplicateType)type context:(NSManagedObjectContext *)context
{
	NSEntityDescription * entity = nil;
	if (type == DuplicateTypeFiles) {// Files
		entity = [NSEntityDescription entityForName:@"FileItemGroup" inManagedObjectContext:context];
	} else if (type == DuplicateTypeImages) {// ImageItem
		entity = [NSEntityDescription entityForName:@"ImageItemGroup" inManagedObjectContext:context];
	} else if (type == DuplicateTypeAudioFiles) {// AudioItem
		entity = [NSEntityDescription entityForName:@"AudioItemGroup" inManagedObjectContext:context];
	}
	return entity;
}

- (NSInteger)numberOfItemsForDuplicateType:(DuplicateType)type
{
	if (type == DuplicateTypeAll) {
		return (NSInteger)([self numberOfItemsForDuplicateType:DuplicateTypeFiles]
						   + [self numberOfItemsForDuplicateType:DuplicateTypeImages]
						   + [self numberOfItemsForDuplicateType:DuplicateTypeAudioFiles]);
	} else {
		/* Don't use context over threads, create a context for each thread with the persistent store */
		NSPersistentStoreCoordinator * coordinator = [[NSApp delegate] persistentStoreCoordinator];
		NSAssert(coordinator != nil, @"coordinator == nil");
		
		NSManagedObjectContext * context = [[NSManagedObjectContext alloc] init];
		[context setPersistentStoreCoordinator:coordinator];
		[context setUndoManager:nil];
		
		NSFetchRequest * request = [[NSFetchRequest alloc] init];
		[request setEntity:[self entityForDuplicateType:type context:context]];
		
		__block NSInteger count = 0;
		[request setPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
			NSInteger groupCount = [evaluatedObject mutableSetValueForKey:@"items"].count;
			if (groupCount > 1)// Find groups with more than one item
				count += groupCount;
			return YES;
		}]];
		
		[context countForFetchRequest:request error:NULL];
		
		return count;
	}
}

- (NSArray *)groupsForDuplicateType:(DuplicateType)type
{
	if (type == DuplicateTypeAll) {
		NSMutableArray * allItems = [NSMutableArray arrayWithCapacity:100];
		[allItems addObjectsFromArray:[self groupsForDuplicateType:DuplicateTypeFiles]];
		[allItems addObjectsFromArray:[self groupsForDuplicateType:DuplicateTypeImages]];
		[allItems addObjectsFromArray:[self groupsForDuplicateType:DuplicateTypeAudioFiles]];
		
		NSPersistentStoreCoordinator * coordinator = [[NSApp delegate] persistentStoreCoordinator];
		NSAssert(coordinator != nil, @"coordinator == nil");
		
		NSManagedObjectContext * context = [[NSManagedObjectContext alloc] init];
		[context setPersistentStoreCoordinator:coordinator];
		[context setUndoManager:nil];
		
		/* Order the array by number of items */
		return [allItems sortedArrayUsingComparator:^NSComparisonResult(NSManagedObject * obj1, NSManagedObject * obj2) {
			
			NSManagedObject * o1 = [context objectWithID:obj1.objectID];
			NSManagedObject * o2 = [context objectWithID:obj2.objectID];
			
			/*
			 NSFetchRequest * request = [[NSFetchRequest alloc] init];
			 request.entity = obj1.entity;
			 request.predicate = [NSPredicate predicateWithFormat:@"TRUEPREDICATE"];
			 NSUInteger count1 = [context countForFetchRequest:request error:NULL];
			 
			 request.entity = obj2.entity;
			 NSUInteger count2 = [context countForFetchRequest:request error:NULL];
			 
			 NSLog(@"Obj1 = %@", (obj1.isFault) ? @"Fault" : @"Not fault");
			 NSLog(@"Obj2 = %@", (obj2.isFault) ? @"Fault" : @"Not fault");
			 */
			
			NSUInteger count1 = [o1 mutableSetValueForKey:@"items"].count;
			NSUInteger count2 = [o2 mutableSetValueForKey:@"items"].count;
			NSInteger count = (count2 - count1);
			return (count > 0)? NSOrderedDescending : ((count < 0)? NSOrderedAscending : NSOrderedSame);
		}];
	} else {
		/* Don't use context over threads, create a context for each thread with the persistent store */
		NSPersistentStoreCoordinator * coordinator = [[NSApp delegate] persistentStoreCoordinator];
		NSAssert(coordinator != nil, @"coordinator == nil");
		
		NSManagedObjectContext * context = [[NSManagedObjectContext alloc] init];
		[context setPersistentStoreCoordinator:coordinator];
		[context setUndoManager:nil];
		
		NSFetchRequest * request = [[NSFetchRequest alloc] init];
		request.entity = [self entityForDuplicateType:type context:context];
		request.predicate = [NSPredicate predicateWithFormat:@"items[SIZE] > 1"]; // Find groups with more than one item
		
		NSString * key = [[NSUserDefaults standardUserDefaults] stringForKey:@"OriginalSortedKey"];
		BOOL ascending = !([key isEqualToString:@"lastModificationDate"]);// Descending (NO) if "lastModificationDate", Ascending (YES) if "creationDate" or nil
		
		NSSortDescriptor * sortDescriptor = [[NSSortDescriptor alloc] initWithKey:key ascending:ascending];
		request.sortDescriptors = [NSArray arrayWithObjects:sortDescriptor, [NSSortDescriptor sortDescriptorWithKey:@"path" ascending:YES], nil];
		
		NSArray * groups = [context executeFetchRequest:request error:NULL];
		
		return [groups sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
			NSUInteger count1 = [(NSManagedObject *)obj1 mutableSetValueForKey:@"items"].count;
			NSUInteger count2 = [(NSManagedObject *)obj2 mutableSetValueForKey:@"items"].count;
			NSInteger count = (count2 - count1);
			return (count > 0)? NSOrderedDescending : ((count < 0)? NSOrderedAscending : NSOrderedSame);
		}];
	}
}

- (NSArray *)allItemsForDuplicateType:(DuplicateType)type
{
	if (type == DuplicateTypeAll) {
		NSMutableArray * allItems = [[NSMutableArray alloc] initWithCapacity:100];
		[allItems addObjectsFromArray:[self allItemsForDuplicateType:DuplicateTypeFiles]];
		[allItems addObjectsFromArray:[self allItemsForDuplicateType:DuplicateTypeImages]];
		[allItems addObjectsFromArray:[self allItemsForDuplicateType:DuplicateTypeAudioFiles]];
		return allItems;
	} else {
		NSMutableArray * allItems = [NSMutableArray arrayWithCapacity:500];
		NSArray * groups = [self groupsForDuplicateType:type];
		for (NSManagedObject * group in groups) {
			[allItems addObjectsFromArray:[group mutableSetValueForKey:@"items"].allObjects];
		}
		return allItems;
	}
}

- (NSArray *)duplicatesForDuplicateType:(DuplicateType)type
{
	if (type == DuplicateTypeAll) {
		NSMutableArray * allItems = [[NSMutableArray alloc] initWithCapacity:100];
		[allItems addObjectsFromArray:[self duplicatesForDuplicateType:DuplicateTypeFiles]];
		[allItems addObjectsFromArray:[self duplicatesForDuplicateType:DuplicateTypeImages]];
		[allItems addObjectsFromArray:[self duplicatesForDuplicateType:DuplicateTypeAudioFiles]];
		return allItems;
	} else {
		NSString * key = [[NSUserDefaults standardUserDefaults] stringForKey:@"OriginalSortedKey"];
		BOOL ascending = !([key isEqualToString:@"lastModificationDate"]);// Descending (NO) if "lastModificationDate", Ascending (YES) if "creationDate" or nil
		
		NSSortDescriptor * sortDescriptor = [[NSSortDescriptor alloc] initWithKey:((!key)? @"creationDate": key)
																		ascending:ascending];
		NSArray * sortDescriptors = [NSArray arrayWithObjects:sortDescriptor, [NSSortDescriptor sortDescriptorWithKey:@"path" ascending:YES], nil];
		
		NSMutableArray * allItems = [NSMutableArray arrayWithCapacity:500];
		NSArray * groups = [self groupsForDuplicateType:type];
		for (NSManagedObject * group in groups) {
			NSMutableArray * itemsCopy = [[[group mutableSetValueForKey:@"items"] sortedArrayUsingDescriptors:sortDescriptors] mutableCopy];
			[itemsCopy removeObjectAtIndex:0];
			[allItems addObjectsFromArray:itemsCopy];
		}
		
		return allItems;
	}
}

- (NSInteger)numberOfDuplicatesForDuplicateType:(DuplicateType)type
{
	if (type == DuplicateTypeAll) {
		return (NSInteger)([self numberOfDuplicatesForDuplicateType:DuplicateTypeFiles]
						   + [self numberOfDuplicatesForDuplicateType:DuplicateTypeImages]
						   + [self numberOfDuplicatesForDuplicateType:DuplicateTypeAudioFiles]);
	} else {
		/* Don't use context over threads, create a context for each thread with the persistent store */
		NSPersistentStoreCoordinator * coordinator = [[NSApp delegate] persistentStoreCoordinator];
		NSAssert(coordinator != nil, @"coordinator == nil");
		
		NSManagedObjectContext * context = [[NSManagedObjectContext alloc] init];
		[context setPersistentStoreCoordinator:coordinator];
		[context setUndoManager:nil];
		
		NSFetchRequest * request = [[NSFetchRequest alloc] init];
		[request setEntity:[self entityForDuplicateType:type context:context]];
		
		__block NSInteger count = 0;
		[request setPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
			count += ([evaluatedObject mutableSetValueForKey:@"items"].count - 1);
			return YES;
		}]];
		
		[context countForFetchRequest:request error:NULL];
		
		return count;
	}
}

- (unsigned long long)sizeOfDuplicatesForDuplicateType:(DuplicateType)type
{
	if (type == DuplicateTypeAll) {
		return (unsigned long long)([self sizeOfDuplicatesForDuplicateType:DuplicateTypeFiles]
									+ [self sizeOfDuplicatesForDuplicateType:DuplicateTypeImages]
									+ [self sizeOfDuplicatesForDuplicateType:DuplicateTypeAudioFiles]);
	} else {
		/* Don't use context over threads, create a context for each thread with the persistent store */
		NSPersistentStoreCoordinator * coordinator = [[NSApp delegate] persistentStoreCoordinator];
		NSAssert(coordinator != nil, @"coordinator == nil");
		
		NSManagedObjectContext * context = [[NSManagedObjectContext alloc] init];
		[context setPersistentStoreCoordinator:coordinator];
		[context setUndoManager:nil];
		
		NSFetchRequest * request = [[NSFetchRequest alloc] init];
		[request setEntity:[self entityForDuplicateType:type context:context]];
		
		__block unsigned long long totalSize = 0.;
		[request setPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
			BOOL isFirstItem = YES;
			NSArray * items = [evaluatedObject mutableSetValueForKey:@"items"].allObjects;
			for (FileItem * item in items) {
				if (isFirstItem) {// Jump the first item
					isFirstItem = NO;
				} else {
					totalSize += ((NSNumber *)[item valueForKey:@"fileSize"]).unsignedLongLongValue;
				}
			}
			
			return YES;
		}]];
		
		[context countForFetchRequest:request error:NULL];
		
		return totalSize;
	}
}

#pragma mark - Core Data Items Management

- (void)deleteItems:(NSArray *)items
{
	NSMutableArray * contexts = [NSMutableArray arrayWithCapacity:3];
	for (FileItem * item in items) {
		if (![contexts containsObject:item.managedObjectContext])
			[contexts addObject:item.managedObjectContext];
		
		[item.managedObjectContext deleteObject:item];
	}
	
	for (NSManagedObjectContext * context in contexts) {
		NSError * error = nil;
		[context save:&error];
		if (error) {
			NSDebugLog(@"save error %@", [error localizedDescription]);
		}
	}
}

#pragma mark - Grid's Items Creation

- (NSArray *)gridItemsForDuplicatesType:(DuplicateType)type
{
	NSArray * groups = [self groupsForDuplicateType:type];
	
	NSString * itemsString = NSLocalizedString(@"%li items", nil);
	
	if ([SandboxHelper sandboxActived]) {
		BOOL started = [SandboxHelper startAccessingSecurityScopedSources];
		if (!started) NSLog(@"startAccessingSecurityScopedSources failed");
	}
	
	NSPersistentStoreCoordinator * coordinator = [[NSApp delegate] persistentStoreCoordinator];
	NSAssert(coordinator != nil, @"coordinator == nil");
	
	NSManagedObjectContext * context = [[NSManagedObjectContext alloc] init];
	[context setPersistentStoreCoordinator:coordinator];
	[context setUndoManager:nil];
	
	
	dispatch_group_t dispatch_group = dispatch_group_create();
	dispatch_queue_t dispatch_queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
	
	NSMutableArray * items = [[NSMutableArray alloc] initWithCapacity:groups.count];
	for (NSManagedObject * group in groups) {
		
		NSSet * set = (NSSet *)[[context objectWithID:group.objectID] mutableSetValueForKey:@"items"];
		/*
		 [group willAccessValueForKey:@"items"];
		 NSSet * set = (NSSet *)[group mutableSetValueForKey:@"items"];
		 [group didAccessValueForKey:@"items"];
		 */
		
		GridItem * item = [[GridItem alloc] init];
		item.title = [NSString stringWithFormat:itemsString, set.count];
		
		item.isGroup = YES;
		item.group = group;
		
		FileItem * fileItem = [set anyObject];
		NSString * path = fileItem.path;
		dispatch_group_async(dispatch_group, dispatch_queue, ^{
			item.image = [[NSWorkspace sharedWorkspace] iconForFile:path];
		});
		
		[items addObject:item];
	}
	
	/* Stop Sandbox when group finished */
	dispatch_group_notify(dispatch_group, dispatch_queue, ^{
		if ([SandboxHelper sandboxActived]) [SandboxHelper stopAccessingSecurityScopedSources];
	});
	
	return items;
}

- (NSArray *)gridItemsForGroup:(NSManagedObject *)group
{
	NSPersistentStoreCoordinator * coordinator = [[NSApp delegate] persistentStoreCoordinator];
	NSAssert(coordinator != nil, @"coordinator == nil");
	
	NSManagedObjectContext * context = [[NSManagedObjectContext alloc] init];
	[context setPersistentStoreCoordinator:coordinator];
	[context setUndoManager:nil];
	
	NSString * key = [[NSUserDefaults standardUserDefaults] stringForKey:@"OriginalSortedKey"];
	BOOL ascending = !([key isEqualToString:@"lastModificationDate"]);// Descending (NO) if "lastModificationDate", Ascending (YES) if "creationDate" or nil
	
	NSSortDescriptor * sortDescriptor = [[NSSortDescriptor alloc] initWithKey:((!key)? @"creationDate": key)
																	ascending:ascending];
	NSArray * descriptors = [[NSArray alloc] initWithObjects:sortDescriptor, [NSSortDescriptor sortDescriptorWithKey:@"path" ascending:YES], nil];
	
	NSManagedObject * newGroup = [context objectWithID:group.objectID];
	NSArray * groups = [[newGroup mutableSetValueForKey:@"items"] sortedArrayUsingDescriptors:descriptors];
	NSManagedObject * originalItemsObject = [newGroup valueForKey:@"originalItems"];
	
	if (groups.count > 0 && (originalItemsObject == nil)) {
		[self setOriginalItem:[groups objectAtIndex:0]
					 forGroup:group];
	}
	
	if ([SandboxHelper sandboxActived]) {
		BOOL started = [SandboxHelper startAccessingSecurityScopedSources];
		if (!started) NSLog(@"startAccessingSecurityScopedSources failed");
	}
	
	dispatch_group_t dispatch_group = dispatch_group_create();
	dispatch_queue_t dispatch_queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
	
	NSManagedObjectID * groupID = originalItemsObject.objectID;
	NSMutableArray * items = [[NSMutableArray alloc] initWithCapacity:groups.count];
	for (FileItem * fileItem in groups) {
		
		GridItem * item = [[GridItem alloc] init];
		item.title = [fileItem.path lastPathComponent];
		
		NSString * path = fileItem.path;
		dispatch_sync(dispatch_queue, ^{
			NSImage * image = [[NSWorkspace sharedWorkspace] iconForFile:path];
			if (!item.image) item.image = image;// Set the image only if no image have been set
		});
		
		item.isOriginal = ([groupID isEqual:fileItem.objectID]);
		
		
		BOOL becameAlias = NO;
		for (GridItem * item in itemsToReplace) {
			if ([((FileItem *)item.managedObject).path isEqualToString:fileItem.path]) {
				becameAlias = YES;
				break;
			}
		}
		item.becameAlias = becameAlias;
		
		
		BOOL deleted = NO;
		for (GridItem * item in duplicatesToDelete) {
			if ([((FileItem *)item.managedObject).path isEqualToString:fileItem.path]) {
				deleted = YES;
				break;
			}
		}
		item.deleted = deleted;
		
		
		item.labelColor = [(FileItem *)fileItem labelColor];
		
		NSURL * fileURL = [NSURL fileURLWithPath:fileItem.path];
		
		dispatch_group_async(dispatch_group, dispatch_queue, ^{
			const void * keys[1] = { (void *)kQLThumbnailOptionIconModeKey };
			const void * values[1] = { (void *)kCFBooleanTrue };
			
			CFDictionaryRef thumbnailAttributes = CFDictionaryCreate(kCFAllocatorDefault, keys, values, 1, NULL, NULL);
			CGImageRef imageRef = QLThumbnailImageCreate(kCFAllocatorDefault, (__bridge CFURLRef)fileURL, CGSizeMake(64., 64.), thumbnailAttributes);
			//if (thumbnailAttributes) CFRelease(thumbnailAttributes);
			
			if (imageRef) {
				NSImage * image = [[NSImage alloc] initWithCGImage:imageRef size:NSZeroSize];
				CGImageRelease(imageRef);
				
				item.image = image;
			}
		});
		
		[item setManagedObject:fileItem];
		item.group = group;
		
		[items addObject:item];
	}
	
	/* Stop Sandbox when group finished */
	dispatch_group_notify(dispatch_group, dispatch_queue, ^{
		if ([SandboxHelper sandboxActived]) [SandboxHelper stopAccessingSecurityScopedSources];
	});
	
	return items;
}

- (NSArray *)gridItemsForEmptyItems
{
	if ([SandboxHelper sandboxActived]) {
		BOOL started = [SandboxHelper startAccessingSecurityScopedSources];
		if (!started) NSLog(@"startAccessingSecurityScopedSources failed");
	}
	
	dispatch_group_t group = dispatch_group_create();
	dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
	
	NSMutableArray * items = [[NSMutableArray alloc] initWithCapacity:emptyItems.count];
	for (FileItem * fileItem in emptyItems) {
		
		GridItem * item = [[GridItem alloc] init];
		item.title = [fileItem.path lastPathComponent];
		
		NSString * path = fileItem.path;
		dispatch_sync(queue, ^{
			NSImage * image = [[NSWorkspace sharedWorkspace] iconForFile:path];
			if (!item.image) item.image = image;// Set the image only if no image have been set
		});
		
		dispatch_group_async(group, queue, ^{
			const void * keys[1] = { (void *)kQLThumbnailOptionIconModeKey };
			const void * values[1] = { (void *)kCFBooleanTrue };
			
			NSURL * fileURL = [NSURL fileURLWithPath:path];
			
			CFDictionaryRef thumbnailAttributes = CFDictionaryCreate(kCFAllocatorDefault, keys, values, 1, NULL, NULL);
			CGImageRef imageRef = QLThumbnailImageCreate(kCFAllocatorDefault, (__bridge CFURLRef)fileURL, CGSizeMake(64., 64.), thumbnailAttributes);
			if (thumbnailAttributes) CFRelease(thumbnailAttributes);
			
			if (imageRef) {
				NSImage * image = [[NSImage alloc] initWithCGImage:imageRef size:NSZeroSize];
				CGImageRelease(imageRef);
				
				item.image = image;
			}
		});
		
		[item setManagedObject:fileItem];
		
		[items addObject:item];
	}
	
	/* Stop Sandbox when group finished */
	dispatch_group_notify(group, queue, ^{
		if ([SandboxHelper sandboxActived]) [SandboxHelper stopAccessingSecurityScopedSources];
	});
	
	return items;
}

- (NSArray *)gridItemsForBrokensAliases
{
	dispatch_group_t dispatch_group = dispatch_group_create();
	dispatch_queue_t dispatch_queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
	
	NSMutableArray * items = [[NSMutableArray alloc] initWithCapacity:brokenAliases.count];
	for (FileItem * fileItem in brokenAliases) {
		
		GridItem * item = [[GridItem alloc] init];
		item.title = [fileItem.path lastPathComponent];
		
		NSString * path = fileItem.path;
		dispatch_sync(dispatch_queue, ^{
			NSImage * image = [[NSWorkspace sharedWorkspace] iconForFile:path];
			if (!item.image) item.image = image;// Set the image only if no image have been set
		});
		
		dispatch_group_async(dispatch_group, dispatch_queue, ^{
			const void * keys[1] = { (void *)kQLThumbnailOptionIconModeKey };
			const void * values[1] = { (void *)kCFBooleanTrue };
			
			NSURL * fileURL = [NSURL fileURLWithPath:fileItem.path];
			
			CFDictionaryRef thumbnailAttributes = CFDictionaryCreate(kCFAllocatorDefault, keys, values, 1, NULL, NULL);
			CGImageRef imageRef = QLThumbnailImageCreate(kCFAllocatorDefault, (__bridge CFURLRef)fileURL, CGSizeMake(64., 64.), thumbnailAttributes);
			if (thumbnailAttributes) CFRelease(thumbnailAttributes);
			
			if (imageRef) {
				NSImage * image = [[NSImage alloc] initWithCGImage:imageRef size:NSZeroSize];
				CGImageRelease(imageRef);
				
				item.image = image;
			}
		});
		
		[item setManagedObject:fileItem];
		
		[items addObject:item];
	}
	
	return items;
}

- (void)reloadTabs
{
	_tabView.delegate = self;
	
	NSMutableArray * tabItems = [[NSMutableArray alloc] initWithCapacity:3];
	
	NSInteger numberOfDuplicatesFiles = [self numberOfDuplicatesForDuplicateType:DuplicateTypeFiles];
	NSInteger numberOfDuplicatesImages = [self numberOfDuplicatesForDuplicateType:DuplicateTypeImages];
	NSInteger numberOfDuplicatesAudioFiles = [self numberOfDuplicatesForDuplicateType:DuplicateTypeAudioFiles];
	
	/* If we have duplicates to show, show the menu, else, just show the "Duplicates" tab */
	if ((numberOfDuplicatesFiles + numberOfDuplicatesImages + numberOfDuplicatesAudioFiles) > 0) {
		
		NSMenu * menu = [[NSMenu alloc] initWithTitle:@"all-duplicates-menu"];
		[menu addItemWithTitle:NSLocalizedString(@"All Duplicates", nil) action:NULL keyEquivalent:@""];
		[menu addItem:[NSMenuItem separatorItem]];
		
		if (numberOfDuplicatesFiles > 0)
			[menu addItemWithTitle:NSLocalizedString(@"File Duplicates", nil) action:NULL keyEquivalent:@""];
		
		if (numberOfDuplicatesImages > 0)
			[menu addItemWithTitle:NSLocalizedString(@"Image Duplicates", nil) action:NULL keyEquivalent:@""];
		
		if (numberOfDuplicatesAudioFiles > 0)
			[menu addItemWithTitle:NSLocalizedString(@"Audio File Duplicates", nil) action:NULL keyEquivalent:@""];
		
		[tabItems addObject:[TabItem itemWithMenu:menu]];
	} else {
		[tabItems addObject:[TabItem itemWithTitle:NSLocalizedString(@"Duplicates", nil)]];
	}
	
	if ([OptionItem shouldFindBrokenAliases])
		[tabItems addObject:[TabItem itemWithTitle:NSLocalizedString(@"Empty Items", nil)]];
	
	if ([OptionItem shouldFindEmptyItems])
		[tabItems addObject:[TabItem itemWithTitle:NSLocalizedString(@"Broken Aliases", nil)]];
	
	_tabView.items = tabItems;
}

#pragma mark - TabViewDelegate

- (void)tabView:(TabView *)tabView didSelectItem:(TabItem *)item
{
	if ([item.title isEqualToString:NSLocalizedString(@"Empty Items", nil)]) {
		[self selectSourceType:SourceTypeEmptyItems];
	} else if ([item.title isEqualToString:NSLocalizedString(@"Broken Aliases", nil)]) {
		[self selectSourceType:SourceTypeBrokenAliases];
	} else {
		[self selectSourceType:SourceTypeDuplicates];
	}
}

- (void)tabView:(id)tabView didSelectMenuItem:(NSMenuItem *)menuItem fromItem:(TabItem *)item
{
	if ([menuItem.title isEqualToString:NSLocalizedString(@"File Duplicates", nil)]) {
		[self selectDuplicateType:DuplicateTypeFiles];
	} else if ([menuItem.title isEqualToString:NSLocalizedString(@"Image Duplicates", nil)]) {
		[self selectDuplicateType:DuplicateTypeImages];
	} else if ([menuItem.title isEqualToString:NSLocalizedString(@"Audio File Duplicates", nil)]) {
		[self selectDuplicateType:DuplicateTypeAudioFiles];
	} else {// "All Duplicates"
		[self selectDuplicateType:DuplicateTypeAll];
	}
}

#pragma mark - Update Content

- (void)updateContent
{
	if ([OptionItem useAutomaticComparaison] && showSummaryView) {
		[self reloadSummaryView];
	} else {
		
		if (currentGroup) {
			NSUInteger count = 0;
			for (FileItem * item in [currentGroup mutableSetValueForKey:@"items"]) {
				if (!item.isDeleted) count++;
			}
			
			if (count <= 1) {// If the group is empty (under two items)...
				/* ...quit the group */
				gridView.headerView = nil;
				currentGroup = nil;
			} else {// Else...
				/* ...reload the title of the header */
				NSString * itemsString = NSLocalizedString(@"%li items", nil);
				backHeaderView.title = [NSString stringWithFormat:itemsString, count];
				gridView.headerView = backHeaderView;
			}
		}
		
		[gridView reloadData];
		[self gridViewSelectionDidChange:gridView];
	}
}

- (void)reloadData
{
	[self reloadTabs];
	[self selectDuplicateType:selectedDuplicateType];
	
	[self updateContent];
}

#pragma mark - Summary View

- (void)reloadSummaryView
{
	if ([OptionItem useAutomaticComparaison] && showSummaryView) {// Summary View is visible
		_summaryCenteredView.verticallyCentered = YES;
		_summaryCenteredView.offsetEdge = RectEdgeMake(48., 0., 60., 0.);
		
		_summaryResultsView.numberOfDuplicatesLabel.fontHeight = 18.;
		_summaryResultsView.totalSizeLabel.fontHeight = 18.;
		
		if (selectedSourceType == SourceTypeDuplicates) {
			/* Show the number of duplicates */
			_summaryResultsView.numberOfDuplicatesLabel.title = [NSString stringWithFormat:@"%ld %@", [self numberOfItemsForDuplicateType:selectedDuplicateType], NSLocalizedString(@"Duplicates", nil)];
			
			/* Show the total size of all duplicates */
			_summaryResultsView.totalSizeLabel.title = [NSString localizedStringForFileSize:[self sizeOfDuplicatesForDuplicateType:selectedDuplicateType]];
			
		} else if (selectedSourceType == SourceTypeEmptyItems){
			_summaryResultsView.numberOfDuplicatesLabel.title = @"";// Show "{dd} Empty Items" to the bottom label to avoid the blank
			_summaryResultsView.totalSizeLabel.title = [NSString stringWithFormat:@"%ld %@", emptyItems.count, NSLocalizedString(@"Empty Items", nil)];
		} else if (selectedSourceType == SourceTypeBrokenAliases) {
			_summaryResultsView.numberOfDuplicatesLabel.title = @"";// Show "{dd} Broken Aliases" to the bottom label to avoid the blank
			_summaryResultsView.totalSizeLabel.title = [NSString stringWithFormat:@"%ld %@", brokenAliases.count, NSLocalizedString(@"Broken Aliases", nil)];
		}
		[_summaryResultsView setHidden:NO];
	} else {
		[_summaryResultsView setHidden:YES];
	}
}

- (IBAction)dismissSummaryResultsView:(id)sender
{
	showSummaryView = NO;
	[_summaryResultsView setHidden:YES];
	
	[gridView reloadData];
}

#pragma mark - //////

- (IBAction)moveToAction:(id)sender// => used?
{
	NSOpenPanel * openPanel = [NSOpenPanel openPanel];
	[openPanel setCanChooseFiles:NO];
	[openPanel setCanChooseDirectories:YES];
	[openPanel setCanCreateDirectories:YES];
	[openPanel setPrompt:NSLocalizedString(@"Move", nil)];
	[openPanel beginSheetModalForWindow:self.view.window
					  completionHandler:^(NSInteger result) {
						  if (result == NSFileHandlingPanelOKButton) {
							  NSMutableArray * itemsToMove = [[NSMutableArray alloc] initWithCapacity:self.items.count];
							  for (FileItem * item in self.items) {
								  if ([item.selected boolValue]) {
									  [itemsToMove addObject:item];
								  }
							  }
							  
							  NSString * path = [[openPanel URL] path];
							  
							  NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
							  BOOL keepHierarchy = [userDefaults boolForKey:@"keepHierarchy"];
							  
							  NSArray * movedItems;
							  BOOL success = [self moveItems:itemsToMove toFolder:path keepHierarchy:keepHierarchy movedItems:&movedItems];// @TODO: Add a button to the openPanel for "keepHierarchy"
							  
							  /* Delete items from context */
							  for (FileItem * item in movedItems)
								  [item.managedObjectContext deleteObject:item];
							  
							  if (!success) NSLog(@"moving items fails!");// @TODO: show an alert on fails
							  
							  [self updateContent];
						  }
					  }];
}

- (void)moveTo:(id)sender// @TODO: used???
{
	NSMenuItem * menuItem = (NSMenuItem *)sender;
	NSInteger index = [[menuItem menu] indexOfItem:menuItem];
	
	NSDebugLog(@"moveTo: (index = %i)", index);
	
	if (index == 0) {// Trash
		
		NSMutableArray * itemsToDelete = [[NSMutableArray alloc] initWithCapacity:self.items.count];
		for (FileItem * item in self.items) {
			if ([item.selected boolValue]) {
				[itemsToDelete addObject:item];
			}
		}
		
		[self moveItemsToTrash:itemsToDelete];
		
	} else if (index == 2) {// Browse... (index 1 is the separator)
		
		NSOpenPanel * openPanel = [NSOpenPanel openPanel];
		[openPanel setCanChooseFiles:NO];
		[openPanel setCanChooseDirectories:YES];
		[openPanel setCanCreateDirectories:YES];
		[openPanel setPrompt:NSLocalizedString(@"Move", nil)];
		
		[openPanel setAccessoryView:keepHierarchyCheckbox];
		
		[openPanel beginSheetModalForWindow:[self.view window]
						  completionHandler:^(NSInteger result) {
							  if (result == NSFileHandlingPanelOKButton) {
								  NSMutableArray * itemsToMove = [[NSMutableArray alloc] initWithCapacity:self.items.count];
								  for (FileItem * item in self.items) {
									  if ([item.selected boolValue]) {
										  [itemsToMove addObject:item];
									  }
								  }
								  
								  NSString * path = [[openPanel URL] path];
								  
								  NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
								  [self moveItems:itemsToMove toFolder:path keepHierarchy:[userDefaults boolForKey:@"keepHierarchy"] movedItems:NULL];
								  
								  for (FileItem * item in itemsToMove) {
									  item.selected = [NSNumber numberWithBool:NO];
								  }
								  
							  }
						  }];
	}
}

- (IBAction)moveToTrash:(id)sender
{
	NSManagedObject * group = nil;
	NSMutableArray * itemsToDelete = [[NSMutableArray alloc] initWithCapacity:10];
	for (FileItem * item in self.items) {
		if ([item.selected boolValue]) {
			[itemsToDelete addObject:item];
			group = [item valueForKey:@"group"];
		}
	}
	
	[group setValue:nil forKey:@"originalItems"];
	[self originalItemForGroup:group];
	
	[self moveItemsToTrash:itemsToDelete];
}

- (void)moveItems:(NSArray *)items toPath:(NSString *)path
{
	NSMutableArray * itemsToMove = [[NSMutableArray alloc] initWithCapacity:items.count];
	for (FileItem * item in items) {
		
		// @TODO: if destination file exist, ask to skip, replace or keep both
		
		NSString * newPath = [NSString stringWithFormat:@"%@/%@", path, [item.path lastPathComponent]];
		
		NSError * error = nil;
		BOOL succeed = [[NSFileManager defaultManager] moveItemAtPath:item.path toPath:newPath error:&error];
		
		if (succeed) {
			item.path = newPath;
		} else {
			[itemsToMove addObject:item];
			NSDebugLog(@"moveItemAtPath failed (%@ - %i) for item at path : %@", [error localizedDescription], [error code], item.path);
		}
	}
	
	[self updateContent];
}

- (BOOL)moveItems:(NSArray *)items toFolder:(NSString *)folder keepHierarchy:(BOOL)keepHierarchy movedItems:(NSArray **)movedItems
{
	NSInteger count = 0;
	if (keepHierarchy) {
		
		NSMutableArray * paths = [[NSMutableArray alloc] initWithCapacity:items.count];
		for (FileItem * item in items) { [paths addObject:item.path]; }
		NSString * rootPath = [self rootPathForPaths:paths];
		
		NSMutableArray * mutableMovedItems = [NSMutableArray arrayWithCapacity:items.count];
		for (FileItem * item in items) {
			
			NSString * newPath = [item.path stringByReplacingOccurrencesOfString:rootPath withString:folder];
			
			NSString * folderPath = [newPath stringByDeletingLastPathComponent];
			
			NSError * error = nil;
			/* Try moving */
			BOOL succeed = [[NSFileManager defaultManager] moveItemAtPath:item.path toPath:newPath error:&error];
			if (!succeed) {/* If it fails... */
				
				NSError * error = nil;
				/* ...Create subfolders... */
				BOOL succeed = [[NSFileManager defaultManager] createDirectoryAtPath:folderPath withIntermediateDirectories:YES attributes:nil error:&error];
				if (!succeed) {
					NSDebugLog(@"error: %@", [error localizedDescription]);
					continue;
				}
				
				/* ...And retry moving operation */
				succeed = [[NSFileManager defaultManager] moveItemAtPath:item.path toPath:newPath error:&error];
				if (!succeed) {/* If it fails again, catch error properly */
					NSDebugLog(@"error: %@", [error localizedDescription]);// @TODO: catch error properly
					continue;
				}
			}
			
			[mutableMovedItems addObject:item];
			
			item.path = newPath;
		}
		
		if (movedItems)
			*movedItems = (NSArray *)mutableMovedItems;
		
		count = mutableMovedItems.count;
		
		
	} else {
		NSMutableArray * mutableMovedItems = [NSMutableArray arrayWithCapacity:items.count];
		NSMutableArray * itemsToMove = [[NSMutableArray alloc] initWithCapacity:items.count];
		for (FileItem * item in items) {
			
			// @TODO: if destination file exist, ask to skip, replace or keep both
			
			NSString * newPath = [NSString stringWithFormat:@"%@/%@", folder, [item.path lastPathComponent]];
			
			NSError * error = nil;
			BOOL succeed = [[NSFileManager defaultManager] moveItemAtPath:item.path toPath:newPath error:&error];
			
			if (succeed) {
				[mutableMovedItems addObject:item];
				item.path = newPath;
			} else {
				[itemsToMove addObject:item];
				NSDebugLog(@"moveItemAtPath failed (%@ - %i) for item at path : %@", [error localizedDescription], [error code], item.path);
			}
		}
		
		if (movedItems)
			*movedItems = (NSArray *)mutableMovedItems;
		
		count = mutableMovedItems.count;
		
	}
	
	return (items.count != count);
}

- (NSString *)rootPathForPaths:(NSArray *)paths
{
	if (paths.count == 0) return nil;
	
	NSMutableArray * rootPathComponents = [[[(NSString *)[paths objectAtIndex:0] stringByDeletingLastPathComponent] pathComponents] mutableCopy];
	for (NSString * path in paths) {
		
		NSArray * pathComponents = [path pathComponents];
		NSMutableArray * _rootPathComponents = [[NSMutableArray alloc] initWithCapacity:pathComponents.count];
		
		for (int i = 0; i < MIN(pathComponents.count, rootPathComponents.count); i++) {
			NSString * folder = [pathComponents objectAtIndex:i];
			if ([folder isEqualToString:[rootPathComponents objectAtIndex:i]]) {
				[_rootPathComponents addObject:folder];
			} else {
				break;
			}
		}
		[rootPathComponents removeAllObjects];
		[rootPathComponents addObjectsFromArray:_rootPathComponents];
	}
	
	if (rootPathComponents.count == 1) {
		return [rootPathComponents componentsJoinedByString:@"/"];
	} else {
		return [(NSString *)[rootPathComponents componentsJoinedByString:@"/"] stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:@""];
	}
}

- (BOOL)moveItemToTrash:(FileItem *)item
{
	return [self moveItemsToTrash:[NSArray arrayWithObject:item]];
}

- (BOOL)moveItemsToTrash:(NSArray *)items movedItems:(NSArray **)movedItems
{
	NSFileManager * fileManager = [[NSFileManager alloc] init];
	NSMutableArray * _movedItems = [NSMutableArray arrayWithCapacity:items.count];
	
	if ([SandboxHelper sandboxActived]) {
		BOOL started = [SandboxHelper startAccessingSecurityScopedSources];
		if (!started) NSLog(@"startAccessingSecurityScopedSources failed");
	}
	
	BOOL success = YES;
	for (FileItem * item in items) {
		
		BOOL moved = NO;
		if ([fileManager respondsToSelector:@selector(trashItemAtURL:resultingItemURL:error:)]) {/* Since 10.8, use -[NSFileManager trashItemAtURL:resultingItemURL:error:] */
			moved = (BOOL)[fileManager trashItemAtURL:[NSURL fileURLWithPath:item.path] resultingItemURL:nil error:nil];
		} else {
			const char * sourcePath = item.path.UTF8String;
			char * targetPath = NULL;
			OSStatus error = FSPathMoveObjectToTrashSync(sourcePath, &targetPath, kFSFileOperationDefaultOptions);
			moved = (targetPath != NULL);
			
			if (!moved) NSLog(@"move to trash fails for %@ (%d)", item.path, error);
		}
		if (moved) {
			[_movedItems addObject:item];
		}
		
		success &= moved;
	}
	
	if ([SandboxHelper sandboxActived])
		[SandboxHelper stopAccessingSecurityScopedSources];
	
	if (movedItems) {
		*movedItems = _movedItems;
	}
	
	
	return success;
}

- (BOOL)moveItemsToTrash:(NSArray *)array
{
	BOOL completeSuccess = YES;
	
	NSFileManager * fileManager = [[NSFileManager alloc] init];
	NSMutableArray * itemsToDelete = [[NSMutableArray alloc] initWithCapacity:array.count];
	for (FileItem * item in array) {
		
		BOOL success = NO;
		if ([fileManager respondsToSelector:@selector(trashItemAtURL:resultingItemURL:error:)]) {/* Since 10.8, use -[NSFileManager trashItemAtURL:resultingItemURL:error:] */
			success = (BOOL)[fileManager trashItemAtURL:[NSURL fileURLWithPath:item.path] resultingItemURL:nil error:nil];
		} else {
			const char * sourcePath = [item.path cStringUsingEncoding:NSUTF8StringEncoding];
			char * targetPath = NULL;
			/*OSStatus error = */FSPathMoveObjectToTrashSync(sourcePath, &targetPath, kFSFileOperationDefaultOptions);
			success = (targetPath != NULL);
		}
		if (success) {
			
			NSArray * duplicatesToDeleteCopy = [duplicatesToDelete copy];
			for (GridItem * gridItem in duplicatesToDeleteCopy) {
				if ([((FileItem *)gridItem.managedObject).path isEqualToString:item.path]) {
					[duplicatesToDelete removeObject:gridItem];
				}
			}
			
			NSArray * emptyItemsToDeleteCopy = [emptyItemsToDelete copy];
			for (GridItem * gridItem in emptyItemsToDeleteCopy) {
				if ([((FileItem *)gridItem.managedObject).path isEqualToString:item.path]) {
					[emptyItemsToDelete removeObject:gridItem];
				}
			}
			
			NSArray * brokenAliasesToDeleteCopy = [brokenAliasesToDelete copy];
			for (GridItem * gridItem in brokenAliasesToDeleteCopy) {
				if ([((FileItem *)gridItem.managedObject).path isEqualToString:item.path]) {
					[brokenAliasesToDelete removeObject:gridItem];
				}
			}
			
			NSArray * itemsToReplaceCopy = [itemsToReplace copy];
			for (GridItem * gridItem in itemsToReplaceCopy) {
				if ([((FileItem *)gridItem.managedObject).path isEqualToString:item.path]) {
					[itemsToReplace removeObject:gridItem];
				}
			}
			
			[item.managedObjectContext deleteObject:item];
			NSError * error = nil;// @TODO: save the context juste one time
			[item.managedObjectContext save:&error];// Force save from the context of the group
			if (error) {
				NSDebugLog(@"save error %@", [error localizedDescription]);
			}
			
		} else {
			[itemsToDelete addObject:item];
		}
		
		completeSuccess &= success;
	}
	
	if (itemsToDelete.count > 0) {
		NSAlert * alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Some items can't be moved to trash (the file system may not manage trash system). Would you want to delete the file?\nThis operation can't be undone.", nil)
										  defaultButton:NSLocalizedString(@"Cancel", nil)
										alternateButton:nil
											otherButton:NSLocalizedString(@"Delete", nil)
							  informativeTextWithFormat:@""];
		
		if ([alert runModal] == NSAlertOtherReturn) {
			// Move to trash failed so try to delete files
			for (FileItem * item in itemsToDelete) {
				
				NSError * error = nil;
				BOOL success = [[NSFileManager defaultManager] removeItemAtPath:item.path error:&error];
				
				if (!success && error) {
					NSLog(@"removeItemAtPath:error: %@", [error localizedDescription]);
				} else {
					
					NSArray * duplicatesToDeleteCopy = [duplicatesToDelete copy];
					for (GridItem * gridItem in duplicatesToDeleteCopy) {
						if ([((FileItem *)gridItem.managedObject).path isEqualToString:item.path]) {
							[duplicatesToDelete removeObject:gridItem];
						}
					}
					
					NSArray * emptyItemsToDeleteCopy = [emptyItemsToDelete copy];
					for (GridItem * gridItem in emptyItemsToDeleteCopy) {
						if ([((FileItem *)gridItem.managedObject).path isEqualToString:item.path]) {
							[emptyItemsToDelete removeObject:gridItem];
						}
					}
					
					NSArray * brokenAliasesToDeleteCopy = [brokenAliasesToDelete copy];
					for (GridItem * gridItem in brokenAliasesToDeleteCopy) {
						if ([((FileItem *)gridItem.managedObject).path isEqualToString:item.path]) {
							[brokenAliasesToDelete removeObject:gridItem];
						}
					}
					
					NSArray * itemsToReplaceCopy = [itemsToReplace copy];
					for (GridItem * gridItem in itemsToReplaceCopy) {
						if ([((FileItem *)gridItem.managedObject).path isEqualToString:item.path]) {
							[itemsToReplace removeObject:gridItem];
						}
					}
					
					[item.managedObjectContext deleteObject:item];
					NSError * error = nil;
					[item.managedObjectContext save:&error];// Force save from the context of the group
					if (error) {
						NSDebugLog(@"save error: %@", [error localizedDescription]);
					}
				}
			}
		}
	}
	
	
	[self updateContent];
	
	return completeSuccess;
}

- (IBAction)selectAll:(id)sender
{
	[gridView selectAll];
}

- (IBAction)selectDuplicates:(id)sender
{
	if (currentGroup) {
		/*
		 [gridView selectAll];
		 [gridView deselectFirstItem];
		 */
		[gridView selectAllNonOriginalsItems];
	} else {
		[gridView selectAll];
	}
}

- (IBAction)deselectAll:(id)sender
{
	[gridView deselectAll];
}

- (IBAction)deleteSelected:(id)sender
{
	[gridView deleteItems:[gridView selectedItems]];
}

- (BOOL)replaceItemsWithAliasToOriginalItem:(NSArray *)items
{
	return [self replaceItemsWithAliasToOriginalItem:items replacedItems:NULL];
}

- (BOOL)replaceItemsWithAliasToOriginalItem:(NSArray *)items replacedItems:(NSArray **)replacedItems
{
	NSMutableArray * mutableReplaceItems = [NSMutableArray arrayWithCapacity:items.count];
	BOOL success = YES;
	for (FileItem * item in items) {
		
		NSManagedObject * group = nil;
		if ([item isKindOfClass:[ImageItem class]]) {
			group = [item valueForKey:@"imageGroups"];
		} else if ([item isKindOfClass:[AudioItem class]]) {
			group = [item valueForKey:@"audioGroups"];
		} else if ([item isKindOfClass:[FileItem class]]) {
			group = [item valueForKey:@"fileGroups"];
		}
		
		FileItem * originalItem = [self originalItemForGroup:group];
		
		NSString * path = item.path;
		BOOL moved = [self moveItemToTrash:item];
		BOOL replaced = [self createAlias:path
								   toPath:originalItem.path];
		
		if (moved && replaced) {
			[mutableReplaceItems addObject:item];
		}
		
		success &= (moved && replaced);
	}
	
	if (replacedItems)
		*replacedItems = mutableReplaceItems;
	
	return success;
}

- (void)createAliase:(NSString *)path toPath:(NSString *)targetPath
{
	[self createAlias:path toPath:targetPath];
}

- (BOOL)createAlias:(NSString *)path toPath:(NSString *)targetPath// The source is the path of the alias to create, the target is the original file
{
	NSError * error = nil;
	BOOL succeed = [[NSFileManager defaultManager] createSymbolicLinkAtPath:path withDestinationPath:targetPath error:&error];
	
	if (!succeed && error)
		NSDebugLog(@"ERROR: createSymbolicLinkAtPath:%@ withDestinationPath:%@ error: %@ (%d)", path, targetPath, [error localizedDescription], (int)[error code]);
	
	return succeed;
	/*
	 NSUndoManager * undo = [tableView undoManager];
	 [[undo prepareWithInvocationTarget:self] deleteAlias:path];
	 */
}

- (void)deleteAlias:(NSString *)path
{
	NSError * error = nil;
	[[NSFileManager defaultManager] removeItemAtPath:path error:&error];
	
	if (error)
		NSDebugLog(@"removeItemAtPath:error: %@", [error localizedDescription]);
}

- (IBAction)revealInFinder:(id)sender
{
}

/*
 - (IBAction)moveToTrashAllItems:(id)sender
 {
 NSDebugLog(@"moveToTrashAllItems: %lu items", [self allItemsToDeleteCount]);
 
 NSArray * items = [self allItemsToDelete];
 NSMutableArray * fileItems = [[NSMutableArray alloc] initWithCapacity:items.count];
 for (GridItem * item in items) {
 [fileItems addObject:item.managedObject];
 }
 
 [self moveItemsToTrash:fileItems];
 [fileItems release];
 }
 
 - (IBAction)replaceAllItems:(id)sender
 {
 NSDebugLog(@"replaceAllItems: %lu items", [self allItemsToDeleteCount]);
 
 NSMutableArray * fileItems = [[NSMutableArray alloc] initWithCapacity:itemsToReplace.count];
 for (GridItem * item in itemsToReplace) {
 [fileItems addObject:item.managedObject];
 }
 
 [self replaceItemsWithAliasToOriginalItem:fileItems];
 [fileItems release];
 }
 */

- (FileItem *)originalItemForGroup:(NSManagedObject *)group
{
	if ([group valueForKey:@"originalItems"]) {
		return [group valueForKey:@"originalItems"];
	} else {
		
		NSString * key = [[NSUserDefaults standardUserDefaults] stringForKey:@"OriginalSortedKey"];
		BOOL ascending = !([key isEqualToString:@"lastModificationDate"]);// Descending (NO) if "lastModificationDate", Ascending (YES) if "creationDate" or nil
		
		NSSortDescriptor * sortDescriptor = [[NSSortDescriptor alloc] initWithKey:((!key)? @"creationDate": key)
																		ascending:ascending];
		NSArray * descriptors = [[NSArray alloc] initWithObjects:sortDescriptor, [NSSortDescriptor sortDescriptorWithKey:@"path" ascending:YES], nil];
		NSArray * sortedItems = [[group mutableSetValueForKey:@"items"] sortedArrayUsingDescriptors:descriptors];
		
		if (sortedItems.count > 0) {
			
			/* from all items in "sortedItems", return the first item that is not into the "duplicatesToDelete" array */
			int index = 0;
			for (FileItem * fileItem in sortedItems) {
				BOOL contains = NO;
				for (GridItem * item in duplicatesToDelete) {
					if ([fileItem.objectID isEqual:item.managedObject.objectID]) {
						contains = YES;
						break;
					}
				}
				
				if (!contains)
					return [sortedItems objectAtIndex:index];
				
				index++;
			}
		}
	}
	
	return nil;
}

- (IBAction)setAsOriginalAction:(id)sender
{
	NSArray * selectedItems = [gridView selectedItems];
	if (selectedItems.count == 1) {// Only one item can be selected
		
		GridItem * gridItem = [selectedItems objectAtIndex:0];
		FileItem * item = (FileItem *)gridItem.managedObject;
		
		for (GridItem * item in [gridView gridItems]) {
			if (item.isOriginal) {
				item.isOriginal = NO;
				break;
			}
		}
		
		[self setOriginalItem:item
					 forGroup:gridItem.group];
		
		gridItem.isOriginal = YES;
		
	} else {
		NSDebugLog(@"You must selected only one item.");
	}
}

- (void)setOriginalItem:(FileItem *)item forGroup:(NSManagedObject * )group
{
	if (group == nil) {
		if ([item isKindOfClass:[ImageItem class]]) {
			group = [item valueForKey:@"imageGroups"];
		} else if ([item isKindOfClass:[AudioItem class]]) {
			group = [item valueForKey:@"audioGroups"];
		} else if ([item isKindOfClass:[FileItem class]]) {
			group = [item valueForKey:@"fileGroups"];
		}
	}
	
	NSPersistentStoreCoordinator * coordinator = [[NSApp delegate] persistentStoreCoordinator];
	NSAssert(coordinator != nil, @"coordinator == nil");
	
	NSManagedObjectContext * context = [[NSManagedObjectContext alloc] init];
	[context setPersistentStoreCoordinator:coordinator];
	[context setUndoManager:nil];
	
	NSManagedObject * newGroup = [context objectWithID:group.objectID];
	NSManagedObject * newItem = [context objectWithID:item.objectID];
	
	[newGroup setValue:newItem forKey:@"originalItems"];
	
	NSError * error = nil;
	[context save:&error];// Force save the change
	if (error) {
		NSDebugLog(@"save error: %@", [error localizedDescription]);
	}
}

#pragma mark - Actions

- (IBAction)doneAction:(id)sender
{
	[(ComparatorAppDelegate *)[NSApp delegate] backToMainView:sender];
}

- (IBAction)gridBackButtonAction:(id)sender
{
	gridView.headerView = nil;
	
	[gridView deselectAll];
	
	currentGroup = nil;
	[gridView reloadData];
	
	NSMutableArray * options = [[NSMutableArray alloc] init];
	for (OptionItem * option in [OptionItem checkedItems]) {
		[options addObject:[option localizedName]];
	}
	NSString * optionsString = [options componentsJoinedByString:@", "];
	
	NSMutableDictionary * allItemsPanelAttributes = [[NSMutableDictionary alloc] init];
	[allItemsPanelAttributes setObject:optionsString forKey:@"Options"];
	
	itemsPanelAttributes = allItemsPanelAttributes;
	
	panelRows = [[NSArray alloc] initWithObjects:[NSString stringWithFormat:@"Options=%@", optionsString], nil];
	
	[previewPanelView setHidden:YES];
	
	[self reloadRightPanel];
}

#pragma mark "Move All Duplicates to Trash..."

- (IBAction)moveDuplicateToTrashAction:(id)sender
{
	NSAlert * alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Would you want to move all duplicates to trash?", nil)
									  defaultButton:NSLocalizedString(@"Move to Trash", nil)
									alternateButton:NSLocalizedString(@"Cancel", nil)
										otherButton:nil
						  informativeTextWithFormat:NSLocalizedString(@"This action cannot be undone.", nil)];
	
	[alert beginSheetModalForWindow:self.view.window
					  modalDelegate:self
					 didEndSelector:@selector(moveDuplicateToTrashAlertDidEnd:returnCode:contextInfo:)
						contextInfo:NULL];
}

- (void)moveDuplicateToTrashAlertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	if (returnCode == NSAlertDefaultReturn) {// "Move to Trash"
		// @TODO: test it
		
		NSArray * duplicates = [self duplicatesForDuplicateType:selectedDuplicateType];
		NSArray * movedItems = nil;
		BOOL success = [self moveItemsToTrash:duplicates movedItems:&movedItems];
		// @TODO: show an error is it's fail
		if (!success) {
			NSLog(@"%ld items couldn't be moved!", (duplicates.count - movedItems.count));
		}
		
		[self deleteItems:movedItems];
		
		[self updateContent];
		
	} else {// Cancel
		
	}
}

#pragma mark "Move All Duplicates..."

- (IBAction)moveDuplicatesAction:(id)sender
{
	NSOpenPanel * openPanel = [NSOpenPanel openPanel];
	openPanel.canChooseFiles = NO;
	openPanel.canChooseDirectories = YES;
	openPanel.canCreateDirectories = YES;
	openPanel.allowsMultipleSelection = NO;
	
	openPanel.title = NSLocalizedString(@"Choose a destination for selected items", nil);
	openPanel.prompt = NSLocalizedString(@"Move", nil);
	openPanel.accessoryView = movedPanelAccessoryView;
	
	__unsafe_unretained NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
	BOOL keepHierarchy = YES;// Active the "keep hierarchy" options by default
	if ([userDefaults objectForKey:@"keepHierarchy"])// If we have an entry into the user defaults, use it
		keepHierarchy = [userDefaults boolForKey:@"keepHierarchy"];
	keepHierarchyCheckbox.state = (keepHierarchy)? NSOnState : NSOffState;
	
	[openPanel beginSheetModalForWindow:self.view.window
					  completionHandler:^(NSInteger result) {
						  if (result == NSFileHandlingPanelOKButton) {
							  
							  // @TODO: test it
							  NSArray * duplicates = [self duplicatesForDuplicateType:selectedDuplicateType];
							  
							  
							  BOOL keepHierarchy = (keepHierarchyCheckbox.state == NSOnState);
							  [userDefaults setBool:keepHierarchy forKey:@"keepHierarchy"];
							  
							  NSArray * movedItems;
							  BOOL success = [self moveItems:duplicates toFolder:openPanel.URL.path keepHierarchy:keepHierarchy movedItems:&movedItems];
							  
							  /* Delete items from context */
							  [self deleteItems:movedItems];
							  
							  if (!success) NSLog(@"moving items fails!");// @TODO: show an alert on fails
							  
							  [self updateContent];
						  }
					  }];
}

- (IBAction)duplicateTypeDidChangeAction:(id)sender// => used???
{
	NSMenuItem * item = sender;
	[self selectDuplicateType:([item.menu indexOfItem:item])];
	
	[self updateContent];
}

/* The action from the bottom button to show the move menu */
- (IBAction)moveAction:(id)sender
{
	NSMenu * menu = [[NSMenu alloc] initWithTitle:@"results-move-menu"];
	[menu addItemWithTitle:NSLocalizedString(@"Move Duplicates to Trash...", nil) target:self action:@selector(moveDuplicateToTrashAction:)];
	[menu addItemWithTitle:NSLocalizedString(@"Move Duplicates...", nil) target:self action:@selector(moveDuplicatesAction:)];
	
	NSPoint location = [self.view convertPoint:NSZeroPoint fromView:(NSButton *)sender];
	location.y -= ((NSButton *)sender).frame.size.height + 3.;
	[menu popUpMenuPositioningItem:nil
						atLocation:location
							inView:self.view];
}

#pragma mark "Replace All Duplicates..."

- (IBAction)replaceAction:(id)sender
{
	NSAlert * alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Would you want to replace all duplicates with an alias to the original file?", nil)
									  defaultButton:NSLocalizedString(@"Replace", nil)
									alternateButton:NSLocalizedString(@"Cancel", nil)
										otherButton:nil
						  informativeTextWithFormat:NSLocalizedString(@"All duplicates will be moved to Trash.\nThis action cannot be undone.", nil)];
	
	[alert beginSheetModalForWindow:self.view.window
					  modalDelegate:self
					 didEndSelector:@selector(replaceAlertDidEnd:returnCode:contextInfo:)
						contextInfo:NULL];
}

- (void)replaceAlertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	if (returnCode == NSAlertDefaultReturn) {// Replace
		// @TODO: test it
		NSArray * duplicates = [self duplicatesForDuplicateType:selectedDuplicateType];
		
		NSArray * replacedItems;
		BOOL success = [self replaceItemsWithAliasToOriginalItem:duplicates replacedItems:&replacedItems];
		
		[self deleteItems:replacedItems];
		if (!success) NSLog(@"Replacing items fails!");
		
	} else {// Cancel
		
	}
}

#pragma mark "Move to Trash..."
- (IBAction)moveToTrashAction:(id)sender
{
	BOOL showAlert = NO;
	NSString * title = nil;
	if (selectedSourceType == SourceTypeEmptyItems) {
		title = NSLocalizedString(@"Would you want to move all empty items to trash?", nil);
		showAlert = (emptyItems.count > 0);
	} else {
		title = NSLocalizedString(@"Would you want to move all broken aliases to trash?", nil);
		showAlert = (brokenAliases.count > 0);
	}
	
	if (showAlert) {
		NSAlert * alert = [NSAlert alertWithMessageText:title
										  defaultButton:NSLocalizedString(@"Move to Trash", nil)
										alternateButton:NSLocalizedString(@"Cancel", nil)
											otherButton:nil
							  informativeTextWithFormat:NSLocalizedString(@"This action cannot be undone.", nil)];
		
		[alert beginSheetModalForWindow:self.view.window
						  modalDelegate:self
						 didEndSelector:@selector(moveToTrashAlertDidEnd:returnCode:contextInfo:)
							contextInfo:NULL];
	}
}

- (void)moveToTrashAlertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	if (returnCode == NSAlertDefaultReturn) {// "Move to Trash"
		
		if (selectedSourceType == SourceTypeEmptyItems) {
			/* Move all items (from "emptyItems") to trash */
			NSArray * movedItems = nil;
			BOOL success = [self moveItemsToTrash:emptyItems movedItems:&movedItems];
			if (!success) NSLog(@"Move empty items to trash fails!");
			
			[emptyItems removeObjectsInArray:movedItems];
			
			/* Delete items from context */
			[self deleteItems:movedItems];
			
		} else {
			/* Move all items (from "brokenAliases") to trash */
			NSArray * movedItems = nil;
			BOOL success = [self moveItemsToTrash:brokenAliases movedItems:&movedItems];
			if (!success) NSLog(@"Move brokens aliases to trash fails!");
			
			[brokenAliases removeObjectsInArray:movedItems];
			
			/* Delete items from context */
			[self deleteItems:movedItems];
		}
		
		[self updateContent];
		
	} else {// "Cancel"
		
	}
}

#pragma mark "Delete..."
- (IBAction)deleteAction:(id)sender
{
	if (brokenAliases.count > 0) {
		NSAlert * alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Would you want to delete all broken aliases?", nil)
										  defaultButton:NSLocalizedString(@"Delete", nil)
										alternateButton:NSLocalizedString(@"Cancel", nil)
											otherButton:nil
							  informativeTextWithFormat:NSLocalizedString(@"This action cannot be undone.", nil)];
		
		[alert beginSheetModalForWindow:self.view.window
						  modalDelegate:self
						 didEndSelector:@selector(deleteAlertDidEnd:returnCode:contextInfo:)
							contextInfo:NULL];
	}
}

- (void)deleteAlertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	if (returnCode == NSAlertDefaultReturn) {// "Move to Trash"
		
		if ([SandboxHelper sandboxActived]) {
			BOOL started = [SandboxHelper startAccessingSecurityScopedSources];
			if (!started) NSLog(@"startAccessingSecurityScopedSources failed");
		}
		
		NSMutableArray * removedItems = [NSMutableArray arrayWithCapacity:3];
		/* Delete items from context */
		for (FileItem * item in brokenAliases) {
			
			BOOL success = [[NSFileManager defaultManager] removeItemAtPath:item.path error:NULL];
			
			if (success) {
				[removedItems addObject:item];
			}
		}
		
		[brokenAliases removeObjectsInArray:removedItems];
		
		/* Delete items from context */
		[self deleteItems:removedItems];
		
		if ([SandboxHelper sandboxActived])
			[SandboxHelper stopAccessingSecurityScopedSources];
		
		[self updateContent];
		
	} else {// "Cancel"
		
	}
}

- (IBAction)showHelpAction:(id)sender
{
	NSString * helpBookName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleHelpBookName"];
	[[NSHelpManager sharedHelpManager] openHelpAnchor:@"interface_results" inBook:helpBookName];
}

#pragma mark - Sources Management

- (void)selectSourceType:(SourceType)type
{
	if (type != selectedSourceType) {
		
		selectedSourceType = type;
		
		/* Show the "Move..." and "Replace..." buttons when "Duplicates" tab is selected */
		[moveButton setHidden:(type != SourceTypeDuplicates)];
		[replaceButton setHidden:(type != SourceTypeDuplicates)];
		
		/* Show the "Move to Trash..." button on "Empty Items" */
		[moveToTrashButton setHidden:(type != SourceTypeEmptyItems)];
		
		/* Show the "Delete..." button on "Broken Aliases"*/
		[deleteButton setHidden:(type != SourceTypeBrokenAliases)];
		
		/* Enable/disable the "Move to Trash..." button */
		if (selectedSourceType == SourceTypeEmptyItems) {
			[moveToTrashButton setEnabled:(emptyItems.count > 0)];
		} else if (selectedSourceType == SourceTypeBrokenAliases) {
			/* Enable/disable the "Delete..." button */
			[deleteButton setEnabled:(brokenAliases.count > 0)];
		}
	}
	
	[gridView.headerView setHidden:YES];
	[gridView deselectAll];
	
	currentGroup = nil;
	[self updateContent];
}

- (void)selectDuplicateType:(DuplicateType)type
{
	if (type != selectedDuplicateType) {
		currentGroup = nil;
		[gridView.headerView setHidden:YES];
		[gridView deselectAll];
		
		selectedDuplicateType = type;
		
		// @TODO: disable/enable bottom buttons depending of the number of duplicates shown
		
		[self updateContent];
	}
}

#pragma mark - Compare Selected Items

- (IBAction)compareSelectedItems:(id)sender
{
	NSArray * selectedItems = [gridView selectedItems];
	if (selectedItems.count == 2) {
		GridItem * item1 = [selectedItems objectAtIndex:0];
		GridItem * item2 = [selectedItems objectAtIndex:1];
		if (!item1.isGroup && !item2.isGroup) {
			
			FileItem * fileItem1 = (FileItem *)item1.managedObject;
			FileItem * fileItem2 = (FileItem *)item2.managedObject;
			
			[compareWindow compareItem:fileItem1 withItem:fileItem2];
			
			[NSApp beginSheet:compareWindow
			   modalForWindow:[NSApp mainWindow]
				modalDelegate:self
			   didEndSelector:@selector(didEndSheet:returnCode:contextInfo:)
				  contextInfo:NULL];
		} else {
			NSDebugLog(@"Must select items, not groups");
		}
	} else {
		NSDebugLog(@"Must select exactly 2 items");
	}
}

- (void)didEndSheet:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    [sheet orderOut:self];
}

#pragma mark - Selected Items Actions

- (IBAction)moveSelectedItemsAction:(id)sender
{
	NSOpenPanel * openPanel = [NSOpenPanel openPanel];
	openPanel.canChooseFiles = NO;
	openPanel.canChooseDirectories = YES;
	openPanel.canCreateDirectories = YES;
	openPanel.allowsMultipleSelection = NO;
	
	openPanel.title = NSLocalizedString(@"Choose a destination for selected items", nil);
	openPanel.prompt = NSLocalizedString(@"Move", nil);
	openPanel.accessoryView = movedPanelAccessoryView;
	
	__unsafe_unretained NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
	BOOL keepHierarchy = YES;// Active the "keep hierarchy" options by default
	if ([userDefaults objectForKey:@"keepHierarchy"])// If we have an entry into the user defaults, use it
		keepHierarchy = [userDefaults boolForKey:@"keepHierarchy"];
	keepHierarchyCheckbox.state = (keepHierarchy)? NSOnState : NSOffState;
	
	[openPanel beginSheetModalForWindow:self.view.window
					  completionHandler:^(NSInteger result) {
						  
						  if (result == NSFileHandlingPanelOKButton) {
							  
							  NSArray * selectedItems = gridView.selectedItems;
							  NSMutableArray * items = [NSMutableArray arrayWithCapacity:selectedItems.count];
							  for (GridItem * item in selectedItems) {
								  
								  if (item.isGroup) {
									  NSManagedObject * group = item.group;
									  NSMutableSet * duplicates = [[group mutableSetValueForKey:@"items"] copy];
									  [duplicates removeObject:[self originalItemForGroup:group]];
									  [items addObjectsFromArray:duplicates.allObjects];
								  } else {
									  [items addObject:(FileItem *)item.managedObject];
								  }
							  }
							  
							  BOOL keepHierarchy = (keepHierarchyCheckbox.state == NSOnState);
							  [userDefaults setBool:keepHierarchy forKey:@"keepHierarchy"];
							  
							  NSArray * movedItems;
							  BOOL success = [self moveItems:items toFolder:openPanel.URL.path keepHierarchy:keepHierarchy movedItems:&movedItems];
							  
							  /* Delete items from Core Data context */
							  [self deleteItems:movedItems];
							  
							  if (!success) NSLog(@"moving items fails!");// @TODO: show an alert on fails
							  
							  [self updateContent];
						  }
					  }];
}

- (IBAction)moveSelectedItemsToTrashAction:(id)sender
{
	NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
	if ([[userDefaults arrayForKey:@"Alerts to Hide"] containsObject:@"Move to Trash Selected Items Alert"]) {
		
		BOOL success = YES;
		NSArray * selectedItems = gridView.selectedItems;
		NSMutableArray * itemsToDelete = [NSMutableArray arrayWithCapacity:selectedItems.count];
		NSMutableArray * items = [NSMutableArray arrayWithCapacity:selectedItems.count];
		for (GridItem * item in selectedItems) {
			
			if (item.isGroup) {
				NSManagedObject * group = item.group;
				NSMutableSet * duplicates = [[group mutableSetValueForKey:@"items"] copy];
				[duplicates removeObject:[self originalItemForGroup:group]];
				
				NSArray * movedItems;
				success &= [self moveItemsToTrash:duplicates.allObjects movedItems:&movedItems];
				
				[itemsToDelete addObjectsFromArray:movedItems];
				
			} else {
				FileItem * fileItem = (FileItem *)item.managedObject;
				[items addObject:fileItem];
			}
		}
		
		if (items.count > 0) {
			NSArray * movedItems;
			success &= [self moveItemsToTrash:items movedItems:&movedItems];
			[itemsToDelete addObjectsFromArray:movedItems];
		}
		
		/* Delete items from Core Data context */
		[self deleteItems:itemsToDelete];
		
		if (!success) NSLog(@"Moving to trash %ld items fails", selectedItems.count);
		
		[self updateContent];
		
	} else {
		NSAlert * alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Would you want to move selected items to trash?", nil)
										  defaultButton:NSLocalizedString(@"Move to Trash", nil)
										alternateButton:NSLocalizedString(@"Cancel", nil)
											otherButton:nil
							  informativeTextWithFormat:NSLocalizedString(@"This action cannot be undone.", nil)];
		alert.showsSuppressionButton = YES;
		
		[alert beginSheetModalForWindow:self.view.window
						  modalDelegate:self
						 didEndSelector:@selector(moveSelectedItemsToTrashAlertDidEnd:returnCode:contextInfo:)
							contextInfo:NULL];
	}
}

- (void)moveSelectedItemsToTrashAlertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	if (returnCode == NSAlertDefaultReturn) {// "Move to Trash"
		
		BOOL success = YES;
		NSArray * selectedItems = gridView.selectedItems;
		NSMutableArray * itemsToDelete = [NSMutableArray arrayWithCapacity:selectedItems.count];
		NSMutableArray * items = [NSMutableArray arrayWithCapacity:selectedItems.count];
		for (GridItem * item in selectedItems) {
			
			if (item.isGroup) {
				NSManagedObject * group = item.group;
				NSMutableSet * duplicates = [[group mutableSetValueForKey:@"items"] copy];
				[duplicates removeObject:[self originalItemForGroup:group]];
				
				NSArray * movedItems;
				success &= [self moveItemsToTrash:duplicates.allObjects movedItems:&movedItems];
				
				[itemsToDelete addObjectsFromArray:movedItems];
				
			} else {
				FileItem * fileItem = (FileItem *)item.managedObject;
				[items addObject:fileItem];
			}
		}
		
		if (items.count > 0) {
			NSArray * movedItems;
			success &= [self moveItemsToTrash:items movedItems:&movedItems];
			[itemsToDelete addObjectsFromArray:movedItems];
		}
		
		/* Delete items from Core Data context */
		[self deleteItems:itemsToDelete];
		
		if (!success) NSLog(@"Moving to trash %ld items fails", selectedItems.count);
		
		if (alert.suppressionButton.state == NSOnState) {
			
			NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
			NSMutableArray * alertsToHide = [[userDefaults arrayForKey:@"Move to Trash Selected Items Alert"] mutableCopy];
			if (!alertsToHide)
				alertsToHide = [[NSMutableArray alloc] initWithCapacity:1];
			
			[alertsToHide addObject:@"Move to Trash Selected Items Alert"];
			[userDefaults setObject:alertsToHide forKey:@"Alerts to Hide"];
		}
		
		[self updateContent];
		
	} else {// Cancel
		
	}
}

- (IBAction)replaceSelectedItemsAction:(id)sender
{
	NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
	if ([[userDefaults arrayForKey:@"Alerts to Hide"] containsObject:@"Replace Selected Items Alert"]) {
		
		NSArray * selectedItems = gridView.selectedItems;
		NSMutableArray * items = [NSMutableArray arrayWithCapacity:selectedItems.count];
		for (GridItem * item in selectedItems) {
			
			if (item.isGroup) {
				NSManagedObject * group = item.group;
				NSMutableSet * duplicates = [[group mutableSetValueForKey:@"items"] copy];
				[duplicates removeObject:[self originalItemForGroup:group]];
				[items addObjectsFromArray:duplicates.allObjects];
			} else {
				[items addObject:(FileItem *)item.managedObject];
			}
		}
		
		BOOL success = [self replaceItemsWithAliasToOriginalItem:items];
		if (!success) NSLog(@"Replacing with alias %ld items fails", selectedItems.count);
		
		[self updateContent];
		
	} else {
		
		NSAlert * alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Would you want to replace selected duplicates with an alias to the original file?", nil)
										  defaultButton:NSLocalizedString(@"Replace", nil)
										alternateButton:NSLocalizedString(@"Cancel", nil)
											otherButton:nil
							  informativeTextWithFormat:NSLocalizedString(@"All duplicates with be moved to Trash.\nThis action cannot be undone.", nil)];
		alert.showsSuppressionButton = YES;
		
		[alert beginSheetModalForWindow:self.view.window
						  modalDelegate:self
						 didEndSelector:@selector(replaceSelectedItemsAlertDidEnd:returnCode:contextInfo:)
							contextInfo:NULL];
	}
}

- (void)replaceSelectedItemsAlertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	if (returnCode == NSAlertDefaultReturn) {// "Replace"
		
		NSArray * selectedItems = gridView.selectedItems;
		NSMutableArray * items = [NSMutableArray arrayWithCapacity:selectedItems.count];
		for (GridItem * item in selectedItems) {
			
			if (item.isGroup) {
				NSManagedObject * group = item.group;
				NSMutableSet * duplicates = [[group mutableSetValueForKey:@"items"] copy];
				[duplicates removeObject:[self originalItemForGroup:group]];
				[items addObjectsFromArray:duplicates.allObjects];
			} else {
				[items addObject:(FileItem *)item.managedObject];
			}
		}
		
		BOOL success = [self replaceItemsWithAliasToOriginalItem:items];
		if (!success) NSLog(@"Replacing with alias %ld items fails", selectedItems.count);
		
		if (alert.suppressionButton.state == NSOnState) {
			
			NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
			NSMutableArray * alertsToHide = [[userDefaults arrayForKey:@"Alerts to Hide"] mutableCopy];
			if (!alertsToHide)
				alertsToHide = [[NSMutableArray alloc] initWithCapacity:1];
			
			[alertsToHide addObject:@"Replace Selected Items Alert"];
			[userDefaults setObject:alertsToHide forKey:@"Alerts to Hide"];
		}
		
		[self updateContent];
		
	} else {// Cancel
		
	}
}

- (IBAction)showInFinderSelectedItemsAction:(id)sender
{
	NSArray * selectedItems = gridView.selectedItems;
	NSMutableArray * URLs = [NSMutableArray arrayWithCapacity:selectedItems.count];
	for (GridItem * item in selectedItems) {
		NSURL * fileURL = [NSURL fileURLWithPath:[(FileItem *)item.managedObject path]];
		if (fileURL) [URLs addObject:fileURL];
	}
	
#if _SANDBOX_SUPPORTED_
	[fileURL startAccessingSecurityScopedResource];
#endif
	
	[[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:URLs];
	
#if _SANDBOX_SUPPORTED_
	[fileURL stopAccessingSecurityScopedResource];
#endif
}

#pragma mark - Right Panel

- (void)refreshPrewiewForPath:(NSString *)path
{
	NSAssert(path, @"%@ path is null", NSStringFromSelector(_cmd));
	
	if ([SandboxHelper sandboxActived]) {
		BOOL started = [SandboxHelper startAccessingSecurityScopedSources];
		if (!started) NSLog(@"startAccessingSecurityScopedSources failed");
	}
	
	dispatch_group_t group = dispatch_group_create();
	dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
	
	NSURL * fileURL = [NSURL fileURLWithPath:path];
	if (fileURL) {
		
		dispatch_group_async(group, queue, ^{
			const void * keys[1] = { (void *)kQLThumbnailOptionIconModeKey };
			const void * values[1] = { (void *)kCFBooleanTrue };
			
			CFDictionaryRef thumbnailAttributes = CFDictionaryCreate(kCFAllocatorDefault, keys, values, 1, NULL, NULL);
			CGImageRef imageRef = QLThumbnailImageCreate(kCFAllocatorDefault, (__bridge CFURLRef)fileURL, CGSizeMake(128., 128.), thumbnailAttributes);
			if (thumbnailAttributes) CFRelease(thumbnailAttributes);
			
			if (imageRef) {
				NSImage * image = [[NSImage alloc] initWithCGImage:imageRef size:NSZeroSize];
				CGImageRelease(imageRef);
				
				previewImageView.image = image;
			} else {
				NSImage * image = [[NSWorkspace sharedWorkspace] iconForFile:fileURL.path];
				image.size = NSMakeSize(128., 128.);
				previewImageView.image = image;
			}
		});
		
		/* Stop Sandbox when group finished */
		dispatch_group_notify(group, queue, ^{
			if ([SandboxHelper sandboxActived]) [SandboxHelper stopAccessingSecurityScopedSources];
		});
	}
}

- (void)refreshRightPanelRows
{
	NSArray * selectedItems = [gridView selectedItems];
	
	NSPersistentStoreCoordinator * coordinator = [[NSApp delegate] persistentStoreCoordinator];
	NSAssert(coordinator != nil, @"coordinator == nil");
	
	NSManagedObjectContext * context = [[NSManagedObjectContext alloc] init];
	[context setPersistentStoreCoordinator:coordinator];
	[context setUndoManager:nil];
	
	/* Get commons value from selected items */
	NSMutableArray * fileItems = [[NSMutableArray alloc] initWithCapacity:selectedItems.count];
	for (GridItem * item in selectedItems) {
		
		if (item.managedObject) {
			[fileItems addObject:[context objectWithID:item.managedObject.objectID]];
			
		} else {
			NSManagedObject * newGroup = [context objectWithID:item.group.objectID];
			NSArray * groups = [[newGroup mutableSetValueForKey:@"items"] allObjects];
			for (NSManagedObject * group in groups) {
				[fileItems addObject:group];
			}
		}
	}
	
	if (fileItems.count > 0) {
		
		if ([SandboxHelper sandboxActived]) {
			BOOL started = [SandboxHelper startAccessingSecurityScopedSources];
			if (!started) NSLog(@"startAccessingSecurityScopedSources failed");
		}
		
		NSDictionary * commonsValues = [FileItem commonsValuesForItems:fileItems];
		
		if ([SandboxHelper sandboxActived]) [SandboxHelper stopAccessingSecurityScopedSources];
		
		
		NSMutableDictionary * allItemsPanelAttributes = [[NSMutableDictionary alloc] initWithDictionary:commonsValues];
		
		NSString * type = [[NSWorkspace sharedWorkspace] localizedDescriptionForType:[commonsValues objectForKey:@"type"]];
		if (type) {
			[allItemsPanelAttributes setObject:type forKey:@"type"];
		}
		
		NSMutableArray * paths = [[NSMutableArray alloc] initWithCapacity:fileItems.count];
		for (FileItem * item in fileItems) {
			[paths addObject:item.path];
		}
		
		NSString * rootPath = [self rootPathForPaths:paths];
		[allItemsPanelAttributes setObject:rootPath forKey:@"rootPath"];
		
		
		itemsPanelAttributes = allItemsPanelAttributes;
		
		NSMutableArray * allPanelRows = [[NSMutableArray alloc] initWithCapacity:itemsPanelAttributes.count];
		
		for (NSString * key in [itemsPanelAttributes allKeys]) {
			id object = [itemsPanelAttributes objectForKey:key];
			
			if ([key isEqualToString:@"rootPath"]) {
				
				NSSize size = [panelTableView rectOfColumn:1].size;
				size.width -= 30.;
				
				NSArray * lines = [object linesConstraitWithSize:size separatedByString:@"/"];
				
				int index = 0;
				for (NSString * line in lines) {
					
					NSString * newKey = @"";
					if (index == 0)// Show "Where" only for the first row of the root path
						newKey = [OptionItem localizedShortDescriptionForOption:key];
					
					[allPanelRows insertObject:[NSString stringWithFormat:@"%@=%@", newKey, line]
									   atIndex:index];
					
					index++;
				}
				
			} else {
				
				id value = nil;
				if ([key isEqualToString:@"FileItemCompareUTI"]) {
					value = [[NSWorkspace sharedWorkspace] localizedDescriptionForType:object];
					if (!value) {
						NSString * extension = [itemsPanelAttributes objectForKey:@"FileItemCompareExtension"];
						if (extension && extension.length > 0) { value = [NSString stringWithFormat:NSLocalizedString(@"%@ Files", nil), [extension capitalizedString]]; }
						else { value = NSLocalizedString(@"Unknown Type", nil); }
					}
				} else if ([key isEqualToString:@"FileItemCompareCreationDate"]) {
					NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
					formatter.dateStyle = NSDateFormatterLongStyle;
					formatter.timeStyle = NSDateFormatterShortStyle;
					value = [formatter stringFromDate:object];
				} else if ([key isEqualToString:@"FileItemCompareLastModificationDate"]) {
					NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
					formatter.dateStyle = NSDateFormatterLongStyle;
					formatter.timeStyle = NSDateFormatterShortStyle;
					value = [formatter stringFromDate:object];
				} else if ([key isEqualToString:@"FileItemCompareSize"]) {
					value = [NSString localizedStringForFileSize:[object doubleValue]];
				} else if ([key isEqualToString:@"FileItemCompareExtension"]) {
					NSString * extension = (NSString *)object;
					if (extension && extension.length > 0) { value = extension; }
					/* else { value = NSLocalizedString(@"_(No Extension)", nil); }*/
				} else {
					value = [NSString stringWithFormat:@"%@", object];
				}
				
				if (value) {
					[allPanelRows addObject:[NSString stringWithFormat:@"%@=%@", [OptionItem localizedShortDescriptionForOption:key], value]];
				}
			}
		}
		
		panelRows = allPanelRows;
	}
}

- (void)showOptions:(NSArray *)options
{
	NSSize size = [panelTableView rectOfColumn:1].size;
	size.width -= 30.;
	
	NSMutableArray * allPanelRows = [[NSMutableArray alloc] initWithCapacity:itemsPanelAttributes.count];
	
	int index = 0;
	
	if ([OptionItem useAutomaticComparaison]) {
		[allPanelRows addObject:[NSString stringWithFormat:@"Option=%@", @"Automatic"]];
	} else {
		NSMutableArray * fileOptions = [[NSMutableArray alloc] init];
		NSMutableArray * imageOptions = [[NSMutableArray alloc] init];
		NSMutableArray * audioOptions = [[NSMutableArray alloc] init];
		
		for (OptionItem * option in options) {
			if ([ImageItem canCompareWithOption:option.identifier]) {
				[imageOptions addObject:[option localizedName]];
			} else if ([AudioItem canCompareWithOption:option.identifier]) {
				[audioOptions addObject:[option localizedName]];
			} else {
				[fileOptions addObject:[option localizedName]];
			}
		}
		
		if (fileOptions.count > 0) {
			NSArray * fileOptionsLines = [[fileOptions componentsJoinedByString:@", "] linesConstraitWithSize:size
																							separatedByString:@", "];
			index = 0;
			for (NSString * line in fileOptionsLines) {
				NSString * newKey = @"";
				if (index == 0)// Show "File Options" only for the first row of the root path
					newKey = NSLocalizedString(@"fileOptionsShort", nil);
				
				[allPanelRows addObject:[NSString stringWithFormat:@"%@=%@", newKey, line]];
				index++;
			}
		}
		
		if (imageOptions.count > 0) {
			NSArray * imageOptionsLines = [[imageOptions componentsJoinedByString:@", "] linesConstraitWithSize:size
																							  separatedByString:@", "];
			index = 0;
			for (NSString * line in imageOptionsLines) {
				NSString * newKey = @"";
				if (index == 0)// Show "Image Options" only for the first row of the root path
					newKey = NSLocalizedString(@"imageOptionsShort", nil);
				
				[allPanelRows addObject:[NSString stringWithFormat:@"%@=%@", newKey, line]];
				index++;
			}
		}
		
		if (audioOptions.count > 0) {
			NSArray * audioOptionsLines = [[audioOptions componentsJoinedByString:@", "] linesConstraitWithSize:size
																							  separatedByString:@", "];
			index = 0;
			for (NSString * line in audioOptionsLines) {
				NSString * newKey = @"";
				if (index == 0)// Show "Audio Options" only for the first row of the root path
					newKey = NSLocalizedString(@"audioOptionsShort", nil);
				
				[allPanelRows addObject:[NSString stringWithFormat:@"%@=%@", newKey, line]];
				index++;
			}
		}
	}
	
	/* Show whitelist or blacklist items */
	NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
	BOOL extensionBlacklistSelected = !([[userDefaults stringForKey:@"extensionTypeList"] isEqualToString:@"extensionWhitelistSelected"]);
	
	if (extensionBlacklistSelected) {
		NSArray * blacklistItems = [userDefaults arrayForKey:@"extensionBlacklists"];
		if (blacklistItems.count > 0) {
			NSMutableArray * blacklistTypeDescriptions = [[NSMutableArray alloc] initWithCapacity:blacklistItems.count];
			for (NSString * item in blacklistItems) {
				[blacklistTypeDescriptions addObject:[[NSWorkspace sharedWorkspace] localizedDescriptionForType:item]];
			}
			
			NSArray * blacklistItemsLines = [[blacklistTypeDescriptions componentsJoinedByString:@", "] linesConstraitWithSize:size
																											 separatedByString:@", "];
			
			index = 0;
			for (NSString * line in blacklistItemsLines) {
				NSString * newKey = @"";
				if (index == 0)// Show "Image Options" only for the first row of the root path
					newKey = NSLocalizedString(@"Ext. Blacklist", nil);
				
				[allPanelRows addObject:[NSString stringWithFormat:@"%@=%@", newKey, line]];
				index++;
			}
		}
	} else {
		NSArray * whitelistItems = [userDefaults arrayForKey:@"extensionWhitelists"];
		if (whitelistItems.count > 0) {
			NSMutableArray * whitelistTypeDescriptions = [[NSMutableArray alloc] initWithCapacity:whitelistItems.count];
			for (NSString * item in whitelistItems) {
				[whitelistTypeDescriptions addObject:[[NSWorkspace sharedWorkspace] localizedDescriptionForType:item]];
			}
			
			NSArray * whitelistItemsLines = [[whitelistItems componentsJoinedByString:@", "] linesConstraitWithSize:size
																								  separatedByString:@", "];
			
			index = 0;
			for (NSString * line in whitelistItemsLines) {
				NSString * newKey = @"";
				if (index == 0)// Show "Image Options" only for the first row of the root path
					newKey = NSLocalizedString(@"Ext. Whitlist", nil);
				
				[allPanelRows addObject:[NSString stringWithFormat:@"%@=%@", newKey, line]];
				index++;
			}
		}
	}
	
	panelRows = allPanelRows;
	
	[previewPanelView setHidden:YES];
}


- (void)showItemInformations:(GridItem *)item
{
	NSPersistentStoreCoordinator * coordinator = [[NSApp delegate] persistentStoreCoordinator];
	NSAssert(coordinator != nil, @"coordinator == nil");
	
	NSManagedObjectContext * context = [[NSManagedObjectContext alloc] init];
	[context setPersistentStoreCoordinator:coordinator];
	[context setUndoManager:nil];
	
	/* ... generate the thumbnail from QuickLook */
	FileItem * fileItem = (FileItem *)[context objectWithID:item.managedObject.objectID];
	if (!fileItem.path)
		NSLog(@"no path for %@", fileItem);
	[self refreshPrewiewForPath:fileItem.path];
	
	/* ... show buttons from right panel */
	[moveToTrash setHidden:NO];
	
	/* Hide alias related buttons when original item is selected */
	[replaceWithAliasButton setHidden:(item.isOriginal)];
	[setAsOriginalButton setHidden:(item.isOriginal)];
	
	/* If "item" is deleted, show "Remove from Trash", show "Move to Trash" else */
	if (item.deleted) {
		[moveToTrash setTitle:NSLocalizedString(@"Remove from Trash", nil)];
	} else {
		[moveToTrash setTitle:NSLocalizedString(@"Move to Trash", nil)];
	}
	[moveToTrash sizeToFit];
	
	/* If "item" will be replaced with alias, show "Do not Replace", show "Replace with Alias" else */
	if (item.becameAlias) {
		[replaceWithAliasButton setTitle:NSLocalizedString(@"Do not Replace", nil)];
	} else {
		[replaceWithAliasButton setTitle:NSLocalizedString(@"Replace with Alias", nil)];
	}
	[replaceWithAliasButton sizeToFit];
	
	
	[previewPanelView setHidden:NO];
	
	[self refreshRightPanelRows];
}

- (void)showItemsInformations:(NSArray *)items
{
	previewImageView.image = [NSImage imageNamed:NSImageNameMultipleDocuments];
	previewImageView.image.size = NSMakeSize(128., 128.);
	
	[moveToTrash setHidden:NO];
	
	BOOL originalItemIsSelected = NO;
	for (GridItem * item in items) { if (item.isOriginal) { originalItemIsSelected = YES; break; } }
	[replaceWithAliasButton setHidden:(originalItemIsSelected)];// Hide the "Replace with Alias" button if the original item is selected
	
	[setAsOriginalButton setHidden:YES];
	
	[self refreshRightPanelRows];
}

- (void)showGroupInformations:(NSManagedObject *)group
{
	previewImageView.image = [NSImage imageNamed:NSImageNameMultipleDocuments];
	previewImageView.image.size = NSMakeSize(128., 128.);
	
	/* ... hide buttons from right panel */
	[moveToTrash setHidden:YES];
	[replaceWithAliasButton setHidden:YES];
	[setAsOriginalButton setHidden:YES];
	
	[previewPanelView setHidden:NO];
	
	
	NSPersistentStoreCoordinator * coordinator = [[NSApp delegate] persistentStoreCoordinator];
	NSAssert(coordinator != nil, @"coordinator == nil");
	
	NSManagedObjectContext * context = [[NSManagedObjectContext alloc] init];
	[context setPersistentStoreCoordinator:coordinator];
	[context setUndoManager:nil];
	
	NSArray * items = [(NSSet *)[[context objectWithID:group.objectID] mutableSetValueForKey:@"items"] allObjects];
	
	if ([SandboxHelper sandboxActived]) {
		BOOL started = [SandboxHelper startAccessingSecurityScopedSources];
		if (!started) NSLog(@"startAccessingSecurityScopedSources failed");
	}
	
	NSDictionary * commonsValues = [FileItem commonsValuesForItems:items];
	
	if ([SandboxHelper sandboxActived])
		[SandboxHelper stopAccessingSecurityScopedSources];
	
	
	NSMutableDictionary * allItemsPanelAttributes = [[NSMutableDictionary alloc] initWithDictionary:commonsValues];
	
	NSString * type = [[NSWorkspace sharedWorkspace] localizedDescriptionForType:[commonsValues objectForKey:@"type"]];
	if (type) {
		[allItemsPanelAttributes setObject:type forKey:@"type"];
	}
	
	NSMutableArray * paths = [[NSMutableArray alloc] initWithCapacity:items.count];
	for (FileItem * item in items) {
		[paths addObject:item.path];
	}
	
	NSString * rootPath = [self rootPathForPaths:paths];
	[allItemsPanelAttributes setObject:rootPath forKey:@"rootPath"];
	
	
	itemsPanelAttributes = allItemsPanelAttributes;
	
	NSMutableArray * allPanelRows = [[NSMutableArray alloc] initWithCapacity:itemsPanelAttributes.count];
	
	for (NSString * key in [itemsPanelAttributes allKeys]) {
		id object = [itemsPanelAttributes objectForKey:key];
		
		if ([key isEqualToString:@"rootPath"]) {
			
			NSSize size = [panelTableView rectOfColumn:1].size;
			size.width -= 30.;
			
			NSArray * lines = [object linesConstraitWithSize:size separatedByString:@"/"];
			
			int index = 0;
			for (NSString * line in lines) {
				
				NSString * newKey = @"";
				if (index == 0)// Show "Where" only for the first row of the root path
					newKey = [OptionItem localizedShortDescriptionForOption:key];
				
				[allPanelRows insertObject:[NSString stringWithFormat:@"%@=%@", newKey, line]
								   atIndex:index];
				
				index++;
			}
		} else {
			
			id value = nil;
			if ([key isEqualToString:@"FileItemCompareUTI"]) {
				
				value = [[NSWorkspace sharedWorkspace] localizedDescriptionForType:object];
				if (!value) {
					NSString * extension = [itemsPanelAttributes objectForKey:@"FileItemCompareExtension"];
					if (extension) { value = [NSString stringWithFormat:NSLocalizedString(@"%@ Files", nil), [extension capitalizedString]]; }
					else { value = NSLocalizedString(@"Unknown Type", nil); }
				}
				
			} else if ([key isEqualToString:@"FileItemCompareCreationDate"]) {
				NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
				formatter.dateStyle = NSDateFormatterLongStyle;
				formatter.timeStyle = NSDateFormatterShortStyle;
				value = [formatter stringFromDate:object];
			} else if ([key isEqualToString:@"FileItemCompareLastModificationDate"]) {
				NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
				formatter.dateStyle = NSDateFormatterLongStyle;
				formatter.timeStyle = NSDateFormatterShortStyle;
				value = [formatter stringFromDate:object];
			} else if ([key isEqualToString:@"FileItemCompareSize"]) {
				value = [NSString localizedStringForFileSize:[object doubleValue]];
			} else if ([key isEqualToString:@"FileItemCompareExtension"]) {
				NSString * extension = (NSString *)object;
				if (extension && extension.length > 0) { value = extension; }
				/* else { value = NSLocalizedString(@"_(No Extension)", nil); }*/
			} else {
				value = [NSString stringWithFormat:@"%@", object];
			}
			
			if (value) {
				[allPanelRows addObject:[NSString stringWithFormat:@"%@=%@", [OptionItem localizedShortDescriptionForOption:key], value]];
			}
		}
	}
	
	panelRows = allPanelRows;
}

- (void)showGroupsInformations:(NSArray *)groups
{
	previewImageView.image = [NSImage imageNamed:NSImageNameMultipleDocuments];
	previewImageView.image.size = NSMakeSize(128., 128.);
	
	[moveToTrash setHidden:YES];
	[replaceWithAliasButton setHidden:YES];
	[setAsOriginalButton setHidden:YES];
	
	[self refreshRightPanelRows];
}

- (void)reloadRightPanel
{
	NSArray * selectedItems = [gridView selectedItems];
	[self reloadRightPanelWithItems:selectedItems];
}

- (void)reloadRightPanelWithItems:(NSArray *)gridItems
{
	if (gridItems.count == 0) {// If no items or groups selected...
		
		if ((selectedSourceType == SourceTypeDuplicates) && currentGroup) {// If we are into "Duplicates" and into a group
			// Show the group information from "currentGroup"
			[self showGroupInformations:currentGroup];
		} else {// If no items selected, show selected options
			// No items or groups selected, show options
			[self showOptions:[OptionItem checkedItems]];
		}
		
	} else if (gridItems.count == 1) {// If only one item or group is selected...
		
		GridItem * item = [gridItems objectAtIndex:0];
		if (item.isGroup) {// ... if it's a group...
			// Show only one group information from "item"
			[self showGroupInformations:item.group];
		} else {// ... else (it's a file) ...
			// Show only one file information from "item"
			[self showItemInformations:item];
		}
		
	} else {// If many items or groups are selected...
		
		BOOL onlyFilesAreSelected = YES;
		for (GridItem * item in gridItems) {
			if (item.isGroup) { onlyFilesAreSelected = NO; break; }
		}
		
		if (onlyFilesAreSelected) {
			// Show multiple files from "selectedItems"
			[self showItemsInformations:gridItems];
		} else {
			// Show multiple groups from "selectedItems"
			[self showGroupsInformations:gridItems];
		}
	}
	
	/* Reload the "panelTableView" before fix the position and size */
	[panelTableView reloadData];
	
	NSDictionary * attributes = [[NSDictionary alloc] initWithObjectsAndKeys:[NSFont systemFontOfSize:13./* fontWithName:@"Helvetica" size:13.*/], NSFontAttributeName, nil];
	
	CGFloat maxWidth = 0.;
	for (NSString * rowString in panelRows) {
		NSString * key = [[[rowString componentsSeparatedByString:@"="] objectAtIndex:0] stringByAppendingString:@" :"];
		
		float width = [key sizeWithAttributes:attributes].width;
		if (width > maxWidth) maxWidth = width;
	}
	
	[[panelTableView tableColumnWithIdentifier:@"key"] setWidth:maxWidth];
	
	/* Fix the position of the bottom part of the panelTableView (with preview and buttons) */
	CGFloat rowHeight = panelTableView.rowHeight;
	CGFloat intercellHeight = panelTableView.intercellSpacing.height;
	NSInteger tableViewHeight = panelRows.count * (rowHeight + intercellHeight) + intercellHeight;
	
	NSRect frame = previewPanelView.frame;
	frame.origin.y = tableViewHeight;
	previewPanelView.frame = frame;
}

#pragma mark - NSSplitView Delegate

- (BOOL)splitView:(NSSplitView *)theSplitView canCollapseSubview:(NSView *)subview
{
	return ([theSplitView.subviews indexOfObject:subview] == 1);// The second view (on right) can be collapsed
}

- (CGFloat)splitView:(NSSplitView *)theSplitView constrainSplitPosition:(CGFloat)proposedPosition ofSubviewAt:(NSInteger)dividerIndex
{
	CGFloat leftMargin = 300., rightMargin = 300.;
	CGFloat width = theSplitView.frame.size.width;
	return MAX(leftMargin, MIN(width - rightMargin, proposedPosition));
}

#pragma mark - GridViewDataSource

- (NSString *)placeholderInGridView:(GridView *)gridView
{
	if (selectedSourceType == SourceTypeDuplicates) {
		return NSLocalizedString(@"No Duplicates", nil);
	} else if (selectedSourceType == SourceTypeEmptyItems) {
		return NSLocalizedString(@"No Empty Items", nil);
	} else if (selectedSourceType == SourceTypeBrokenAliases) {
		return NSLocalizedString(@"No Broken Aliases", nil);
	}
	
	return @"";
}

- (NSInteger)numberOfSectionsInGridView:(GridView *)gridView
{
	if (selectedSourceType == SourceTypeDuplicates) {
		if (!currentGroup) {
			return ([self numberOfItemsForDuplicateType:selectedDuplicateType] > 0)? 1: 0;
		} else {
			return 1;
		}
	} else if (selectedSourceType == SourceTypeEmptyItems) {
		return (emptyItems.count > 0)? 1: 0;
	} else if (selectedSourceType == SourceTypeBrokenAliases) {
		return (brokenAliases.count > 0)? 1: 0;
	}
	
	return 0;
}

- (NSArray *)titlesForSectionsInGridView:(GridView *)gridView
{
	return [NSArray arrayWithObject:@""];
}

- (NSArray *)gridView:(GridView *)gridView itemsForSection:(NSInteger)section
{
	if (selectedSourceType == SourceTypeDuplicates) {
		
		if (currentGroup) {
			return [self gridItemsForGroup:currentGroup];
		} else {
			return [self gridItemsForDuplicatesType:selectedDuplicateType];
		}
		
	} else if (selectedSourceType == SourceTypeEmptyItems) {
		return [self gridItemsForEmptyItems];
	} else if (selectedSourceType == SourceTypeBrokenAliases) {
		return [self gridItemsForBrokensAliases];
	}
	
	return nil;
}

#pragma mark - GridViewDelegate

- (void)gridView:(GridView *)aGridView didSelectItem:(GridItem *)item indexPath:(NSIndexPath *)indexPath
{
}

- (void)gridView:(GridView *)aGridView didSelectItems:(NSArray *)items indexPaths:(NSArray *)indexPaths
{
}

- (void)gridView:(GridView *)aGridView didDoubleClickOnItem:(GridItem *)item indexPath:(NSIndexPath *)indexPath
{
	if (selectedSourceType == SourceTypeDuplicates) {
		if (currentGroup) {// If we are into a group, open the file
			
			NSString * path = ((FileItem *)item.managedObject).path;
			NSURL * fileURL = [NSURL fileURLWithPath:path];
			[[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:[NSArray arrayWithObject:fileURL]];
			
		} else {// Else, open the group
			NSRect frame = backHeaderView.frame;
			frame.origin.x = 0.;
			frame.origin.y = 0.;
			frame.size.width = gridView.frame.size.width;
			backHeaderView.frame = frame;
			
			backHeaderView.title = item.title;
			gridView.headerView = backHeaderView;
			
			currentGroup = item.group;
			[gridView reloadData];
		}
	} else {
		NSString * path = ((FileItem *)item.managedObject).path;
		NSURL * fileURL = [NSURL fileURLWithPath:path];
		[[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:[NSArray arrayWithObject:fileURL]];
	}
}

- (void)gridViewSelectionDidChange:(GridView *)theGridView
{
	[self reloadRightPanel];
	
	/* reload QLPreview from selection */
	if ([QLPreviewPanel sharedPreviewPanelExists] && [[QLPreviewPanel sharedPreviewPanel] isVisible]) {
		[[QLPreviewPanel sharedPreviewPanel] reloadData];
	}
}

- (NSMenu *)menuForGridView:(GridView *)gridView selectedItems:(NSArray *)items
{
	NSMenu * menu = [[NSMenu alloc] initWithTitle:@"gridview-click-right-menu"];
	
	if (selectedSourceType == SourceTypeDuplicates) {
		BOOL containsGroupItem = NO;
		for (GridItem * item in items) {
			if (item.isGroup) { containsGroupItem = YES; break; }
		}
		
		BOOL containsOriginalItem = NO;
		for (GridItem * item in items) {
			NSManagedObject * originalItem = [self originalItemForGroup:item.group];
			if ([originalItem.objectID isEqualTo:item.managedObject.objectID]) { containsOriginalItem = YES; break; }
		}
		if (containsOriginalItem) NSLog(@"Original item selected");
		
		if ((items.count > 0 && containsGroupItem)// If the user select groups
			|| (items.count == 0 && currentGroup)) {// or if the user doesn't select items but are into a group (click on background)
			/* one or many groups selected:
			 * - "Move duplicates" > "Move to Trash...", "Move..."
			 * - "Replace Duplicates..."
			 */
			
			NSMenuItem * moveMenuItem = [[NSMenuItem alloc] initWithTitle:@"Move Duplicates" action:NULL keyEquivalent:@""];
			{
				NSMenu * moveMenu = [[NSMenu alloc] initWithTitle:@"move-submenu"];
				[moveMenu addItemWithTitle:NSLocalizedString(@"Move to Trash...", nil) target:self action:@selector(moveSelectedItemsToTrashAction:)];
				[moveMenu addItemWithTitle:NSLocalizedString(@"Move...", nil) target:self action:@selector(moveSelectedItemsAction:)];
				moveMenuItem.submenu = moveMenu;
			}
			[menu addItem:moveMenuItem];
			
			[menu addItemWithTitle:NSLocalizedString(@"Replace Duplicates...", nil) target:self action:@selector(replaceSelectedItemsAction:)];
			
		} else if (containsOriginalItem) {
			/* original (and duplicates) item selected:
			 * - "Move to Trash..."
			 * - "Move..."
			 * ---------------------
			 * - "Show in Finder"
			 */
			
			[menu addItemWithTitle:NSLocalizedString(@"Move to Trash...", nil) target:self action:@selector(moveSelectedItemsToTrashAction:)];
			[menu addItemWithTitle:NSLocalizedString(@"Move...", nil) target:self action:@selector(moveSelectedItemsAction:)];
			
			[menu addSeparatorItem];
			[menu addItemWithTitle:NSLocalizedString(@"Show in Finder", nil) target:self action:@selector(showInFinderSelectedItemsAction:)];
			
		} else if ((items.count == 1 && !containsOriginalItem)) {
			/* one item selected:
			 * - "Set as Original Item"
			 * ---------------------
			 * - "Move to Trash..."
			 * - "Move..."
			 * - "Replace..."
			 * ---------------------
			 * - "Show in Finder"
			 */
			
			[menu addItemWithTitle:NSLocalizedString(@"Set as Original Item", nil) target:self action:@selector(setAsOriginalAction:)];
			[menu addSeparatorItem];
			
			[menu addItemWithTitle:NSLocalizedString(@"Move to Trash...", nil) target:self action:@selector(moveSelectedItemsToTrashAction:)];
			[menu addItemWithTitle:NSLocalizedString(@"Move...", nil) target:self action:@selector(moveSelectedItemsAction:)];
			[menu addItemWithTitle:NSLocalizedString(@"Replace...", nil) target:self action:@selector(replaceSelectedItemsAction:)];
			
			[menu addSeparatorItem];
			[menu addItemWithTitle:NSLocalizedString(@"Show in Finder", nil) target:self action:@selector(showInFinderSelectedItemsAction:)];
			
		} else if (items.count == 2 && !containsOriginalItem) {
			/* two items selected:
			 * - "Show Differences"
			 * ---------------------
			 * - "Move to Trash..."
			 * - "Move..."
			 * - "Replace..."
			 * ---------------------
			 * - "Show in Finder"
			 */
			
			[menu addItemWithTitle:NSLocalizedString(@"Show differences", nil) target:self action:@selector(compareSelectedItems:)];
			[menu addSeparatorItem];
			
			[menu addItemWithTitle:NSLocalizedString(@"Move to Trash...", nil) target:self action:@selector(moveSelectedItemsToTrashAction:)];
			[menu addItemWithTitle:NSLocalizedString(@"Move...", nil) target:self action:@selector(moveSelectedItemsAction:)];
			[menu addItemWithTitle:NSLocalizedString(@"Replace...", nil) target:self action:@selector(replaceSelectedItemsAction:)];
			
			[menu addSeparatorItem];
			[menu addItemWithTitle:NSLocalizedString(@"Show in Finder", nil) target:self action:@selector(showInFinderSelectedItemsAction:)];
			
		} else if (items.count > 2 && !containsOriginalItem) {
			/* more items selected:
			 * - "Move to Trash..."
			 * - "Move..."
			 * - "Replace..."
			 * ---------------------
			 * - "Show in Finder"
			 */
			
			[menu addItemWithTitle:NSLocalizedString(@"Move to Trash...", nil) target:self action:@selector(moveSelectedItemsToTrashAction:)];
			[menu addItemWithTitle:NSLocalizedString(@"Move...", nil) target:self action:@selector(moveSelectedItemsAction:)];
			[menu addItemWithTitle:NSLocalizedString(@"Replace...", nil) target:self action:@selector(replaceSelectedItemsAction:)];
			
			[menu addSeparatorItem];
			[menu addItemWithTitle:NSLocalizedString(@"Show in Finder", nil) target:self action:@selector(showInFinderSelectedItemsAction:)];
			
		} else {// None of these case, return nil
			return nil;
		}
	} else if (selectedSourceType == SourceTypeEmptyItems) {
		
		if (items.count > 0) {
			/* more items selected:
			 * - "Move to Trash..."
			 * ---------------------
			 * - "Show in Finder"
			 */
			
			[menu addItemWithTitle:NSLocalizedString(@"Move to Trash...", nil) target:self action:@selector(moveSelectedItemsToTrashAction:)];
			[menu addSeparatorItem];
			[menu addItemWithTitle:NSLocalizedString(@"Show in Finder", nil) target:self action:@selector(showInFinderSelectedItemsAction:)];
		} else {
			return nil;
		}
	} else {// "Boken Aliases"
		
		if (items.count > 0) {
			/* more items selected:
			 * - "Move to Trash..."
			 * ---------------------
			 * - "Show in Finder"
			 */
			
			[menu addItemWithTitle:NSLocalizedString(@"Move to Trash...", nil) target:self action:@selector(moveSelectedItemsToTrashAction:)];
			[menu addSeparatorItem];
			[menu addItemWithTitle:NSLocalizedString(@"Show in Finder", nil) target:self action:@selector(showInFinderSelectedItemsAction:)];
		} else {
			return nil;
		}
	}
	
	return menu;
}

- (void)gridView:(GridView *)gridView didReceiveKeyString:(NSString *)keyString
{
	if ([keyString isEqualToString:@" "]) {// If the pressed key is the space key...
		/* ... toogle QuickLook  */
		QLPreviewPanel * previewPanel = [QLPreviewPanel sharedPreviewPanel];
		if ([QLPreviewPanel sharedPreviewPanelExists] && [previewPanel isVisible]) {
			[previewPanel orderOut:nil];
		} else {
			[previewPanel makeKeyAndOrderFront:nil];
		}
	}
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return panelRows.count;
}

- (CGFloat)tableView:(NSTableView *)aTableView heightOfRow:(NSInteger)row
{
	if (row == (panelRows.count - 1)) {
		return previewPanelView.frame.size.height + 30.;
	} else {
		return 17.;
	}
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	NSString * rowObject = [panelRows objectAtIndex:rowIndex];
	NSArray * components = [rowObject componentsSeparatedByString:@"="];
	
	if ([aTableColumn.identifier isEqualToString:@"key"]) {
		NSString * key = [components objectAtIndex:0];
		// Return "key:" if we have key value, else return nothing
		return (key.length > 0)? [key stringByAppendingString:@" :"] : nil;
	} else {
		return (components.count >= 2)? [components objectAtIndex:1] : nil;
	}
}

- (void)tableViewColumnDidResize:(NSNotification *)aNotification
{
	[self gridViewSelectionDidChange:gridView];
}

#pragma mark - QLPreviewPanelDelegate

- (NSRect)previewPanel:(QLPreviewPanel *)panel sourceFrameOnScreenForPreviewItem:(id <QLPreviewItem>)item
{
	GridItem * selectedItem = [gridView selectedItem];
	NSRect rect = selectedItem.itemView.frame;
	NSPoint point = [self.view convertPoint:rect.origin fromView:gridView];
	point.y = gridView.frame.size.height - point.y;
	
	rect.origin = [[NSApp mainWindow] convertBaseToScreen:point];
	
	if (![gridView itemIsVisible:selectedItem]) {
		return NSZeroRect;
	}
	
	return rect;
}

- (NSImage *)previewPanel:(QLPreviewPanel *)panel transitionImageForPreviewItem:(id <QLPreviewItem>)item contentRect:(NSRect *)contentRect
{
	if (item) {
		
		if ([SandboxHelper sandboxActived]) {
			BOOL started = [SandboxHelper startAccessingSecurityScopedSources];
			if (!started) NSLog(@"startAccessingSecurityScopedSources failed");
		}
		
		NSImage * image = [[NSWorkspace sharedWorkspace] iconForFile:((FileItem *)item).path];
		
		if ([SandboxHelper sandboxActived])
			[SandboxHelper stopAccessingSecurityScopedSources];
		
		return image;
	}
	
	return nil;
}

#pragma mark - QLPreviewPanelDataSource

- (NSInteger)numberOfPreviewItemsInPreviewPanel:(QLPreviewPanel *)panel
{
	return [gridView selectedItems].count;
}

- (id <QLPreviewItem>)previewPanel:(QLPreviewPanel *)panel previewItemAtIndex:(NSInteger)index
{
	GridItem * selectedItem = [[gridView selectedItems] objectAtIndex:index];
	return (FileItem *)selectedItem.managedObject;
}

@end

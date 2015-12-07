//
//  OptionItem.m
//  Comparator
//
//  Created by Max on 14/02/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "OptionItem.h"
#import "NSString+addition.h"

@implementation Section

@dynamic name;
@dynamic descriptionString;
@dynamic index;

static NSArray * sections = nil;

+ (NSArray *)sections
{
	if (!sections) {
		NSManagedObjectContext * context = [OptionItem managedObjectContext];
		NSFetchRequest * request = [[NSFetchRequest alloc] init];
		[request setPredicate:[NSPredicate predicateWithFormat:@"TRUEPREDICATE"]];
		[request setEntity:[NSEntityDescription entityForName:@"Section" inManagedObjectContext:context]];
		
		NSSortDescriptor * sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"index" ascending:YES];
		[request setSortDescriptors:@[sortDescriptor]];
		
		sections = [context executeFetchRequest:request error:NULL];
	}
	
	return sections;
}

- (instancetype)init
{
	NSManagedObjectContext * managedObjectContext = [OptionItem managedObjectContext];
	NSEntityDescription * entity = [NSEntityDescription entityForName:@"Section" inManagedObjectContext:managedObjectContext];
	Section * section = [[Section alloc] initWithEntity:entity insertIntoManagedObjectContext:managedObjectContext];
	return section;
}

- (instancetype)initWithName:(NSString *)name
{
	static int _index = 0;
	
	NSManagedObjectContext * managedObjectContext = [OptionItem managedObjectContext];
	
	NSEntityDescription * entity = [NSEntityDescription entityForName:@"Section" inManagedObjectContext:managedObjectContext];
	Section * section = [[Section alloc] initWithEntity:entity insertIntoManagedObjectContext:managedObjectContext];
	section.name = name;
	section.index = @(_index++);
	return section;
}

- (NSArray *)groups
{
	if (!groups) {
		NSArray * array = [[self mutableSetValueForKey:@"groups"] allObjects];
		NSSortDescriptor * sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"index" ascending:YES];
		groups = [array sortedArrayUsingDescriptors:@[ sortDescriptor ]];
	}
	
	return groups;
}

- (NSArray *)allOptions
{
	if (!options) {
		NSMutableArray * items = [[NSMutableArray alloc] initWithCapacity:10];
		for (Group * group in [self groups]) {
			[items addObjectsFromArray:[[group mutableSetValueForKeyPath:@"items"] allObjects]];
			
			int index = 0;
			NSArray * objects = [[group mutableSetValueForKeyPath:@"items"] allObjects];
			for (OptionItem * item in objects) {
				if (!item.index)
					item.index = @(index);
				index++;
			}
		}
		
		NSSortDescriptor * sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"index" ascending:YES];
		[items sortUsingDescriptors:@[sortDescriptor]];
		
		options = items;
	}
	return options;
}

- (OptionItem *)optionItemWithIndex:(NSInteger)index
{
	NSPredicate * predicate = [NSPredicate predicateWithFormat:@"index == %i", index];
	
	NSMutableArray * allItems = [[NSMutableArray alloc] initWithCapacity:10];
	for (Group * group in [self groups]) {
		[allItems addObjectsFromArray:[[group mutableSetValueForKeyPath:@"items"] allObjects]];
	}
	
	NSArray * items = [allItems filteredArrayUsingPredicate:predicate];
	
	if (items.count > 0)
		return items.firstObject;
	
	return nil;
}

- (NSArray *)optionsAtRow:(NSInteger)row
{
	NSPredicate * predicate = [NSPredicate predicateWithFormat:@"(%i == index) || (%i == index)", (row * 2), (row * 2) + 1 ];
	return [[self allOptions] filteredArrayUsingPredicate:predicate];
}

- (NSInteger)numberOfRow
{
	NSArray * allOptions = [self allOptions];
	NSInteger indexMax = [((OptionItem *)[allOptions lastObject]).index integerValue];
	return ((indexMax + 1) / 2);
}

- (NSString *)localizedDescriptionString
{
	return NSLocalizedString(self.descriptionString, nil);
}

@end


@implementation Group

@dynamic name;
@dynamic index;

- (instancetype)initWithSection:(Section *)section
{
	NSManagedObjectContext * managedObjectContext = [OptionItem managedObjectContext];
	
	NSEntityDescription * entity = [NSEntityDescription entityForName:@"Group" inManagedObjectContext:managedObjectContext];
	Group * group = [[Group alloc] initWithEntity:entity insertIntoManagedObjectContext:managedObjectContext];
	
	CFUUIDRef uuidRef = CFUUIDCreate(kCFAllocatorDefault);
	CFStringRef uuidString = CFUUIDCreateString(kCFAllocatorDefault, uuidRef);
	group.name = (__bridge NSString *)uuidString;
	if (uuidString) CFRelease(uuidString);
	if (uuidRef) CFRelease(uuidRef);
	
	static int _index = 0;
	group.index = @(_index++);
	
	[group setValue:section forKey:@"sections"];
	
	return group;
}

- (NSArray *)options
{
	if (!options) {
		NSSortDescriptor * sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"index" ascending:YES];
		NSArray * array = [[self mutableSetValueForKey:@"items"] allObjects];
		options = [array sortedArrayUsingDescriptors:@[sortDescriptor]];
	}
	return options;
}

- (OptionItem *)optionItemWithIndex:(NSInteger)index
{
	NSPredicate * predicate = [NSPredicate predicateWithFormat:@"index == %i", index];
	NSArray * items = [[self options] filteredArrayUsingPredicate:predicate];
	
	if (items.count > 0)
		return items.firstObject;
	
	return nil;
}

- (NSArray *)optionsAtRow:(NSInteger)row
{
	NSPredicate * predicate = [NSPredicate predicateWithFormat:@"(%i == index) || (%i == index)", (row * 2), (row * 2) + 1 ];
	return [[self options] filteredArrayUsingPredicate:predicate];
}

- (NSInteger)numberOfRow
{
	NSArray * allOptions = [self options];
	return (int)ceilf(allOptions.count / 2.);// Return an extra row to odd number of row
}

@end


@interface OptionItem (PrivateMethods)

+ (NSString *)applicationSupportDirectory;
+ (NSManagedObjectModel *)managedObjectModel;
+ (NSPersistentStoreCoordinator *)persistentStoreCoordinator;

@end

@implementation OptionItem

static NSManagedObjectContext * managedObjectContext;
static NSPersistentStoreCoordinator * persistentStoreCoordinator;
static NSManagedObjectModel * managedObjectModel;

static NSMutableDictionary * _localizedNames = NULL, * _localizedShortDescriptions = NULL;

@dynamic selected;
@dynamic identifier, descriptionString;
@dynamic index;

+ (void)initialize
{
	static BOOL initialized = NO;
	if (!initialized) {
		_localizedNames = [[NSMutableDictionary alloc] initWithCapacity:10];
		_localizedShortDescriptions = [[NSMutableDictionary alloc] initWithCapacity:10];
		initialized = YES;
	}
}

+ (NSString *)localizedNameForOption:(NSString *)option
{
	NSString * localizedName = _localizedNames[option];
	if (!localizedName) {
		NSString * optionName = [option stringByAppendingString:@"Name"];
		localizedName = NSLocalizedString(optionName, nil);
		_localizedNames[option] = localizedName;
	}
	
	return localizedName;
}

+ (NSString *)localizedShortDescriptionForOption:(NSString *)option
{
	NSString * localizedShortDescription = _localizedShortDescriptions[option];
	if (!localizedShortDescription) {
		NSString * optionShortDescription = [option stringByAppendingString:@"ShortDescription"];
		localizedShortDescription = NSLocalizedString(optionShortDescription, nil);
		_localizedShortDescriptions[option] = localizedShortDescription;
	}
	
	return localizedShortDescription;
}

+ (NSString *)localizedDescriptionForOption:(NSString *)option
{
	/* Don't add the "Compare the" to advanced options */
	if ([option isEqualToString:@"AdvancedOptionsIncludeHiddenItems"] || [option isEqualToString:@"AdvancedOptionsIncludeBundleContent"]) {
		return [OptionItem localizedNameForOption:option];
	} else {
		return [NSString stringWithFormat:NSLocalizedString(@"Compare the %@", nil), [OptionItem localizedNameForOption:option]];
	}
}

- (instancetype)init
{
	if (!managedObjectContext) {
		managedObjectContext = [OptionItem managedObjectContext];
	}
	
	NSEntityDescription * entity = [NSEntityDescription entityForName:@"OptionItem" inManagedObjectContext:managedObjectContext];
	OptionItem * item = [[OptionItem alloc] initWithEntity:entity insertIntoManagedObjectContext:managedObjectContext];
	
	return item;
}

- (NSString *)descriptionString
{
	return [NSString stringWithFormat:@"%@ (%@)", self, self.index];
}

- (instancetype)initWithGroup:(Group *)group
{
	if (!managedObjectContext) {
		managedObjectContext = [OptionItem managedObjectContext];
	}
	
	NSEntityDescription * entity = [NSEntityDescription entityForName:@"OptionItem" inManagedObjectContext:managedObjectContext];
	OptionItem * item = [[OptionItem alloc] initWithEntity:entity insertIntoManagedObjectContext:managedObjectContext];
	
	[item setValue:group forKey:@"groups"];
	
	return item;
}

- (Group *)group
{
	NSArray * groups = [[self mutableSetValueForKey:@"groups"] allObjects];
	if (groups.count > 0)
		return groups.firstObject;
	
	return nil;
}

- (Group *)section
{
	NSArray * sections = [[self mutableSetValueForKeyPath:@"groups.sections"] allObjects];
	if (sections.count > 0)
		return sections.firstObject;
	
	return nil;
}

- (NSString *)localizedName
{
	NSString * optionName = [self.identifier stringByAppendingString:@"Name"];
	return NSLocalizedString(optionName, nil);
}

- (NSString *)localizedDescription
{
	NSString * option = self.identifier;
	/* Don't add the "Compare the" to advanced options */
	if (option.length >= @"AdvancedOptions".length && [[option substringToIndex:@"AdvancedOptions".length] isEqualToString:@"AdvancedOptions"]) {// Check if the option begins with "AdvancedOptions"
		return [OptionItem localizedNameForOption:option].firstLetterCapitalized;
	} else {
		return [NSString stringWithFormat:NSLocalizedString(@"Compare the %@", nil), [OptionItem localizedNameForOption:option]];
	}
}

+ (void)async_save
{
	dispatch_async(dispatch_get_main_queue(), ^{
		NSError *error = nil;
		
		if (![managedObjectContext commitEditing]) {
			NSDebugLog(@"%@:%@ unable to commit editing before saving", @"OptionItem", NSStringFromSelector(_cmd));
		}
		
		BOOL succeed = [managedObjectContext save:&error];
		
		if (!succeed) {
			[[NSApplication sharedApplication] presentError:error];
		}
	});
}

+ (void)save
{
	[OptionItem async_save];
}

+ (void)async_rollback
{
	dispatch_async(dispatch_get_main_queue(), ^{
		NSError *error = nil;
		
		if (![managedObjectContext commitEditing]) {
			NSDebugLog(@"%@:%@ unable to commit editing before saving", @"OptionItem", NSStringFromSelector(_cmd));
		}
		
		BOOL succeed = [managedObjectContext save:&error];
		
		if (!succeed) {
			[[NSApplication sharedApplication] presentError:error];
		}
	});
}

+ (void)rollback
{
	[OptionItem async_rollback];
}

+ (NSArray *)items
{
	NSManagedObjectContext * context = [OptionItem managedObjectContext];
	NSFetchRequest * request = [[NSFetchRequest alloc] init];
	[request setPredicate:[NSPredicate predicateWithFormat:@"TRUEPREDICATE"]];
	[request setEntity:[NSEntityDescription entityForName:@"OptionItem" inManagedObjectContext:context]];
	
	return [context executeFetchRequest:request error:NULL];
}

+ (NSArray *)checkedItems
{
	NSManagedObjectContext * context = [OptionItem managedObjectContext];
	NSFetchRequest * request = [[NSFetchRequest alloc] init];
	[request setPredicate:[NSPredicate predicateWithFormat:@"selected == 1"]];
	[request setEntity:[NSEntityDescription entityForName:@"OptionItem" inManagedObjectContext:context]];
	
	return [context executeFetchRequest:request error:NULL];
}

+ (BOOL)useAutomaticComparaison
{
	NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
	return !([userDefaults boolForKey:@"UsingCustomOptions"]);
}

+ (BOOL)includeHiddenItems
{
	if ([OptionItem useAutomaticComparaison])
		return NO;
	
	NSManagedObjectContext * context = [OptionItem managedObjectContext];
	NSFetchRequest * request = [[NSFetchRequest alloc] init];
	request.predicate = [NSPredicate predicateWithFormat:@"identifier == %@", @"AdvancedOptionsIncludeHiddenItems"];
	request.entity = [NSEntityDescription entityForName:@"OptionItem" inManagedObjectContext:context];
	request.fetchLimit = 1;
	
	OptionItem * option = [context executeFetchRequest:request error:NULL].firstObject;
	return option.selected.boolValue;
}

+ (BOOL)includeBundleContent
{
	if ([OptionItem useAutomaticComparaison])
		return NO;
	
	NSManagedObjectContext * context = [OptionItem managedObjectContext];
	NSFetchRequest * request = [[NSFetchRequest alloc] init];
	request.predicate = [NSPredicate predicateWithFormat:@"identifier == %@", @"AdvancedOptionsIncludeBundleContent"];
	request.entity = [NSEntityDescription entityForName:@"OptionItem" inManagedObjectContext:context];
	request.fetchLimit = 1;
	
	OptionItem * option = [context executeFetchRequest:request error:NULL].firstObject;
	return option.selected.boolValue;
}

+ (BOOL)shouldFindBrokenAliases
{
	if ([OptionItem useAutomaticComparaison])
		return YES;
	
	NSManagedObjectContext * context = [OptionItem managedObjectContext];
	NSFetchRequest * request = [[NSFetchRequest alloc] init];
	[request setPredicate:[NSPredicate predicateWithFormat:@"identifier == %@", @"AdvancedOptionsSearchBrokenAliases"]];
	[request setEntity:[NSEntityDescription entityForName:@"OptionItem" inManagedObjectContext:context]];
	
	OptionItem * option = [context executeFetchRequest:request error:NULL].firstObject;
	return option.selected.boolValue;
}

+ (BOOL)shouldFindEmptyItems
{
	if ([OptionItem useAutomaticComparaison])
		return YES;
	
	NSManagedObjectContext * context = [OptionItem managedObjectContext];
	NSFetchRequest * request = [[NSFetchRequest alloc] init];
	[request setPredicate:[NSPredicate predicateWithFormat:@"identifier == %@", @"AdvancedOptionsSearchEmptyItems"]];
	[request setEntity:[NSEntityDescription entityForName:@"OptionItem" inManagedObjectContext:context]];
	
	OptionItem * option = [context executeFetchRequest:request error:NULL].firstObject;
	return option.selected.boolValue;
}

#pragma mark -
#pragma mark Core Date

/**
 Returns the support directory for the application, used to store the Core Data
 store file.  This code uses a directory named "TEST" for
 the content, either in the NSApplicationSupportDirectory location or (if the
 former cannot be found), the system's temporary directory.
 */

+ (NSString *)applicationSupportDirectory {
	
    NSArray * paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString * basePath = ([paths count] > 0) ? paths.firstObject : NSTemporaryDirectory();
    return [basePath stringByAppendingPathComponent:@"File Comparator"];
}


/**
 Creates, retains, and returns the managed object model for the application 
 by merging all of the models found in the application bundle.
 */

+ (NSManagedObjectModel *)managedObjectModel
{
    if (managedObjectModel)
		return managedObjectModel;
	
	NSURL * modelURL = [[NSBundle mainBundle] URLForResource:@"OptionItem" withExtension:@"mom"];
    managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return managedObjectModel;
}


/**
 Returns the persistent store coordinator for the application.  This 
 implementation will create and return a coordinator, having added the 
 store for the application to it.  (The directory for the store is created, 
 if necessary.)
 */

+ (NSPersistentStoreCoordinator *) persistentStoreCoordinator
{
    if (persistentStoreCoordinator)
		return persistentStoreCoordinator;
	
    NSManagedObjectModel * model = [[self class] managedObjectModel];
    if (!model) {
        NSAssert(NO, @"Managed object model is nil");
        NSDebugLog(@"%@:%@ No model to generate a store from", [self class], NSStringFromSelector(_cmd));
        return nil;
    }
	
	NSError * error = nil;
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *applicationSupportDirectory = [[self class] applicationSupportDirectory];
	
	if (![fileManager fileExistsAtPath:applicationSupportDirectory isDirectory:NULL] ) {
		if (![fileManager createDirectoryAtPath:applicationSupportDirectory withIntermediateDirectories:NO attributes:nil error:&error]) {
			[NSException raise:@"FileComparatorException" format:@"Failed to create App Support directory %@ : %@", applicationSupportDirectory, error];
			NSDebugLog(@"Error creating application support directory at %@ : %@",applicationSupportDirectory,error);
			return nil;
		}
	}
	
	NSString * path = [applicationSupportDirectory stringByAppendingPathComponent:@"compare-options-v1.2"];
	if (![fileManager fileExistsAtPath:path]) {
		NSString * bundleFile = [[NSBundle mainBundle] pathForResource:@"options-v1.2" ofType:nil];
		[fileManager copyItemAtPath:bundleFile toPath:path error:NULL];
	}
	
	persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
	
	NSURL * url = [NSURL fileURLWithPath:path];
	
	NSString * storeType = NSXMLStoreType;
	NSPersistentStore * persistentStore = [persistentStoreCoordinator addPersistentStoreWithType:storeType 
																				   configuration:nil 
																							 URL:url 
																						 options:nil 
																						   error:&error];
    if (!persistentStore) {
        [[NSApplication sharedApplication] presentError:error];
		persistentStoreCoordinator = nil;
		
        return nil;
    }    
	
    return persistentStoreCoordinator;
}

/**
 Returns the managed object context for the application (which is already
 bound to the persistent store coordinator for the application.) 
 */

+ (NSManagedObjectContext *) managedObjectContext
{
    if (managedObjectContext) {
		return managedObjectContext;
	}
	
    NSPersistentStoreCoordinator * coordinator = [[self class] persistentStoreCoordinator];
    if (!coordinator) {
        NSMutableDictionary * dict = [NSMutableDictionary dictionary];
        [dict setValue:@"Failed to initialize the store" forKey:NSLocalizedDescriptionKey];
        [dict setValue:@"There was an error building up the data file." forKey:NSLocalizedFailureReasonErrorKey];
		// @TODO: Change code and error domain
        NSError *error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        [[NSApplication sharedApplication] presentError:error];
		
        return nil;
    }
	
	managedObjectContext = [[NSManagedObjectContext alloc] init];
		[managedObjectContext setPersistentStoreCoordinator:coordinator];
		
		[managedObjectContext setUndoManager:nil];
	
    return managedObjectContext;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<OptionItem: 0x%x, name: %@, index: %@, %@>", (unsigned int)self, [self localizedName], self.index, ([self.selected boolValue])? @"selected": @"not selected"];
}

@end

//
//  OptionItem.h
//  Comparator
//
//  Created by Max on 14/02/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class OptionItem;

@interface Section : NSManagedObject
{
	NSArray * options, * groups;
}

@property (nonatomic, strong) NSString * name;
@property (nonatomic, strong) NSString * descriptionString;
@property (nonatomic, strong) NSNumber * index;

+ (NSArray *)sections;

- (id)initWithName:(NSString *)name;

- (NSArray *)groups;

- (NSArray *)allOptions;
- (OptionItem *)optionItemWithIndex:(NSInteger)index;

- (NSArray *)optionsAtRow:(NSInteger)row;

- (NSInteger)numberOfRow;

- (NSString *)localizedDescriptionString;

@end


@interface Group : NSManagedObject
{
	NSArray * options;
}

@property (nonatomic, strong) NSString * name;
@property (nonatomic, strong) NSNumber * index;

- (id)initWithSection:(Section *)section;
- (NSArray *)options;

- (OptionItem *)optionItemWithIndex:(NSInteger)index;
- (NSArray *)optionsAtRow:(NSInteger)row;
- (NSInteger)numberOfRow;

@end


@interface OptionItem : NSManagedObject
{
}

@property (nonatomic, strong) NSNumber * selected;
@property (nonatomic, strong) NSString * identifier, * descriptionString;
@property (nonatomic, strong) NSNumber * index;

+ (NSString *)localizedNameForOption:(NSString *)option;
+ (NSString *)localizedShortDescriptionForOption:(NSString *)option;
+ (NSString *)localizedDescriptionForOption:(NSString *)option;

+ (NSManagedObjectContext *)managedObjectContext;

- (id)initWithGroup:(Group *)group;

- (NSString *)localizedName;
- (NSString *)localizedDescription;

+ (void)save;
+ (void)rollback;

+ (NSArray *)items;
+ (NSArray *)checkedItems;

+ (BOOL)includeHiddenItems;
+ (BOOL)includeBundleContent;

+ (BOOL)useAutomaticComparaison;
+ (BOOL)shouldFindBrokenAliases;
+ (BOOL)shouldFindEmptyItems;

// Private
+ (void)async_save;
+ (void)async_rollback;

@end

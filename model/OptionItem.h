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

- (instancetype)initWithName:(NSString *)name;

@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSArray *groups;

@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSArray *allOptions;
- (OptionItem *)optionItemWithIndex:(NSInteger)index;

- (NSArray *)optionsAtRow:(NSInteger)row;

@property (NS_NONATOMIC_IOSONLY, readonly) NSInteger numberOfRow;

@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *localizedDescriptionString;

@end


@interface Group : NSManagedObject
{
	NSArray * options;
}

@property (nonatomic, strong) NSString * name;
@property (nonatomic, strong) NSNumber * index;

- (instancetype)initWithSection:(Section *)section;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSArray *options;

- (OptionItem *)optionItemWithIndex:(NSInteger)index;
- (NSArray *)optionsAtRow:(NSInteger)row;
@property (NS_NONATOMIC_IOSONLY, readonly) NSInteger numberOfRow;

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

- (instancetype)initWithGroup:(Group *)group;

@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *localizedName;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *localizedDescription;

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

//
//  FileInformations.h
//  Comparator
//
//  Created by Max on 20/12/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kFileInformationsDidFinishNotification @"FileInformationsDidFinishNotification"

@interface FileInformations : NSObject

+ (void)fetchPropertiesForItemsAtPath:(NSString *)path;
+ (NSArray *)propertiesForSubItemsAtPath:(NSString *)folderPath;

@end

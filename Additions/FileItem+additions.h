//
//  FileItem+additions.h
//  Comparator
//
//  Created by Maxime on 10/01/13.
//  Copyright (c) 2013 Lis@cintosh. All rights reserved.
//

#import "FileItem.h"

@interface FileItem (additions)

@property (NS_NONATOMIC_IOSONLY, readonly) BOOL moveToTrash;

- (BOOL)moveToFolder:(NSString *)folderPath;

- (BOOL)moveToPath:(NSString *)newPath;
- (BOOL)moveToURL:(NSURL *)newURL;

- (void)removeFromContext;

@end

//
//  MovieItem.h
//  Comparator
//
//  Created by Max on 14/03/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "FileItem.h"

@interface MovieItem : FileItem

- (void)getInfoFromOptionsItems:(NSArray *)options;
- (void)getInfoFromOptions:(NSArray *)options;

- (BOOL)isEqualTo:(MovieItem *)anotherItem options:(NSArray *)options;

@end

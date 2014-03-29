//
//  AudioItem.h
//  Comparator
//
//  Created by Max on 14/03/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "FileItem.h"

#import <AudioToolbox/AudioToolbox.h>

@interface AudioItem : FileItem
{
	@private
	CFDictionaryRef _attributes;
}

@property (nonatomic, strong) NSString * album, * approximateDuration, * artist, * channelLayout, * comments, * composer, * copyright, * encodingApplication, * genre, * keySignature, * lyriscist, * nominalBitRate, * recorderDate, * sourceBitDepth, * sourceEncoder, * tempo, * timeSignature, * title, * trackNumber, * year;

+ (BOOL)canCompareWithOption:(NSString *)option;

+ (NSArray *)propertiesForOptions:(NSArray *)options;

+ (id)valueForOption:(NSString *)option fromItem:(AudioItem *)item;

- (void)getInfoFromOptions:(NSArray *)options;

- (BOOL)isEqualTo:(AudioItem *)anotherItem options:(NSArray *)options;

@end

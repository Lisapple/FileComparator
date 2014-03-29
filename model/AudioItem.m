//
//  AudioItem.m
//  Comparator
//
//  Created by Max on 14/03/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "AudioItem.h"

@implementation AudioItem

@dynamic album, approximateDuration, artist, channelLayout, comments, composer, copyright, encodingApplication, genre, keySignature, lyriscist, nominalBitRate, recorderDate, sourceBitDepth, sourceEncoder, tempo, timeSignature, title, trackNumber, year;

static NSArray * _availableOptions = nil;
+ (void)initialize
{
	static BOOL initialized = NO;
	if (!initialized) {
		_availableOptions = [[NSArray alloc] initWithObjects:@"AudioItemCompareAlbum", @"AudioItemCompareApproximateDuration", @"AudioItemCompareArtist", @"AudioItemCompareChannelLayout", @"AudioItemCompareComments", @"AudioItemCompareComposer", @"AudioItemCompareCopyright", @"AudioItemCompareEncodingApplication", @"AudioItemCompareGenre", @"AudioItemCompareKeySignature", @"AudioItemCompareLyricist", @"AudioItemCompareNominalBitRate", @"AudioItemCompareRecorderDate", @"AudioItemCompareSourceBitDepth", @"AudioItemCompareSourceEncoder", @"AudioItemCompareTempo", @"AudioItemCompareTimeSignature", @"AudioItemCompareTitle", @"AudioItemCompareTrackNumber", @"AudioItemCompareYear", nil];
		
		initialized = YES;
	}
}

+ (BOOL)canCompareWithOption:(NSString *)option
{
	NSString * baseOptionString = @"AudioItemCompare";
	return (option.length > baseOptionString.length && [[option substringToIndex:baseOptionString.length] isEqualToString:baseOptionString]);
	
	//return ([_availableOptions containsObject:option]);
}

+ (NSArray *)availableOptions
{
	return _availableOptions;
}

+ (NSArray *)propertiesForOptions:(NSArray *)options
{
	NSMutableArray * properties = [[NSMutableArray alloc] initWithCapacity:options.count];
	[properties addObjectsFromArray:[FileItem propertiesForOptions:options]];
	
	for (NSString * option in options) {
		
		if ([option isEqualToString:@"AudioItemCompareAlbum"]) {
			[properties addObject:@"album"];
		} else if ([option isEqualToString:@"AudioItemCompareApproximateDuration"]) {
			[properties addObject:@"approximateDuration"];
		} else if ([option isEqualToString:@"AudioItemCompareArtist"]) {
			[properties addObject:@"artist"];
		} else if ([option isEqualToString:@"AudioItemCompareChannelLayout"]) {
			[properties addObject:@"channelLayout"];
		} else if ([option isEqualToString:@"AudioItemCompareComments"]) {
			[properties addObject:@"comments"];
		} else if ([option isEqualToString:@"AudioItemCompareComposer"]) {
			[properties addObject:@"composer"];
		} else if ([option isEqualToString:@"AudioItemCompareCopyright"]) {
			[properties addObject:@"copyright"];
		} else if ([option isEqualToString:@"AudioItemCompareEncodingApplication"]) {
			[properties addObject:@"encodingApplication"];
		} else if ([option isEqualToString:@"AudioItemCompareGenre"]) {
			[properties addObject:@"genre"];
		} else if ([option isEqualToString:@"AudioItemCompareKeySignature"]) {
			[properties addObject:@"keySignature"];
		} else if ([option isEqualToString:@"AudioItemCompareLyricist"]) {
			[properties addObject:@"lyriscist"];
		} else if ([option isEqualToString:@"AudioItemCompareNominalBitRate"]) {
			[properties addObject:@"nominalBitRate"];
		} else if ([option isEqualToString:@"AudioItemCompareRecorderDate"]) {
			[properties addObject:@"recorderDate"];
		} else if ([option isEqualToString:@"AudioItemCompareSourceBitDepth"]) {
			[properties addObject:@"sourceBitDepth"];
		} else if ([option isEqualToString:@"AudioItemCompareSourceEncoder"]) {
			[properties addObject:@"sourceEncoder"];
		} else if ([option isEqualToString:@"AudioItemCompareTempo"]) {
			[properties addObject:@"tempo"];
		} else if ([option isEqualToString:@"AudioItemCompareTimeSignature"]) {
			[properties addObject:@"timeSignature"];
		} else if ([option isEqualToString:@"AudioItemCompareTitle"]) {
			[properties addObject:@"title"];
		} else if ([option isEqualToString:@"AudioItemCompareTrackNumber"]) {
			[properties addObject:@"trackNumber"];
		} else if ([option isEqualToString:@"AudioItemCompareYear"]) {
			[properties addObject:@"year"];
		}
	}
	return (NSArray *)properties;
}

+ (id)valueForOption:(NSString *)option fromItem:(AudioItem *)item
{
	if ([option isEqualToString:@"AudioItemCompareAlbum"]) {
		return item.album;
	} else if ([option isEqualToString:@"AudioItemCompareApproximateDuration"]) {
		return item.approximateDuration;
	} else if ([option isEqualToString:@"AudioItemCompareArtist"]) {
		return item.artist;
	} else if ([option isEqualToString:@"AudioItemCompareChannelLayout"]) {
		return item.channelLayout;
	} else if ([option isEqualToString:@"AudioItemCompareComments"]) {
		return item.comments;
	} else if ([option isEqualToString:@"AudioItemCompareComposer"]) {
		return item.composer;
	} else if ([option isEqualToString:@"AudioItemCompareCopyright"]) {
		return item.copyright;
	} else if ([option isEqualToString:@"AudioItemCompareEncodingApplication"]) {
		return item.encodingApplication;
	} else if ([option isEqualToString:@"AudioItemCompareGenre"]) {
		return item.genre;
	} else if ([option isEqualToString:@"AudioItemCompareKeySignature"]) {
		return item.keySignature;
	} else if ([option isEqualToString:@"AudioItemCompareLyricist"]) {
		return item.lyriscist;
	} else if ([option isEqualToString:@"AudioItemCompareNominalBitRate"]) {
		return item.nominalBitRate;
	} else if ([option isEqualToString:@"AudioItemCompareRecorderDate"]) {
		return item.recorderDate;
	} else if ([option isEqualToString:@"AudioItemCompareSourceBitDepth"]) {
		return item.sourceBitDepth;
	} else if ([option isEqualToString:@"AudioItemCompareSourceEncoder"]) {
		return item.sourceEncoder;
	} else if ([option isEqualToString:@"AudioItemCompareTempo"]) {
		return item.tempo;
	} else if ([option isEqualToString:@"AudioItemCompareTimeSignature"]) {
		return item.timeSignature;
	} else if ([option isEqualToString:@"AudioItemCompareTitle"]) {
		return item.title;
	} else if ([option isEqualToString:@"AudioItemCompareTrackNumber"]) {
		return item.trackNumber;
	} else if ([option isEqualToString:@"AudioItemCompareYear"]) {
		return item.year;
	}
	
	return nil;
}

- (NSManagedObject *)group
{
	return [self valueForKey:@"audioGroups"];
}

- (void)getInfoFromOptions:(NSArray *)options
{
	/* Check if "options" has audio specific options (before fetching informations from the file) */
	BOOL hasAudioOptions = NO;
	for (NSString * option in options) {
		if ([AudioItem canCompareWithOption:option]) {
			hasAudioOptions = YES;
			break;
		}
	}
	
	if (hasAudioOptions) {
		NSURL * fileURL = [NSURL fileURLWithPath:self.path];
		
		AudioFileID audioID;
		OSStatus err = AudioFileOpenURL((__bridge CFURLRef)fileURL, kAudioFileReadPermission, 0, &audioID);
		
		if (err) { NSLog(@"err: %d", err); }
		
		_attributes = NULL;
		/* => used
		 UInt32 dataSize = sizeof(_attributes);
		 err = AudioFileGetProperty(audioID, kAudioFilePropertyInfoDictionary, &dataSize, &_attributes);
		 */
		err = AudioFileGetProperty(audioID, kAudioFilePropertyInfoDictionary, NULL, &_attributes);
		
		if (err) { NSLog(@"err: %d", err); }
		
		if (_attributes) {
			CFRetain(_attributes);
			
			for (NSString * option in options) {
				[self getOptionInfo:option];
			}
		} else {
			NSMutableArray * fileOptions = [options mutableCopy];
			[fileOptions removeObjectsInArray:[AudioItem availableOptions]];
			[super getInfoFromOptions:fileOptions];
		}
		AudioFileClose(audioID);
	} else {
		/* Just get informations without fetching audio file properties */
		for (NSString * option in options) {
			[super getOptionInfo:option];
		}
	}
}

- (void)getOptionInfo:(NSString *)option
{
	if (!_attributes) {
		NSURL * fileURL = [NSURL fileURLWithPath:self.path];
		
		AudioFileID audioID;
		OSStatus err = AudioFileOpenURL((__bridge CFURLRef)fileURL, kAudioFileReadPermission, 0, &audioID);
		
		// @TODO: return on error
		if (err) { NSLog(@"err: %d", err); }
		
		_attributes = NULL;
		UInt32 dataSize = sizeof(_attributes);
		err = AudioFileGetProperty(audioID, kAudioFilePropertyInfoDictionary, &dataSize, &_attributes);
		
		if (err) { NSLog(@"err: %d", err); }
		
		if (!_attributes)// If not attributes, this is probably not an audio file
			return ;
		
		CFRetain(_attributes);
	}
	
	if ([option isEqualToString:@"AudioItemCompareAlbum"]) {
		
		if (!self.album) self.album = (NSString *)CFDictionaryGetValue(_attributes, CFSTR(kAFInfoDictionary_Album));
		
	} else if ([option isEqualToString:@"AudioItemCompareApproximateDuration"]) {
		
		if (!self.approximateDuration) self.approximateDuration = (NSString *)CFDictionaryGetValue(_attributes, CFSTR(kAFInfoDictionary_ApproximateDurationInSeconds));
		
	} else if ([option isEqualToString:@"AudioItemCompareArtist"]) {
		
		if (!self.artist) self.artist = (NSString *)CFDictionaryGetValue(_attributes, CFSTR(kAFInfoDictionary_Artist));
		
	} else if ([option isEqualToString:@"AudioItemCompareChannelLayout"]) {
		
		if (!self.channelLayout) self.channelLayout = (NSString *)CFDictionaryGetValue(_attributes, CFSTR(kAFInfoDictionary_ChannelLayout));
		
	} else if ([option isEqualToString:@"AudioItemCompareComments"]) {
		
		if (!self.comments) self.comments = (NSString *)CFDictionaryGetValue(_attributes, CFSTR(kAFInfoDictionary_Comments));
		
	} else if ([option isEqualToString:@"AudioItemCompareComposer"]) {
		
		if (!self.composer) self.composer = (NSString *)CFDictionaryGetValue(_attributes, CFSTR(kAFInfoDictionary_Composer));
		
	} else if ([option isEqualToString:@"AudioItemCompareCopyright"]) {
		
		if (!self.copyright) self.copyright = (NSString *)CFDictionaryGetValue(_attributes, CFSTR(kAFInfoDictionary_Copyright));
		
	} else if ([option isEqualToString:@"AudioItemCompareEncodingApplication"]) {
		
		if (!self.encodingApplication) self.encodingApplication = (NSString *)CFDictionaryGetValue(_attributes, CFSTR(kAFInfoDictionary_EncodingApplication));
		
	} else if ([option isEqualToString:@"AudioItemCompareGenre"]) {
		
		if (!self.genre) self.genre = (NSString *)CFDictionaryGetValue(_attributes, CFSTR(kAFInfoDictionary_Genre));
		
	} else if ([option isEqualToString:@"AudioItemCompareKeySignature"]) {
		
		if (!self.keySignature) self.keySignature = (NSString *)CFDictionaryGetValue(_attributes, CFSTR(kAFInfoDictionary_KeySignature));
		
	} else if ([option isEqualToString:@"AudioItemCompareLyricist"]) {
		
		if (!self.lyriscist) self.lyriscist = (NSString *)CFDictionaryGetValue(_attributes, CFSTR(kAFInfoDictionary_Lyricist));
		
	} else if ([option isEqualToString:@"AudioItemCompareNominalBitRate"]) {
		
		if (!self.nominalBitRate) self.nominalBitRate = (NSString *)CFDictionaryGetValue(_attributes, CFSTR(kAFInfoDictionary_NominalBitRate));
		
	} else if ([option isEqualToString:@"AudioItemCompareRecorderDate"]) {
		
		if (!self.recorderDate) self.recorderDate = (NSString *)CFDictionaryGetValue(_attributes, CFSTR(kAFInfoDictionary_RecordedDate));
		
	} else if ([option isEqualToString:@"AudioItemCompareSourceBitDepth"]) {
		
		if (!self.sourceBitDepth) self.sourceBitDepth = (NSString *)CFDictionaryGetValue(_attributes, CFSTR(kAFInfoDictionary_SourceBitDepth));
		
	} else if ([option isEqualToString:@"AudioItemCompareSourceEncoder"]) {
		
		if (!self.sourceEncoder) self.sourceEncoder = (NSString *)CFDictionaryGetValue(_attributes, CFSTR(kAFInfoDictionary_SourceEncoder));
		
	} else if ([option isEqualToString:@"AudioItemCompareTempo"]) {
		
		if (!self.tempo) self.tempo = (NSString *)CFDictionaryGetValue(_attributes, CFSTR(kAFInfoDictionary_Tempo));
		
	} else if ([option isEqualToString:@"AudioItemCompareTimeSignature"]) {
		
		if (!self.timeSignature) self.timeSignature = (NSString *)CFDictionaryGetValue(_attributes, CFSTR(kAFInfoDictionary_TimeSignature));
		
	} else if ([option isEqualToString:@"AudioItemCompareTitle"]) {
		
		if (!self.title) self.title = (NSString *)CFDictionaryGetValue(_attributes, CFSTR(kAFInfoDictionary_Title));
		
	} else if ([option isEqualToString:@"AudioItemCompareTrackNumber"]) {
		
		if (!self.trackNumber) self.trackNumber = (NSString *)CFDictionaryGetValue(_attributes, CFSTR(kAFInfoDictionary_TrackNumber));
		
	} else if ([option isEqualToString:@"AudioItemCompareYear"]) {
		
		if (!self.year) self.year = (NSString *)CFDictionaryGetValue(_attributes, CFSTR(kAFInfoDictionary_Year));
		
	} else {
		[super getOptionInfo:option];
	}
}

- (BOOL)isEqualTo:(AudioItem *)anotherItem option:(NSString *)option
{
	if ([option isEqualToString:@"AudioItemCompareAlbum"]) {
		
		return ([self.album isEqualToString:anotherItem.album]);
		
	} else if ([option isEqualToString:@"AudioItemCompareApproximateDuration"]) {
		
		return ([self.approximateDuration isEqualToString:anotherItem.approximateDuration]);
		
	} else if ([option isEqualToString:@"AudioItemCompareArtist"]) {
		
		return ([self.artist isEqualToString:anotherItem.artist]);
		
	} else if ([option isEqualToString:@"AudioItemCompareChannelLayout"]) {
		
		return ([self.channelLayout isEqualToString:anotherItem.channelLayout]);
		
	} else if ([option isEqualToString:@"AudioItemCompareComments"]) {
		
		return ([self.comments isEqualToString:anotherItem.comments]);
		
	} else if ([option isEqualToString:@"AudioItemCompareComposer"]) {
		
		return ([self.composer isEqualToString:anotherItem.composer]);
		
	} else if ([option isEqualToString:@"AudioItemCompareCopyright"]) {
		
		return ([self.copyright isEqualToString:anotherItem.copyright]);
		
	} else if ([option isEqualToString:@"AudioItemCompareEncodingApplication"]) {
		
		return ([self.encodingApplication isEqualToString:anotherItem.encodingApplication]);
		
	} else if ([option isEqualToString:@"AudioItemCompareGenre"]) {
		
		return ([self.genre isEqualToString:anotherItem.genre]);
		
	} else if ([option isEqualToString:@"AudioItemCompareKeySignature"]) {
		
		return ([self.keySignature isEqualToString:anotherItem.keySignature]);
		
	} else if ([option isEqualToString:@"AudioItemCompareLyricist"]) {
		
		return ([self.lyriscist isEqualToString:anotherItem.lyriscist]);
		
	} else if ([option isEqualToString:@"AudioItemCompareNominalBitRate"]) {
		
		return ([self.nominalBitRate isEqualToString:anotherItem.nominalBitRate]);
		
	} else if ([option isEqualToString:@"AudioItemCompareRecorderDate"]) {
		
		return ([self.recorderDate isEqualToString:anotherItem.recorderDate]);
		
	} else if ([option isEqualToString:@"AudioItemCompareSourceBitDepth"]) {
		
		return ([self.sourceBitDepth isEqualToString:anotherItem.sourceBitDepth]);
		
	} else if ([option isEqualToString:@"AudioItemCompareSourceEncoder"]) {
		
		return ([self.sourceEncoder isEqualToString:anotherItem.sourceEncoder]);
		
	} else if ([option isEqualToString:@"AudioItemCompareTempo"]) {
		
		return ([self.tempo isEqualToString:anotherItem.tempo]);
		
	} else if ([option isEqualToString:@"AudioItemCompareTimeSignature"]) {
		
		return ([self.timeSignature isEqualToString:anotherItem.timeSignature]);
		
	} else if ([option isEqualToString:@"AudioItemCompareTitle"]) {
		
		return ([self.title isEqualToString:anotherItem.title]);
		
	} else if ([option isEqualToString:@"AudioItemCompareTrackNumber"]) {
		
		return ([self.trackNumber isEqualToString:anotherItem.trackNumber]);
		
	} else if ([option isEqualToString:@"AudioItemCompareYear"]) {
		
		return ([self.year isEqualToString:anotherItem.year]);
		
	} else {
		[NSException raise:@"ImageItemException" format:@"could not compare items with \"%@\" option", option];
	}
	
	return NO;
}

- (BOOL)isEqualTo:(AudioItem *)anotherItem options:(NSArray *)options
{
	//if ([anotherItem isKindOfClass:[self class]] || [anotherItem isKindOfClass:[NSClassFromString(@"AudioItemGroup") class]]) {
		for (NSString * option in options) { // For each option,
			if ([[self class] canCompareWithOption:option]) { // If option is a ImageItem specific option,
				if (![self isEqualTo:anotherItem option:option]) { // Compare image items with option
					return NO;
				}
			} else {
				if (![super isEqualTo:anotherItem options:[NSArray arrayWithObject:option]]) {// Else, compare with FileItem class
					return NO;
				}
			}
		}
	//}
	/*
	 if ([anotherItem isKindOfClass:[self class]]) {// If we compare only two image files, compare with current options
	 
	 for (NSString * option in options) { // For each option,
	 if ([self canCompareWithOption:option]) { // If option is a ImageItem specific option,
	 if (![self isEqualTo:anotherItem option:option]) { // Compare image items with option
	 return NO;
	 }
	 } else {
	 if (![super isEqualTo:anotherItem options:[NSArray arrayWithObject:option]]) {// Else, compare with FileItem class
	 return NO;
	 }
	 }
	 }
	 
	 } else {// Else, compare items as file (mother class)
	 return [super isEqualTo:anotherItem options:options];
	 }
	 */
	
	return YES;
}

- (NSDictionary *)itemValues
{
	NSMutableDictionary * attributes = [NSMutableDictionary dictionaryWithDictionary:[super itemValues]];
	
	NSURL * fileURL = [NSURL fileURLWithPath:self.path];
	
	AudioFileID audioID;
	OSStatus err = AudioFileOpenURL((__bridge CFURLRef)fileURL, kAudioFileReadPermission, 0, &audioID);
	
	if (err) { NSLog(@"err: %d", err); }
	
	_attributes = NULL;
	UInt32 dataSize = sizeof(_attributes);
	err = AudioFileGetProperty(audioID, kAudioFilePropertyInfoDictionary, &dataSize, &_attributes);
	
	if (err) { NSLog(@"err: %d", err); }
	
	if (_attributes) {
		CFRetain(_attributes);
		
		NSArray * availableOptions = [[self class] availableOptions];
		for (NSString * option in availableOptions) {
			[self getOptionInfo:option];
			id value = [self valueForOption:option];
			if (value) {
				[attributes setObject:value forKey:option];
			}
		}
	}
	
	AudioFileClose(audioID);
	
	return attributes;
}

- (NSDictionary *)commonsValuesWithItem:(AudioItem *)anotherItem
{
	NSMutableDictionary * commonValues = [NSMutableDictionary dictionaryWithCapacity:10];
	
	NSDictionary * itemValues = [self itemValues];
	NSDictionary * anotherItemValues = [anotherItem itemValues];
	for (NSString * key in [itemValues allKeys]) {
		id object = [itemValues objectForKey:key];
		id anotherObject = [anotherItemValues objectForKey:key];
		if ([object isEqualTo:anotherObject]) {
			[commonValues setObject:object forKey:key];
		}
	}
	
	return commonValues;
}






- (NSDictionary *)localizedItemValues
{
	NSMutableDictionary * attributes = [NSMutableDictionary dictionaryWithCapacity:3];
	
	NSArray * availableOptions = [AudioItem availableOptions];
	for (NSString * option in availableOptions) {
		[self getOptionInfo:option];
		
		id value = [self valueForOption:option];
		if (value)
			[attributes setObject:value forKey:option];
	}
	
	/*
	 NSArray * availableOptions = [ImageItem availableOptions];
	 for (NSString * option in availableOptions) {
	 [ImageItem getOptionInfo:option forItem:self];
	 
	 // @TODO: create a class function +[FileItem valueForItem:forOption:]
	 id value = [FileItem valueForOption:option fromItem:self];
	 id localizedValue = nil;
	 
	 if ([option isEqualToString:@"FileItemCompareUTI"]) {
	 localizedValue = [[NSWorkspace sharedWorkspace] localizedDescriptionForType:value];
	 } else if ([option isEqualToString:@"FileItemCompareCreationDate"]) {
	 NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
	 formatter.dateStyle = NSDateFormatterLongStyle;
	 formatter.timeStyle = NSDateFormatterShortStyle;
	 localizedValue = [formatter stringFromDate:value];
	 [formatter release];
	 } else if ([option isEqualToString:@"FileItemCompareLastModificationDate"]) {
	 NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
	 formatter.dateStyle = NSDateFormatterLongStyle;
	 formatter.timeStyle = NSDateFormatterShortStyle;
	 localizedValue = [formatter stringFromDate:value];
	 [formatter release];
	 } else if ([option isEqualToString:@"FileItemCompareSize"]) {
	 localizedValue = [NSString localizedStringForFileSize:[value doubleValue]];
	 } else if ([option isEqualToString:@"FileItemCompareUTI"]) {
	 localizedValue = [[NSWorkspace sharedWorkspace] localizedDescriptionForType:value];
	 } else {
	 localizedValue = [NSString stringWithFormat:@"%@", value];
	 }
	 
	 if (localizedValue) {
	 [attributes setObject:localizedValue forKey:option];
	 }
	 }
	 */
	
	NSDebugLog(@"%@", [super localizedItemValues]);
	[attributes addEntriesFromDictionary:[super localizedItemValues]];
	
	return attributes;
}

- (id)valueForOption:(NSString *)option
{
	if ([option isEqualToString:@"AudioItemCompareAlbum"]) {
		return self.album;
	} else if ([option isEqualToString:@"AudioItemCompareApproximateDuration"]) {
		return self.approximateDuration;
	} else if ([option isEqualToString:@"AudioItemCompareArtist"]) {
		return self.artist;
	} else if ([option isEqualToString:@"AudioItemCompareChannelLayout"]) {
		return self.channelLayout;
	} else if ([option isEqualToString:@"AudioItemCompareComments"]) {
		return self.comments;
	} else if ([option isEqualToString:@"AudioItemCompareComposer"]) {
		return self.composer;
	} else if ([option isEqualToString:@"AudioItemCompareCopyright"]) {
		return self.copyright;
	} else if ([option isEqualToString:@"AudioItemCompareEncodingApplication"]) {
		return self.encodingApplication;
	} else if ([option isEqualToString:@"AudioItemCompareGenre"]) {
		return self.genre;
	} else if ([option isEqualToString:@"AudioItemCompareKeySignature"]) {
		return self.keySignature;
	} else if ([option isEqualToString:@"AudioItemCompareLyricist"]) {
		return self.lyriscist;
	} else if ([option isEqualToString:@"AudioItemCompareNominalBitRate"]) {
		return self.nominalBitRate;
	} else if ([option isEqualToString:@"AudioItemCompareRecorderDate"]) {
		return self.recorderDate;
	} else if ([option isEqualToString:@"AudioItemCompareSourceBitDepth"]) {
		return self.sourceBitDepth;
	} else if ([option isEqualToString:@"AudioItemCompareSourceEncoder"]) {
		return self.sourceEncoder;
	} else if ([option isEqualToString:@"AudioItemCompareTempo"]) {
		return self.tempo;
	} else if ([option isEqualToString:@"AudioItemCompareTimeSignature"]) {
		return self.timeSignature;
	} else if ([option isEqualToString:@"AudioItemCompareTitle"]) {
		return self.title;
	} else if ([option isEqualToString:@"AudioItemCompareTrackNumber"]) {
		return self.trackNumber;
	} else if ([option isEqualToString:@"AudioItemCompareYear"]) {
		return self.year;
	} else {
		[super valueForOption:option];
	}
	
	return nil;
}

@end

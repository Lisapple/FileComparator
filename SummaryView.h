//
//  SummaryView.h
//  Comparator
//
//  Created by Max on 20/12/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import <AppKit/AppKit.h>

#import "PlaceholderLabel.h"

@interface SummaryView : NSView
{
	PlaceholderLabel * __strong numberOfDuplicatesLabel, * __strong totalSizeLabel;
}

@property (strong) IBOutlet PlaceholderLabel * numberOfDuplicatesLabel, * totalSizeLabel;

@end

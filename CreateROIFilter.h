//
//  CreateROIFilter.h
//  CreateROI
//
//  Created by rossetantoine on Wed Jun 09 2004.
//  Copyright (c) 2004 Antoine Rosset. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PluginFilter.h"
#import <AppKit/AppKit.h>

@interface CreateROIFilter : PluginFilter {
    // IB Outlets
    IBOutlet NSWindow *stepsWindow;
    IBOutlet NSTextField *txtStep1;
    IBOutlet NSTextField *txtStep2;
    IBOutlet NSButton *btnPerformCalculation;
    IBOutlet NSTextField *txtArea;
    IBOutlet NSTextField *txtRadius;
    
    // Misc
    NSUInteger curSlice;
    
}

// Fundamental methods
- (long) filterImage:(NSString*) menuName;
- (void) initPlugin;

// IB Actions
- (IBAction)performCalculation:(id)sender;

// Other methods
- (void) _initToolbarItems;

@end

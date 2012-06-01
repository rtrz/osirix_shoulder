//
//  CreateROIFilter.m
//  CreateROI
//
//  Created by rossetantoine on Wed Jun 09 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "CreateROIFilter.h"
#define PI 3.141592654

@implementation CreateROIFilter

- (long) filterImage:(NSString*) menuName
{
    // Show the steps window
    NSWindowController *_stepsWindow = [[NSWindowController alloc] initWithWindowNibName:@"StepsWindow"
                                                                                   owner:self];
    [_stepsWindow showWindow:self];
    
    // Disable the button and step 2
    [btnPerformCalculation setEnabled:false];
    [txtStep2 setTextColor:[NSColor grayColor]];

    // Determine number of ROIs
    curSlice = [[viewerController imageView] curImage];
    NSUInteger numROIs = [[[viewerController roiList] objectAtIndex:curSlice] count];
    
    // Do we have an ROI to work with?
    if(numROIs > 0) {
        
        // Enable step 2
        [txtStep2 setTextColor:[NSColor blackColor]];
        [txtStep1 setTextColor:[NSColor grayColor]];
        [btnPerformCalculation setEnabled:true];
    }
	
	return 0;
}

- (IBAction)performCalculation:(id)sender 
{
        
    // Get the area of the most recently create ROI
    NSUInteger roiIndex = [[[viewerController roiList] objectAtIndex:curSlice] count] - 1;
    ROI *roi = [[[viewerController roiList] objectAtIndex:curSlice] objectAtIndex:roiIndex];
    
    // Get the ROI dimensions
    float area = [roi roiArea];
    float radius = sqrtf(area/PI);
    
    // Display calculations in a modal dialog
    NSString *msgString = [NSString stringWithFormat:@"Area:   %.3f cm^2\nRadius: %.3f cm", area, radius];
    NSAlert *myAlert = [NSAlert alertWithMessageText:@"Measurements"
                                       defaultButton:@"Done"
                                     alternateButton:nil
                                         otherButton:nil
                           informativeTextWithFormat:msgString];
    [myAlert runModal];    
    
}

@end

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

- (void) initPlugin
{
    //[self _initToolbarItems];
}

static CreateROIFilter* DPIDocumentFilterInstance = nil;

- (void)_initToolbarItems {
    DPIDocumentFilterInstance = self;
    
    Method method;
    IMP imp;
    
    ///////////////////////
    // BrowserController //
    ///////////////////////
    
    Class BrowserControllerClass = NSClassFromString(@"BrowserController");
    
    // Get toolbarAllowedItemIdentifiers
    method = class_getInstanceMethod(BrowserControllerClass, @selector(toolbarAllowedItemIdentifiers:));
    imp = method_getImplementation(method);
    // Add our own identifier
    class_addMethod(BrowserControllerClass, @selector(_DPIDocumentBrowserToolbarAllowedItemIdentifiers:), imp, method_getTypeEncoding(method));
    method_setImplementation(method, class_getMethodImplementation([self class], @selector(_DPIDocumentBrowserToolbarAllowedItemIdentifiers:)));
    
    // Get toolbar
    method = class_getInstanceMethod(BrowserControllerClass, @selector(toolbar:itemForItemIdentifier:willBeInsertedIntoToolbar:));
    imp = method_getImplementation(method);
    // Add our own identifer
    class_addMethod(BrowserControllerClass, @selector(_DPIDocumentBrowserToolbar:itemForItemIdentifier:willBeInsertedIntoToolbar:), imp, method_getTypeEncoding(method));
    method_setImplementation(method, class_getMethodImplementation([self class], @selector(_DPIDocumentBrowserToolbar:itemForItemIdentifier:willBeInsertedIntoToolbar:)));
    
    //////////////////////
    // ViewerController //
    //////////////////////
    
    Class ViewerControllerClass = NSClassFromString(@"ViewerController");
    
    // Get toolbarAllowedItemIdentifiers
    method = class_getInstanceMethod(ViewerControllerClass, @selector(toolbarAllowedItemIdentifiers:));
    imp = method_getImplementation(method);
    // Add our own identifer
    class_addMethod(ViewerControllerClass, @selector(_DPIDocumentViewerToolbarAllowedItemIdentifiers:), imp, method_getTypeEncoding(method));
    method_setImplementation(method, class_getMethodImplementation([self class], @selector(_DPIDocumentViewerToolbarAllowedItemIdentifiers:)));
    
    // Get toolbar
    method = class_getInstanceMethod(ViewerControllerClass, @selector(toolbar:itemForItemIdentifier:willBeInsertedIntoToolbar:));
    imp = method_getImplementation(method);
    // Add our own identifer
    class_addMethod(ViewerControllerClass, @selector(_DPIDocumentViewerToolbar:itemForItemIdentifier:willBeInsertedIntoToolbar:), imp, method_getTypeEncoding(method));
    method_setImplementation(method, class_getMethodImplementation([self class], @selector(_DPIDocumentViewerToolbar:itemForItemIdentifier:willBeInsertedIntoToolbar:)));
}

static NSString* DPIDocumentToolbarItemIdentifier = @"DPIDocumentToolbarItem";

// Adds to allowed identifiers for browser and viewer controllers
-(NSArray*)_DPIDocumentBrowserToolbarAllowedItemIdentifiers:(NSToolbar*)toolbar {
    return [[self _DPIDocumentBrowserToolbarAllowedItemIdentifiers:toolbar] arrayByAddingObject:DPIDocumentToolbarItemIdentifier];
}
-(NSArray*)_DPIDocumentViewerToolbarAllowedItemIdentifiers:(NSToolbar*)toolbar {
    return [[self _DPIDocumentViewerToolbarAllowedItemIdentifiers:toolbar] arrayByAddingObject:DPIDocumentToolbarItemIdentifier];
}

// Adds items to browser and viewer controller toolbars?
-(NSToolbarItem*)_DPIDocumentViewerToolbar:(NSToolbar*)toolbar itemForItemIdentifier:(NSString*)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag {
    NSToolbarItem* item = [DPIDocumentFilterInstance _DPIDocumentToolbar:toolbar itemForItemIdentifier:itemIdentifier willBeInsertedIntoToolbar:flag];
    if (item) return item;
    return [self _DPIDocumentViewerToolbar:toolbar itemForItemIdentifier:itemIdentifier willBeInsertedIntoToolbar:flag];
}
-(NSToolbarItem*)_DPIDocumentBrowserToolbar:(NSToolbar*)toolbar itemForItemIdentifier:(NSString*)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag {
    NSToolbarItem* item = [DPIDocumentFilterInstance _DPIDocumentToolbar:toolbar itemForItemIdentifier:itemIdentifier willBeInsertedIntoToolbar:flag];
    if (item) return item;
    return [self _DPIDocumentBrowserToolbar:toolbar itemForItemIdentifier:itemIdentifier willBeInsertedIntoToolbar:flag];
}

-(NSToolbarItem*)_DPIDocumentToolbar:(NSToolbar*)toolbar itemForItemIdentifier:(NSString*)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag {
    //static NSString* DPIDocumentIconFilePath = [[[NSBundle bundleForClass:[DPIDocumentFilter class]] pathForImageResource:@"DPIDocument"] retain];
    
    if ([itemIdentifier isEqualToString:DPIDocumentToolbarItemIdentifier]) {
        NSToolbarItem* item = [[[NSToolbarItem alloc] initWithItemIdentifier:DPIDocumentToolbarItemIdentifier] autorelease];
        item.image = nil; //[[NSImage alloc] initWithContentsOfFile:DPIDocumentIconFilePath];
        item.minSize = item.image.size;
        item.label = item.paletteLabel = NSLocalizedString(@"Rapports Xplore", @"Name of toolbar item");
        item.target = DPIDocumentFilterInstance;
        item.action = @selector(_toolbarItemAction:);
        return item;
    }
    
    return nil;
}

-(void)_toolbarItemAction:(NSToolbarItem*)sender {
    if ([sender.toolbar.delegate isKindOfClass:[NSWindowController class]])
        [self _processWithWindowController:(NSWindowController*)sender.toolbar.delegate];
    else NSLog(@"Warning: the toolbar delegate is not of type NSWindowController as expected, so the DPIDocument plugin cannot proceed.");
}

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
    
    DCMPix *dcm = [[viewerController pixList]objectAtIndex:curSlice];
    
    // Create the outer circle ROI
    NSPoint outerPt = NSMakePoint(0, 0);
    NSSize outerSz = NSMakeSize(100, 100);
    NSRect outerRect;
    outerRect.origin = outerPt;
    outerRect.size = outerSz;
    ROI *outerROI = [viewerController newROI:tOval];
    [outerROI setROIRect:outerRect];
    [outerROI setColor:(RGBColor){65535,0,0}]; //red
    [outerROI setThickness:3];
    [outerROI setName:[NSString stringWithFormat:@"Outer"]];

    // Create the inner circle ROI
    NSPoint innerPt = NSMakePoint(0, 0);
    NSSize innerSz = NSMakeSize(75, 75);
    NSRect innerRect;
    innerRect.origin = innerPt;
    innerRect.size = innerSz;
    ROI *innerROI = [viewerController newROI:tOval];
    [innerROI setROIRect:innerRect];
    [innerROI setColor:(RGBColor){0,0,65535}]; //blue
    [innerROI setThickness:3];
    [innerROI setName:[NSString stringWithFormat:@"Inner"]];
    
    // Create the chord that will interesect the outer circle
    // and lie tangent to the inner circle
    ROI *chordROI = [viewerController newROI:tMesure];
    NSMutableArray *chordPts = [chordROI points];
    [chordPts addObject: [viewerController newPoint:0 : 0]];
    [chordPts addObject: [viewerController newPoint:100: 0]];
    
    // Add ROIs to the current slice
    [[[viewerController roiList]objectAtIndex:curSlice]addObject:chordROI];
    [[[viewerController roiList]objectAtIndex:curSlice]addObject:outerROI];
    [[[viewerController roiList]objectAtIndex:curSlice]addObject:innerROI];
    
    
    [viewerController setROIToolTag:tArrow];
    
    [btnPerformCalculation setEnabled:true];
    
	
	return 0;
}

- (IBAction)performCalculation:(id)sender 
{
        
    // Get the area of the most recently create ROI
    NSUInteger roiIndex = [[[viewerController roiList] objectAtIndex:curSlice] count] - 1;
    
    ROI *r1 = [[[viewerController roiList] objectAtIndex:curSlice] objectAtIndex:roiIndex];
    ROI *r2 = [[[viewerController roiList] objectAtIndex:curSlice] objectAtIndex:(roiIndex - 1)]; 
    ROI *r3 = [[[viewerController roiList] objectAtIndex:curSlice] objectAtIndex:(roiIndex - 2)];
    ROI *roi1, *roi2, *roiChord; // roi2: outer circle, roi1: inner circle
    
    // The ROI array gets mixed up, so we need to sort through it
    if([r3 type] == tMesure) {
        roiChord = r3;
        
        if([r2 roiArea] > [r1 roiArea]) {
            roi2 = r2;
            roi1 = r1;
        } else { 
            roi2 = r1;
            roi1 = r2;
        }
    } else if([r2 type] == tMesure) {
        roiChord = r2;
        
        if([r3 roiArea] > [r1 roiArea]) {
            roi2 = r3;
            roi1 = r1;
        } else { 
            roi2 = r1;
            roi1 = r3;
        }
    } else {
        roiChord = r1;
        
        if([r3 roiArea] > [r2 roiArea]) {
            roi2 = r3;
            roi1 = r2;
        } else { 
            roi2 = r2;
            roi1 = r3;
        }
    }
    

    DCMPix *dcm = [[viewerController pixList]objectAtIndex:curSlice];
    
    NSString *msgString;
    NSAlert *myAlert;

    float outerROIradius; //(in pixels)
    
    float area1, area2;
    float radiusB, radiusA;
    float percentageBoneLoss;
    
    area1 = [roi1 roiArea];
    area2 = [roi2 roiArea];
    
    //if(area2 > area1) {
        radiusB = sqrtf(area2/PI);    
        radiusA = sqrtf(area1/PI);
        outerROIradius = sqrtf(area2 * 100 / [dcm pixelSpacingX] / [dcm pixelSpacingY] / PI);
    
    msgString = [NSString stringWithFormat:@"in, out, chord = %f, %f, %f\nouterROIRadius = %f", [roi1 roiArea], [roi2 roiArea], [roiChord roiArea], outerROIradius];
    myAlert = [NSAlert alertWithMessageText:@"outerROIRadius" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:msgString];
    [myAlert runModal];
    
    //} else {
    //    radiusB = sqrtf(area1/PI);    
    //    radiusA = sqrtf(area2/PI);
    //    outerROIradius = sqrtf(area1 * 100 / [dcm pixelSpacingX] / [dcm pixelSpacingY] / PI);
    //}
    
    percentageBoneLoss = ((radiusB - radiusA)/(2 * radiusB)) * 100;
    
    NSPoint ptInner = NSMakePoint(roi1.centroid.y, roi1.centroid.x);
    NSPoint ptOuter = NSMakePoint(roi2.centroid.y, roi2.centroid.x);
    
    //////////////////////////////////////////////////////////////////////
    // Find the intersection points between the chord and outer ROI //////
    //////////////////////////////////////////////////////////////////////
    NSPoint p1 = NSMakePoint(roiChord.centroid.y, roiChord.centroid.x);
    NSPoint p2 = NSMakePoint(roiChord.lowerRightPoint.y, roiChord.lowerRightPoint.x);

    
    // Slope of chord
    float dx, dy, M, B;
    
    if(p1.y > p2.y) {
        dy = p1.y - p2.y;
        dx = p1.x - p2.x;
    } else {
        dy = p2.y - p1.y;
        dx = p2.x - p1.x;
    }
    
    // slope = rise / run
    if(dx != 0) {
        M = dy/dx;
    } else {
        M = 9999;
    }
    
    // Equation of a straight line: y = Mx + b
    // b = y - Mx, (plug in p1)
    B = p1.y - (M * p1.x); 
    
    msgString = [NSString stringWithFormat:@"y = %fx + %f\nusing (%f,%f),(%f,%f)\ncircle centroid (%f, %f)", M, B, p1.x, p1.y, p2.x, p2.y, ptOuter.x, ptOuter.y];
    myAlert = [NSAlert alertWithMessageText:@"Percentage Bone Loss" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:msgString];
    [myAlert runModal];
    
    // Equation of outer circle: 
    // (X - ptOuter.x)^2 + (Y - ptOuter.y)^2 = outerROIradius^2
    
    // Sub in the equation of the line (Y = MX + B) into the equation of the circle
    // (X - ptOuter.x)^2 + (MX + B - ptOuter.y)^2 = outerROIradius^2
    // {X^2 - 2*ptOuter.x*X + (ptOuter.x)^2} + { (M^2)*(X^2) + 2*(B - ptOuter.y)*M*X + (B - ptOuter.y)^2} = outerROIradius^2
    // (M^2 + 1)*X^2  +  2*((B - ptOuter.y)*M - ptOuter.x)*X  +  ((ptOuter.x)^2 + (B - ptOuter.y)^2 - outerROIradius^2) = 0
    // |---a---|*X^2     |-------------b-----------------|*X     |-----------------------c----------------------------| = 0
    
    // Use the trusty quadratic formula
    // x = -b +/- sqrt(b^2 - 4ac)
    //     ----------------------
    //               2a
        
    float a = powf(M,2) + 1;
    float b = 2 * (((B - ptOuter.y)*M) - ptOuter.x);
    float c = (powf(ptOuter.x,2) + powf(B - ptOuter.y,2) - powf(outerROIradius,2));
    
    msgString = [NSString stringWithFormat:@"a %f\nb %f\nc %f", a, b, c];
    myAlert = [NSAlert alertWithMessageText:@"Percentage Bone Loss" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:msgString];
    //[myAlert runModal];
    
    float x1, x2, y1, y2;
    // Make sure the points exist
    if(powf(b,2)  <= (4*a*c)) {
        //ERROR
        msgString = [NSString stringWithFormat:@"ERROR: %f %f", powf(b,2), (4*a*c)]; 
        myAlert = [NSAlert alertWithMessageText:@"Measurements"
                                  defaultButton:@"Done"
                                alternateButton:nil
                                    otherButton:nil
                      informativeTextWithFormat:msgString];
        
        [myAlert runModal];
        return;
    }
    x1 = ((-1)*b + sqrtf(powf(b,2) - 4*a*c))/(2*a);
    x2 = ((-1)*b - sqrtf(powf(b,2) - 4*a*c))/(2*a);
    
    // Sub x1 and x2 into the Y = MX + B equation to find y1 and y2
    y1 = M * x1 + B;
    y2 = M * x2 + B;
    
    // Now we know the points of intersections (POI)
    NSPoint POI1 = NSMakePoint(x1, y1);
    NSPoint POI2 = NSMakePoint(x2, y2);
    
    //////////////////////////

    
    msgString = [NSString stringWithFormat:@"(%f,%f)\n(%f,%f)\n%f", 
                           POI1.x, POI1.y,
                           POI2.x, POI2.y,
                         outerROIradius];
    myAlert = [NSAlert alertWithMessageText:@"Measurements"
                                       defaultButton:@"Done"
                                     alternateButton:nil
                                         otherButton:nil
                           informativeTextWithFormat:msgString];
    
    //[myAlert runModal];   
    
    //Draw the intersection points for visualization
    /*NSSize outerSz = NSMakeSize(10, 10);
    NSRect rect1, rect2;
    rect1.origin = NSMakePoint(POI1.y, POI1.x);
    rect2.origin = NSMakePoint(POI2.y, POI2.x);
    rect1.size = outerSz;
    rect2.size = outerSz;
    ROI *rr1 = [viewerController newROI:tOval];
    ROI *rr2 = [viewerController newROI:tOval];
    [rr1 setROIRect:rect1];
    [rr2 setROIRect:rect2];
    [[[viewerController roiList]objectAtIndex:curSlice]addObject:rr1];
    [[[viewerController roiList]objectAtIndex:curSlice]addObject:rr2];*/
    
    
    // Now find the area of the pie slice between two vectors from the 
    // centroid to the two intersection points
    
    // Find the angle using dot product
    // A dot B = |A||B|cos(theta)
    // Model a 2D vector using NSPoint
    NSPoint v1 = NSMakePoint(POI1.x - ptOuter.x, POI1.y - ptOuter.y);
    float v1mag = sqrtf(powf(v1.x,2) + powf(v1.y,2));
    
    NSPoint v2 = NSMakePoint(POI2.x - ptOuter.x, POI2.y - ptOuter.y);
    float v2mag = sqrtf(powf(v2.x,2) + powf(v2.y,2));
    
    float dotProduct = (v1.x * v2.x) + (v1.y * v2.y);
    float sweepAngle = acos(dotProduct/(v1mag*v2mag));//radians
    
    // Area of missing bone segment
    // A = (R^2/2)*(theta - sin(theta)) 
    // see http://en.wikipedia.org/wiki/Circular_segment
    float missingArea = 0.5 * powf(outerROIradius, 2) * (sweepAngle - sin(sweepAngle));
    float circleArea = PI * powf(outerROIradius, 2);
    
    msgString = [NSString stringWithFormat:@"angle %f rad\nmissing area %f\ncircle area %f\npercentage %.3f%%%%%", 
                 sweepAngle,
                 missingArea,
                 circleArea,
                 (missingArea/circleArea)*100];
    myAlert = [NSAlert alertWithMessageText:@"Measurements"
                              defaultButton:@"Done"
                            alternateButton:nil
                                otherButton:nil
                  informativeTextWithFormat:msgString];
    
    [myAlert runModal];

    
}

@end

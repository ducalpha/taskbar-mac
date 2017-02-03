/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Nicolas Jinchereau. All rights reserved.
 *  Licensed under the MIT License. See License.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

#include <ui/Utils.h>

@implementation Utils

+ (NSImage*)iconForPath:(NSString*)path
{
    NSImage *icon = nil;
    
    BOOL isDir;
    [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir];
    
    if(isDir)
        icon = [[NSWorkspace sharedWorkspace] iconForFile:path];
    else
        icon = [[NSWorkspace sharedWorkspace] iconForFileType:[path pathExtension]];
    
    return icon;
}

+ (NSString*)titleForPath:(NSString*)path
{
    return [[path lastPathComponent] stringByDeletingPathExtension];
}

+ (NSImage*)iconForHighlightedItem:(NSImage*)icon
{
    NSImage *ret = [icon copy];
    
    NSRect bounds = NSMakeRect(0, 0, icon.size.width, icon.size.height);
    
    [ret lockFocus];
    [[NSColor controlBackgroundColor] set];
    NSRectFillUsingOperation(bounds, NSCompositeSourceAtop);
    [ret unlockFocus];
    
    return [ret autorelease];
}

+ (NSImage *)iconWithRotation:(NSImage*)icon angle:(float)angle
{
    NSImage *ret = [[[NSImage alloc] autorelease] initWithSize:icon.size];
    
    [ret lockFocus];
    
    NSAffineTransform *xf = [NSAffineTransform transform];
    NSPoint center = NSMakePoint(icon.size.width / 2, icon.size.height / 2);
    
    [xf translateXBy:center.x yBy:center.y];
    [xf rotateByDegrees:angle];
    [xf translateXBy:-center.y yBy:-center.x];
    [xf concat];
    
    [icon drawInRect:NSMakeRect(0, 0, icon.size.width, icon.size.height)];
    
    [ret unlockFocus];
    
    return ret;
}

+ (BOOL)isDir:(NSString*)path
{
    BOOL isDir = NO;
    [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir];
    return isDir && ![[NSWorkspace sharedWorkspace] isFilePackageAtPath:path];
}

@end


/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Nicolas Jinchereau. All rights reserved.
 *  Licensed under the MIT License. See License.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

#pragma once
#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>
#include <functional>
using namespace std;

@interface Utils : NSObject
+ (NSImage*)iconForPath:(NSString*)path;
+ (NSString*)titleForPath:(NSString*)path;
+ (NSImage*)iconForHighlightedItem:(NSImage*)icon;
+ (NSImage*)iconWithRotation:(NSImage*)icon angle:(float)angle;
+ (BOOL)isDir:(NSString*)path;
@end

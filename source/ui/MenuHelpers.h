/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Nicolas Jinchereau. All rights reserved.
 *  Licensed under the MIT License. See License.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

#pragma once
#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>
#include <functional>
using namespace std;

// a dummy view used to move the start menu to the correct position
@interface ForceMenuPos : NSView
{
    NSPoint _point;
    NSInteger _level;
}
-(id)initWithPoint:(NSPoint)point level:(NSInteger)level;
+(NSMenuItem*)forcePosItem:(NSPoint)point level:(NSInteger)level;
@end


@interface ActionItem : NSMenuItem
{
    function<void()> _fn;
}
-(id)initWithTitle:(NSString*)title action:(const function<void()>&)action;
+(NSMenuItem*)itemWithTitle:(NSString*)title action:(const function<void()>&)action;
@end

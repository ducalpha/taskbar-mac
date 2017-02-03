/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Nicolas Jinchereau. All rights reserved.
 *  Licensed under the MIT License. See License.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

#pragma once
#import <Foundation/Foundation.h>
#include <CoreGraphics/CoreGraphics.h>
#include <Cocoa/Cocoa.h>
#include <cstdint>
#include <string>
#include <iostream>
#include <set>
#include <vector>
#include <memory>
#include <unordered_map>
#include <ax/AXWorkspace.h>
using namespace std;

class WindowInfo;
@class TaskClient;
@class AppleButton;

@interface TaskBarWindow : NSPanel
{
    AppleButton *_appleButton;
    NSRect rect;
    CVDisplayLinkRef displayLink;
    double lastRender;
    
    std::vector<std::shared_ptr<WindowInfo>> _windows;
    
    id _mouseEventMonitor;
}

-(id)init;
-(void)startAnimation;
-(void)stopAnimation;
-(BOOL)isAnimating;
-(void)updateWindows:(NSTimer*)timer;
-(void)updateAnimation;

-(void)clearWindows;
-(void)addWindow:(ax::Window*)window;
-(void)removeWindow:(ax::Window*)window;
-(void)renameWindow:(ax::Window*)window;
-(void)setWindowFocus:(ax::Window*)window focused:(bool)focused;

-(void)globalLeftMouseDown;
-(void)globalLeftMouseUp;
@end

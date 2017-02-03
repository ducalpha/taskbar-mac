/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Nicolas Jinchereau. All rights reserved.
 *  Licensed under the MIT License. See License.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

#pragma once
#include <ax/Application.h>
#include <ax/Window.h>
#include <ax/UIElement.h>
#include <ax/Observer.h>
#include <Cocoa/Cocoa.h>
#include <AppKit/AppKit.h>
#include <string>
#include <memory>
#include <vector>
#include <functional>
#include <queue>
#include <thread>
#include <mutex>
#include <condition_variable>
#include <unordered_map>

using namespace std;

@interface AXWorkspace : NSObject
{
    vector<shared_ptr<ax::Application>> _applications;
    ax::UIElement _systemWideElement;
    bool _needUpdate;
    bool _updateFocus;
    @public ax::Window* _focusedWindow;
}

-(id)init;
-(void)setNeedsUpdate;
-(void)focusMainWindow:(ax::Application*)app;
-(void)focusWindow:(ax::Window*)win focused:(bool)focused;
+(void)assertAccessibilityEnabled;

-(void)applicationCreated:(ax::Application*)app;
-(void)applicationDestroyed:(ax::Application*)app;
-(void)windowCreated:(ax::Window*)window;
-(void)windowDestroyed:(ax::Window*)window;
-(void)windowRenamed:(ax::Window*)window;
-(void)windowResized:(ax::Window*)window;
-(void)windowMoved:(ax::Window*)window;
-(void)windowFocusChanged:(ax::Window*)window focused:(bool)focused;
@end

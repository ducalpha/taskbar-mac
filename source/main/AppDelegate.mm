/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Nicolas Jinchereau. All rights reserved.
 *  Licensed under the MIT License. See License.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

#import "AppDelegate.h"
#include <ui/TaskBarWindow.h>
#import <Cocoa/Cocoa.h>

@implementation Workspace
-(void)applicationCreated:(ax::Application*)app
{
    //cout << "   app created: " << app->title() << endl;
}
-(void)applicationDestroyed:(ax::Application*)app
{
    //cout << "   app destroyed: " << app->title() << endl;
}
-(void)windowCreated:(ax::Window*)window
{
    //cout << "window created: " << window->title() << endl;
    [_taskbar addWindow:window];
}
-(void)windowDestroyed:(ax::Window*)window
{
    //cout << "window destroyed: " << window->title() << endl;
    [_taskbar removeWindow:window];
}
-(void)windowRenamed:(ax::Window*)window
{
    //cout << "window renamed: " << window->title() << endl;
    [_taskbar renameWindow:window];
}
-(void)windowResized:(ax::Window*)window
{
    //cout << "window resized: " << window->title() << endl;
}
-(void)windowMoved:(ax::Window*)window
{
    //cout << "window moved: " << window->title() << endl;
}
-(void)windowFocusChanged:(ax::Window*)window focused:(bool)focused
{
    //if(focused)
    //    cout << "window focused: " << window->title() << endl;
    [_taskbar setWindowFocus:window focused:focused];
}
-(id)initWithTaskbar:(TaskBarWindow*)taskbar
{
    _taskbar = [taskbar retain];
    self = [super init];
    return self;
}
-(void)dealloc
{
    [super dealloc];
    [_taskbar release];
}
@end

@implementation AppDelegate
-(void)applicationDidFinishLaunching:(NSNotification*)aNotification
{
    [AXWorkspace assertAccessibilityEnabled];
    
    TaskBarWindow* taskbar = [[[TaskBarWindow alloc] init] autorelease];
    _workspace = [[Workspace alloc] initWithTaskbar:taskbar];
}

- (void)applicationWillTerminate:(NSNotification*)aNotification
{
    [_workspace release];
}
@end

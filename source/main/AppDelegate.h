/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Nicolas Jinchereau. All rights reserved.
 *  Licensed under the MIT License. See License.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

#import <Cocoa/Cocoa.h>
#include <memory>
#include <ax/AXWorkspace.h>

@class TaskBarWindow;
@interface Workspace : AXWorkspace
{
    TaskBarWindow* _taskbar;
}
-(id)initWithTaskbar:(TaskBarWindow*)taskbar;
@end


@interface AppDelegate : NSObject<NSApplicationDelegate>
{
    Workspace* _workspace;
}

@end

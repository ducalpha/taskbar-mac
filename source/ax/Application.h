/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Nicolas Jinchereau. All rights reserved.
 *  Licensed under the MIT License. See License.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

#pragma once
#include <ax/UIElement.h>
#include <ax/Observer.h>
#include <ax/Window.h>
#include <Cocoa/Cocoa.h>
#include <AppKit/AppKit.h>
#include <vector>
#include <string>
#include <memory>
#include <unordered_map>
#include <functional>

@class AXWorkspace;

using namespace std;

namespace ax
{

class workspace;
    
class Application
{
public:
    friend class UIElement;
    friend class Observer;
    friend class Window;
    friend class workspace;
    
    Application();
    Application(Application &&other);
    Application(AXWorkspace *ws, NSRunningApplication *app);
    ~Application();
    
    Application& operator=(Application &&other);
    
    NSRunningApplication *runningApplication();
    const string& title();
    pid_t processID();
    const string& bundleID();
    NSImage *icon();
    Observer& observer();
    vector<shared_ptr<Window>> &windows();
    UIElement element();
    
    // returns false if any errors occurred, but may have partially succeeded
    int update();
    State state() const;
    void setDirty();
    
    void hide();
    void quit();
    void force_quit();
    
    Window* getWindow(const UIElement& element);
    vector<shared_ptr<Window>>::iterator findWindow(const UIElement& element);
    vector<shared_ptr<Window>>::iterator findWindow(Window *window);
    
private:
    
    void onAppShown(UIElement element);
    void onAppHidden(UIElement element);
    void onAppActivated(UIElement element);
    void onAppDeactivated(UIElement element);
    void onFocusChanged(UIElement element);
    void onWindowCreated(UIElement element);
    void onWindowDestroyed(UIElement element);
    void onWindowResized(UIElement element);
    void onWindowMoved(UIElement element);
    void onWindowTitleChanged(UIElement element);
    
    Application(const Application&)= delete;
    Application& operator=(const Application&) = delete;
    
    UIElement _element;
    Observer _observer;
    pid_t _pid;
    string _defaultTitle;
    string _title;
    string _bundleID;
    NSImage *_icon;
    bool _hidden;
    vector<shared_ptr<Window>> _windows;
    AXWorkspace *_workspace;
    State _state;
    bool _dirty;
};

}

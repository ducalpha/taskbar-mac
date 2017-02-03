/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Nicolas Jinchereau. All rights reserved.
 *  Licensed under the MIT License. See License.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

#include <ax/Application.h>
#include <ax/Window.h>
#include <ax/AXWorkspace.h>
#include <functional>
#include <iostream>
#include <exception>

namespace ax
{
    
Application::Application()
    : _pid(0),
      _icon(nil),
      _hidden(false),
      _workspace(nullptr),
      _state(State::Pending),
      _dirty(false)
{
    
}

string _non_null_string(const char *str)
{
    return str ? str : "";
}

Application::Application(AXWorkspace *ws, NSRunningApplication *app)
    : _pid([app processIdentifier]),
      _element([app processIdentifier]),
      _defaultTitle(_non_null_string([[app localizedName] UTF8String])),
      _title(_non_null_string([[app localizedName] UTF8String])),
      _bundleID(_non_null_string([[app bundleIdentifier] UTF8String])),
      _icon([[app icon] retain]),
      _hidden(app.hidden),
      _workspace(ws),
      _state(State::Pending),
      _dirty(false)
{
    
}

Application::Application(Application &&other)
    : _pid(other._pid),
      _element(move(other._element)),
      _observer(move(other._observer)),
      _title(move(other._title)),
      _defaultTitle(move(other._defaultTitle)),
      _bundleID(move(other._bundleID)),
      _windows(move(other._windows)),
      _icon(other._icon),
      _hidden(other._hidden),
      _workspace(other._workspace),
      _state(other._state),
      _dirty(other._dirty)
{
    other._pid = 0;
    other._icon = nil;
    other._hidden = false;
    other._workspace = nullptr;
    other._state = State::Pending;
    other._dirty = false;
}

Application& Application::operator=(Application &&other)
{
    _pid = other._pid;
    _element = move(other._element);
    _observer = move(other._observer);
    _defaultTitle = move(other._defaultTitle);
    _title = move(other._title);
    _bundleID = move(other._bundleID);
    _windows = move(other._windows);
    _icon = other._icon;
    _hidden = other._hidden;
    _workspace = other._workspace;
    _state = other._state;
    _dirty = other._dirty;
    
    other._pid = 0;
    other._icon = nil;
    other._hidden = false;
    other._workspace = nullptr;
    other._state = State::Pending;
    other._dirty = false;
    
    return *this;
}
    
Application::~Application()
{
    _observer = Observer();
    
    _windows.clear();
    
    [_icon release];
    
    if(_state == State::Valid)
        [_workspace applicationDestroyed:this];
}

int Application::update()
{
    int errors = 0;
    
    if(!_element.isValid())
        _state = State::Invalid;
    
    if(_state == State::Pending)
    {
        try
        {
            Attribute attTitle = _element.attributeFor(kAXTitleAttribute);
            if(!attTitle)
                throw runtime_error("failed to retrieve application title: " + _title);
            
            Observer obs = Observer(this);
            
            if(!obs.addNotification(_element, kAXApplicationShownNotification))
                throw std::runtime_error("error adding kAXApplicationShownNotification: " + _title);
            
            if(!obs.addNotification(_element, kAXApplicationHiddenNotification))
                throw std::runtime_error("error adding kAXApplicationHiddenNotification: " + _title);
            
            if(!obs.addNotification(_element, kAXApplicationActivatedNotification))
                throw std::runtime_error("error adding kAXApplicationActivatedNotification: " + _title);
            
            if(!obs.addNotification(_element, kAXApplicationDeactivatedNotification))
                throw std::runtime_error("error adding kAXApplicationDeactivatedNotification: " + _title);
            
            if(!obs.addNotification(_element, kAXWindowCreatedNotification))
                throw std::runtime_error("error adding kAXWindowCreatedNotification: " + _title);
            
            if(!obs.addNotification(_element, kAXWindowResizedNotification))
                throw std::runtime_error("error adding kAXWindowResizedNotification: " + _title);
            
            if(!obs.addNotification(_element, kAXWindowMovedNotification))
                throw std::runtime_error("error adding kAXWindowMovedNotification: " + _title);
            
            if(!obs.addNotification(_element, kAXMainWindowChangedNotification))
                throw std::runtime_error("error adding kAXMainWindowChangedNotification: " + _title);
            
            // throws if children cannot be retrieved.
            vector<UIElement> children = _element.children();
            
            // -- no exceptions --
            NSRunningApplication* app = [NSRunningApplication runningApplicationWithProcessIdentifier:_pid];
            _hidden = app.hidden;
            
            _windows.reserve(children.size());
            
            for(auto &child : children)
            {
                shared_ptr<Window> win = make_shared<Window>(this, child);
                _windows.push_back(move(win));
            }
            
            _title = attTitle.stringValue();
            _observer = std::move(obs);
            
            _state = State::Valid;
            _dirty = false;
            
            [_workspace applicationCreated:this];
        }
        catch(exception& ex)
        {
            cout << ex.what() << endl;
            ++errors;
        }
    }
    
    if(_state == State::Valid && _dirty)
    {
        Attribute attTitle = _element.attributeFor(kAXTitleAttribute);
        if(attTitle)
        {
            _title = attTitle.stringValue();
            _dirty = false;
        }
    }
    
    for(auto it = _windows.begin(); it != _windows.end(); )
    {
        shared_ptr<Window>& win = *it;
        
        errors += win->update();
        
        if(win->state() == State::Invalid)
        {
            [_workspace focusWindow:it->get() focused:false];
            it = _windows.erase(it);
        }
        else
        {
            ++it;
        }
    }
    
    return errors;
}

State Application::state() const
{
    return _state;
}
    
void Application::setDirty()
{
    _dirty = true;
}

Window* Application::getWindow(const UIElement& element)
{
    auto it = findWindow(element);
    return (it != _windows.end()) ? it->get() : nullptr;
}
    
vector<shared_ptr<Window>>::iterator Application::findWindow(const UIElement& element)
{
    auto it = _windows.begin();
    
    for( ; it != _windows.end(); ++it) {
        if((*it)->_element == element)
            break;
    }
    
    return it;
}

vector<shared_ptr<Window>>::iterator Application::findWindow(Window *window)
{
    auto it = _windows.begin();
    
    for( ; it != _windows.end(); ++it) {
        if(it->get() == window)
            break;
    }
    
    return it;
}

void Application::onAppShown(UIElement element)
{
    //cout << "APP: onAppShown: " << _title << endl;
    
    _hidden = false;
    
    for(auto& win : _windows)
    {
        if(win->state() == State::Valid)
            win->createWindow();
    }
    
    if(runningApplication().active)
    {
        [_workspace focusMainWindow:this];
    }
}

void Application::onAppHidden(UIElement element)
{
    //cout << "APP: onAppHidden: " << _title << endl;
    
    _hidden = true;
    
    for(auto& win : _windows)
    {
        if(win->state() == State::Valid)
        {
            [_workspace focusWindow:win.get() focused:false];
            win->destroyWindow();
        }
    }
}

void Application::onAppActivated(UIElement element)
{
    //cout << "APP: onAppActivated: " << _title << endl;
    [_workspace focusMainWindow:this];
}

void Application::onAppDeactivated(UIElement element)
{
    //cout << "APP: onAppDeactivated: " << _title << endl;
}

void Application::onFocusChanged(UIElement element)
{
    //cout << "APP: onFocusChanged: " << _title << endl;
    
    if(runningApplication().active)
    {
        ax::Window* win = getWindow(element);
        if(win) [_workspace focusWindow:win focused:true];
    }
}

void Application::onWindowCreated(UIElement element)
{
    //cout << "APP: onWindowCreated: " << _title << endl;
    
    if(getWindow(element) == nullptr)
    {
        shared_ptr<Window> win = make_shared<Window>(this, element);
        _windows.push_back(win);
        
        int errors = win->update();
        
        if(errors)
            [_workspace setNeedsUpdate];
    }
}

void Application::onWindowDestroyed(UIElement element)
{
    //cout << "APP: onWindowDestroyed: " << _title << endl;
    
    auto it = findWindow(element);
    if(it != _windows.end())
    {
        [_workspace focusWindow:it->get() focused:false];
        _windows.erase(it);
    }
}

void Application::onWindowResized(UIElement element)
{
    auto it = findWindow(element);
    if(it != _windows.end())
    {
        Window* win = it->get();
        
        // make sure the window is not hiding behind the taskbar
        CGPoint pos = win->position();
        CGSize sz = win->size();
        
        float bottom = pos.y + sz.height;
        float screenHeight = [[NSScreen mainScreen] frame].size.height;
        float taskbarHeight = 32;
        float taskbarTop = screenHeight - taskbarHeight;
        
        if(bottom >= taskbarTop)
        {
            sz.height -= (bottom - taskbarTop + 1);
            win->size(sz);
        }
        
        [_workspace windowResized:win];
    }
}

void Application::onWindowMoved(UIElement element)
{
    auto it = findWindow(element);
    if(it != _windows.end())
        [_workspace windowMoved:it->get()];
}

void Application::onWindowTitleChanged(UIElement element)
{
    auto it = findWindow(element);
    if(it != _windows.end())
    {
        auto& win = *it;
        win->setDirty();
        if(win->update() != 0)
            [_workspace setNeedsUpdate];
    }
}

NSRunningApplication *Application::runningApplication() {
    return [NSRunningApplication runningApplicationWithProcessIdentifier:_pid];
}

const string& Application::title() {
    return !_title.empty() ? _title : _defaultTitle;
}

pid_t Application::processID() {
    return _pid;
}

const string& Application::bundleID() {
    return _bundleID;
}

NSImage *Application::icon() {
    return _icon;
}

Observer& Application::observer() {
    return _observer;
}

vector<shared_ptr<Window>> &Application::windows() {
    return _windows;
}

UIElement Application::element() {
    return _element;
}

void Application::hide() {
    NSRunningApplication *app = [NSRunningApplication runningApplicationWithProcessIdentifier:_pid];
    [app hide];
}

void Application::quit() {
    NSRunningApplication *app = [NSRunningApplication runningApplicationWithProcessIdentifier:_pid];
    [app terminate];
}

void Application::force_quit() {
    NSRunningApplication *app = [NSRunningApplication runningApplicationWithProcessIdentifier:_pid];
    [app forceTerminate];
}

} // namespace ax

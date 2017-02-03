/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Nicolas Jinchereau. All rights reserved.
 *  Licensed under the MIT License. See License.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

#include <ax/Window.h>
#include <ax/Application.h>
#include <ax/AXWorkspace.h>
#include <exception>
using namespace std;

namespace ax
{    

Window::Window(Application *app, const UIElement& element)
    : _app(app),
      _element(element),
      _title(app->_defaultTitle),
      _state(State::Pending),
      _dirty(false),
      _hasWindow(false)
{
    
}

Window::Window(Window &&other)
{
    _app = other._app;
    _element = move(other._element);
    _title = move(other._title);
    _observer = move(other._observer);
    _state = other._state;
    _dirty = other._dirty;
    _hasWindow = other._hasWindow;
    
    other._app = nullptr;
    other._state = State::Pending;
    other._dirty = false;
    other._hasWindow = false;
}

Window::~Window()
{
    //cout << "~Window destroyed: " << this->title() << endl;
    if(_hasWindow)
        this->destroyWindow();
}

Window& Window::operator=(Window &&other)
{
    _app = other._app;
    _element = move(other._element);
    _title = move(other._title);
    _observer = move(other._observer);
    _state = other._state;
    _dirty = other._dirty;
    _hasWindow = other._hasWindow;
    
    other._app = nullptr;
    other._state = State::Pending;
    other._dirty = false;
    other._hasWindow = false;
    
    return *this;
}

Application *Window::app()
{
    return _app;
}

const string& Window::title()
{
    return _title;
}

UIElement Window::element()
{
    return _element;
}

CGSize Window::size()
{
    return _element.attributeFor(kAXSizeAttribute).sizeValue();
}

void Window::size(const CGSize &value)
{
    _element.setAttribute(kAXSizeAttribute, Attribute(value));
}

void Window::position(const CGPoint &value)
{
    _element.setAttribute(kAXSizeAttribute, Attribute(value));
}
    
CGPoint Window::position()
{
    return _element.attributeFor(kAXPositionAttribute).pointValue();
}

class window_type_error : public exception
{
    std::string _what;
public:
    window_type_error(const string& what) : _what(what){}
    window_type_error(const char* what) : _what(what){}
    
    virtual const char* what() const noexcept override {
        return _what.c_str();
    }
};
    
int Window::update()
{
    int errors = 0;
    
    if(!_element.isValid()) {
        _state = State::Invalid;
    }
    
    if(_state == State::Pending)
    {
        try
        {
            Attribute windowRole(kAXWindowRole);
            Attribute windowSubrole(kAXStandardWindowSubrole);
            Attribute dialogSubrole(kAXDialogSubrole);
            
            if(_element.hasAttribute(kAXRoleAttribute) == 0)
                throw window_type_error("error: window has no role attrib");
            
            Attribute role = _element.attributeFor(kAXRoleAttribute);
            if(!role)
                throw runtime_error("failed to add window(couldn't get role attrib): " + _title);
            
            if(role != windowRole)
                throw window_type_error("error: role is not 'AXWindow'");
            
            if(_element.hasAttribute(kAXSubroleAttribute) == 0)
                throw window_type_error("error: window has no subrole attrib");
            
            Attribute subRole = _element.attributeFor(kAXSubroleAttribute);
            if(!subRole)
                throw runtime_error("failed to add window(couldn't get subrole): " + _title);
            
            if(subRole != windowSubrole && subRole != dialogSubrole)
                throw window_type_error("error: window subrole is not 'AXStandardWindow' or 'AXDialog'");
            
            Attribute attTitle = _element.attributeFor(kAXTitleAttribute);
            if(!attTitle)
                throw runtime_error("failed to retrieve window title: " + _title);
            
            Observer obs(_app);
            
            if(!obs.addNotification(_element, kAXUIElementDestroyedNotification))
                throw std::runtime_error("error adding kAXUIElementDestroyedNotification: " + _title);
            
            if(!obs.addNotification(_element, kAXTitleChangedNotification))
                throw std::runtime_error("error adding kAXTitleChangedNotification: " + _title);
            
            string newTitle = attTitle.stringValue();
            if(!newTitle.empty())
                _title =  attTitle.stringValue();
            
            _observer = move(obs);
            _state = State::Valid;
            
            _dirty = false;
            
            if(!_app->_hidden)
            {
                createWindow();
                
                if(_app->runningApplication().active)
                    [_app->_workspace focusWindow:this focused:true];
            }
        }
        catch(window_type_error& ex)
        {
            //cout << ex.what() << endl;
            _state = State::Invalid;
        }
        catch(runtime_error& ex)
        {
            cout << ex.what() << endl;
            ++errors;
        }
    }
    
    if(_state == State::Valid && _dirty)
    {
        try
        {
            Attribute attTitle = _element.attributeFor(kAXTitleAttribute);
            if(!attTitle)
                throw runtime_error("failed to retrieve window title: " + _title);
            
            string oldTitle = move(_title);
            string newTitle = attTitle.stringValue();
            if(!newTitle.empty())
                _title = newTitle;
            
            _dirty = false;
            
            if(oldTitle != _title)
                [_app->_workspace windowRenamed:this];
        }
        catch(exception& ex)
        {
            cout << ex.what() << endl;
            ++errors;
        }
    }
    
    return errors;
}

State Window::state() const
{
    return _state;
}

void Window::setDirty()
{
    _dirty = true;
}

void Window::focus()
{
    NSRunningApplication *runningApp = app()->runningApplication();
    [runningApp activateWithOptions:NSApplicationActivateIgnoringOtherApps];
    _element.setAttribute(kAXMinimizedAttribute, Attribute(kCFBooleanFalse));
    
    // Setting kAXMainAttribute=true doesn't work while window
    // is in the process on deminiaturizing.
    // Performing kAXRaiseAction will cause flicker, but works.
    //_element.setAttribute(kAXMainAttribute, Attribute(kCFBooleanTrue));
    _element.performAction(kAXRaiseAction);
}

void Window::minimize()
{
    _element.setAttribute(kAXMinimizedAttribute, Attribute(kCFBooleanTrue));
}
    
void Window::toggleFocusMinimize()
{
    Application* hostApp = app();
    NSRunningApplication *runningApp = hostApp->runningApplication();
    
    // Bug?: kAXFocusedAttribute is incorrect half the time
    // bool hasFocus = _element.attributeFor(kAXFocusedAttribute).boolValue();
    // cout << "  hasFocus: " << boolalpha << hasFocus << endl;
    
    // Workaround: Deduce focus - if a window is kAXMainAttribute,
    // and it's application is active, then that window has focus.
    Attribute isMainAttrib = _element.attributeFor(kAXMainAttribute);
    if(!isMainAttrib)
        return;
    
    bool isMain = isMainAttrib.boolValue();
    
    Attribute isMinimizedAttrib = _element.attributeFor(kAXMinimizedAttribute);
    
    if(!isMinimizedAttrib)
        return;
    
    bool isMinimized = isMinimizedAttrib.boolValue();
    
    if(runningApp.active && isMain && !isMinimized)
        minimize();
    else
        focus();
}

void Window::close()
{
    Attribute closeButtonAttrib = _element.attributeFor(kAXCloseButtonAttribute);
    
    if(closeButtonAttrib)
    {
        UIElement closeButton = closeButtonAttrib.elementRefValue();
        Attribute btnEnabled = closeButton.attributeFor(kAXEnabledAttribute);
        
        if(btnEnabled && btnEnabled.boolValue())
        {
            closeButton.performAction(kAXPressAction);
            return;
        }
    }
    
    NSRunningApplication *app = [NSRunningApplication runningApplicationWithProcessIdentifier:_app->_pid];
    [app terminate];
}

void Window::createWindow()
{
    _hasWindow = true;
    [_app->_workspace windowCreated:this];
}

void Window::destroyWindow()
{
    _hasWindow = false;
    [_app->_workspace windowDestroyed:this];
}
    
}

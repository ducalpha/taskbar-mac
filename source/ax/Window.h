/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Nicolas Jinchereau. All rights reserved.
 *  Licensed under the MIT License. See License.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

#pragma once
#include <ax/UIElement.h>
#include <ax/Observer.h>
#include <Cocoa/Cocoa.h>
#include <AppKit/AppKit.h>
#include <string>
#include <iostream>
using namespace std;

namespace ax
{

typedef AXUIElementRef wid_t;

class Application;

class Window
{
public:
    friend class UIElement;
    friend class Observer;
    friend class Application;
    friend class workspace;
    
    Window(Application *app, const UIElement& element);
    Window(Window &&other);
    ~Window();
    Window& operator=(Window &&other);
    
    Application *app();
    const string& title();
    UIElement element();
    
    CGSize size();
    void size(const CGSize &value);
    
    CGPoint position();
    void position(const CGPoint &value);
    
    void focus();
    void minimize();
    void toggleFocusMinimize();
    void close();
    
    int update();
    State state() const;
    void setDirty();
    
private:
    Window()= delete;
    Window(const Window&)= delete;
    Window& operator=(const Window&)= delete;
    
    void createWindow();
    void destroyWindow();
    
    Application *_app;
    UIElement _element;
    Observer _observer;
    string _title;
    State _state;
    bool _dirty;
    bool _hasWindow;
};

}


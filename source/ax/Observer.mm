/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Nicolas Jinchereau. All rights reserved.
 *  Licensed under the MIT License. See License.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

#include <ax/Observer.h>
#include <ax/UIElement.h>
#include <ax/Application.h>
#include <iostream>
#include <CoreFoundation/CoreFoundation.h>

namespace ax
{

bool strEqual(CFStringRef notification, CFStringRef notifType) {
    return CFStringCompare(notification, notifType, 0) == 0;
}
    
void Observer::_proxy(AXObserverRef observer, AXUIElementRef element, CFStringRef notification, void *userdata)
{
    Application *app = (Application*)userdata;
    
    if(strEqual(notification, kAXApplicationShownNotification)) {
        app->onAppShown(UIElement(element));
    }
    else if(strEqual(notification, kAXApplicationHiddenNotification)) {
        app->onAppHidden(UIElement(element));
    }
    else if(strEqual(notification, kAXApplicationActivatedNotification)) {
        app->onAppActivated(UIElement(element));
    }
    else if(strEqual(notification, kAXApplicationDeactivatedNotification)) {
        app->onAppDeactivated(UIElement(element));
    }
    else if(strEqual(notification, kAXWindowCreatedNotification)) {
        app->onWindowCreated(UIElement(element));
    }
    else if(strEqual(notification, kAXWindowResizedNotification)) {
        app->onWindowResized(UIElement(element));
    }
    else if(strEqual(notification, kAXWindowMovedNotification)) {
        app->onWindowMoved(UIElement(element));
    }
    //else if(strEqual(notification, kAXFocusedWindowChangedNotification)) {
    else if(strEqual(notification, kAXMainWindowChangedNotification)) {
        app->onFocusChanged(UIElement(element));
    }
    else if(strEqual(notification, kAXUIElementDestroyedNotification)) {
        app->onWindowDestroyed(UIElement(element));
    }
    else if(strEqual(notification, kAXTitleChangedNotification)) {
        app->onWindowTitleChanged(UIElement(element));
    }
    else {
        cout << "warning: notification not implemented in Observer" << endl;
    }
}

Observer::Observer()
    : _observer_ref(nullptr), _app(nullptr)
{
    
}

Observer::Observer(Application *app)
    : _observer_ref(nullptr), _app(app)
{
    pid_t pid = _app->processID();
    AXError err = AXObserverCreate(pid, &Observer::_proxy, &_observer_ref);
    
    if(err == 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(_observer_ref), kCFRunLoopDefaultMode);
    else
        cout << "failed to created observer: " << err << endl;
}

Observer::Observer(Observer &&other)
    : _observer_ref(other._observer_ref),
      _app(other._app),
      _callbacks(move(other._callbacks))
{
    other._observer_ref = nullptr;
    other._app = nullptr;
}

Observer::~Observer()
{
    if(_observer_ref) CFRelease(_observer_ref);
}

Observer& Observer::operator=(nullptr_t)
{
    if(_observer_ref) CFRelease(_observer_ref);
    
    _observer_ref = nullptr;
    _app = nullptr;
    _callbacks.clear();
    
    return *this;
}

Observer& Observer::operator=(Observer &&other)
{
    if(_observer_ref) CFRelease(_observer_ref);
    
    _observer_ref = other._observer_ref;
    _app = other._app;
    _callbacks = move(other._callbacks);
    
    other._observer_ref = nullptr;
    other._app = nullptr;
    
    return *this;
}

bool Observer::addNotification(const UIElement &element, CFStringRef notification)
{
    if(hasNotification(element, notification))
        return true;
    
    AXError err = AXObserverAddNotification(_observer_ref,
                                            element._element_ref,
                                            notification,
                                            _app);
    
    if(err && err != kAXErrorNotificationAlreadyRegistered)
        return false;
    
    _callbacks.insert(make_pair(element, notification));
    
    return true;
}

void Observer::removeNotification(const UIElement &element, CFStringRef notification)
{
    AXObserverRemoveNotification(_observer_ref, element._element_ref, notification);
    
    auto range = _callbacks.equal_range(element);
    
    for(auto it = range.first; it != range.second; ++it)
    {
        if(strEqual(it->second, notification))
        {
            _callbacks.erase(it);
            break;
        }
    }
}

void Observer::removeNotifications(const UIElement &element)
{
    auto range = _callbacks.equal_range(element);
    
    for(auto it = range.first; it != range.second; )
    {
        AXObserverRemoveNotification(_observer_ref, it->first._element_ref, it->second);
        it = _callbacks.erase(it);
    }
}

bool Observer::hasNotification(const UIElement &element, CFStringRef notification)
{
    auto range = _callbacks.equal_range(element);
    
    auto it = find_if(range.first, range.second,
                      [notification](auto& str){
                          return strEqual(notification, str.second);
                      });
    
    return it != range.second;
}

bool Observer::hasNotifications(const UIElement &element)
{
    auto range = _callbacks.equal_range(element);
    return range.first != range.second;
}

}

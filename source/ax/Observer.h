/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Nicolas Jinchereau. All rights reserved.
 *  Licensed under the MIT License. See License.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

#pragma once
#include <ax/Common.h>
#include <ax/UIElement.h>
#include <cstdlib>
#include <AppKit/AppKit.h>
#include <vector>
#include <functional>
#include <unordered_set>
#include <unordered_map>
#include <memory>
using namespace std;

namespace ax
{

class UIElement;
class Application;

class Observer
{
public:
    friend class UIElement;
    friend class Window;
    friend class Application;
    friend class workspace;
    
    Observer();
    Observer(Observer &&other);
    explicit Observer(Application *app);
    ~Observer();
    
    Observer& operator=(nullptr_t);
    Observer& operator=(Observer &&other);
    
    inline operator bool() const;
    inline bool operator!() const;
    inline friend bool operator==(const Observer &x, const Observer &y);
    inline friend bool operator==(const Observer &x, nullptr_t);
    inline friend bool operator!=(const Observer &x, const Observer &y);
    inline friend bool operator!=(const Observer &x, nullptr_t);
    
    bool addNotification(const UIElement &element, CFStringRef notification);
    void removeNotification(const UIElement &element, CFStringRef notification);
    void removeNotifications(const UIElement &element);
    bool hasNotification(const UIElement &element, CFStringRef notification);
    bool hasNotifications(const UIElement &element);
    
private:
    Observer(const Observer &other);
    Observer& operator=(const Observer &other);
    
    static void _proxy(AXObserverRef observer,
                       AXUIElementRef element,
                       CFStringRef notification,
                       void *userdata);
    
    struct ElemHash {
        size_t operator()(const UIElement& elem) const {
            return elem.hashCode();
        }
    };
    
    std::unordered_multimap<UIElement, CFStringRef, ElemHash> _callbacks;
    
    AXObserverRef _observer_ref;
    Application *_app;
};

inline Observer::operator bool() const {
    return _observer_ref != nullptr;
}

inline bool Observer::operator!() const {
    return _observer_ref == nullptr;
}

inline bool operator==(const Observer &x, const Observer &y) {
    return equal_pointees(x._observer_ref, y._observer_ref);
}

inline bool operator==(const Observer &x, nullptr_t) {
    return x._observer_ref == nullptr;
}

inline bool operator!=(const Observer &x, const Observer &y) {
    return unequal_pointees(x._observer_ref, y._observer_ref);
}

inline bool operator!=(const Observer &x, nullptr_t) {
    return x._observer_ref != nullptr;
}

}

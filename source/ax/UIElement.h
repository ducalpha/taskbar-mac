/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Nicolas Jinchereau. All rights reserved.
 *  Licensed under the MIT License. See License.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

#pragma once
#include <ax/Common.h>
#include <ax/Attribute.h>
#include <cstdlib>
#include <AppKit/AppKit.h>
#include <vector>
#include <stdint.h>

using namespace std;

namespace ax
{
class UIElement
{
    AXUIElementRef _element_ref;
    
public:
    friend class Observer;
    friend class Attribute;
    friend class Window;
    friend class Application;
    friend class workspace;
    
    UIElement();
    UIElement(const UIElement &other);
    UIElement(UIElement &&other);
    explicit UIElement(pid_t pid);
    explicit UIElement(AXUIElementRef element_ref);
    ~UIElement();
    
    UIElement& operator=(nullptr_t);
    UIElement& operator=(const UIElement &other);
    UIElement& operator=(UIElement &&other);
    
    inline operator bool() const;
    inline bool operator!() const;
    inline friend bool operator==(const UIElement &x, const UIElement &y);
    inline friend bool operator==(const UIElement &x, nullptr_t);
    inline friend bool operator!=(const UIElement &x, const UIElement &y);
    inline friend bool operator!=(const UIElement &x, nullptr_t);
    
    static UIElement systemWideElement();
    
    bool isValid() const;
    size_t hashCode() const;
    size_t childCount();
    UIElement childAt(size_t index);
    vector<UIElement> children();
    AXUIElementRef elementRef();
    Attribute attributeFor(CFStringRef name);
    AXError setAttribute(CFStringRef name, const Attribute &att);
    bool isAttributeSettable(CFStringRef name);
    int hasAttribute(CFStringRef name);
    AXError performAction(CFStringRef name);
    AXError setMessagingTimeout(float seconds);
};
    
inline UIElement::operator bool() const {
    return _element_ref != nullptr;
}

inline bool UIElement::operator!() const {
    return _element_ref == nullptr;
}

inline bool operator==(const UIElement &x, const UIElement &y) {
    return equal_pointees(x._element_ref, y._element_ref);
}

inline bool operator==(const UIElement &x, nullptr_t) {
    return x._element_ref == nullptr;
}

inline bool operator!=(const UIElement &x, const UIElement &y) {
    return unequal_pointees(x._element_ref, y._element_ref);
}

inline bool operator!=(const UIElement &x, nullptr_t) {
    return x._element_ref != nullptr;
}

}

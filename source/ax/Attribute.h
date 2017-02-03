/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Nicolas Jinchereau. All rights reserved.
 *  Licensed under the MIT License. See License.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

#pragma once
#include <ax/Common.h>
#include <AppKit/AppKit.h>
#include <CoreFoundation/CoreFoundation.h>
#include <cstdlib>
#include <vector>
#include <string>
using namespace std;

namespace ax
{

class UIElement;
    
class Attribute
{
    CFTypeRef _type_ref;
    
public:
    friend class UIElement;
    friend class Observer;
    friend class Window;
    friend class Application;
    friend class workspace;
    
    Attribute();
    Attribute(const Attribute &other);
    Attribute(Attribute &&other);
    explicit Attribute(const UIElement& element);
    explicit Attribute(CFTypeRef typeRef);
    explicit Attribute(CGSize size);
    explicit Attribute(CGPoint point);
    ~Attribute();
    
    Attribute& operator=(nullptr_t);
    Attribute& operator=(const Attribute &other);
    Attribute& operator=(Attribute &&other);
    
    inline operator bool() const;
    inline bool operator!() const;
    inline friend bool operator==(const Attribute &x, const Attribute &y);
    inline friend bool operator==(const Attribute &x, nullptr_t);
    inline friend bool operator!=(const Attribute &x, const Attribute &y);
    inline friend bool operator!=(const Attribute &x, nullptr_t);
    
    CFTypeRef typeRef();
    AXValueType type();
    
    bool boolValue();
    int intValue();
    string stringValue();
    CGSize sizeValue();
    CGPoint pointValue();
    UIElement elementRefValue();
};

inline Attribute::operator bool() const {
    return _type_ref != NULL;
}

inline bool Attribute::operator!() const {
    return _type_ref == NULL;
}

inline bool operator==(const Attribute &x, const Attribute &y) {
    return equal_pointees(x._type_ref, y._type_ref);
}

inline bool operator==(const Attribute &x, nullptr_t) {
    return x._type_ref == NULL;
}

inline bool operator!=(const Attribute &x, const Attribute &y) {
    return unequal_pointees(x._type_ref, y._type_ref);
}

inline bool operator!=(const Attribute &x, nullptr_t) {
    return x._type_ref != NULL;
}

}

/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Nicolas Jinchereau. All rights reserved.
 *  Licensed under the MIT License. See License.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

#include <ax/UIElement.h>
#include <iostream>

namespace ax
{

UIElement::UIElement()
    : _element_ref(NULL)
{
    
}

UIElement::UIElement(pid_t pid)
    : _element_ref(AXUIElementCreateApplication(pid))
{
}

UIElement::UIElement(AXUIElementRef elementRef)
    : _element_ref(elementRef)
{
    if(_element_ref) CFRetain(_element_ref);
}

UIElement::UIElement(const UIElement &other)
    : _element_ref(other._element_ref)
{
    if(_element_ref) CFRetain(_element_ref);
}

UIElement::UIElement(UIElement &&other)
    : _element_ref(other._element_ref)
{
    other._element_ref = NULL;
}

UIElement::~UIElement()
{
    if(_element_ref) CFRelease(_element_ref);
}

UIElement& UIElement::operator=(nullptr_t)
{
    if(_element_ref) CFRelease(_element_ref);
    _element_ref = NULL;
    return *this;
}

UIElement& UIElement::operator=(const UIElement &other)
{
    if(_element_ref) CFRelease(_element_ref);
    _element_ref = other._element_ref;
    if(_element_ref) CFRetain(_element_ref);
    return *this;
}

UIElement& UIElement::operator=(UIElement &&other)
{
    if(_element_ref) CFRelease(_element_ref);
    _element_ref = other._element_ref;
    other._element_ref = NULL;
    return *this;
}

UIElement UIElement::systemWideElement()
{
    UIElement ret;
    
    AXUIElementRef element = AXUIElementCreateSystemWide();
    ret = UIElement(element);
    CFRelease(element);
    
    return ret;
}

bool UIElement::isValid() const
{
    CFIndex childCount;
    AXError err = AXUIElementGetAttributeValueCount(_element_ref, kAXChildrenAttribute, &childCount);
    return err != kAXErrorInvalidUIElement;
}
    
size_t UIElement::hashCode() const
{
    return CFHash(_element_ref);
}

size_t UIElement::childCount()
{
    CFIndex childCount;
    AXUIElementGetAttributeValueCount(_element_ref, kAXChildrenAttribute, &childCount);
    return (size_t)childCount;
}

UIElement UIElement::childAt(size_t index)
{
    CFArrayRef child;
    AXError err = AXUIElementCopyAttributeValues(_element_ref, kAXChildrenAttribute, index, 1, &child);
    
    UIElement ret;
    
    if(err == 0)
    {
        ret = UIElement((AXUIElementRef)CFArrayGetValueAtIndex(child, 0));
        CFRelease(child);
    }
    
    return ret;
}

vector<UIElement> UIElement::children()
{
    vector<UIElement> ret;
    
    CFIndex childCount = 0;
    AXError err = AXUIElementGetAttributeValueCount(_element_ref, kAXChildrenAttribute, &childCount);
    
    if(err)
        throw runtime_error("failed to retrieve children: "s + to_string(err));
    
    if(childCount > 0)
    {
        CFArrayRef children;
        err = AXUIElementCopyAttributeValues(_element_ref, kAXChildrenAttribute, 0, childCount, &children);
        
        if(err)
            throw runtime_error("failed to copy children: "s + to_string(err));
        
        ret.reserve(childCount);
        
        for(CFIndex i = 0; i < childCount; ++i)
            ret.emplace_back((AXUIElementRef)CFArrayGetValueAtIndex(children, i));
        
        CFRelease(children);
    }
    
    return ret;
}

AXUIElementRef UIElement::elementRef()
{
    return _element_ref;
}
    
Attribute UIElement::attributeFor(CFStringRef name)
{
    Attribute ret;
    
    CFTypeRef value;
    AXError err = AXUIElementCopyAttributeValue(_element_ref, name, &value);
    
    if(err)
    {
//        if(err != kAXErrorNoValue)
//            cout << "failed to retrieve attribute: " << err << endl;
    }
    else
    {
        ret = Attribute(value);
        CFRelease(value);
    }
    
    return ret;
}

AXError UIElement::setAttribute(CFStringRef name, const Attribute &att)
{
    Boolean settable = false;
    
    AXError err = AXUIElementIsAttributeSettable(_element_ref, name, &settable);
    if(err || !settable)
        return err;
    
    return AXUIElementSetAttributeValue(_element_ref, name, att._type_ref);
}

int UIElement::hasAttribute(CFStringRef name)
{
    CFTypeRef value;
    AXError err = AXUIElementCopyAttributeValue(_element_ref, name, &value);
    
    if(err == kAXErrorSuccess)
    {
        CFRelease(value);
        return 1;
    }
    else if(err == kAXErrorAttributeUnsupported || err == kAXErrorNoValue)
    {
        return 0;
    }
    
    return -1;
}

bool UIElement::isAttributeSettable(CFStringRef name)
{
    Boolean settable = false;
    AXUIElementIsAttributeSettable(_element_ref, name, &settable);
    return (bool)settable;
}

AXError UIElement::performAction(CFStringRef name)
{
    return AXUIElementPerformAction(_element_ref, name);
}

AXError UIElement::setMessagingTimeout(float seconds) {
    return AXUIElementSetMessagingTimeout(_element_ref, seconds);
}

}

/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Nicolas Jinchereau. All rights reserved.
 *  Licensed under the MIT License. See License.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

#include <ax/Attribute.h>
#include <ax/UIElement.h>
#import <Cocoa/Cocoa.h>
#include <CoreFoundation/CoreFoundation.h>
#include <ApplicationServices/ApplicationServices.h>
#include <iostream>

namespace ax
{

Attribute::Attribute()
    : _type_ref(NULL)
{
    
}

Attribute::Attribute(const Attribute &other)
    : _type_ref(other._type_ref)
{
    if(_type_ref) CFRetain(_type_ref);
}

Attribute::Attribute(Attribute &&other)
    : _type_ref(other._type_ref)
{
    other._type_ref = NULL;
}

Attribute::Attribute(const UIElement& element)
    : _type_ref((CFTypeRef)element._element_ref)
{
    if(_type_ref) CFRetain(_type_ref);
}

Attribute::Attribute(CFTypeRef typeRef)
    : _type_ref(typeRef)
{
    if(typeRef) CFRetain(typeRef);
}

Attribute::Attribute(CGSize size)
{
    _type_ref = AXValueCreate(kAXValueTypeCGSize, &size);
}

Attribute::Attribute(CGPoint point)
{
    _type_ref = AXValueCreate(kAXValueTypeCGSize, &point);
}
    
Attribute::~Attribute()
{
    if(_type_ref) CFRelease(_type_ref);
}

Attribute& Attribute::operator=(nullptr_t)
{
    if(_type_ref) CFRelease(_type_ref);
    _type_ref = NULL;
    return *this;
}

Attribute& Attribute::operator=(const Attribute &other)
{
    if(_type_ref) CFRelease(_type_ref);
    _type_ref = other._type_ref;
    if(_type_ref) CFRetain(_type_ref);
    return *this;
}

Attribute& Attribute::operator=(Attribute &&other)
{
    if(_type_ref) CFRelease(_type_ref);
    _type_ref = other._type_ref;
    other._type_ref = NULL;
    return *this;
}

CFTypeRef Attribute::typeRef()
{
    return _type_ref;
}

bool Attribute::boolValue()
{
    return CFBooleanGetValue((CFBooleanRef)_type_ref);
}

int Attribute::intValue()
{
    int value = 0;
    
    if(_type_ref && CFGetTypeID(_type_ref) == CFNumberGetTypeID())
        CFNumberGetValue((CFNumberRef)_type_ref, kCFNumberSInt32Type, &value);
    
    return value;
}

string Attribute::stringValue()
{
    string ret;
    
    if(_type_ref && CFGetTypeID(_type_ref) == CFStringGetTypeID())
    {
        CFStringRef cfs = (CFStringRef)_type_ref;
        CFIndex len = CFStringGetLength(cfs);
        CFIndex maxSize = CFStringGetMaximumSizeForEncoding(len, kCFStringEncodingUTF8) + 1;
        
        ret.resize(maxSize, 0);
        
        if(CFStringGetCString(cfs, (char*)ret.data(), maxSize, kCFStringEncodingUTF8))
            ret.resize(strlen(ret.data()));
        else
            ret.resize(0);
    }
    
    return ret;
}

CGSize Attribute::sizeValue()
{
    if(AXValueGetType((AXValueRef)_type_ref) == kAXValueCGSizeType)
    {
        CGSize size;
        AXValueGetValue((AXValueRef)_type_ref, kAXValueTypeCGSize, &size);
        return size;
    }
    else
    {
        return CGSizeMake(0, 0);
    }
}

CGPoint Attribute::pointValue()
{
    if(AXValueGetType((AXValueRef)_type_ref) == kAXValueCGPointType)
    {
        CGPoint point;
        AXValueGetValue((AXValueRef)_type_ref, kAXValueTypeCGPoint, &point);
        return point;
    }
    else
    {
        return CGPointMake(0, 0);
    }
}

UIElement Attribute::elementRefValue() {
    return UIElement((AXUIElementRef)_type_ref);
}

AXValueType Attribute::type() {
    return AXValueGetType((AXValueRef)_type_ref);
}
    
}

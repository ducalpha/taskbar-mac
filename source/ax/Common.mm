/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Nicolas Jinchereau. All rights reserved.
 *  Licensed under the MIT License. See License.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

#include <ax/Common.h>

namespace ax
{

std::string to_string(AXError error)
{
    switch(error)
    {
        case kAXErrorSuccess:
            return "Success";
        
        case kAXErrorFailure:
            return "Failure";
        
        case kAXErrorIllegalArgument:
            return "Illegal Argument";
        
        case kAXErrorInvalidUIElement:
            return "Invalid UIElement";
        
        case kAXErrorInvalidUIElementObserver:
            return "Invalid UIElement Observer";
        
        case kAXErrorCannotComplete:
            return "Cannot Complete";
        
        case kAXErrorAttributeUnsupported:
            return "Attribute Unsupported";
        
        case kAXErrorActionUnsupported:
            return "Action Unsupported";
        
        case kAXErrorNotificationUnsupported:
            return "Notification Unsupported";
        
        case kAXErrorNotImplemented:
            return "Not Implemented";
        
        case kAXErrorNotificationAlreadyRegistered:
            return "Notification Already Registered";
        
        case kAXErrorNotificationNotRegistered:
            return "Notification Not Registered";
        
        case kAXErrorAPIDisabled:
            return "API Disabled";
        
        case kAXErrorNoValue:
            return "No Value";
        
        case kAXErrorParameterizedAttributeUnsupported:
            return "Parameterized Attribute Unsupported";
        
        case kAXErrorNotEnoughPrecision:
            return "Not Enough Precision";
            
        default:
            return "Invalid Error Type";
    }
}

}

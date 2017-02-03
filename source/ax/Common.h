/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Nicolas Jinchereau. All rights reserved.
 *  Licensed under the MIT License. See License.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

#pragma once
#include <cstdlib>
#include <string>
#import <Cocoa/Cocoa.h>

namespace ax
{

constexpr float AX_RETRY_DELAY = 1.0f;

// This applies to 'Application' and 'Window' objects.
enum class State
{
    // An application or window can enter this state if it's AXUIElementRef became invalid before destruction callbacks could be registered.
    Invalid = -1,
    
    // This is the initial state of an 'Application' and 'Window', before it's update() function has succeeded, or it's AXUIElementRef has been invalidated.
    Pending = 0,
    
    // Once an 'Application' or 'Window' update() function succeeds, all callbacks are registered, and initial information is retrieved, it is set to this state
    Valid = 1
};

inline bool equal_pointees(CFTypeRef x, CFTypeRef y) {
    return (x == NULL) != (y == NULL) ? false : ((x == NULL) || (bool)CFEqual(x, y));
}

inline bool unequal_pointees(CFTypeRef x, CFTypeRef y) {
    return (x == NULL) != (y == NULL) ? true : ((x != NULL) && !(bool)CFEqual(x, y));
}

std::string to_string(AXError error);

}

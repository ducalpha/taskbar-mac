/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Nicolas Jinchereau. All rights reserved.
 *  Licensed under the MIT License. See License.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

#import <Cocoa/Cocoa.h>
#import "AppDelegate.h"

int main(int argc, const char * argv[])
{
    @autoreleasepool
    {
        auto del = [[AppDelegate alloc] init];
        [[NSApplication sharedApplication] setDelegate:del];
        [[NSApplication sharedApplication] run];
    }
    
    return 0;
}

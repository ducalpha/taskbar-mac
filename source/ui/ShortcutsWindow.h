/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Nicolas Jinchereau. All rights reserved.
 *  Licensed under the MIT License. See License.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

#pragma once

#import <Cocoa/Cocoa.h>
#include <vector>
#include <string>
#include <memory>
using namespace std;

@interface ShortcutsWindow : NSWindow<NSTableViewDataSource, NSWindowDelegate>
{
    NSTableView *_tableView;
    NSScrollView *_scrollView;
    NSMutableArray<NSString *> *_shortcuts;
}
@property (readonly) NSTableView* tableView;
- (id)init;
- (void)removeShortcut:(id)sender;
@end

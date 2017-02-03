/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Nicolas Jinchereau. All rights reserved.
 *  Licensed under the MIT License. See License.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

#pragma once
#include <iostream>
#include <Foundation/Foundation.h>
#include <Cocoa/Cocoa.h>
#include <AppKit/AppKit.h>
#include <ui/HoverButton.h>
using namespace std;

@interface AppleButton : HoverButton
- (id)initWithFrame:(NSRect)frame;
- (void)onClickedQuit:(NSEvent*)theEvent;
- (void)onClickEditShortcuts:(NSEvent*)theEvent;
@end

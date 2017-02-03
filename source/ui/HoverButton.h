/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Nicolas Jinchereau. All rights reserved.
 *  Licensed under the MIT License. See License.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

#pragma once
#include <iostream>
#include <functional>
#include <Foundation/Foundation.h>
#include <Cocoa/Cocoa.h>
#include <QuartzCore/QuartzCore.h>
#include <QuartzCore/CVDisplayLink.h>
#include <CoreVideo/CoreVideo.h>
#include <ui/Utils.h>
using namespace std;

struct WindowInfo;

@interface HoverButtonCell : NSButtonCell
{
@public bool _hot;
@public bool _focused;
@public bool _down;
    
    NSDictionary *textAttributes;
    NSImage *_hotImage;
    NSGradient* _hotGradient;
    NSGradient* _selectedGradient;
    NSGradient* _pressedGradient;
}
-(void)setHotImage:(NSImage*)image;
@end

@interface HoverButton : NSButton
{
    HoverButtonCell *buttonCell;
    NSTrackingArea *focusTrackingArea;
    function<void(NSEvent*)> _leftClickAction;
    function<void(NSEvent*)> _rightClickAction;
    function<void()> _dragAction;
    BOOL _enabled;
    
    NSTimer *_hoverTimer;
    bool _mouseDown;
    bool _leftDown;
    bool _rightDown;
}
@property function<void(NSEvent*)> leftClickAction;
@property function<void(NSEvent*)> rightClickAction;
@property function<void()> dragAction;
@property BOOL isEnabled;
-(id)initWithFrame:(NSRect)frame title:(NSString*)title;
-(void)setHotImage:(NSImage*)image;
-(void)setTitle:(NSString*)title;
-(void)setFocused:(BOOL)focused;
-(HoverButtonCell*)hoverButtonCell;
// called by TaskBarWindow
-(void)globalLeftMouseDown;
-(void)globalLeftMouseUp;
@end

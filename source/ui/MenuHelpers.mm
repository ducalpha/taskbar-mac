/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Nicolas Jinchereau. All rights reserved.
 *  Licensed under the MIT License. See License.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

#include <ui/MenuHelpers.h>

@implementation ForceMenuPos
-(id)initWithPoint:(NSPoint)point level:(NSInteger)level;
{
    self = [super initWithFrame:NSMakeRect(0, 0, 1, 1)];
    
    if(self)
    {
        _point = point;
        _level = level;
        self.autoresizingMask |= NSViewWidthSizable;
    }
    
    return self;
}

+(NSMenuItem*)forcePosItem:(NSPoint)point level:(NSInteger)level
{
    NSMenuItem *ret = [[[NSMenuItem alloc] init] autorelease];
    ForceMenuPos *fmp = [[[ForceMenuPos alloc] initWithPoint:point level:level] autorelease];
    [ret setView:fmp];
    return ret;
}

- (void)viewDidMoveToWindow
{
    NSWindow *window = [self window];
    [window setLevel:_level];
    
    NSRect frame = [window frame];
    NSRect screen = [[NSScreen mainScreen] frame];
    
    NSPoint pt = _point;
    
    if(pt.x + frame.size.width > screen.size.width)
        pt.x -= frame.size.width;
    
    frame.origin = pt;
    
    [window setFrame:frame display:YES];
}
@end

////////////

@implementation ActionItem
- (void)onClick:(id)sender
{
    if(_fn)
        _fn();
}

-(id)initWithTitle:(NSString*)title action:(const function<void()>&)action;
{
    self = [super initWithTitle:title action:@selector(onClick:) keyEquivalent:@""];
    
    if(self)
    {
        _fn = action;
        [self setTarget:self];
    }
    
    return self;
}

+(NSMenuItem*)itemWithTitle:(NSString*)title action:(const function<void()>&)action;
{
    return [[[ActionItem alloc] initWithTitle:title action:action] autorelease];
}
@end


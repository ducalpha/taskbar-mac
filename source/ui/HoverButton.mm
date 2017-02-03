/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Nicolas Jinchereau. All rights reserved.
 *  Licensed under the MIT License. See License.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

#include <ui/HoverButton.h>
#include <ax/AXWorkspace.h>

@implementation HoverButtonCell

-(id)initTextCell:(NSString*)aString
{
    self = [super initTextCell:aString];
    
    if(self)
    {
        _hot = false;
        _focused = false;
        _down = false;
        _hotImage = nil;
        
        NSColor* _hotGradStart = [NSColor colorWithRed:(165 / 255.0f) green:(227 / 255.0f) blue:(254 / 255.0f) alpha:1.0f];
        NSColor* _hotGradEnd = [NSColor colorWithRed:(44 / 255.0f) green:(182 / 255.0f) blue:(255 / 255.0f) alpha:1.0f];
        _hotGradient = [[NSGradient alloc] initWithStartingColor:_hotGradStart endingColor:_hotGradEnd];
        
        NSColor* _selectedGradStart = [NSColor colorWithRed:(178 / 255.0f) green:(206 / 255.0f) blue:(220 / 255.0f) alpha:1.0f];
        NSColor* _selectedGradEnd = [NSColor colorWithRed:(107 / 255.0f) green:(163 / 255.0f) blue:(195 / 255.0f) alpha:1.0f];
        _selectedGradient = [[NSGradient alloc] initWithStartingColor:_selectedGradStart endingColor:_selectedGradEnd];
        
        NSColor* _pressedGradStart = [NSColor colorWithRed:(127 / 255.0f) green:(192 / 255.0f) blue:(247 / 255.0f) alpha:1.0f];
        NSColor* _pressedGradEnd = [NSColor colorWithRed:(47 / 255.0f) green:(146 / 255.0f) blue:(247 / 255.0f) alpha:1.0f];
        _pressedGradient = [[NSGradient alloc] initWithStartingColor:_pressedGradStart endingColor:_pressedGradEnd];
        
        NSMutableParagraphStyle *textStyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
        [textStyle setLineBreakMode:NSLineBreakByClipping];
        [textStyle setAlignment:NSLeftTextAlignment];
        
        textAttributes = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                         textStyle, NSParagraphStyleAttributeName,
                         [NSColor blackColor], NSForegroundColorAttributeName,
                         nil];
    }
    
    return self;
}

-(void)dealloc
{
    [_hotImage release];
    [textAttributes release];
    [_hotGradient release];
    [_selectedGradient release];
    [_pressedGradient release];
    [super dealloc];
}

- (void)setHotImage:(NSImage*)image
{
    [_hotImage release];
    _hotImage = [image retain];
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView*)controlView
{
    ////////////////
    // background
    
    NSRect rect = NSInsetRect(cellFrame, 0.5f, 1.5f);
    
    if(_down)
    {
        if(_hot)
            [_pressedGradient drawInRect:rect angle:90];
        else
            [_hotGradient drawInRect:rect angle:90];
    }
    else if(_hot)
    {
        [_hotGradient drawInRect:rect angle:90];
    }
    else if(_focused)
    {
        [_selectedGradient drawInRect:rect angle:90];
    }
    else
    {
        [[NSColor controlColor] setFill];
        [NSBezierPath fillRect:rect];
    }
    
    ////////////////
    // border
    
    [[NSColor controlShadowColor] set];
    [NSBezierPath strokeRect:rect];
    
    ////////////////
    // image
    
    NSImage *image;
    
    if((_down || _hot || _focused) && _hotImage != nil)
        image = _hotImage;
    else
        image = [self image];
    
    NSRect imageRect = NSMakeRect(0.0f, 0.0f, [image size].width, [image size].height);
    
    if([self imagePosition] == NSImageOnly)
    {
        NSRect rc = NSMakeRect((cellFrame.size.width - 28) / 2, (cellFrame.size.height - 28) / 2, 28, 28);
        [image drawInRect:rc fromRect:imageRect operation:NSCompositeSourceOver fraction:1.0f respectFlipped:TRUE hints:nil];
    }
    else
    {
        NSRect rc = NSMakeRect(2, 2, 28, 28);
        [image drawInRect:rc fromRect:imageRect operation:NSCompositeSourceOver fraction:1.0f respectFlipped:TRUE hints:nil];
    }
    
    ////////////////
    // text
    
    if(_hot || _down)
        [textAttributes setValue:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
    else
        [textAttributes setValue:[NSColor blackColor] forKey:NSForegroundColorAttributeName];
    
    NSRect textRect = cellFrame;
    textRect.origin.x += [image size].width + 5;
    textRect.size.width -= [image size].width + 10;
    textRect.origin.y = (textRect.size.height - [self font].pointSize) * 0.5f;
    
    [self.title drawInRect:textRect withAttributes:textAttributes];
}

@end


@implementation HoverButton

+ (Class)cellClass
{
   return [HoverButtonCell class];
}

- (id)initWithFrame:(NSRect)frame title:(NSString*)title
{
    self = [super initWithFrame:frame];
    
    if(self)
    {
        _leftDown = false;
        _rightDown = false;
        _enabled = YES;
        focusTrackingArea = nil;
        
        buttonCell = [[[HoverButtonCell alloc] initTextCell:title] autorelease];
        [buttonCell setGradientType:NSGradientConvexWeak];
        [buttonCell setButtonType:NSMomentaryLightButton];
        [buttonCell setBordered:YES];
        [buttonCell setBezelStyle:NSSmallSquareBezelStyle];
        [buttonCell setAlignment:NSLeftTextAlignment];
        [buttonCell setFont:[NSFont systemFontOfSize:12]];
        [buttonCell setImagePosition:NSImageLeft];
        [buttonCell setImageScaling:NSImageScaleProportionallyUpOrDown];
        
        [self setCell:buttonCell];
        [self setToolTip:title];
        [self resetTrackingRect];
        [self setNeedsDisplay:YES];
    }
    
    return self;
}

- (void)dealloc
{
    [self removeTrackingArea:focusTrackingArea];
    [super dealloc];
}

-(BOOL)canBecomeKeyView
{
    return NO;
}

- (void)setHotImage:(NSImage*)image
{
    [buttonCell setHotImage:image];
}

- (void)setFocused:(BOOL)focused
{
    buttonCell->_focused = focused;
    [self setNeedsDisplay:YES];
}

- (void)setTitle:(NSString*)title
{
    [super setTitle:title];
    HoverButtonCell * btnCell = (HoverButtonCell*)[self cell];
    [btnCell setTitle:title];
}

-(HoverButtonCell*)hoverButtonCell {
    return (HoverButtonCell*)[self cell];
}

- (function<void(NSEvent*)>)leftClickAction {
    return _leftClickAction;
}

- (void)setLeftClickAction:(function<void(NSEvent*)>)fn {
    _leftClickAction = fn;
}

- (function<void(NSEvent*)>)rightClickAction {
    return _rightClickAction;
}

- (void)setRightClickAction:(function<void(NSEvent*)>)fn {
    _rightClickAction = fn;
}

- (function<void()>)dragAction {
    return _dragAction;
}

- (void)setDragAction:(function<void()>)fn {
    _dragAction = fn;
}

- (BOOL)isEnabled {
    return _enabled;
}

- (void)setIsEnabled:(BOOL)enabled {
    _enabled = enabled;
}

- (void)sizeToFit
{
    [self resetTrackingRect];
    [self setNeedsDisplay:YES];
}

- (void)frameDidChange:(NSNotification *)aNotification
{
    [self resetTrackingRect];
    [self setNeedsDisplay:YES];
}

- (void)resetTrackingRect
{
    if(focusTrackingArea)
        [self removeTrackingArea:focusTrackingArea];
    
    NSTrackingAreaOptions focusTrackingAreaOptions = NSTrackingMouseEnteredAndExited;
    focusTrackingAreaOptions |= NSTrackingActiveAlways;
    focusTrackingAreaOptions |= NSTrackingEnabledDuringMouseDrag;
    focusTrackingAreaOptions |= NSTrackingInVisibleRect;
    
    NSRect trackingRect = [self frame];
    trackingRect.origin = NSZeroPoint;
    
    focusTrackingArea = [[NSTrackingArea alloc] autorelease];
    [focusTrackingArea initWithRect:trackingRect
                       options:focusTrackingAreaOptions
                       owner:self userInfo:nil];
    
    [self addTrackingArea:focusTrackingArea];
}

- (void)mouseDown:(NSEvent*)theEvent
{
    if(!_rightDown)
    {
        _leftDown = true;
        
        buttonCell->_down = true;
        [self setNeedsDisplay:YES];
        
        [self cancelHoverTimer];
    }
}

-(void)mouseUp:(NSEvent *)theEvent
{
    if(_leftDown)
    {
        _leftDown = false;
        
        buttonCell->_down = false;
        [self setNeedsDisplay:YES];
        
        if(_enabled && _leftClickAction)
        {
            NSPoint pos = [self convertPoint:[theEvent locationInWindow] fromView:nil];
            bool inside = [self mouse:pos inRect:[self bounds]];
            if(inside)
                _leftClickAction(theEvent);
        }
    }
}

- (void)rightMouseDown:(NSEvent*)theEvent
{
    if(!_leftDown)
    {
        _rightDown = true;
        
        buttonCell->_down = true;
        [self setNeedsDisplay:YES];
        
        [self cancelHoverTimer];
    }
}

-(void)rightMouseUp:(NSEvent *)theEvent
{
    if(_rightDown)
    {
        _rightDown = false;
        
        buttonCell->_down = false;
        [self setNeedsDisplay:YES];
        
        if(_enabled && _rightClickAction)
            _rightClickAction(theEvent);
    }
}

-(void)startHoverTimer
{
    if(!_hoverTimer)
        _hoverTimer = [NSTimer scheduledTimerWithTimeInterval:0.5f target:self selector:@selector(onDragHover:) userInfo:nil repeats:NO];
}

-(void)cancelHoverTimer
{
    if(_hoverTimer)
    {
        [_hoverTimer invalidate];
        _hoverTimer = nil;
    }
}

-(void)mouseEntered:(NSEvent*)theEvent
{
    buttonCell->_hot = true;
    [self setNeedsDisplay:YES];
    
    if(_dragAction && _mouseDown)
        [self startHoverTimer];
}

-(void)mouseExited:(NSEvent*)theEvent
{
    buttonCell->_hot = false;
    [self setNeedsDisplay:YES];
    
    [self cancelHoverTimer];
}

- (void)globalLeftMouseDown
{
    _mouseDown = true;
}

- (void)globalLeftMouseUp
{
    _mouseDown = false;
    
    if(_hoverTimer)
    {
        [_hoverTimer invalidate];
        _hoverTimer = nil;
    }
}

-(void)onDragHover:(NSTimer*)timer
{
    _hoverTimer = nil;
    
    if(_dragAction)
        _dragAction();
}

@end

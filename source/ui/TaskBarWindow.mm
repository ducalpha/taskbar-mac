/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Nicolas Jinchereau. All rights reserved.
 *  Licensed under the MIT License. See License.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

#include <ui/TaskBarWindow.h>
#include <ui/AppleButton.h>
#include <ui/MenuHelpers.h>
#include <Cocoa/Cocoa.h>
#include <AppKit/AppKit.h>
#include <algorithm>

#define TB_HEIGHT                   32
#define START_BTN_WIDTH             64
#define START_BTN_HEIGHT            32
#define START_BTN_RIGHT_SPACING     4
#define BUTTON_SIZE                 200
#define BUTTON_SPACING              1
#define UPDATE_RATE                 0.1f
#define BUTTON_EXPAND_SPEED         3.0f

CVReturn RenderTaskBarButtons(CVDisplayLinkRef displayLink,
                              const CVTimeStamp *inNow,
                              const CVTimeStamp *inOutputTime,
                              CVOptionFlags flagsIn,
                              CVOptionFlags *flagsOut,
                              void *displayLinkContext)
{
    TaskBarWindow *taskbarWindow = (__bridge TaskBarWindow*)displayLinkContext;
    [taskbarWindow performSelectorOnMainThread:@selector(updateAnimation) withObject:nil waitUntilDone:NO];
    return 0;
}

class WindowInfo
{
public:
    WindowInfo(){}
    
    ~WindowInfo() {
        [icon release];
        [app release];
    }
    
    NSRunningApplication *app;
    ax::Window* window;
    uint64_t processId;
    string title;
    NSImage *icon;
    HoverButton *button;
    float currentWidth;
    bool keep;
    bool updateTitle;
    bool unsupported;
};

@implementation TaskBarWindow

-(id)init
{
    rect = [[NSScreen mainScreen] frame];
    rect.origin.x = 0;
    rect.origin.y = 0;
    rect.size.height = TB_HEIGHT;
    
    self = [super initWithContentRect:rect styleMask:NSNonactivatingPanelMask backing:NSBackingStoreBuffered defer:NO];
    
    if(self)
    {
        NSString *title = @"MyTaskbar_865d3ddb-d43b-40f1-bc2d-74fcf3d725e7";
        [self setTitle:title];
        [self setLevel:NSDockWindowLevel + 1];
        [self orderFrontRegardless];
        
        NSRect rc = NSMakeRect(BUTTON_SPACING, 0, START_BTN_WIDTH, START_BTN_HEIGHT);
        _appleButton = [[[AppleButton alloc] initWithFrame:rc] autorelease];
        [[self contentView] addSubview:_appleButton];
        
        TaskBarWindow *tb = self;
        
        NSEventMask eventMask = NSLeftMouseDownMask | NSLeftMouseUpMask;
        
        _mouseEventMonitor = [NSEvent addGlobalMonitorForEventsMatchingMask:eventMask handler:^(NSEvent *event)
        {
            if(event.type == NSLeftMouseDown)
            {
                [tb globalLeftMouseDown];
            }
            else if(event.type == NSLeftMouseUp)
            {
                [tb globalLeftMouseUp];
            }
        }];
        
        CVDisplayLinkCreateWithActiveCGDisplays(&displayLink);
        CVDisplayLinkSetCurrentCGDisplay(displayLink, CGMainDisplayID());
        CVDisplayLinkSetOutputCallback(displayLink, &RenderTaskBarButtons, (void*)self);
    }
    
    return self;
}

- (void)dealloc
{
    [NSEvent removeMonitor:_mouseEventMonitor];
    CVDisplayLinkRelease(displayLink);
    [super dealloc];
}

-(BOOL)canBecomeKeyWindow
{
    return NO;
}

-(BOOL)canBecomeMainWindow
{
    return NO;
}

-(void)globalLeftMouseDown
{
    for(auto& info : _windows)
        [info->button globalLeftMouseDown];
}

-(void)globalLeftMouseUp
{
    for(auto& info : _windows)
        [info->button globalLeftMouseUp];
}

-(void)startAnimation
{
    if(!CVDisplayLinkIsRunning(displayLink))
    {
        lastRender = CACurrentMediaTime();
        CVDisplayLinkStart(displayLink);
    }
}

-(void)stopAnimation
{
    if(CVDisplayLinkIsRunning(displayLink))
    {
        CVDisplayLinkStop(displayLink);
    }
}

-(BOOL)isAnimating
{
    return CVDisplayLinkIsRunning(displayLink);
}

- (void)updateWindows:(NSTimer*)timer
{
    rect = [[NSScreen mainScreen] frame];
    rect.origin.x = 0;
    rect.origin.y = 0;
    rect.size.height = TB_HEIGHT;
    
    NSRect currentFrame = [[self contentView] frame];
    NSRect newFrame = [self frameRectForContentRect:rect];
    
    if(!NSEqualRects(currentFrame, newFrame))
    {
        [self setFrame:newFrame display:YES];
    }
}

- (void)updateAnimation
{
    float deltaTime = (float)(CACurrentMediaTime() - lastRender);
    
    float usedWidth = BUTTON_SPACING + START_BTN_WIDTH + START_BTN_RIGHT_SPACING;
    usedWidth += (float)(max((int)_windows.size() - 1, 0)) * BUTTON_SPACING;
    
    float availableWidth = [self frame].size.width - usedWidth;
    int maxButtonSize = (int)(availableWidth / (float)_windows.size());
    
    int windowButtonX = BUTTON_SPACING + START_BTN_WIDTH + START_BTN_RIGHT_SPACING;
    
    bool didUpdateButton = false;
    
    for(auto it = _windows.begin();
             it != _windows.end(); )
    {
        auto &info = (*it);
        
        if(info->keep)
        {
            if(info->currentWidth < BUTTON_SIZE - 0.1f)
            {
                info->currentWidth = std::min(info->currentWidth
                                   + BUTTON_SIZE * BUTTON_EXPAND_SPEED
                                   * deltaTime, (float)BUTTON_SIZE);
                didUpdateButton = true;
            }
        }
        else
        {
            if(info->currentWidth > 0.1f)
            {
                info->currentWidth = max(info->currentWidth
                                   - (float)BUTTON_SIZE * BUTTON_EXPAND_SPEED
                                   * deltaTime, 0.0f);
                didUpdateButton = true;
            }
        }
        
        if(info->currentWidth > 0.1f)
        {
            int visibleWidth = min((int)info->currentWidth, maxButtonSize);
            [info->button setFrame:NSMakeRect(windowButtonX, 0, visibleWidth, TB_HEIGHT)];
            windowButtonX += visibleWidth + BUTTON_SPACING;
            ++it;
        }
        else
        {
            [info->button removeFromSuperview];
            it = _windows.erase(it);
        }
    }
    
    if(!didUpdateButton)
    {
        [self stopAnimation];
    }
}

-(void)mouseDown:(NSEvent *)theEvent
{
    NSPoint mouseLoc = [NSEvent mouseLocation];
    
    CGFloat x = mouseLoc.x;
    CGFloat y = mouseLoc.y;
    
    if(x < START_BTN_WIDTH && y < START_BTN_HEIGHT)
    {
        [_appleButton performClick:nil];
    }
}

-(void)clearWindows
{
    for(auto &info : _windows)
        [info->button removeFromSuperview];
    
    _windows.clear();
}

-(void)addWindow:(ax::Window*)window
{
    NSRunningApplication *runningApp = window->app()->runningApplication();
    
    if(!runningApp)
        return;
    
    int windowButtonX = BUTTON_SPACING + START_BTN_WIDTH + START_BTN_RIGHT_SPACING;
    
    for(auto &info : _windows)
        windowButtonX += info->currentWidth + BUTTON_SPACING;
    
    auto info = make_shared<WindowInfo>();
    
    info->app = [runningApp retain];
    info->window = window;
    info->processId = window->app()->processID();
    info->title = window->title();
    info->icon = [[runningApp icon] retain];
    info->keep = true;
    info->updateTitle = false;
    info->unsupported = false;
    info->currentWidth = 0.5f;
    
    NSString *btnText = [NSString stringWithUTF8String:window->title().c_str()];
    
    info->button = [[HoverButton alloc] autorelease];
    [info->button initWithFrame:NSMakeRect(0, 0, 0, 0) title:btnText];
    [info->button setImage:info->icon];
    
    info->button.leftClickAction = [=](NSEvent *event)
    {
        window->toggleFocusMinimize();
    };
    
    info->button.rightClickAction = [=](NSEvent *event)
    {
        NSMenu *menu = [[[NSMenu alloc] initWithTitle:@"AppMenu"] autorelease];
        
        auto minimizeAction = [=](){
            window->minimize();
        };
        
        auto closeAction = [=](){
            window->close();
        };
        
        [menu addItem:[ActionItem itemWithTitle:@"Minimize" action:minimizeAction]];
        [menu addItem:[NSMenuItem separatorItem]];
        [menu addItem:[ActionItem itemWithTitle:@"Close" action:closeAction]];
        [menu addItem:[ForceMenuPos forcePosItem:[NSEvent mouseLocation] level:NSDockWindowLevel + 1]];
        
        [NSMenu popUpContextMenu:menu withEvent:event forView:info->button];
    };
    
    info->button.dragAction = [=]()
    {
        window->focus();
    };
    
    [[self contentView] addSubview: info->button];
    
    _windows.push_back(info);
    
    [self startAnimation];
}

-(void)removeWindow:(ax::Window*)window
{
    auto it = std::find_if(_windows.begin(), _windows.end(), [window](const shared_ptr<WindowInfo>& info){
        return info->window == window;
    });
    
    if(it != _windows.end())
    {
        (*it)->keep = false;
        (*it)->button.isEnabled = NO;
        [self startAnimation];
    }
}

-(void)renameWindow:(ax::Window*)window
{
    auto it = std::find_if(_windows.begin(), _windows.end(), [window](const shared_ptr<WindowInfo>& info){
        return info->window == window;
    });
    
    if(it != _windows.end())
    {
        (*it)->title = window->title();
        NSString* nsTitle = [NSString stringWithUTF8String:window->title().c_str()];
        [(*it)->button setTitle:nsTitle];
    }
}

-(void)setWindowFocus:(ax::Window*)window focused:(bool)focused
{
    for(auto& win : _windows)
    {
        if(win->window == window) {
            [win->button setFocused:focused];
            break;
        }
    }
}
@end


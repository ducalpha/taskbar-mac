/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Nicolas Jinchereau. All rights reserved.
 *  Licensed under the MIT License. See License.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

#include <ax/AXWorkspace.h>
#include <ax/Window.h>
#include <iostream>
#include <functional>

using namespace std;
using namespace ax;

@implementation AXWorkspace

-(id)init
{
    self = [super init];
    
    if(self)
    {
        _focusedWindow = nullptr;
        _updateFocus = false;
        _systemWideElement = UIElement::systemWideElement();
        
        float timeout = 0.1f;
        //float timeout = 3.0f;
        AXError err = _systemWideElement.setMessagingTimeout(timeout);
        if(err != kAXErrorSuccess)
            cout << "failed to set timeout for workspace: " << to_string(err) << endl;
        
        NSNotificationCenter *nc = [[NSWorkspace sharedWorkspace] notificationCenter];
        [nc addObserver:self selector:@selector(onAppLaunched:) name:NSWorkspaceDidLaunchApplicationNotification object:nil];
        [nc addObserver:self selector:@selector(onAppTerminated:) name:NSWorkspaceDidTerminateApplicationNotification object:nil];
        
        NSArray *runningApps = [[NSWorkspace sharedWorkspace] runningApplications];
        
        for(NSRunningApplication *runningApp in runningApps)
        {
            if(runningApp.activationPolicy == NSApplicationActivationPolicyRegular)
            {
                NSDictionary* dict = @{ NSWorkspaceApplicationKey : runningApp };
                NSWorkspace* ws = [NSWorkspace sharedWorkspace];
                NSString* name = NSWorkspaceDidLaunchApplicationNotification;
                NSNotification* notif = [NSNotification notificationWithName:name object:ws userInfo:dict];
                [self onAppLaunched:notif];
            }
        }
        
        int errors = [self updateFocusedWindow];
        if(errors)
            [self setNeedsUpdate];
    }
    
    return self;
}

-(void)dealloc
{
    NSNotificationCenter *nc = [[NSWorkspace sharedWorkspace] notificationCenter];
    [nc removeObserver:self name:NSWorkspaceDidLaunchApplicationNotification object:nil];
    [nc removeObserver:self name:NSWorkspaceDidTerminateApplicationNotification object:nil];
    
    _applications = vector<shared_ptr<Application>>();
    
    [super dealloc];
}

-(vector<shared_ptr<ax::Application>>::iterator)findApplication:(NSRunningApplication*)runningApp
{
    pid_t pid = [runningApp processIdentifier];
    
    auto it = _applications.begin();
    
    for( ; it != _applications.end(); ++it) {
        if((*it)->processID() == pid)
            break;
    }

    return it;
}

-(ax::Application*)getApplication:(NSRunningApplication*)runningApp
{
    pid_t pid = [runningApp processIdentifier];
    
    auto it = _applications.begin();
    
    for( ; it != _applications.end(); ++it) {
        if((*it)->processID() == pid)
            break;
    }
    
    return it != _applications.end() ? it->get() : nullptr;
}

-(void)retryUpdate
{
    //cout << "retrying update..." << endl;
    
    _needUpdate = false;
    
    int errors = 0;
    
    for(auto it = _applications.begin(); it != _applications.end(); )
    {
        auto& app = *it;
        
        errors += app->update();
        
        if(app->state() == State::Invalid)
            it = _applications.erase(it);
        else
            ++it;
    }
    
    if(_updateFocus)
        errors += [self updateFocusedWindow];
    
    if(errors)
        [self setNeedsUpdate];
}

-(void)focusMainWindow:(ax::Application*)app
{
    try
    {
        Attribute mainWindowAttrib = app->element().attributeFor(kAXMainWindowAttribute);
        if(!mainWindowAttrib)
            throw runtime_error("failed to get main window attrib");
        
        UIElement mainWindow = mainWindowAttrib.elementRefValue();
        if(!mainWindow)
            throw runtime_error("failed to get main window element");
        
        ax::Window* win = app->getWindow(mainWindow);
        
        if(_focusedWindow != win)
        {
            if(_focusedWindow)
                [self windowFocusChanged:_focusedWindow focused:false];
            
            if(win)
                [self windowFocusChanged:win focused:true];
            
            _focusedWindow = win;
        }
        
        _updateFocus = false;
    }
    catch(exception& ex)
    {
        _updateFocus = true;
        [self setNeedsUpdate];
    }
}

-(void)focusWindow:(ax::Window*)win focused:(bool)focused
{
    try
    {
        if(focused)
        {
            if(win == nullptr)
                throw runtime_error("window is null");
            
            Attribute mainAttrib = win->element().attributeFor(kAXMainAttribute);
            if(!mainAttrib)
                throw runtime_error("failed to get main attrib");
            
            if(mainAttrib.boolValue())
            {
                if(_focusedWindow != win)
                {
                    if(_focusedWindow)
                        [self windowFocusChanged:_focusedWindow focused:false];
                    
                    if(win)
                        [self windowFocusChanged:win focused:true];
                    
                    _focusedWindow = win;
                }
            }
        }
        else
        {
            if(win && _focusedWindow == win)
            {
                [self windowFocusChanged:win focused:false];
                _focusedWindow = nullptr;
            }
        }
        
        _updateFocus = false;
    }
    catch(exception& ex)
    {
        cout << ex.what() << endl;
        _updateFocus = true;
        [self setNeedsUpdate];
    }
}

+(void)assertAccessibilityEnabled
{
    // check if accessibility is enabled for this app
#if(MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_9)
    BOOL axEnabled = AXAPIEnabled();
#else
    NSDictionary *options = @{ (id)kAXTrustedCheckOptionPrompt: @YES };
    BOOL axEnabled = AXIsProcessTrustedWithOptions((CFDictionaryRef)options);
#endif
    
    if(!axEnabled)
    {
        [[NSWorkspace sharedWorkspace] openFile:@"/System/Library/PreferencePanes/Security.prefPane"];
        [NSApp terminate:self];
        return;
    }
}

-(int)updateFocusedWindow
{
    int errors = 0;
    
    try
    {
        NSWorkspace* ws = [NSWorkspace sharedWorkspace];
        NSRunningApplication* runningApp = [ws frontmostApplication];
        
        if(runningApp != nullptr && runningApp.activationPolicy == NSApplicationActivationPolicyRegular)
        {
            Application* app = [self getApplication:runningApp];
            if(!app)
                throw runtime_error("cound't find ax::Application for running app: "s + [[runningApp localizedName] UTF8String]);
            
            Attribute mainWindowAttrib = app->element().attributeFor(kAXMainWindowAttribute);
            if(!mainWindowAttrib)
                throw runtime_error("couldn't get kAXMainWindowAttribute: "s + app->title());
            
            UIElement mainWindow = mainWindowAttrib.elementRefValue();
            if(!mainWindow)
                throw runtime_error("mainWindow element is empty: "s + app->title());
            
            Window* win = app->getWindow(mainWindow);
            if(!win)
                throw runtime_error("couldn't find window for mainWindow windowRef: "s + app->title());
            
            if(_focusedWindow != win)
            {
                if(_focusedWindow)
                    [self windowFocusChanged:_focusedWindow focused:false];
                
                if(win)
                    [self windowFocusChanged:win focused:true];
                
                _focusedWindow = win;
            }
        }
        
        _updateFocus = false;
    }
    catch(exception& ex)
    {
        cout << ex.what() << endl;
        ++errors;
    }
    
    return errors;
};

-(void)onAppLaunched:(NSNotification*)notification
{
    NSRunningApplication *runningApp = [[notification userInfo] objectForKey:NSWorkspaceApplicationKey];
    if(runningApp.activationPolicy == NSApplicationActivationPolicyRegular)
    {
        if([self getApplication:runningApp] == nullptr)
        {
            auto app = make_shared<ax::Application>(self, runningApp);
            _applications.push_back(app);
            
            int errors = app->update();
            if(errors)
                [self setNeedsUpdate];
        }
    }
}

-(void)onAppTerminated:(NSNotification*)notification
{
    NSRunningApplication *runningApp = [[notification userInfo] objectForKey:NSWorkspaceApplicationKey];
    if(runningApp.activationPolicy == NSApplicationActivationPolicyRegular)
    {
        auto it = [self findApplication:runningApp];
        if(it != _applications.end())
        {
            _applications.erase(it);
        }
    }
}

-(void)setNeedsUpdate
{
    if(!_needUpdate)
    {
        _needUpdate = true;
        [self performSelector:@selector(retryUpdate) withObject:nil afterDelay:AX_RETRY_DELAY];
    }
}

-(void)applicationCreated:(ax::Application*)app{}
-(void)applicationDestroyed:(ax::Application*)app{}
-(void)windowCreated:(ax::Window*)window{}
-(void)windowDestroyed:(ax::Window*)window{}
-(void)windowRenamed:(ax::Window*)window{}
-(void)windowResized:(ax::Window*)window{}
-(void)windowMoved:(ax::Window*)window{}
-(void)windowFocusChanged:(ax::Window*)window focused:(bool)focused{}
@end


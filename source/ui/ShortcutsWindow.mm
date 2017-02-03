/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Nicolas Jinchereau. All rights reserved.
 *  Licensed under the MIT License. See License.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

#include <ui/ShortcutsWindow.h>
#include <ui/Utils.h>

@implementation ShortcutsWindow

- (id)init
{
    int style = NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask;
    NSRect rect = NSMakeRect(0, 0, 400, 300);
    
    self = [super initWithContentRect:rect styleMask:style backing:NSBackingStoreBuffered defer:NO];
    
    if(self)
    {
        _shortcuts = [[NSMutableArray array] retain];
        
        [self setReleasedWhenClosed:YES];
        [self setDelegate:self];
        [[self contentView] setCornerRadius:0];
        
        NSRect tableRect = [[self contentView] bounds];
        tableRect.origin.y += 22;
        tableRect.size.height -= 22;
        
        // add scroll view to window
        _scrollView = [[NSScrollView alloc] initWithFrame:tableRect];
        [_scrollView setHasVerticalScroller:YES];
        [[self contentView] addSubview:_scrollView];
        
        // add tableview to scrollview
        _tableView = [[NSTableView alloc] initWithFrame:tableRect];
        
        NSTableColumn *col = [[[NSTableColumn alloc] autorelease] initWithIdentifier:@"Shortcut Path"];
        [col.headerCell setStringValue:@"Shortcut Path"];
        [col setWidth:tableRect.size.width];
        
        [_tableView addTableColumn:col];
        [_tableView setDataSource:self];
        [_tableView reloadData];
        [_tableView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
        [_scrollView setDocumentView:_tableView];
        
        float scrollerWidth = [NSScroller scrollerWidthForControlSize:NSRegularControlSize scrollerStyle:NSScrollerStyleLegacy];
        
        // add buttons for adding and removing items
        NSButton *addButton = [[[NSButton alloc] autorelease] initWithFrame:NSMakeRect(rect.size.width - 4 * 21 - 6 - scrollerWidth, 0, 21, 21)];
        [addButton setImage:[NSImage imageNamed:NSImageNameAddTemplate]];
        [addButton setButtonType:NSMomentaryPushInButton];
        [addButton setBezelStyle:NSSmallSquareBezelStyle];
        [addButton setAction:@selector(addShortcut:)];
        [addButton setTarget:self];
        [[self contentView] addSubview:addButton];
        
        NSButton *remButton = [[[NSButton alloc] autorelease] initWithFrame:NSMakeRect(rect.size.width - 3 * 21 - 5 - scrollerWidth, 0, 21, 21)];
        [remButton setImage:[NSImage imageNamed:NSImageNameRemoveTemplate]];
        [remButton setButtonType:NSMomentaryPushInButton];
        [remButton setBezelStyle:NSSmallSquareBezelStyle];
        [remButton setAction:@selector(removeShortcut:)];
        [remButton setTarget:self];
        [[self contentView] addSubview:remButton];
        
        // add buttons for moving items up and down
        NSImage *downImg = [Utils iconWithRotation:[NSImage imageNamed:NSImageNameGoRightTemplate] angle:-90];
        NSButton *downButton = [[[NSButton alloc] autorelease] initWithFrame:NSMakeRect(rect.size.width - 2 * 21 - 1 - scrollerWidth, 0, 21, 21)];
        [downButton setImage:downImg];
        [downButton setButtonType:NSMomentaryPushInButton];
        [downButton setBezelStyle:NSSmallSquareBezelStyle];
        [downButton setAction:@selector(moveItemDown:)];
        [downButton setTarget:self];
        [[self contentView] addSubview:downButton];
        
        NSImage *upImg = [Utils iconWithRotation:[NSImage imageNamed:NSImageNameGoRightTemplate] angle:90];
        NSButton *upButton = [[[NSButton alloc] autorelease] initWithFrame:NSMakeRect(rect.size.width - 1 * 21 - 0 - scrollerWidth, 0, 21, 21)];
        [upButton setImage:upImg];
        [upButton setButtonType:NSMomentaryPushInButton];
        [upButton setBezelStyle:NSSmallSquareBezelStyle];
        [upButton setAction:@selector(moveItemUp:)];
        [upButton setTarget:self];
        [[self contentView] addSubview:upButton];
        
        // add all shortcuts to datasource
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        NSMutableArray *shortcuts = [NSMutableArray arrayWithArray:[prefs objectForKey:@"Shortcuts"]];
        NSUInteger shortcutCount = [shortcuts count];
        
        for(size_t i = 0, ct = shortcutCount; i < ct; ++i)
            [self addItem:[shortcuts objectAtIndex:i]];
        
        [_tableView reloadData];
    }
    
    return self;
}

- (void)dealloc
{
    [_tableView release];
    [_scrollView release];
    [_shortcuts release];
    [super dealloc];
}

- (void)removeShortcut:(id)sender
{
    int row = (int)[_tableView selectedRow];
    if(row >= 0)
    {
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        NSMutableArray *items = [NSMutableArray arrayWithArray:[prefs objectForKey:@"Shortcuts"]];
        
        [items removeObject:[_shortcuts objectAtIndex:row]];
        [_shortcuts removeObjectAtIndex:row];
        
        [prefs setObject:items forKey:@"Shortcuts"];
        [prefs synchronize];
        
        [_tableView reloadData];
    }
}

- (void)addShortcut:(id)sender
{
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setCanChooseDirectories:TRUE];
    [panel setCanChooseFiles:TRUE];
    [panel setAllowsMultipleSelection:FALSE];
    [panel beginSheetModalForWindow:self completionHandler:^(NSInteger result)
    {
        if(result == NSFileHandlingPanelOKButton)
        {
            NSString *path = [[[panel URLs] objectAtIndex:0] path];
            
            NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
            NSMutableArray *items = [NSMutableArray arrayWithArray:[prefs objectForKey:@"Shortcuts"]];
            if(items == nil) items = [NSMutableArray array];
            
            [items addObject:path];
            
            [prefs setObject:items forKey:@"Shortcuts"];
            [prefs synchronize];
            
            [self addItem:path];
            
            [_tableView reloadData];
        }
    }];
}

- (void)moveItemUp:(id)sender
{
    int row = (int)[_tableView selectedRow];
    if(row > 0)
    {
        [_shortcuts exchangeObjectAtIndex:row withObjectAtIndex:row - 1];
        
        [_tableView beginUpdates];
        [_tableView moveRowAtIndex:row toIndex:row - 1];
        [_tableView endUpdates];
        
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        NSMutableArray *items = [NSMutableArray arrayWithArray:[prefs objectForKey:@"Shortcuts"]];
        if(items == nil) items = [NSMutableArray array];
        
        [items exchangeObjectAtIndex:row withObjectAtIndex:row - 1];
        
        [prefs setObject:items forKey:@"Shortcuts"];
        [prefs synchronize];
    }
}

- (void)moveItemDown:(id)sender
{
    int row = (int)[_tableView selectedRow];
    if(row >= 0 && row < (_shortcuts.count - 1))
    {
        [_shortcuts exchangeObjectAtIndex:row withObjectAtIndex:row + 1];
        
        [_tableView beginUpdates];
        [_tableView moveRowAtIndex:row toIndex:row + 1];
        [_tableView endUpdates];
        
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        NSMutableArray *items = [NSMutableArray arrayWithArray:[prefs objectForKey:@"Shortcuts"]];
        if(items == nil) items = [NSMutableArray array];
        
        [items exchangeObjectAtIndex:row withObjectAtIndex:row + 1];
        
        [prefs setObject:items forKey:@"Shortcuts"];
        [prefs synchronize];
    }
}

- (void)windowWillClose:(NSNotification *)notification
{
    [NSApp stopModal];
}

-(NSTableView*)tableView
{
    return _tableView;
}

- (void)addItem:(NSString*)item
{
    [_shortcuts addObject:item];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView*)tableView
{
    return _shortcuts.count;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    return [_shortcuts objectAtIndex:row];
}

@end

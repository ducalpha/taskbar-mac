/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Nicolas Jinchereau. All rights reserved.
 *  Licensed under the MIT License. See License.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

#pragma once

#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>

@class AppleButton;

@interface StartMenu : NSMenu<NSMenuDelegate, NSUserInterfaceValidations>
{
    AppleButton *_button;
    StartMenu *_rootMenu;
    NSString *_path; // null unless item is a folder menu
}

- (id)initAsRootMenu:(AppleButton*)button;
- (id)initAsSubmenu:(StartMenu*)rootMenu path:(NSString*)path;
- (void)dealloc;
+ (StartMenu*)rootMenu:(AppleButton*)button;
+ (StartMenu*)menuAsSubmenu:(StartMenu*)rootMenu path:(NSString*)path;
+ (NSMenuItem*)menuItemForPath:(NSString*)path rootMenu:(StartMenu*)rootMenu largeIcon:(BOOL)largeIcon;
+ (NSMenuItem*)menuItemForFile:(NSString*)file rootMenu:(StartMenu*)rootMenu largeIcon:(BOOL)largeIcon;
+ (NSMenuItem*)menuItemForShortcut:(NSString*)shortcut rootMenu:(StartMenu*)rootMenu;
- (void)launchItem:(id)sender;

@end

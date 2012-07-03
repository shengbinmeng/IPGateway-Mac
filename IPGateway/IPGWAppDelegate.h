//
//  IPGWAppDelegate.h
//  IPGateway
//
//  Created by Meng Shengbin on 1/12/12.
//  Copyright (c) 2012 Peking University. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface IPGWAppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSTextField *useridTextField;
@property (assign) IBOutlet NSTextField *passwordTextField;
@property (assign) IBOutlet NSButton *loginButton;
@property (assign) IBOutlet NSButton *logoutButton;
@property (assign) IBOutlet NSTextField *messageTextView;
@property (assign) IBOutlet NSButton *globalSwitch;
@property (assign) IBOutlet NSButton *rememberSwitch;


- (IBAction)loginButtonPressed:(id)sender;
- (IBAction)logoutButtonPressed:(id)sender;

@end

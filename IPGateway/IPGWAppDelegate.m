//
//  IPGWAppDelegate.m
//  IPGateway
//
//  Created by Meng Shengbin on 1/12/12.
//  Copyright (c) 2012 Peking University. All rights reserved.
//

#import "IPGWAppDelegate.h"

@implementation IPGWAppDelegate {
    NSString *username;
    NSString *password;
    NSMutableData* receivedData;
    NSURLConnection * connection;
}

@synthesize window;
@synthesize useridTextField;
@synthesize passwordTextField;
@synthesize loginButton;
@synthesize logoutButton;
@synthesize messageTextView;
@synthesize globalSwitch;
@synthesize rememberSwitch;

- (void)dealloc
{
    [super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    [self.logoutButton setEnabled:NO];
    [useridTextField setStringValue:[[NSUserDefaults standardUserDefaults] valueForKey:@"rememberedUser"]];
    [passwordTextField setStringValue:[[NSUserDefaults standardUserDefaults] valueForKey:@"rememberedPwd"]];
    
    if ([useridTextField stringValue] != nil && [[useridTextField stringValue] isEqualToString:@""] == NO && [passwordTextField stringValue] != nil && [[passwordTextField stringValue] isEqualToString:@""] == NO) {
        [self loginButtonPressed:nil];
    }
}

- (NSString*) findItem:(NSString *) item ofInfomation:(NSString*) information {
    NSString *infoItem = @"unknown";
    if ([item isEqualToString:@"BALANCE"]) {
        NSRange range1 = [information rangeOfString:@"BALANCE="];
        NSRange range2 = [information rangeOfString:@"IP="];
        infoItem = [information substringWithRange:NSMakeRange(range1.location + range1.length, range2.location - (range1.location + range1.length))];
    } else if ([item isEqualToString:@"IP"]) {
        NSRange range1 = [information rangeOfString:@"IP="];
        NSRange range2 = [information rangeOfString:@"MESSAGE="];
        infoItem = [information substringWithRange:NSMakeRange(range1.location + range1.length, range2.location - (range1.location + range1.length))];
    }
    
    return infoItem;
}


/*
 https://its.pku.edu.cn:5428/ipgatewayofpku?uid=1101111141&password=pas&operation=connect&range=2&timeout=2
 
 operation: connect, disconnect, disconnectall
 range: 1(fee), 2(free)
 
 */

- (IBAction)loginButtonPressed:(id)sender {
    [useridTextField resignFirstResponder];
    [passwordTextField resignFirstResponder];
    [messageTextView setStringValue:@"logging in..."];
    
    username = [[self useridTextField] stringValue];
    password = [[self passwordTextField] stringValue];
    if (username == nil) username = @"";
    if (password == nil) password = @"";
    
    NSString *errorMessage = nil;
    if ([username isEqualToString:@""]) {
        errorMessage = @"user ID required! - Please input.";
    } else if ([password isEqualToString:@""]) {
        errorMessage = @"password requered! - Please input.";
    }
    
    if (errorMessage) {
        [messageTextView setStringValue:errorMessage];
        return;
    }
    
    if ([logoutButton isEnabled]) {
        NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] init] autorelease]; 
        [request setURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://its.pku.edu.cn:5428/ipgatewayofpku?uid=%@&password=%@&operation=disconnect&range=%d&timeout=3", username, password, 2]]];  
        [request setHTTPMethod:@"GET"];
        [request setTimeoutInterval:15];
        [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
    }
    
    int range = 2; //2 for free
    if ([globalSwitch state] == NSOnState) {
        range = 1; //1 for fee; can't be others
    }
    NSString *requestString = [NSString stringWithFormat:@"https://its.pku.edu.cn:5428/ipgatewayofpku?uid=%@&password=%@&operation=connect&range=%d&timeout=3", username, password, range];
#ifdef DEBUG
    NSLog(@"%@", requestString);
#endif
    NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] init] autorelease]; 
    [request setURL:[NSURL URLWithString:requestString]];  
    [request setHTTPMethod:@"GET"];
    [request setTimeoutInterval:45];
    connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    if (connection) {
        // Create the NSMutableData to hold the received data.
        // receivedData is an instance variable declared elsewhere.
        receivedData = [[NSMutableData data] retain];
    } else {
        // Inform the user that the connection failed.
        [messageTextView setStringValue:@"connection init failed !"];
    }

}

- (IBAction)logoutButtonPressed:(id)sender {
    [messageTextView setStringValue:@"logging out ..."];
    
    NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] init] autorelease]; 
    [request setURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://its.pku.edu.cn:5428/ipgatewayofpku?uid=%@&password=%@&operation=disconnect&range=%d&timeout=3", username, password, 2]]];  
    [request setHTTPMethod:@"GET"];
    [request setTimeoutInterval:15];
    NSData *returnedData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
    if (returnedData) {
        NSStringEncoding enc = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
        NSString *content = [[[NSString alloc] initWithData:returnedData encoding:enc] autorelease];
#ifdef DEBUG
        NSLog(@"***************\n%@",content);
#endif
        NSRange range = [content rangeOfString:@"<!--IPGWCLIENT_START SUCCESS=YES"];
        if(range.length != 0) {
            [messageTextView setStringValue:@"logout success! - You are offline now."];
            [logoutButton setEnabled:NO];
            if ([rememberSwitch state] == NSOffState) {
                [useridTextField setStringValue:@""];
                [passwordTextField setStringValue:@""];
                [[NSUserDefaults standardUserDefaults] setValue:@"" forKey:@"rememberedUser"];
                [[NSUserDefaults standardUserDefaults] setValue:@"" forKey:@"rememberedPwd"];
            }
        } else {
            [messageTextView setStringValue:@"somethin wrong! - Sorry."];
        }
    } else {
        [messageTextView setStringValue:@"somethin wrong! - Sorry."];
    }

}


#pragma mark - connection delegate

- (void)connection:(NSURLConnection *)aConn didReceiveData:(NSData *)data
{
    if (aConn == connection) {
        [receivedData appendData:data];
    }
}

- (void)connection:(NSURLConnection *)aConn didFailWithError:(NSError *)error
{
    [messageTextView  setStringValue:[NSString stringWithFormat:@"connection failed! - %@", [error localizedDescription]]];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)aConn
{
    if (aConn == connection) {
        NSStringEncoding enc = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
        NSString *content = [[[NSString alloc] initWithData:receivedData encoding:enc] autorelease];
        if (content == nil) {
            content = [[NSString alloc] initWithData:receivedData encoding:NSUTF8StringEncoding];
        }
#ifdef DEBUG
        NSLog(@"content: ***************\n%@",content);
#endif
        NSRange range1 = [content rangeOfString:@"<!--IPGWCLIENT_START "];
        NSRange range2 = [content rangeOfString:@"IPGWCLIENT_END-->"];
        if(range1.length == 0 || range2.length == 0) {
            [messageTextView setStringValue:@"no information returned! - It is terrible."];
            return ;
        }
        
        NSString *information = [content substringWithRange:NSMakeRange(range1.location + range1.length, range2.location - (range1.location + range1.length))];
#ifdef DEBUG
        NSLog(@"information: **************\n%@",information);
#endif
        if([[information substringToIndex:11] isEqualToString:@"SUCCESS=YES"]){
            NSRange range = [content rangeOfString:@"用&nbsp;户&nbsp;名："];
            NSString *name = [content substringWithRange:NSMakeRange(range.location + range.length + 9, 12)];
            name = [name substringToIndex:[name rangeOfString:@"</td>"].location];
            NSString *IP = [self findItem:@"IP" ofInfomation:information];
            NSString *balance = [self findItem:@"BALANCE" ofInfomation:information];
            balance = [balance stringByAppendingString:@" RMB"];
            [messageTextView setStringValue:[NSString stringWithFormat:@"login success! - You are online now. \n\nUser Name: %@ \nIP Location: %@ \nAccount Balance: %@", name,IP,balance]];
            
            if ([rememberSwitch state] == NSOnState) {
                [[NSUserDefaults standardUserDefaults] setValue:username forKey:@"rememberedUser"];
                [[NSUserDefaults standardUserDefaults] setValue:password forKey:@"rememberedPwd"];
            }
            [logoutButton setEnabled:YES];
        } else if([[information substringToIndex:10] isEqualToString:@"SUCCESS=NO"]){ 
            NSRange range = [information rangeOfString:@"REASON="];
            NSString *reason = [information substringFromIndex:(range.location + range.length)];
            if ([reason rangeOfString:@"户名错"].length != 0 || [reason rangeOfString:@"口令错误"].length != 0) {
                [messageTextView setStringValue:@"login failed! - User ID or password error, please check."];
            }else if ([reason rangeOfString:@"不能登录网关"].length != 0) {
                NSRange range = [reason rangeOfString:@"是服务器"];
                NSString *IP = @"";
                if(range.length != 0) IP = [NSString stringWithFormat:@"<%@>",[reason substringToIndex:range.location]];
                [messageTextView setStringValue:[NSString stringWithFormat:@"login failed! - Your IP address%@ is not in the proper area, can't login to the gateway.",IP]];
            } else if ([reason rangeOfString:@"没有访问收费地址的权限"].length != 0) {
                [messageTextView setStringValue:@"login failed! - Your account is only limited to CERNET free IP. Please turn off Global Access or change your settings from http://its.pku.edu.cn."];
            } else if ([reason rangeOfString:@"连接数超过"].length != 0) {
                NSAlert *alert = [[[NSAlert alloc] init] autorelease];
                [alert setMessageText:@"You have reached the max connection number. Disconnect all others and connect again?"];
                [alert addButtonWithTitle:@"Yes"];
                [alert addButtonWithTitle:@"No"];
                
                [alert beginSheetModalForWindow:window
                                  modalDelegate:self
                                 didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:)
                                    contextInfo:nil];
            } else {
                [messageTextView setStringValue:[@"login failed! - " stringByAppendingString:reason]];
            }
        } else {
            [messageTextView setStringValue:@"something wrong! - Sorry."];
        }
        
    } 
}


- (void) alertDidEnd:(NSAlert *)a returnCode:(NSInteger)rc contextInfo:(void *)ci {
    switch(rc) {
        case NSAlertSecondButtonReturn:
            // "No" pressed
            [messageTextView setStringValue:@"login failed! - Max connection number reached."];
            break;
        case NSAlertFirstButtonReturn:
        {
            // "Yes" pressed
            NSString *requestString = [NSString stringWithFormat:@"https://its.pku.edu.cn:5428/ipgatewayofpku?uid=%@&password=%@&operation=disconnectall&range=%d&timeout=3", username, password, 2];
#ifdef DEBUG
            NSLog(@"%@", requestString);
#endif
            NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] init] autorelease];  
            [request setURL:[NSURL URLWithString:requestString]];  
            [request setHTTPMethod:@"GET"];
            [request setTimeoutInterval:15];
            NSData *returnedData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
            if (returnedData) {
                NSStringEncoding enc = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
                NSString *content = [[[NSString alloc] initWithData:returnedData encoding:enc] autorelease];
#ifdef DEBUG
                NSLog(@"***************\n%@",content);
#endif
                NSRange range = [content rangeOfString:@"<!--IPGWCLIENT_START SUCCESS=YES"];
                if(range.length != 0) {
                    [messageTextView setStringValue:@"close other connections success! - re connectting..."];
                    sleep(1);
                    [self loginButtonPressed:nil];
                } else {
                    [messageTextView setStringValue:@"close other connections failed! - Sorry."];
                }
            } else {
                [messageTextView setStringValue:@"close other connections failed! - Sorry."];
            }
        }
            break;
    }
    
}


-(BOOL)applicationShouldHandleReopen:(NSApplication*)application
                   hasVisibleWindows:(BOOL)visibleWindows
{
    if(!visibleWindows)
    {
        [self.window makeKeyAndOrderFront: nil];
    }
    return NO;
}

@end

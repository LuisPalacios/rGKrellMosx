//
//  AppDelegate.h
//  rGKrellMosx
//
//  Created by Luis Palacios on 28/08/13.
//  Copyright (c) 2013 Luis Palacios. All rights reserved.
//

#import <Cocoa/Cocoa.h>

FOUNDATION_EXPORT NSString *const LPPrefsKey_Hostname;
FOUNDATION_EXPORT NSString *const LPPrefsKey_Port;
FOUNDATION_EXPORT NSString *const LPPrefsKey_Username;
FOUNDATION_EXPORT NSString *const LPPrefsKey_Comando;
FOUNDATION_EXPORT NSString *const LPPrefsKey_CloseOnLaunch;


@interface AppDelegate : NSObject <NSApplicationDelegate, NSTextFieldDelegate> {
   
    NSTextField    *ivHostname;
    NSTextField    *ivPort;
    NSTextField    *ivUsername;
    NSTextField    *ivPassword;
    NSTextField    *ivComando;

    NSTextField    *ivShellComando;
    NSTextView     *ivOutputLog;
    NSString       *ivOutputLogString;
    
}

@property (assign) IBOutlet NSWindow *window;

@property (nonatomic, assign) IBOutlet NSTextField *hostname;
@property (nonatomic, assign) IBOutlet NSTextField *port;
@property (nonatomic, assign) IBOutlet NSTextField *username;
@property (nonatomic, assign) IBOutlet NSTextField *comando;

@property (nonatomic, assign) IBOutlet NSTextField *shellComando;
@property (nonatomic, assign) IBOutlet NSTextView  *outputLog;
@property (nonatomic, retain) NSString *outputLogString;

- (IBAction)doIt:(id)sender;
- (IBAction)resetToDefaults:(id)sender;

@end

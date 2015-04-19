//
//  KeyCaptureTextField.h
//  EMGCocoaHub
//
//  Created by flynn on 4/18/15.
//  Copyright (c) 2015 Virginia Commonwealth University. All rights reserved.
//

//  Hacky subclass of NSTextField to capture inputted key codes.

#import <Cocoa/Cocoa.h>

@interface KeyCaptureTextField : NSTextField

@property (nonatomic) unsigned short keyCode;

@end

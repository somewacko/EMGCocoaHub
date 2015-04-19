//
//  KeyCaptureTextField.m
//  EMGCocoaHub
//
//  Created by flynn on 4/18/15.
//  Copyright (c) 2015 Virginia Commonwealth University. All rights reserved.
//

#import "KeyCaptureTextField.h"


@interface KeyCaptureTextField()

@property (nonatomic, strong) NSString *capturedKey;

@end


@implementation KeyCaptureTextField

static id eventMonitor = nil;

- (BOOL)becomeFirstResponder
{
    // When selected, create an event monitor that steals key presses.

    BOOL canDo = [super becomeFirstResponder];
    
    if (canDo)
    {
        __weak KeyCaptureTextField *_self = self;
        
        if (!eventMonitor)
        {
            eventMonitor = [NSEvent addLocalMonitorForEventsMatchingMask:NSKeyDownMask handler:^(NSEvent *event) {
                                
                if (_self)
                {
                    _self.keyCode = [event keyCode];
                    
                    NSLog(@"Keycode: %d", _self.keyCode);
                    
                    switch (_self.keyCode)
                    {
                        case 36:
                            _self.capturedKey = @"Return";
                            break;
                        case 48:
                            _self.capturedKey = @"Tab";
                            break;
                        case 123:
                            _self.capturedKey = @"Left";
                            break;
                        case 124:
                            _self.capturedKey = @"Right";
                            break;
                        case 125:
                            _self.capturedKey = @"Down";
                            break;
                        case 126:
                            _self.capturedKey = @"Up";
                            break;
                        default:
                            _self.capturedKey = [event charactersIgnoringModifiers];
                    }
                    _self.stringValue = _self.capturedKey;
                }
                
                return event;
            }];
        }
    }
    
    return canDo;
}


- (void)textDidChange:(NSNotification *)notification
{
    self.stringValue = self.capturedKey;
}


- (void)textDidEndEditing:(NSNotification *)notification
{
    if (eventMonitor)
    {
        [NSEvent removeMonitor:eventMonitor];
        eventMonitor = nil;
    }
}


- (void)dealloc
{
    if (eventMonitor)
    {
        [NSEvent removeMonitor:eventMonitor];
        eventMonitor = nil;
    }
}


@end

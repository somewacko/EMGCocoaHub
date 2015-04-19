//
//  GestureWindowController.m
//  EMGCocoaHub
//
//  Created by flynn on 4/18/15.
//  Copyright (c) 2015 Virginia Commonwealth University. All rights reserved.
//

#import "GestureWindowController.h"
#import "KeyCaptureTextField.h"


@interface GestureWindowController ()

@property (nonatomic, strong) IBOutlet NSTextField *gestureNameTextField;
@property (nonatomic, strong) IBOutlet KeyCaptureTextField *assignedKeyTextField;
@property (nonatomic, strong) IBOutlet NSTextField *deviceNameTextField;

@property (nonatomic, strong) IBOutlet NSButton *submitButton;

@end


@implementation GestureWindowController

- (instancetype)initWithGesture:(GestureModel *)gesture
{
    self = [super initWithWindowNibName:@"GestureWindowController"];
    
    if (self)
    {
        if (gesture)
            self.gesture = gesture;
        else
            self.gesture = [[GestureModel alloc] init];
    }
    
    return self;
}


- (void)windowDidLoad
{
    [super windowDidLoad];
    
    if (self.gesture.gestureName)
    {
        self.gestureNameTextField.stringValue = self.gesture.gestureName;
        self.assignedKeyTextField.stringValue = self.gesture.assignedKeyString;
        self.deviceNameTextField.stringValue  = self.gesture.deviceName;
    }
    else
        self.submitButton.title = @"Create";
}


#pragma mark - User Actions

- (IBAction)cancelAction:(id)sender
{
    self.gesture = nil;
    
    [self.window.sheetParent endSheet:self.window returnCode:NSModalResponseCancel];
}


- (IBAction)submitAction:(id)sender
{
    if (self.gestureNameTextField.stringValue.length    > 0
        && self.assignedKeyTextField.stringValue.length > 0
        && self.deviceNameTextField.stringValue.length  > 0)
    {
        self.gesture.gestureName       = self.gestureNameTextField.stringValue;
        self.gesture.keyCode           = self.assignedKeyTextField.keyCode;
        self.gesture.assignedKeyString = self.assignedKeyTextField.stringValue;
        self.gesture.deviceName        = self.deviceNameTextField.stringValue;

        [self.window.sheetParent endSheet:self.window returnCode:NSModalResponseContinue];
    }
}


@end

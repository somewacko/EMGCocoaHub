//
//  GestureModel.m
//  EMGCocoaHub
//
//  Created by flynn on 4/18/15.
//  Copyright (c) 2015 Virginia Commonwealth University. All rights reserved.
//

#import "GestureModel.h"


@interface GestureModel()

@end


@implementation GestureModel

- (instancetype)init
{
    self = [super init];
    
    if (self)
        self.numberOfObservations = @0;
    
    return self;
}


- (void)clearGesture
{
    self.numberOfObservations = @0;
}


- (void)addFeatureVector:(float *)features length:(int)length
{
    self.numberOfObservations = [NSNumber numberWithInt:self.numberOfObservations.intValue+1];
}


- (void)performKeyDown
{
    ProcessSerialNumber psn;
    GetFrontProcess(&psn);
    
    CGEventRef keyDown = CGEventCreateKeyboardEvent(NULL, (CGKeyCode)self.keyCode, true);
    CGEventPostToPSN(&psn, keyDown);
    CFRelease(keyDown);
    
    [self performKeyUp];
}


- (void)performKeyUp
{
    ProcessSerialNumber psn;
    GetFrontProcess(&psn);
    
    CGEventRef keyUp = CGEventCreateKeyboardEvent(NULL, (CGKeyCode)self.keyCode, false);
    CGEventPostToPSN(&psn, keyUp);
    CFRelease(keyUp);
}


@end

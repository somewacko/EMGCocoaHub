//
//  GestureModel.m
//  EMGCocoaHub
//
//  Created by flynn on 4/18/15.
//  Copyright (c) 2015 Virginia Commonwealth University. All rights reserved.
//

#import "GestureModel.h"


@implementation ClassificationInfo
@end


@interface GestureModel()

@end


@implementation GestureModel

+ (ClassificationInfo *)classifyFeatureVector:(fmatrix_t *)features gestures:(NSArray *)gestures
{
    emg_gesture_t * emg_gestures[gestures.count];
    
    for (int i = 0; i < gestures.count; i++)
        emg_gestures[i] = ((GestureModel *)[gestures objectAtIndex:i]).emg_gesture;
    
    classification_info_t info = classify(features, emg_gestures, (unsigned)gestures.count, 1000.f);
    
    GestureModel *identifiedGesture;
    
    for (GestureModel *gesture in gestures)
        if (gesture.emg_gesture == info.identified_gesture)
            identifiedGesture = gesture;
    
    
    ClassificationInfo *classificationInfo = [[ClassificationInfo alloc] init];
    classificationInfo.gesture = identifiedGesture;
    classificationInfo.confidence = [NSNumber numberWithFloat:info.distance];
    
    return classificationInfo;
}


- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
        self.emg_gesture = (emg_gesture_t *)malloc(sizeof(emg_gesture_t));
        *self.emg_gesture = init_emg_gesture("", MAX_CHANNELS * NUM_FEATURES);
        self.numberOfObservations = @0;
    }
    
    return self;
}


- (void)dealloc
{
    free(self.emg_gesture);
}


- (void)clearGesture
{
    self.emg_gesture->observations.rows = 0;
    self.emg_gesture->is_committed = false;

    self.numberOfObservations = @0;
}


- (void)addFeatureVector:(fmatrix_t *)features;
{
    if (self.emg_gesture->observations.rows < MAX_MATRIX_ROWS)
    {
        train_gesture(self.emg_gesture, features);
        self.numberOfObservations = [NSNumber numberWithInt:self.numberOfObservations.intValue+1];
    }
}


- (void)performKeyDown
{
    ProcessSerialNumber psn;
    GetFrontProcess(&psn);
    
    CGEventRef keyDown = CGEventCreateKeyboardEvent(NULL, (CGKeyCode)self.keyCode, true);
    CGEventPostToPSN(&psn, keyDown);
    CFRelease(keyDown);
    
    [self performKeyUp]; // Perform immediately
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

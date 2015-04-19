//
//  GestureModel.h
//  EMGCocoaHub
//
//  Created by flynn on 4/18/15.
//  Copyright (c) 2015 Virginia Commonwealth University. All rights reserved.
//

#import <Foundation/Foundation.h>

#include "constants.h"
#include "emg_gesture.h"
#include "emg_matrix.h"


@class GestureModel;


// Simple class to hold classification info. Similar to the classification_info_t struct.
@interface ClassificationInfo : NSObject
@property (nonatomic, strong) GestureModel *gesture;
@property (nonatomic, strong) NSNumber *confidence;
@end


@interface GestureModel : NSObject

+ (ClassificationInfo *)classifyFeatureVector:(fmatrix_t *)features gestures:(NSArray *)gestures;

@property (nonatomic) emg_gesture_t * emg_gesture;

@property (nonatomic, strong) NSString *gestureName;
@property (nonatomic, strong) NSString *assignedKeyString;
@property (nonatomic, strong) NSNumber *numberOfObservations;
@property (nonatomic) unsigned short keyCode;
@property (nonatomic, strong) NSString *deviceName;

- (void)clearGesture;
- (void)addFeatureVector:(fmatrix_t *)features;

- (void)performKeyDown;
- (void)performKeyUp;

@end

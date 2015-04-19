//
//  GestureModel.h
//  EMGCocoaHub
//
//  Created by flynn on 4/18/15.
//  Copyright (c) 2015 Virginia Commonwealth University. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GestureModel : NSObject

@property (nonatomic, strong) NSString *gestureName;
@property (nonatomic, strong) NSString *assignedKeyString;
@property (nonatomic, strong) NSNumber *numberOfObservations;
@property (nonatomic) unsigned short keyCode;
@property (nonatomic, strong) NSString *deviceName;

- (void)clearGesture;
- (void)addFeatureVector:(float *)features length:(int)length;

- (void)performKeyDown;
- (void)performKeyUp;

@end

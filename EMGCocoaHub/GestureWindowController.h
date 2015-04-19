//
//  GestureWindowController.h
//  EMGCocoaHub
//
//  Created by flynn on 4/18/15.
//  Copyright (c) 2015 Virginia Commonwealth University. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "GestureModel.h"


@interface GestureWindowController : NSWindowController <NSTextFieldDelegate>

- (instancetype)initWithGesture:(GestureModel *)gesture;

@property (nonatomic, strong) GestureModel *gesture;

@end

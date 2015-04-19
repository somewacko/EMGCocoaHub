//
//  BluetoothInterface.h
//  EMGCocoaHub
//
//  Created by flynn on 4/19/15.
//  Copyright (c) 2015 Virginia Commonwealth University. All rights reserved.
//

#import <Foundation/Foundation.h>

#include "emg_matrix.h"


@import IOBluetooth;


@class BluetoothInterface;


@protocol BluetoothInterfaceDelegate

- (void)bluetoothInterfaceDidConnectToDevice:(BluetoothInterface *)interface;
- (void)bluetoothInterfaceFailedToConnectToDevice:(BluetoothInterface *)interface;
- (void)bluetoothInterface:(BluetoothInterface *)interface didReceiveFeatures:(fmatrix_t *)features isOnset:(BOOL)onset;

@end


@interface BluetoothInterface : NSObject < IOBluetoothDeviceInquiryDelegate,
                                           IOBluetoothRFCOMMChannelDelegate >

@property (nonatomic, weak) id<BluetoothInterfaceDelegate> delegate;

- (instancetype)initWithDelegate:(id<BluetoothInterfaceDelegate>)delegate;

- (void)connect;

- (void)sdpQueryComplete:(IOBluetoothDevice *)device status:(IOReturn)status;

@end

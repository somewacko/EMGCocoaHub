//
//  SerialBluetoothInterface.h
//  EMGCocoaHub
//
//  Created by flynn on 4/18/15.
//  Copyright (c) 2015 Virginia Commonwealth University. All rights reserved.
//

#import <Foundation/Foundation.h>


@class SerialBluetoothInterface;


@protocol SerialBluetoothInterfaceDelegate

//  This method gets called whenever the EMG device detects either onset or
//  offset of motion.
//
//  messageInfo contains fields:
//
//      "is_onset" : NSNumber - Boolean indicating whether it's onset or offset
//      "features" : NSArray  - The list of extracted features.

- (void)serialBluetoothInterface:(SerialBluetoothInterface *)interface
         didReceiveMessage:(NSDictionary *)messageInfo;

//  Gets called after establishing or failing to establish connection via the
//  COM port. If fails, try to reconnect the deivce.

- (void)serialBluetoothInterface:(SerialBluetoothInterface *)interface
    didEstablishConnection:(BOOL)connectionEstablished;

- (void)serialBluetoothInterfaceConnectionDidClose:(SerialBluetoothInterface *)interface;

@end


@interface SerialBluetoothInterface : NSObject

- (instancetype)initWithDelegate:(id<SerialBluetoothInterfaceDelegate>)delegate;

@property (nonatomic, weak) id<SerialBluetoothInterfaceDelegate>delegate;

- (void)connectToBluetooth;

@end
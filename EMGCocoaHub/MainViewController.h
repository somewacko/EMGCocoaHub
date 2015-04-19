//
//  MainViewController.h
//  EMGCocoaHub
//
//  Created by flynn on 4/18/15.
//  Copyright (c) 2015 Virginia Commonwealth University. All rights reserved.
//

@import Cocoa;
@import IOBluetooth;

#import "BluetoothInterface.h"

@interface MainViewController : NSViewController < NSTableViewDataSource,
                                                   NSTableViewDelegate,
                                                   BluetoothInterfaceDelegate >

@end

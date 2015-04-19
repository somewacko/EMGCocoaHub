//
//  BluetoothInterface.m
//  EMGCocoaHub
//
//  Created by flynn on 4/19/15.
//  Copyright (c) 2015 Virginia Commonwealth University. All rights reserved.
//

#import "BluetoothInterface.h"


@interface BluetoothInterface()

@property (nonatomic, strong) NSMutableArray *numbers;
@property (nonatomic) NSInteger index;
@property (nonatomic, strong) NSString *tempStr;

@property (nonatomic, strong) IOBluetoothDeviceInquiry *deviceInquiry;

@end


@implementation BluetoothInterface

- (instancetype)initWithDelegate:(id<BluetoothInterfaceDelegate>)delegate
{
    self = [super init];
    
    if (self)
    {
        self.delegate = delegate;
        
        self.numbers = [NSMutableArray new];
        self.index = 0;
    }
    
    return self;
}


- (void)connect
{
    NSLog(@"Connecting...");
    self.deviceInquiry = [[IOBluetoothDeviceInquiry alloc] initWithDelegate:self];
    self.deviceInquiry.updateNewDeviceNames = YES;
    [self.deviceInquiry start];
}


#pragma mark - IOBluetoothDeviceInquiryDelegate

- (void)deviceInquiryComplete:(IOBluetoothDeviceInquiry *)sender error:(IOReturn)error aborted:(BOOL)aborted
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
}


- (void)deviceInquiryDeviceFound:(IOBluetoothDeviceInquiry *)sender device:(IOBluetoothDevice *)device
{
    NSLog(@"Found: %@", device.name);

    if ([device.name isEqualToString:@"Slave2"])
    {
        IOBluetoothDevicePair *devicePair = [IOBluetoothDevicePair pairWithDevice:device];
        [device openConnection];
        [device performSDPQuery:self];
    }
}


- (void)sdpQueryComplete:(IOBluetoothDevice *)device status:(IOReturn)status
{
    static BluetoothRFCOMMChannelID channelId;
    
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    if (status == kIOReturnSuccess)
        NSLog(@"Success!");
    
    IOReturn r;
    if (status != kIOReturnSuccess) {
        NSLog(@"SDP query got status %d", status);
        return;
    }
    
    for(IOBluetoothSDPServiceRecord *service in device.services){
        NSLog(@"%@", [service getServiceName]);
        IOReturn r = [service getRFCOMMChannelID:&channelId];
        if(r == kIOReturnSuccess){
            NSLog(@"ChannelID FOUND %d", channelId);
            break;
        }
    }
    
    IOBluetoothRFCOMMChannel *channel;
    r = [device openRFCOMMChannelAsync:&channel
                         withChannelID:channelId
                              delegate:self];
    
    if(r != kIOReturnSuccess){
        NSLog(@"openRFCOMMChannelSync ON ERROR : 0x%x", r);
        NSLog(@"kIOReturnNotOpen %@", r == kIOReturnNotOpen ? @"YES" : @"NO");
    }
}


#pragma mark IOBluetoothRFCOMMChannelDelegate

- (void)rfcommChannelData:(IOBluetoothRFCOMMChannel*)rfcommChannel data:(void *)dataPointer length:(size_t)dataLength
{
    
    for (int i = 0; i < dataLength; i++)
    {
        char c = ((char *)dataPointer)[i];
        
        NSLog(@"%c", c);
        
        if (c == '[')
        {
            self.tempStr = @"";
            self.numbers = [NSMutableArray new];
            self.index = 0;
        }
        else if (c == ']')
        {
            double x = [self.tempStr doubleValue];
            NSNumber *number = [NSNumber numberWithDouble:x];
            [self.numbers addObject:number];
        
            if (self.numbers.count == 10)
            {
                fmatrix_t features = init_fmatrix(1, 10);
                
                for (int j = 0; j < 10; j++)
                    features.values[0][j] = [[self.numbers objectAtIndex:j] floatValue];
                
                NSString *s = @"";
                for (int j = 0; j < 10; j++)
                    s = [s stringByAppendingString:[NSString stringWithFormat:@"%f ", features.values[0][j]]];
                NSLog(@"%@", s);
                
                if (self.delegate)
                    [self.delegate bluetoothInterface:self didReceiveFeatures:&features isOnset:YES];
            }
        }
        else if (c == ' ')
        {
            double x = [self.tempStr doubleValue];
            NSNumber *number = [NSNumber numberWithDouble:x];
            [self.numbers addObject:number];
            
            self.tempStr = @"";
        }
        else
        {
            NSString *str = [NSString stringWithFormat:@"%c", c];
            self.tempStr = [self.tempStr stringByAppendingString:str];
        }
    }
}


- (void)rfcommChannelOpenComplete:(IOBluetoothRFCOMMChannel*)rfcommChannel status:(IOReturn)error
{
    if (self.delegate)
        [self.delegate bluetoothInterfaceDidConnectToDevice:self];

    NSLog(@"%s", __PRETTY_FUNCTION__);
}


- (void)rfcommChannelClosed:(IOBluetoothRFCOMMChannel*)rfcommChannel
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    IOReturn r;
    if ([rfcommChannel isOpen])
    {
        r = [rfcommChannel closeChannel];
        
        if (r != kIOReturnSuccess)
            NSLog(@"closeChannel ON ERROR, 0x%x", r);
    }
    
    IOBluetoothDevice *device = [rfcommChannel getDevice];
    if ([device isConnected])
    {
        r = [device closeConnection];
        
        if (r != kIOReturnSuccess)
            NSLog(@"closeConnection ON ERROR, 0x%x", r);
    }
}


- (void)rfcommChannelControlSignalsChanged:(IOBluetoothRFCOMMChannel*)rfcommChannel
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
}


- (void)rfcommChannelFlowControlChanged:(IOBluetoothRFCOMMChannel*)rfcommChannel
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
}


- (void)rfcommChannelWriteComplete:(IOBluetoothRFCOMMChannel*)rfcommChannel refcon:(void*)refcon status:(IOReturn)error
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
}


- (void)rfcommChannelQueueSpaceAvailable:(IOBluetoothRFCOMMChannel*)rfcommChannel
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
}


@end

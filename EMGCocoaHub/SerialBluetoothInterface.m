//
//  SerialBluetoothInterface.m
//  EMGCocoaHub
//
//  Created by flynn on 4/18/15.
//  Copyright (c) 2015 Virginia Commonwealth University. All rights reserved.
//

#import "SerialBluetoothInterface.h"

#include <errno.h>
#include <fcntl.h>
#include <string.h>
#include <termios.h>
#include <unistd.h>


@interface SerialBluetoothInterface()

@property int port;

@end


@implementation SerialBluetoothInterface

- (instancetype)initWithDelegate:(id<SerialBluetoothInterfaceDelegate>)delegate
{
    self = [super init];
    
    if (self)
        self.delegate = delegate;
    
    return self;
}


- (void)connectToBluetooth
{
    int port = open("/dev/tty.usbserial-A601LNRD", O_RDWR|O_NONBLOCK|O_NDELAY);
    
    if (port < 0)
    {
        NSLog(@"Unable to open port for Bluetooth connection");
        if (self.delegate)
            [self.delegate serialBluetoothInterface:self didEstablishConnection:NO];
        return;
    }
    else
        NSLog(@"Port opened!");
    
    struct termios tty;
    struct termios tty_old;
    memset (&tty, 0, sizeof tty);
    
    /* Error Handling */
    if ( tcgetattr ( port, &tty ) != 0 )
    {
        NSLog(@"Unable to establish Bluetooth connection");
        if (self.delegate)
            [self.delegate serialBluetoothInterface:self didEstablishConnection:NO];
        return;
    }
    
    /* Save old tty parameters (from old code not used -drew) */
    tty_old = tty;
    
    /* Set Baud Rate */
    cfsetospeed (&tty, (speed_t)B115200);   // 115200 is baud rate for bt
    cfsetispeed (&tty, (speed_t)B115200);
    
    /* Setting other Port Stuff (see
     https://www.cmrr.umn.edu/~strupp/serial.html#config for better
     understanding) */
    
    tty.c_cflag     &=  ~PARENB;            // Makes read 8 bit, no parity,
    tty.c_cflag     &=  ~CSTOPB;            // 1 stop bit
    tty.c_cflag     &=  ~CSIZE;
    tty.c_cflag     |=  CS8;
    
    tty.c_cflag     &=  ~CRTSCTS;           // no flow control
    tty.c_cc[VMIN]   =  1;                  // read doesn't block
    tty.c_cc[VTIME]  =  50;                 // 5 seconds read timeout
    tty.c_cflag     |=  (CREAD | CLOCAL);   // turn on READ & ignore ctrl lines
    
    /* Make raw */
    cfmakeraw(&tty);        // INVESTIGATE: do we need raw vs canonical? -drew
    
    /* Flush Port, then applies attributes */
    tcflush( port, TCIFLUSH );
    if ( tcsetattr ( port, TCSANOW, &tty ) != 0) {
        NSLog(@"Unable to establish Bluetooth connection (tcsetattr)");
        if (self.delegate)
            [self.delegate serialBluetoothInterface:self didEstablishConnection:NO];
        return;
    }
    
    if (self.delegate)
        [self.delegate serialBluetoothInterface:self didEstablishConnection:YES];
    
    [self launchCommunicationThread];
}


- (void)launchCommunicationThread
{
    // Capture self weakly so we don't create a retain cycle.
    __weak SerialBluetoothInterface *_self = self;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0),^
   {
       // Obviously doesn't work - just copy/pasted what Drew had. Will have
       // to go through this and make it work when we can get the device to
       // play with.
       
       ssize_t n = 0;
       int spot = 0;
       char buf = '\0';
       char response[100];
       memset(response, '\0', sizeof response);
       
       do
       {
           n = read(_self.port, &buf, 1 );
           if (n > 0)
           {
               response[spot] = buf;
               printf("%c\n", response[spot]);
               spot += n;
           }
       } while(spot <= 10);
       
       if (n < 0) {
           NSLog(@"error reading from port");
       }
       else if (n == 0) {
           NSLog(@"read nothing from port");
       }
       else {
           NSLog(@"response: %s", response);
       }
       
       if (close(_self.port) == 0) {
           printf("port closed!\n");
       }
       
       if (_self && _self.delegate)
           [_self.delegate serialBluetoothInterfaceConnectionDidClose:_self];
   });
}


@end


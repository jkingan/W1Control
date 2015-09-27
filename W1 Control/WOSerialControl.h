//
//  WOSerialControl.h
//  W1 Control
//
//  Created by Jason Kingan on 9/22/15.
//  Copyright © 2015 Jason Kingan, KG7NUX. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <termios.h>

typedef enum _WOSerialControlState {
    WOSerialControlScanning = -2,
    WOSerialControlDisconnected = -1,
    WOSerialControlIdle = 0,
    WOSerialControlWaiting = 1
} WOSerialControlState;

extern NSString * kWOSerialControlConnectedNotification;
extern NSString * kWOSerialControlDisconnectedNotification;
extern NSString * kWOSerialControlScanningNotification;

@interface WOSerialControl : NSObject
{
    struct termios _serialSettings;
    int _serialDescriptor;
    NSFileHandle * _serialHandle;

    NSMutableArray * _commandQueue;

    NSMutableData * _commandResponse;
    NSMutableArray * _serialPortList;
}
@property (nonatomic, copy) NSString * serialPort;
@property (nonatomic, assign) WOSerialControlState serialControlState;
@property (nonatomic, readonly) NSArray * serialPortList;

-(BOOL)pushCommand:(NSString *)command;

-(void)scanSerialPortListForW1:(NSArray *)portList;
-(IBAction)scanAllSerialPorts:(id)sender;
@end

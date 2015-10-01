//
//  WOSerialControl.m
//  W1 Control
//
//  Created by Jason Kingan on 9/22/15.
//  Copyright © 2015 Jason Kingan, KG7NUX. All rights reserved.
//

#import "WOSerialControl.h"
#import "WOResponseHandler.h"
#import "WOLogging.h"

#include <CoreFoundation/CoreFoundation.h>

#include <IOKit/IOKitLib.h>
#include <IOKit/serial/IOSerialKeys.h>
#include <IOKit/IOBSD.h>

#define RESPONSE_TIMEOUT 3

static NSString * kSerialPort = @"kSerialPort";

NSString * kWOSerialControlConnectedNotification = @"kWOSerialControlConnectedNotification";
NSString * kWOSerialControlDisconnectedNotification = @"kWOSerialControlDisconnectedNotification";
NSString * kWOSerialControlScanningNotification = @"kWOSerialControlScanningNotification";

@implementation WOSerialControl

#pragma mark Init/Dealloc

-(id)init
{
    self = [super init];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dataAvailable:) name:NSFileHandleDataAvailableNotification object:nil];

    _commandQueue = [NSMutableArray arrayWithCapacity:10];

    [self setDisconnectedStatus];

    self.serialPort = [[NSUserDefaults standardUserDefaults] objectForKey:kSerialPort];

    if(!self.serialPort) {
        self.serialPort = @"";
    }

    return self;
}

-(void)dealloc
{
    [[NSUserDefaults standardUserDefaults] setObject:self.serialPort forKey:kSerialPort];
}

#pragma mark Misc

-(void)setSerialPort:(NSString *)serialPort
{
    NSString * oldSerialPort = _serialPort;

    _serialPort = serialPort;

    if(!oldSerialPort) {
        oldSerialPort = @"";
    }

    if(!_serialPort) {
        _serialPort = @"";
    }

    if(0 != [_serialPort length] && ![oldSerialPort isEqualToString:_serialPort] && self.serialControlState != WOSerialControlScanning) {
        [self scanSerialPortListForW1:[NSArray arrayWithObject:_serialPort]];
    }
}

#pragma mark Command Queue Processing

-(BOOL)pushCommand:(NSString *)command
{
    if(nil == command || (self.serialControlState != WOSerialControlIdle && self.serialControlState != WOSerialControlWaiting)) {
        return false;
    }

    [_commandQueue insertObject:command atIndex:0];

    if(self.serialControlState == WOSerialControlIdle) {
        [self sendNextCommand];
    }

    return true;
}

-(NSString *)popCommand
{
    NSString * command = nil;

    if([_commandQueue count]) {
        command = [_commandQueue lastObject];
        [_commandQueue removeLastObject];
    }

    return command;
}

-(BOOL)sendNextCommand
{
    NSString * command = [self popCommand];

    if(command) {
        [self sendCommandDispatchResponse:command];
        return true;
    }

    return false;
}

-(void)flushCommandQueue
{
    [_commandQueue removeAllObjects];
}

#pragma mark Scan for W1 Devices

-(void)gotTestResponse
{
    [self flushCommandQueue];
    [self setConnectedStatus];
}

-(void)checkNextSerialPort
{
    [self performSelector:@selector(_checkNextSerialPort) withObject:nil afterDelay:0];
}

-(void)_checkNextSerialPort
{
    if(0 == [_serialPortList count]) {
        WOLog(WOLOG_ANNOY, @"no more ports to check\n");
        [self setDisconnectedStatus];
        _serialPortList = nil;
        return;
    }

    self.serialPort = [_serialPortList lastObject];

    if(nil == self.serialPort) {
        _serialPortList = nil;
        return;
    }

    [_serialPortList removeLastObject];

    BOOL returnCode = [self openSerialPort:self.serialPort];

    if(returnCode) {
        // Try to get the version number
        [self sendCommand:@"V"];
        [_serialHandle waitForDataInBackgroundAndNotify];
    } else {
        [self checkNextSerialPort];
    }
}

-(void)scanAllSerialPorts:(id)sender
{
    [self scanSerialPortListForW1:self.serialPortList];
}

-(void)scanSerialPortListForW1:(NSArray *)portList
{
    [self closeSerialPort];
    self.serialControlState = WOSerialControlScanning;
    [[NSNotificationCenter defaultCenter] postNotificationName:kWOSerialControlScanningNotification object:nil];

    _serialPortList = [NSMutableArray arrayWithArray:portList];

    [self checkNextSerialPort];
}

-(void)setConnectedStatus
{
    self.serialControlState = WOSerialControlIdle;
    [self flushCommandQueue];
    [[NSNotificationCenter defaultCenter] postNotificationName:kWOSerialControlConnectedNotification object:nil];
}

-(void)setDisconnectedStatus
{
    self.serialControlState = WOSerialControlDisconnected;
    [self flushCommandQueue];
    [[NSNotificationCenter defaultCenter] postNotificationName:kWOSerialControlDisconnectedNotification object:nil];

}

#pragma mark Serial Port Open and Configuration

-(BOOL)openSerialPort:(NSString *)port
{
    [self closeSerialPort];
    [self flushCommandQueue];

    WOLog(WOLOG_STATUS,@"opening port %@\n", port);

    int newDescriptor = open([port UTF8String], O_RDWR | O_NONBLOCK);

    if(newDescriptor < 0) {
        WOLog(WOLOG_STATUS, @"open of %@ returned -1, %s\n", self.serialPort, strerror(errno));
        return false;
    }

    self.serialPort = port;

    _serialDescriptor = newDescriptor;

    if(false == [self setupSerial]) {
        [self closeSerialPort];
        return false;
    }

    _serialHandle = [[NSFileHandle alloc] initWithFileDescriptor:_serialDescriptor closeOnDealloc:NO];

    return true;
}

-(BOOL)closeSerialPort
{
    [self flushCommandQueue];
    if(_serialDescriptor || _serialHandle) {
        close(_serialDescriptor);
        _commandResponse = nil;
        _serialDescriptor = 0;
        _serialHandle = nil;

        return true;
    }

    return false;
}

-(BOOL)setupSerial
{
    cfmakeraw(&_serialSettings);

    _serialSettings.c_cc[VMIN] = 1;
    _serialSettings.c_cc[VTIME] = RESPONSE_TIMEOUT;
    _serialSettings.c_iflag = 0;
    _serialSettings.c_oflag = 0;
    _serialSettings.c_cflag |=  CS8;                // Select 8 data bits
    _serialSettings.c_iflag |= INPCK;

    cfsetispeed(&_serialSettings, B9600);
    cfsetospeed(&_serialSettings, B9600);
    cfsetspeed(&_serialSettings, B9600);

    if(tcsetattr(_serialDescriptor, TCSANOW, &_serialSettings) == -1) {
        WOLog(WOLOG_ERROR, @"tcsetattr on %@ returned -1, %s\n", self.serialPort, strerror(errno));
        return false;
    }

    return true;
}

#pragma mark Command Send/Receive

-(void)dispatchResponse:(NSString *)response
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kWOCommandResponseReceived object:response];
}

-(BOOL)sendCommandDispatchResponse:(NSString *)command
{
    if(self.serialControlState != WOSerialControlIdle) {
        return false;
    }

    self.serialControlState = WOSerialControlWaiting;
    [self sendCommand:command];
    [_serialHandle waitForDataInBackgroundAndNotify];

    return true;
}

-(BOOL)sendCommand:(NSString *)command
{
    if(_serialDescriptor < 1 || [command length] != 1 || nil == _serialHandle) {
        WOLog(WOLOG_ANNOY, @"attempting to send command with no device open\n");
        return false;
    }

    WOLog(WOLOG_ANNOY, @"sending %@ to %@\n", command, self.serialPort);

    [self performSelector:@selector(gotNoResponse) withObject:nil afterDelay:RESPONSE_TIMEOUT];

    [_serialHandle writeData:[command dataUsingEncoding:NSUTF8StringEncoding]];

    return true;
}

-(NSString *)readResponse
{
    if(nil == _serialHandle) {
        _commandResponse = nil;
        return nil;
    }

    if(nil == _commandResponse) {
        _commandResponse = [[NSMutableData alloc] initWithCapacity:30];
    }

    NSData * newData;

    @try {
        newData = [_serialHandle availableData];
        if([newData length]) {
            [_commandResponse appendData:newData];
        }
    }
    @catch(NSException * e) {
    }

    NSString * response = [[NSString alloc] initWithData:_commandResponse encoding:NSUTF8StringEncoding];

    [_serialHandle waitForDataInBackgroundAndNotify];

    if([response hasSuffix:@";"]) {
        _commandResponse = nil;
        // No W1 response is less than three characters
        if([response length] >= 3) {
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(gotNoResponse) object:nil];
            return response;
        }
    }

    return nil;
}

-(void)dataAvailable:(NSNotification *)dataNotification
{
    NSString * response = [self readResponse];

    if(response) {
        if(self.serialControlState == WOSerialControlScanning) {
            [self gotTestResponse];
        } else {
            [self dispatchResponse:response];
            self.serialControlState = WOSerialControlIdle;
            [self sendNextCommand];
        }
    }
}

-(void)gotNoResponse
{
    WOLog(WOLOG_ANNOY, @"received no response from %@ after %d seconds\n", self.serialPort, RESPONSE_TIMEOUT);
    self.serialPort = nil;
    [self closeSerialPort];
    if(self.serialControlState == WOSerialControlScanning) {
        [self checkNextSerialPort];
    } else {
        [self setDisconnectedStatus];
    }
}

#pragma mark Serial Port Lister

-(kern_return_t)createSerialIterator:(io_iterator_t *)serialIterator
{
    kern_return_t kernResult;
    mach_port_t masterPort;
    CFMutableDictionaryRef classesToMatch;

    if((kernResult = IOMasterPort(MACH_PORT_NULL, &masterPort)) != KERN_SUCCESS) {
        return kernResult;
    }
    if((classesToMatch = IOServiceMatching(kIOSerialBSDServiceValue)) == NULL) {
        return kernResult;
    }
    CFDictionarySetValue(classesToMatch, CFSTR(kIOSerialBSDTypeKey),
                         CFSTR(kIOSerialBSDRS232Type));
    kernResult = IOServiceGetMatchingServices(masterPort, classesToMatch, serialIterator);
    if(kernResult != KERN_SUCCESS) {
    }
    return kernResult;
}

-(NSString *)getRegistryString:(io_object_t)sObj withPropName:(const char *)propName
{
    static char resultStr[256];
    NSString * nameCFstring;

    resultStr[0] = 0;
    CFStringRef strRef = CFStringCreateWithCString(kCFAllocatorDefault, propName, kCFStringEncodingASCII);

    nameCFstring = CFBridgingRelease(IORegistryEntryCreateCFProperty(sObj,
                                                                     strRef,
                                                                     kCFAllocatorDefault, 0));

    CFRelease(strRef);

    return nameCFstring;
}

-(NSArray *)serialPortList
{
    io_iterator_t theSerialIterator;
    io_object_t theObject;

    if([self createSerialIterator:&theSerialIterator] != KERN_SUCCESS) {
        return nil;
    }

    NSMutableArray * array = [NSMutableArray arrayWithCapacity:10];

    while((theObject = IOIteratorNext(theSerialIterator))) {
        NSString * device = [self getRegistryString:theObject withPropName:kIOCalloutDeviceKey];
        if(device) {
            [array addObject:device];
        }
    }

    return array;
}


@end

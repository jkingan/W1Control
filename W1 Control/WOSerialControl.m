//
//  WOSerialControl.m
//  W1 Control
//
//  Created by Jason Kingan on 9/22/15.
//  Copyright © 2015 Octal 52. All rights reserved.
//

#import "WOSerialControl.h"
#import "WOResponseHandler.h"

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

-(id)init
{
    self = [super init];

    self.serialPort = [[NSUserDefaults standardUserDefaults] objectForKey:kSerialPort];

    if(!self.serialPort) {
        self.serialPort = @"";
    }

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dataAvailable:) name:NSFileHandleDataAvailableNotification object:nil];

    _commandQueue = [NSMutableArray arrayWithCapacity:10];

    self.serialControlState = WOSerialControlDisconnected;

    [self addObserver:self forKeyPath:@"serialPort" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];

    return self;
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *, id> *)change context:(void *)context
{
    if([keyPath isEqualToString:@"serialPort"]) {

        if(self.serialControlState == WOSerialControlScanning) {
            return;
        }

        NSString * oldValue = [change objectForKey:NSKeyValueChangeOldKey];
        NSString * newValue = [change objectForKey:NSKeyValueChangeNewKey];

        if([oldValue isKindOfClass:[NSNull class]] || nil == oldValue) {
            oldValue = @"";
        }

        if([newValue isKindOfClass:[NSNull class]] || nil == newValue) {
            newValue = @"";
        }

        if(nil == newValue || [oldValue isEqualToString:newValue] || [newValue isEqualToString:@""]) {
            return;
        }

        [self scanSerialPortListForW1:[NSArray arrayWithObject:newValue]];
    }
}

-(void)dealloc
{
    [[NSUserDefaults standardUserDefaults] setObject:self.serialPort forKey:kSerialPort];
}

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
        NSLog(@"%s: tcsetattr on %@ returned -1, %s\n", __FUNCTION__, self.serialPort, strerror(errno));
        return false;
    }

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

-(void)gotTestResponse
{
    NSLog(@"%s",__FUNCTION__);

    [self flushCommandQueue];
    [self setConnectedStatus];
}

-(void)gotNoResponse
{
    NSLog(@"%s: Received no response from port [%@]", __FUNCTION__, self.serialPort);
    self.serialPort = nil;
    [self closeSerialPort];
    if(self.serialControlState == WOSerialControlScanning) {
        [self performSelector:@selector(checkNextSerialPort) withObject:nil afterDelay:0];
    } else {
        [self setDisconnectedStatus];
    }
}

-(void)checkNextSerialPort
{
    if(0 == [_serialPortList count]) {
        NSLog(@"%s: No more ports to check", __FUNCTION__);
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


    NSLog(@"%s: Trying for response from port [%@]", __FUNCTION__, self.serialPort);

    BOOL returnCode = [self openSerialPort:self.serialPort];

    if(returnCode) {
        // Try to get the version number
        [self sendCommand:@"V"];
        [_serialHandle waitForDataInBackgroundAndNotify];
        NSLog(@"Scheduling gotNoREsponse");
    } else {
        [self performSelector:@selector(checkNextSerialPort) withObject:nil afterDelay:0];
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

    [self performSelector:@selector(checkNextSerialPort) withObject:nil afterDelay:0];
}

-(void)flushCommandQueue
{
    [_commandQueue removeAllObjects];
}

-(BOOL)openSerialPort:(NSString *)port
{
    [self closeSerialPort];
    [self flushCommandQueue];

    int newDescriptor = open([port UTF8String], O_RDWR | O_NONBLOCK);

    if(newDescriptor < 0) {
        NSLog(@"%s: open of %@ returned -1, %s\n", __FUNCTION__, self.serialPort, strerror(errno));
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

-(BOOL)sendCommand:(NSString *)command
{
    if(_serialDescriptor < 1 || [command length] != 1 || nil == _serialHandle) {
        return false;
    }

    [self performSelector:@selector(gotNoResponse) withObject:nil afterDelay:RESPONSE_TIMEOUT];

    [_serialHandle writeData:[command dataUsingEncoding:NSUTF8StringEncoding]];

    return true;
}

#pragma mark Serial Port Lister

static kern_return_t _createSerialIterator(io_iterator_t * serialIterator)
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

static NSString * _getRegistryString(io_object_t sObj, char * propName)
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

    if(_createSerialIterator(&theSerialIterator) != KERN_SUCCESS) {
        return nil;
    }

    NSMutableArray * array = [NSMutableArray arrayWithCapacity:10];

    while((theObject = IOIteratorNext(theSerialIterator))) {
        NSString * device = _getRegistryString(theObject, kIOCalloutDeviceKey);
        if(device) {
            [array addObject:device];
        }
    }

    return array;
}


@end

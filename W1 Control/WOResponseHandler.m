//
//  WOResponseHandler.m
//  W1 Control
//
//  Created by Jason Kingan on 9/23/15.
//  Copyright © 2015 Octal 52. All rights reserved.
//

#import "WOResponseHandler.h"
#import "WODisplayModel.h"
#import "WOSerialControl.h"

NSString * kWOCommandResponseReceived = @"kWOCommandResponseReceived";

#define CHECK_LENGTH(_response, _responseLength) {if([_response length] != _responseLength) { NSLog(@"%s: response [%@] is not correct length of %d",__FUNCTION__, _response, _responseLength); return false;}}

@implementation WOResponseHandler

-(id)init
{
    self = [super init];
    [self registerForNotifications];
    return self;
}

-(id)initWithDisplayModel:(WODisplayModel*)displayModel
{
    self = [super init];

    self.displayModel = displayModel;
    [self registerForNotifications];

    return self;
}

-(void)registerForNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(responseReceived:) name:kWOCommandResponseReceived object:nil];
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)responseReceived:(NSNotification*)responseNotification
{
    NSString * response = [responseNotification object];

    [self parseResponse:response];
}

-(BOOL)parseResponse:(NSString*)response
{
    if(nil == response || [response length] < 4 || NO == [response hasSuffix:@";"]) {
        return false;
    }

    BOOL returnCode = false;
    char firstChar = [response characterAtIndex:0];

    switch (firstChar) {
        case 'A':
            returnCode = [self handleAutorange:response];
            break;
        case 'V':
            returnCode = [self handleVersion:response];
            break;
        case 'F':
            returnCode = [self handleForwardPower:response];
            break;
        case 'R':
            returnCode = [self handleForwardPower:response];
            break;
        case 'B':
            returnCode = [self handleForwardGraph:response];
            break;
        case 'C':
            returnCode = [self handleReverseGraph:response];
            break;
        default:
            break;
    }

    return returnCode;
}

-(BOOL)updateRange:(char)range
{
    if(range == '0') {
    } else if(range == '1' || range == 'L') {
        self.displayModel.forwardMaxValue = [NSNumber numberWithFloat:1.4];
    } else if(range == '2' || range == 'M') {
        self.displayModel.forwardMaxValue = [NSNumber numberWithFloat:14];
    } else if(range == '3' || range == 'H') {
        self.displayModel.forwardMaxValue = [NSNumber numberWithFloat:140];
    } else {
        return false;
    }

    return true;
}

-(BOOL)handleAutorange:(NSString*)response
{
    CHECK_LENGTH(response, 3);

    char range = [response characterAtIndex:1];

    return [self updateRange:range];

    return true;
}

-(BOOL)handleVersion:(NSString*)response
{
    CHECK_LENGTH(response, 6);

    self.displayModel.version = [response substringWithRange:NSMakeRange(1, 4)];

    return true;
}

-(BOOL)handleForwardGraph:(NSString*)response
{
    CHECK_LENGTH(response, 6);

    char range = [response characterAtIndex:1];

    return [self updateRange:range];

    return true;
}

-(BOOL)handleReverseGraph:(NSString*)response
{
    CHECK_LENGTH(response, 6);

    char range = [response characterAtIndex:1];

    return [self updateRange:range];

    return true;
}

-(BOOL)handleForwardPower:(NSString*)response
{
    CHECK_LENGTH(response, 6);

    float forwardPower = [[response substringWithRange:NSMakeRange(1,4)] floatValue];

    self.displayModel.forwardValue = [NSNumber numberWithFloat:forwardPower];

    return true;
}

-(BOOL)handleReversePower:(NSString*)response
{
    CHECK_LENGTH(response, 6);

    float reversePower = [[response substringWithRange:NSMakeRange(1,4)] floatValue];

    self.displayModel.reverseValue = [NSNumber numberWithFloat:reversePower];

    return true;
}

@end

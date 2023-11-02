//
//  WOResponseHandler.m
//  W1 Control
//
//  Created by Jason Kingan on 9/23/15.
//  Copyright © 2015 Jason Kingan, KG7NUX. All rights reserved.
//

#import "WOResponseHandler.h"
#import "WODisplayModel.h"
#import "WOSerialControl.h"
#import "WOLogging.h"

NSString * kWOCommandResponseReceived = @"kWOCommandResponseReceived";

#define CHECK_LENGTH(_response, _responseLength) { if([_response length] != _responseLength) { WOLog(WOLOG_STATUS, @"response %@ is not correct length of %d", _response, _responseLength); return false; } }

@implementation WOResponseHandler

#pragma mark Init/Dealloc

-(id)init
{
    self = [super init];
    [self registerForNotifications];
    return self;
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)registerForNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(responseReceived:) name:kWOCommandResponseReceived object:nil];
}

#pragma mark Handle Responses

-(void)responseReceived:(NSNotification *)responseNotification
{
    NSString * response = [responseNotification object];

    [self parseResponse:response];
}

-(BOOL)parseResponse:(NSString *)response
{
    if(nil == response) {
        WOLog(WOLOG_ALWAYS, @"received nil response\n");
        return false;
    }

    if([response length] < 3 || NO == [response hasSuffix:@";"]) {
        WOLog(WOLOG_ERROR, @"received response %@ that didn't appear to be from a W1\n", response);
        return false;
    }

    WOLog(WOLOG_ANNOY, @"handling %@\n", response);

    BOOL returnCode = false;
    char firstChar = [response characterAtIndex:0];

    switch(firstChar) {
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
            returnCode = [self handleReversePower:response];
            break;
        case 'B':
            returnCode = [self handleForwardGraph:response];
            break;
        case 'C':
            returnCode = [self handleReverseGraph:response];
            break;
        case 'X':
            returnCode = [self handleUserSettings:response];
            break;
        default:
            WOLog(WOLOG_STATUS, @"ignoring unhandled message %@\n", response);
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

-(int)averageOrPeak:(char)c
{
    return (c == 'A' ? 0 : 1);
}

-(int)slowMediumOrFast:(char)c
{
    return (c == 'S' ? 0 : (c == 'M' ? 1 : 2));
}

-(BOOL)handleUserSettings:(NSString *)response
{
    CHECK_LENGTH(response, 7);

    self.displayModel.ledTypeNoUpdate = [self averageOrPeak:[response characterAtIndex:1]];
    self.displayModel.serialTypeNoUpdate = [self averageOrPeak:[response characterAtIndex:2]];
    self.displayModel.ledDecayRateNoUpdate = [self slowMediumOrFast:[response characterAtIndex:3]];
    self.displayModel.rangeDropRateNoUpdate = [self slowMediumOrFast:[response characterAtIndex:4]];

    return true;
}

-(BOOL)handleAutorange:(NSString *)response
{
    CHECK_LENGTH(response, 3);

    char range = [response characterAtIndex:1];

    return [self updateRange:range];

    return true;
}

-(BOOL)handleVersion:(NSString *)response
{
    CHECK_LENGTH(response, 6);

    self.displayModel.version = [response substringWithRange:NSMakeRange(1, 4)];

    return true;
}

-(BOOL)handleForwardGraph:(NSString *)response
{
    CHECK_LENGTH(response, 5);

    char range = [response characterAtIndex:1];

    return [self updateRange:range];

    return true;
}

-(BOOL)handleReverseGraph:(NSString *)response
{
    CHECK_LENGTH(response, 5);

    char range = [response characterAtIndex:1];

    return [self updateRange:range];

    return true;
}

-(BOOL)handleForwardPower:(NSString *)response
{
    CHECK_LENGTH(response, 6);

    float forwardPower = [[response substringWithRange:NSMakeRange(1, 4)] floatValue];

    self.displayModel.forwardValue = [NSNumber numberWithFloat:forwardPower];

    return true;
}

-(BOOL)handleReversePower:(NSString *)response
{
    CHECK_LENGTH(response, 6);

    float reversePower = [[response substringWithRange:NSMakeRange(1, 4)] floatValue];

    self.displayModel.reverseValue = [NSNumber numberWithFloat:reversePower];

    return true;
}

@end

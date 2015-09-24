//
//  WODisplayModel.m
//  W1 Control
//
//  Created by Jason Kingan on 9/22/15.
//  Copyright © 2015 Octal 52. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "WODisplayModel.h"
#import "WOSerialControl.h"

@implementation WODisplayModel

-(id)init
{
    self = [super init];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate:) name:NSApplicationWillTerminateNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setDisconnectedMode:) name:kWOSerialControlDisconnectedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setConnectedMode:) name:kWOSerialControlConnectedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setScanningMode:) name:kWOSerialControlScanningNotification object:nil];

    NSNumber * tempNumber = [[NSUserDefaults standardUserDefaults] objectForKey:@"automaticRanging"];

    if(tempNumber) {
        self.automaticRanging = [tempNumber boolValue];
    } else {
        self.automaticRanging = YES;
    }

    tempNumber = [[NSUserDefaults standardUserDefaults] objectForKey:@"writeSettingsToFlash"];
    if(tempNumber) {
        self.writeSettingsToFlash = [tempNumber boolValue];
    } else {
        self.writeSettingsToFlash = YES;
    }

    NSArray * tempArray = [[NSUserDefaults standardUserDefaults] objectForKey:@"updateIndexIntervals"];
    if(tempArray) {
        _updateIndexIntervals = tempArray;
    } else {
        _updateIndexIntervals = @[ @0.25f, @0.5f, @1.0f, @2.0f, @5.0f];
    }

    tempNumber = [[NSUserDefaults standardUserDefaults] objectForKey:@"updateIntervalIndex"];
    if(tempNumber) {
        self.updateIntervalIndex = [tempNumber intValue];
    } else {
        self.updateIntervalIndex = 0;
    }

    self.updateInterval = [[_updateIndexIntervals objectAtIndex:self.updateIntervalIndex] floatValue];

    tempNumber = [[NSUserDefaults standardUserDefaults] objectForKey:@"updateInterval"];
    if(tempNumber) {
        self.updateInterval = [tempNumber floatValue];
    }

    self.connectedImage = [NSImage imageNamed:@"Disconnected"];
    return self;
}

-(NSArray*)updateIndexInterval
{
    return _updateIndexIntervals;
}

-(NSString*)updateIndexInterval_0
{
    return [[_updateIndexIntervals objectAtIndex:0] stringValue];
}

-(NSString*)updateIndexInterval_1
{
    return [[_updateIndexIntervals objectAtIndex:1] stringValue];
}
-(NSString*)updateIndexInterval_2
{
    return [[_updateIndexIntervals objectAtIndex:2] stringValue];
}
-(NSString*)updateIndexInterval_3
{
    return [[_updateIndexIntervals objectAtIndex:3] stringValue];
}
-(NSString*)updateIndexInterval_4
{
    return [[_updateIndexIntervals objectAtIndex:4] stringValue];
}

-(void)applicationWillTerminate:(NSNotification*)notification
{
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:self.automaticRanging] forKey:@"automaticRanging"];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:self.writeSettingsToFlash] forKey:@"writeSettingsToFlash"];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:self.updateIntervalIndex] forKey:@"updateIntervalIndex"];
}

-(void)setScanningMode:(NSNotification*)notification
{
    self.isConnected = NO;
    self.connectedImage = [NSImage imageNamed:@"Scanning"];
}

-(void)setConnectedMode:(NSNotification*)notification
{
    self.isConnected = YES;
    [self.serialControl pushCommand:@"X"];
    [self updateDisplay];

    self.connectedImage = [NSImage imageNamed:@"Connected"];

    [self performSelector:@selector(updateDisplay) withObject:nil afterDelay:self.updateInterval];
}

-(void)setDisconnectedMode:(NSNotification*)notification
{
    self.isConnected = NO;
    [[NSRunLoop mainRunLoop] cancelPerformSelector:@selector(updateDisplay) target:self argument:nil];
    self.connectedImage = [NSImage imageNamed:@"Disconnected"];
}

-(void)updateDisplay
{
    [self.serialControl pushCommand:@"F"];
    [self.serialControl pushCommand:@"R"];
    [self.serialControl pushCommand:@"B"];
    [self.serialControl pushCommand:@"C"];

    if(self.isConnected) {
        [self performSelector:@selector(updateDisplay) withObject:nil afterDelay:self.updateInterval];
    }
}

-(int)updateIntervalIndex
{
    return _updateIntervalIndex;
}

-(void)setUpdateIntervalIndex:(int)updateIntervalIndex
{
    self.updateInterval = [[_updateIndexIntervals objectAtIndex:updateIntervalIndex] floatValue];
    _updateIntervalIndex = updateIntervalIndex;
}

-(NSString*)wattLabel:(NSNumber *) value
{
    NSNumberFormatter * nf = [[NSNumberFormatter alloc] init];

    nf.roundingMode = NSNumberFormatterRoundHalfUp;
    nf.numberStyle = NSNumberFormatterDecimalStyle;
    nf.positiveSuffix = @" W";
    nf.usesSignificantDigits = YES;
    nf.minimumSignificantDigits = 1;
    nf.maximumSignificantDigits = 4;
    nf.format = @"0.00 W";
    return [nf stringFromNumber:value];

    return [NSString stringWithFormat:@"%.1f W", [value floatValue]];
}

-(NSString*)forwardMinLabel
{
    return [self wattLabel:self.forwardMinValue];
}

-(NSString*)forwardMidLabel
{
    return [self wattLabel:[NSNumber numberWithInt:([self.forwardMaxValue intValue] - [self.forwardMinValue intValue]) / 2]];
}

-(NSString*)forwardMaxLabel
{
    return [self wattLabel:self.forwardMaxValue];
}

-(NSNumber*)forwardMaxValue
{
    return [NSNumber numberWithFloat:_forwardMaxValue];
}

-(void)setForwardMaxValue:(NSNumber *)forwardMaxValue
{
    _forwardMaxValue = [forwardMaxValue floatValue];
    [self forwardMidValueChanged];
    [self willChangeValueForKey:@"forwardMaxLabel"];
    [self didChangeValueForKey:@"forwardMaxLabel"];
}

-(void)setForwardMinValue:(NSNumber *)forwardMinValue
{
    _forwardMinValue = [forwardMinValue floatValue];
    [self forwardMidValueChanged];
    [self willChangeValueForKey:@"forwardMinLabel"];
    [self didChangeValueForKey:@"forwardMinLabel"];
}

-(void)forwardMidValueChanged
{
    [self willChangeValueForKey:@"forwardMidLabel"];
    [self didChangeValueForKey:@"forwardMidLabel"];
}

-(void)reverseMidValueChanged
{
    [self willChangeValueForKey:@"reverseMidLabel"];
    [self didChangeValueForKey:@"reverseMidLabel"];
}

-(NSNumber*)forwardMinValue
{
    return [NSNumber numberWithFloat:_forwardMinValue];
}

-(NSString*)forwardValueLabel
{
    return [self wattLabel: self.forwardValue];
}

-(NSNumber*)forwardValue
{
    return [NSNumber numberWithFloat:_forwardValue];
}

-(void)setForwardValue:(NSNumber*)forwardValue;
{
    _forwardValue = [forwardValue floatValue];
    [self swrChanged];
    [self willChangeValueForKey:@"forwardValueLabel"];
    [self didChangeValueForKey:@"forwardValueLabel"];
}

-(NSString*)reverseMinLabel
{
    return [self wattLabel:self.reverseMinValue];
}

-(NSString*)reverseMidLabel
{
    return [self wattLabel:[NSNumber numberWithInt:([self.reverseMaxValue intValue] - [self.reverseMinValue intValue]) / 2]];
}

-(NSString*)reverseMaxLabel
{
    return [self wattLabel:self.reverseMaxValue];
}

-(NSNumber*)reverseMaxValue
{
    return [NSNumber numberWithFloat:_reverseMaxValue];
}

-(NSNumber*)reverseMinValue
{
    return [NSNumber numberWithFloat:_reverseMinValue];
}

-(void)setReverseMaxValue:(NSNumber *)reverseMaxValue
{
    _reverseMaxValue = [reverseMaxValue floatValue];
    [self reverseMidValueChanged];
    [self willChangeValueForKey:@"reverseMaxLabel"];
    [self didChangeValueForKey:@"reverseMaxLabel"];
}

-(void)setReverseMinValue:(NSNumber *)reverseMinValue
{
    _reverseMinValue = [reverseMinValue floatValue];
    [self reverseMidValueChanged];
    [self willChangeValueForKey:@"reverseMinLabel"];
    [self didChangeValueForKey:@"reverseMinLabel"];
}

-(NSString*)swrLabel
{
    float swr = [self.swrValue floatValue];

    if(swr < 1.0 || swr != swr) {
        return @"N/A";
    }

    return [NSString stringWithFormat:@"%.01f", swr];
}

-(NSString*)reverseValueLabel
{
    return [self wattLabel:self.reverseValue];
}

-(void)setReverseValue:(NSNumber*)reverseValue;
{
    _reverseValue = [reverseValue floatValue];
    [self swrChanged];
    [self willChangeValueForKey:@"reverseValueLabel"];
    [self didChangeValueForKey:@"reverseValueLabel"];
}

-(NSNumber*)reverseValue
{
    return [NSNumber numberWithFloat:_reverseValue];
}


-(NSNumber*)swrValue
{
    float forward = [self.forwardValue floatValue];
    float reverse = [self.reverseValue floatValue];

    float rho = sqrtf( reverse / forward );
    float swr = (1+rho) / (1-rho);

    if(swr < 1.0) {
        swr = 0;
    }

    return [NSNumber numberWithFloat:swr];
}

-(void)swrChanged
{
    [self willChangeValueForKey:@"swrLabel"];
    [self willChangeValueForKey:@"swrValue"];

    [self didChangeValueForKey:@"swrLabel"];
    [self didChangeValueForKey:@"swrValue"];
}

@end


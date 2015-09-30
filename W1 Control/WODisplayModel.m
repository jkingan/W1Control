//
//  WODisplayModel.m
//  W1 Control
//
//  Created by Jason Kingan on 9/22/15.
//  Copyright © 2015 Jason Kingan, KG7NUX. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "WODisplayModel.h"
#import "WOSerialControl.h"
#import "WOLogging.h"

#define WODisplayModelAverage 0
#define WODisplayModelPEP     1

@implementation WODisplayModel

static NSString * kAutomaticRanging = @"automaticRanging";
static NSString * kWriteSettingsToFlash = @"writeSettingsToFlash";
static NSString * kUpdateIndexIntervals = @"updateIndexIntervals";
static NSString * kUpdateIntervalIndex  = @"updateIntervalIndex";
static NSString * kUpdateInterval = @"updateInterval";

-(id)init
{
    self = [super init];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate:) name:NSApplicationWillTerminateNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setDisconnectedMode:) name:kWOSerialControlDisconnectedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setConnectedMode:) name:kWOSerialControlConnectedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setScanningMode:) name:kWOSerialControlScanningNotification object:nil];

    NSDictionary * defaults = @{ kAutomaticRanging : @YES, kWriteSettingsToFlash: @YES,
                                 kUpdateIndexIntervals : @[@0.25f, @0.5f, @1.0f, @2.0f, @5.0f],
                                 kUpdateIntervalIndex : @1, kUpdateInterval : @0.0f };

    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
    [[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:kAutomaticRanging options:NSKeyValueObservingOptionNew context:nil];
    [[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:kUpdateIntervalIndex options:NSKeyValueObservingOptionNew context:nil];

    [self updateRangingValue];
    [self updateIntervalValue];

    self.connectedImage = [NSImage imageNamed:@"Disconnected"];
    return self;
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *, id> *)change context:(void *)context
{
    if([keyPath isEqualToString:kAutomaticRanging]) {
        [self updateRangingValue];
    } else if([keyPath isEqualToString:kUpdateIntervalIndex]) {
        [self updateIntervalValue];
    }
}

-(NSArray *)updateIndexIntervals
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:kUpdateIndexIntervals];
}

-(NSString *)updateIndexInterval_0
{
    return [[self.updateIndexIntervals objectAtIndex:0] stringValue];
}

-(NSString *)updateIndexInterval_1
{
    return [[self.updateIndexIntervals objectAtIndex:1] stringValue];
}

-(NSString *)updateIndexInterval_2
{
    return [[self.updateIndexIntervals objectAtIndex:2] stringValue];
}

-(NSString *)updateIndexInterval_3
{
    return [[self.updateIndexIntervals objectAtIndex:3] stringValue];
}

-(NSString *)updateIndexInterval_4
{
    return [[self.updateIndexIntervals objectAtIndex:4] stringValue];
}

-(void)applicationWillTerminate:(NSNotification *)notification
{
}

-(void)setScanningMode:(NSNotification *)notification
{
    self.isConnected = NO;
    self.connectedImage = [NSImage imageNamed:@"Scanning"];
}

-(void)setConnectedMode:(NSNotification *)notification
{
    self.isConnected = YES;
    [self.serialControl pushCommand:@"X"];
    [self updateRangingValue];
    [self updateDisplay];

    self.connectedImage = [NSImage imageNamed:@"Connected"];

    [self performSelector:@selector(updateDisplay) withObject:nil afterDelay:self.updateInterval];
}

-(void)setDisconnectedMode:(NSNotification *)notification
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

-(NSString *)wattLabel:(NSNumber *)value
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

-(NSString *)forwardMinLabel
{
    return [self wattLabel:self.forwardMinValue];
}

-(NSString *)forwardMidLabel
{
    return [self wattLabel:[NSNumber numberWithInt:([self.forwardMaxValue intValue] - [self.forwardMinValue intValue]) / 2]];
}

-(NSString *)forwardMaxLabel
{
    return [self wattLabel:self.forwardMaxValue];
}

-(NSNumber *)forwardMaxValue
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

-(NSNumber *)forwardMinValue
{
    return [NSNumber numberWithFloat:_forwardMinValue];
}

-(NSString *)forwardValueLabel
{
    return [self wattLabel:self.forwardValue];
}

-(NSNumber *)forwardValue
{
    return [NSNumber numberWithFloat:_forwardValue];
}

-(void)saveSettingsToFlash
{
    if([[NSUserDefaults standardUserDefaults] boolForKey:kWriteSettingsToFlash]) {
        [self.serialControl pushCommand:@"W"];
    }
}

-(void)setLedTypeNoUpdate:(int)ledType
{
    [self willChangeValueForKey:@"ledType"];
    _ledType = ledType;
    [self didChangeValueForKey:@"ledType"];
}

-(void)setLedType:(int)ledType
{
    [self setLedTypeNoUpdate:ledType];
    [self.serialControl pushCommand:@"M"];
    [self saveSettingsToFlash];
}

-(void)setSerialTypeNoUpdate:(int)serialType
{
    [self willChangeValueForKey:@"serialType"];
    _serialType = serialType;
    [self didChangeValueForKey:@"serialType"];
}

-(void)setSerialType:(int)serialType
{
    [self setSerialTypeNoUpdate:serialType];
    [self.serialControl pushCommand:@"N"];
    [self saveSettingsToFlash];
}

-(void)setLedDecayRateNoUpdate:(int)ledDecayRateNoUpdate
{
    [self willChangeValueForKey:@"ledDecayRate"];
    _ledDecayRate = ledDecayRateNoUpdate;
    [self didChangeValueForKey:@"ledDecayRate"];
}

-(void)setLedDecayRate:(int)ledDecayRate
{
    [self setLedDecayRateNoUpdate:ledDecayRate];
    unichar commandChar = '4' + ledDecayRate;
    NSString * command = [NSString stringWithCharacters:&commandChar length:1];
    [self.serialControl pushCommand:command];
    [self saveSettingsToFlash];
}

-(void)setForwardValue:(NSNumber *)forwardValue;
{
    _forwardValue = [forwardValue floatValue];
    [self swrChanged];
    [self willChangeValueForKey:@"forwardValueLabel"];
    [self didChangeValueForKey:@"forwardValueLabel"];
}

-(void)setRangeDropRateNoUpdate:(int)rangeDropRateNoUpdate
{
    [self willChangeValueForKey:@"rangeDropRate"];
    _rangeDropRate = rangeDropRateNoUpdate;
    [self didChangeValueForKey:@"rangeDropRate"];
}

-(void)setRangeDropRate:(int)rangeDropRate
{
    [self setRangeDropRateNoUpdate:rangeDropRate];
    unichar commandChar = '7' + rangeDropRate;
    NSString * command = [NSString stringWithCharacters:&commandChar length:1];
    [self.serialControl pushCommand:command];
    [self saveSettingsToFlash];
}

-(NSString *)reverseMinLabel
{
    return [self wattLabel:self.reverseMinValue];
}

-(NSString *)reverseMidLabel
{
    return [self wattLabel:[NSNumber numberWithInt:([self.reverseMaxValue intValue] - [self.reverseMinValue intValue]) / 2]];
}

-(NSString *)reverseMaxLabel
{
    return [self wattLabel:self.reverseMaxValue];
}

-(NSNumber *)reverseMaxValue
{
    return [NSNumber numberWithFloat:_reverseMaxValue];
}

-(NSNumber *)reverseMinValue
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

-(NSString *)swrLabel
{
    float swr = [self.swrValue floatValue];

    if(swr < 1.0 || swr != swr) {
        return @"N/A";
    }

    return [NSString stringWithFormat:@"%.01f", swr];
}

-(NSString *)reverseValueLabel
{
    return [self wattLabel:self.reverseValue];
}

-(void)setReverseValue:(NSNumber *)reverseValue;
{
    _reverseValue = [reverseValue floatValue];
    [self swrChanged];
    [self willChangeValueForKey:@"reverseValueLabel"];
    [self didChangeValueForKey:@"reverseValueLabel"];
}

-(NSNumber *)reverseValue
{
    return [NSNumber numberWithFloat:_reverseValue];
}


-(NSNumber *)swrValue
{
    float forward = [self.forwardValue floatValue];
    float reverse = [self.reverseValue floatValue];

    float rho = sqrtf(reverse / forward);
    float swr = (1 + rho) / (1 - rho);

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

-(float)updateInterval
{
    float updateInterval = [[NSUserDefaults standardUserDefaults] floatForKey:kUpdateInterval];

    if( updateInterval == 0) {
        return _updateInterval;
    } else {
        return updateInterval;
    }
}

-(void)updateIntervalValue
{
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];

    self.updateInterval =  [[[defaults objectForKey:kUpdateIndexIntervals] objectAtIndex:[defaults integerForKey:kUpdateIntervalIndex] - 1] floatValue];
}

-(void)updateRangingValue
{
    if([[NSUserDefaults standardUserDefaults] boolForKey:kAutomaticRanging]) {
        [self.serialControl pushCommand:@"0"];
    } else {
        unichar commandChar = '1' + self.currentRange;
        NSString * command = [NSString stringWithCharacters:&commandChar length:1];
        [self.serialControl pushCommand:command];
    }
    [self.serialControl pushCommand:@"B"];
    [self.serialControl pushCommand:@"C"];
}

-(void)setCurrentRange:(int)currentRange
{
    _currentRange = currentRange;
    [self updateRangingValue];
}

@end


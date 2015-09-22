//
//  WODisplayModel.m
//  W1 Control
//
//  Created by Jason Kingan on 9/22/15.
//  Copyright © 2015 Octal 52. All rights reserved.
//

#import "WODisplayModel.h"

@implementation WODisplayModel

-(NSString*)wattLabel:(NSNumber *) value
{
    NSNumberFormatter * nf = [[NSNumberFormatter alloc] init];

    nf.roundingMode = NSNumberFormatterRoundHalfUp;
    nf.numberStyle = NSNumberFormatterDecimalStyle;
    nf.positiveSuffix = @" W";
    nf.usesSignificantDigits = YES;
    nf.minimumSignificantDigits = 1;
    nf.maximumSignificantDigits = 4;
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
    return [NSNumber numberWithFloat:100];
}

-(NSNumber*)forwardMinValue
{
    return [NSNumber numberWithFloat:0];
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
    return [NSString stringWithFormat:@"%d W", [self.reverseMinValue intValue]];
}

-(NSString*)reverseMidLabel
{
    return [NSString stringWithFormat:@"%d W", ([self.reverseMaxValue intValue] - [self.reverseMinValue intValue]) / 2];
}

-(NSString*)reverseMaxLabel
{
    return [NSString stringWithFormat:@"%d W", [self.reverseMaxValue intValue]];
}

-(NSNumber*)reverseMaxValue
{
    return [NSNumber numberWithFloat:100];
}

-(NSNumber*)reverseMinValue
{
    return [NSNumber numberWithFloat:0];
}

-(NSString*)swrLabel
{
    float swr = [self.swrValue floatValue];

    if(swr < 1.0 || swr != swr) {
        return @"Inf";
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


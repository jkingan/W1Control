//
//  WODisplayModel.h
//  W1 Control
//
//  Created by Jason Kingan on 9/22/15.
//  Copyright © 2015 Octal 52. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WOSerialControl;

@interface WODisplayModel : NSObject
{
    float _reverseValue;
    float _forwardValue;
    float _forwardMaxValue;
    float _forwardMinValue;
    float _reverseMaxValue;
    float _reverseMinValue;
    int _updateIntervalIndex;
    NSArray * _updateIndexIntervals;
}


@property (nonatomic, readonly)  NSString * forwardMinLabel;
@property (nonatomic, readonly)  NSString * forwardMidLabel;
@property (nonatomic, readonly)  NSString * forwardMaxLabel;
@property (nonatomic, copy)  NSNumber * forwardMinValue;
@property (nonatomic, copy)  NSNumber * forwardMaxValue;

@property (nonatomic, readonly)  NSString * forwardValueLabel;
@property (nonatomic, copy)  NSNumber * forwardValue;

@property (nonatomic, readonly)  NSString * reverseMinLabel;
@property (nonatomic, readonly)  NSString * reverseMidLabel;
@property (nonatomic, readonly)  NSString * reverseMaxLabel;
@property (nonatomic, copy)  NSNumber * reverseMinValue;
@property (nonatomic, copy)  NSNumber * reverseMaxValue;

@property (nonatomic, readonly)  NSString * reverseValueLabel;
@property (nonatomic, copy)  NSNumber * reverseValue;

@property (nonatomic, readonly)  NSString * swrLabel;
@property (nonatomic, readonly)  NSNumber * swrValue;

@property (nonatomic, copy) NSString * version;
@property (nonatomic, assign) BOOL isConnected;
@property (nonatomic, copy) NSImage * connectedImage;

@property (nonatomic, assign) BOOL automaticRanging;
@property (nonatomic, assign) int  currentRange;

@property (nonatomic, assign) int rangeDropRate;
@property (nonatomic, assign) int rangeDropRateNoUpdate;
@property (nonatomic, assign) int ledDecayRate;
@property (nonatomic, assign) int ledDecayRateNoUpdate;
@property (nonatomic, assign) int ledType;
@property (nonatomic, assign) int ledTypeNoUpdate;
@property (nonatomic, assign) int serialType;
@property (nonatomic, assign) int serialTypeNoUpdate;

@property (nonatomic, assign) BOOL writeSettingsToFlash;

@property (nonatomic, assign) IBOutlet WOSerialControl * serialControl;
@property (nonatomic, assign) float updateInterval;
@property (nonatomic, assign) int updateIntervalIndex;

@property (nonatomic, readonly) NSString * updateIndexInterval_0;
@property (nonatomic, readonly) NSString * updateIndexInterval_1;
@property (nonatomic, readonly) NSString * updateIndexInterval_2;
@property (nonatomic, readonly) NSString * updateIndexInterval_3;
@property (nonatomic, readonly) NSString * updateIndexInterval_4;

@end

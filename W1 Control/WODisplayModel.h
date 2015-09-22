//
//  WODisplayModel.h
//  W1 Control
//
//  Created by Jason Kingan on 9/22/15.
//  Copyright © 2015 Octal 52. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WODisplayModel : NSObject
{
    float _reverseValue;
    float _forwardValue;
}


@property (nonatomic, readonly)  NSString * forwardMinLabel;
@property (nonatomic, readonly)  NSString * forwardMidLabel;
@property (nonatomic, readonly)  NSString * forwardMaxLabel;
@property (nonatomic, readonly)  NSNumber * forwardMinValue;
@property (nonatomic, readonly)  NSNumber * forwardMaxValue;

@property (nonatomic, readonly)  NSString * forwardValueLabel;
@property (nonatomic, readonly)  NSNumber * forwardValue;

@property (nonatomic, readonly)  NSString * reverseMinLabel;
@property (nonatomic, readonly)  NSString * reverseMidLabel;
@property (nonatomic, readonly)  NSString * reverseMaxLabel;
@property (nonatomic, readonly)  NSNumber * reverseMinValue;
@property (nonatomic, readonly)  NSNumber * reverseMaxValue;

@property (nonatomic, readonly)  NSString * reverseValueLabel;
@property (nonatomic, copy)  NSNumber * reverseValue;

@property (nonatomic, readonly)  NSString * swrLabel;
@property (nonatomic, readonly)  NSString * swrValue;

@end

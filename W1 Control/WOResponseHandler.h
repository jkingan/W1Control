//
//  WOResponseHandler.h
//  W1 Control
//
//  Created by Jason Kingan on 9/23/15.
//  Copyright © 2015 Jason Kingan, KG7NUX. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WODisplayModel;
@class WOSerialControl;

extern NSString * kWOCommandResponseReceived;

@interface WOResponseHandler : NSObject
{
}
-(id)initWithDisplayModel:(WODisplayModel*)displayModel;

@property (nonatomic, retain) IBOutlet WODisplayModel * displayModel;
@property (nonatomic, retain) IBOutlet WOSerialControl * serialControl;

@end

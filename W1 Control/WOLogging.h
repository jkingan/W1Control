//
//  WOLogging.h
//  W1 Control
//
//  Created by Jason Kingan on 9/29/15.
//  Copyright © 2015 KG7NUX. All rights reserved.
//

#import <Foundation/Foundation.h>

extern int _WOLogging_Severity;
#define WOLog(_severity, _format, args...) { if(_WOLogging_Severity >= _severity) {NSLog(_format, ##args );}}

@interface WOLogging : NSObject

@end

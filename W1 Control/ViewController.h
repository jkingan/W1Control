//
//  ViewController.h
//  W1 Control
//
//  Created by Jason Kingan on 9/22/15.
//  Copyright © 2015 Octal 52. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class WODisplayModel;
@class WOResponseHandler;
@class WOSerialControl;

@interface ViewController : NSViewController

@property (retain) IBOutlet WODisplayModel * displayModel;
@property (retain) IBOutlet WOResponseHandler * responseHandler;
@property (retain) IBOutlet WOSerialControl * serialControl;
@end


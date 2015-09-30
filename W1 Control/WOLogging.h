//
//  WOLogging.h
//  W1 Control
//
//  Created by Jason Kingan on 9/29/15.
//  Copyright © 2015 KG7NUX. All rights reserved.
//

#import <Foundation/Foundation.h>


#define WOLOG_ALWAYS 0
#define WOLOG_ERROR  1
#define WOLOG_STATUS 2
#define WOLOG_ANNOY  3

extern void _WOLog(int severity, const char * function, int line, NSString * format, ...);
#define WOLog(_severity, _format, args ...) { _WOLog(_severity, __FUNCTION__, __LINE__, _format, ## args); }

@class NSTextView;

@interface WOLogging : NSObject

-(IBAction)clearLogFile:(id)sender;
-(void)addText:(NSString *)logMsg;

@property (nonatomic, assign) IBOutlet NSTextView * textView;
@property (nonatomic, readonly) NSString * logFilename;
@end

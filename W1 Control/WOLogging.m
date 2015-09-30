//
//  WOLogging.m
//  W1 Control
//
//  Created by Jason Kingan on 9/29/15.
//  Copyright © 2015 KG7NUX. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "WOLogging.h"
#include "asl.h"

#define MAX_LOG_SIZE  (1024 * 256)
#define CLIP_LOG_SIZE (1024 * 96)


static NSInteger _WOLogging_Severity = 99;
static FILE * _WOLogging_file;
static __weak WOLogging * _WOLogging_Output;

static void _WOLog_CloseFile();

static NSString * _WOLog_Filename()
{
    return [@"~/Library/Logs/W1 Control.log" stringByExpandingTildeInPath];
}

static void _WOLog_ClearLogFile()
{
    _WOLog_CloseFile();
    [[NSFileManager defaultManager] removeItemAtPath:_WOLog_Filename() error:nil];
}

static void _WOLog_SizeLogFile()
{
    _WOLog_CloseFile();
    NSFileManager * fm = [NSFileManager defaultManager];

    if(![fm isReadableFileAtPath:_WOLog_Filename()] || ![fm isWritableFileAtPath:_WOLog_Filename()]) {
        return;
    }

    NSDictionary * fileAttributes = [fm attributesOfItemAtPath:_WOLog_Filename() error:nil];

    NSNumber * fileSize = [fileAttributes objectForKey:NSFileSize];

    if([fileSize unsignedLongLongValue] < MAX_LOG_SIZE) {
        return;
    }

    NSString * logContents = [NSString stringWithContentsOfFile:_WOLog_Filename() encoding:NSUTF8StringEncoding error:nil];
    NSString * newContents = [logContents substringFromIndex:logContents.length - CLIP_LOG_SIZE];
    [newContents writeToFile:_WOLog_Filename() atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

static void _WOLog_CloseFile()
{
    if(_WOLogging_file) {
        fflush(_WOLogging_file);
        fclose(_WOLogging_file);
        _WOLogging_file = 0;
    }
}

static void _WOLog_OpenFile()
{
    if(_WOLogging_file) {
        _WOLog_CloseFile();
    }

    _WOLog_SizeLogFile();

    _WOLogging_file = fopen([_WOLog_Filename() UTF8String], "a+");
    _WOLogging_Severity = [[NSUserDefaults standardUserDefaults] integerForKey:@"loggingLevel"];
}

void _WOLog(int severity, const char * function, int line, NSString * format, ...)
{
    if([[NSUserDefaults standardUserDefaults] integerForKey:@"loggingLevel"] < severity) {
        return;
    }

    if(0 == _WOLogging_file) {
        _WOLog_OpenFile();
    }

    va_list list;
    va_start(list, format);

    NSString * logMsg = [NSString stringWithFormat:@"%s:%d - %@", function, line, [[NSString alloc] initWithFormat:format arguments:list]];
    fputs([logMsg UTF8String], stderr);
    if(_WOLogging_file) {
        fputs([logMsg UTF8String], _WOLogging_file);
    }

    if(_WOLogging_Output) {
        [_WOLogging_Output addText:logMsg];
    }

    va_end(list);
}

@implementation WOLogging

-(id)init
{
    self = [super init];
    _WOLogging_Output = self;
    return self;
}

-(void)setTextView:(NSTextView *)textView
{
    _textView = textView;
    [self fillTextView];
}

-(void)addText:(NSString *)logMsg
{
    NSString * oldText = [self.textView string];

    [self.textView setString:[oldText stringByAppendingString:logMsg]];
    [self.textView scrollToEndOfDocument:self];
}

-(void)fillTextView
{
    _WOLog_CloseFile();

    NSString * contents = [NSString stringWithContentsOfFile:_WOLog_Filename() encoding:NSUTF8StringEncoding error:nil];
    if(nil == contents) {
        contents = @"";
    }
    [self.textView setString:contents];
}

-(void)clearLogFile:(id)sender
{
    _WOLog_ClearLogFile();
    [self fillTextView];
}

-(void)dealloc
{
    _WOLogging_Output = nil;
}

-(NSString *)logFilename
{
    return _WOLog_Filename();
}

@end

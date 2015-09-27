//
//  ViewController.m
//  W1 Control
//
//  Created by Jason Kingan on 9/22/15.
//  Copyright © 2015 Octal 52. All rights reserved.
//

#import "ViewController.h"
#import "WODisplayModel.h"
#import "WOSerialControl.h"

@implementation ViewController

-(void)dealloc
{

}

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
}

-(void)viewDidAppear
{
//    [self performSelector:@selector(randomValue) withObject:nil afterDelay:0];
}

-(void)viewDidDisappear
{
    [[NSApplication sharedApplication] terminate:nil];
}

-(void)randomValue
{
    NSNumber * r = self.displayModel.reverseValue;
    NSNumber * f = self.displayModel.forwardValue;

    if(!r) {
        r = [NSNumber numberWithFloat:0];
    }

    if(!f || [f floatValue] < 1) {
        f = [NSNumber numberWithFloat:60];
    }


    r = [NSNumber numberWithFloat:[r floatValue] + 1.7];
    self.displayModel.reverseValue = r;

    f = [NSNumber numberWithFloat:[f floatValue] - 2.1];
    self.displayModel.forwardValue = f;

    [self performSelector:@selector(randomValue) withObject:nil afterDelay:2];
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

@end

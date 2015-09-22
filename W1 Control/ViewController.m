//
//  ViewController.m
//  W1 Control
//
//  Created by Jason Kingan on 9/22/15.
//  Copyright © 2015 Octal 52. All rights reserved.
//

#import "ViewController.h"
#import "WODisplayModel.h"

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
}

-(void)viewDidAppear
{
    [self performSelector:@selector(randomValue) withObject:nil afterDelay:0];
}

-(void)randomValue
{
    NSNumber * v = self.displayModel.reverseValue;

    if(!v) {
        v = [NSNumber numberWithFloat:0];
    }

    v = [NSNumber numberWithFloat:[v floatValue] + 1];
    self.displayModel.reverseValue = v;

    [self performSelector:@selector(randomValue) withObject:nil afterDelay:2];
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

@end

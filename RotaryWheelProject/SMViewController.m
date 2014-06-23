//
//  SMViewController.m
//  RotaryWheelProject
//
//  Created by cesarerocchi on 2/10/12.
//  Copyright (c) 2012 studiomagnolia.com. All rights reserved.
//

#import "SMViewController.h"
#import "SMRotaryWheel.h"

@interface SMViewController ()
@property (nonatomic, assign) CGFloat diameter;
@end

@implementation SMViewController

@synthesize  valueLabel;
// original project assets are assuming this size
static float diameter = 280.0;

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
#ifdef DEBUG
    valueLabel = [[UILabel alloc] initWithFrame:CGRectMake(100, 100, 120, 30)];
    valueLabel.textAlignment = UITextAlignmentCenter;
    valueLabel.backgroundColor = [UIColor lightGrayColor];
    [self.view addSubview:valueLabel];
#endif
    
    // init wheel dimensions and number of sectors. start out at bottom of screen withonly top half showing
	CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    self.diameter = diameter;
	
    SMRotaryWheel *wheel = [SMRotaryWheel wheelControlWithFrame:CGRectMake(0,0, self.diameter, self.diameter)
                                                       delegate:self
                                                    andSections:6];

    wheel.center = CGPointMake(screenWidth/2, screenHeight);
    [self.view addSubview:wheel];
    
}



- (void) wheelDidChangeValue:(int)newValue {

    self.valueLabel.text = [SMRotaryWheel getCloveName:newValue];
    
}

- (void) wheelDidSwipeUp
{
    NSLog(@"show the wheel fully");
}

- (void) wheelDidSwipeDown
{
    NSLog(@"hide bottom part of the wheel");
}


@end

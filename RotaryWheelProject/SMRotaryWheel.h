//
//  SMRotaryWheel.h
//  RotaryWheelProject
//
//  Created by cesarerocchi on 2/10/12.
//  Copyright (c) 2012 studiomagnolia.com. All rights reserved.


#import <UIKit/UIKit.h>
#import "SMRotaryProtocol.h"

@interface SMRotaryWheel : UIControl

@property (weak) id <SMRotaryProtocol> delegate;
@property int currentValue;
@property (nonatomic, strong) UIButton *centerButton;
@property (nonatomic, assign) BOOL rotationDisabled;
@property (nonatomic, assign) BOOL tapEnabled;

+ (SMRotaryWheel *)wheelControlWithFrame:(CGRect)rect delegate:(id)delegate andSections:(NSUInteger *)numSections;
+ (NSString *) getCloveName:(int)position;

- (void)centerButtonHandler:(UIButton *)sender;

@end

//
//  SMRotaryProtocol.h
//  RotaryWheelProject
//
//  Created by cesarerocchi on 2/10/12.
//  Copyright (c) 2012 studiomagnolia.com. All rights reserved.


#import <Foundation/Foundation.h>

@class SMRotaryWheel;

@protocol SMRotaryProtocol <NSObject>

- (void) wheel:(SMRotaryWheel *)wheel didChangeValue:(int)newValue;
- (void) wheelDidSwipeUp;
- (void) wheelDidSwipeDown;
- (void) wheel:(SMRotaryWheel *)wheel didSelectSectorAtIndex:(NSUInteger)index;
- (void) wheelDidSelectCenterButton;

@end

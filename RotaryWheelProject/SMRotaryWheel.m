//
//  SMRotaryWheel.m
//  RotaryWheelProject
//
//  Created by cesarerocchi on 2/10/12.
//  Copyright (c) 2012 studiomagnolia.com. All rights reserved.


#import "SMRotaryWheel.h"
#import <QuartzCore/QuartzCore.h>
#import "SMCLove.h"

@interface SMRotaryWheel()
@property (nonatomic, strong) UIView *container;
@property int numberOfSections;
@property CGAffineTransform startTransform;
@property (nonatomic, strong) NSMutableArray *cloves;

- (void)drawWheel;
- (float) calculateDistanceFromCenter:(CGPoint)point;
- (void) buildClovesEven;
- (void) buildClovesOdd;
- (UIImageView *) getCloveByValue:(int)value;

@end

static float deltaAngle;
static float minAlphavalue = 0.6;
static float maxAlphavalue = 1.0;
static float centerButtonRadius = 40.6;
static float sectorWidth = 98;
static float sectorHeight = 126;
static float sectorIconX = 26;
static float sectorIconY = 26;
static float sectorIconSize = 40;
static float startingAngle = M_PI_2;

@implementation SMRotaryWheel

@synthesize delegate, container, numberOfSections, startTransform, cloves, currentValue;


+ (SMRotaryWheel *)wheelControlWithFrame:(CGRect)rect delegate:(id)delegate andSections:(NSUInteger *)numSections
{
    SMRotaryWheel *wheel = [[SMRotaryWheel alloc] initWithFrame:rect andDelegate:delegate withSections:numSections];
    return wheel;
}

- (id) initWithFrame:(CGRect)frame andDelegate:(id)del withSections:(int)sectionsNumber {
    
    if ((self = [super initWithFrame:frame])) {
		
        self.currentValue = 0;
        self.numberOfSections = sectionsNumber;
        self.delegate = del;
		[self drawWheel];
        
        // Add a gesture recognizer to support swiping up
        UISwipeGestureRecognizer * upSwipeRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeUp:)];
        upSwipeRecognizer.delegate = del;
        upSwipeRecognizer.delaysTouchesBegan = YES;
        [upSwipeRecognizer setDirection:UISwipeGestureRecognizerDirectionUp];
        [self addGestureRecognizer:upSwipeRecognizer];
        
        // down swipe recognizer
        UISwipeGestureRecognizer * downSwipeRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeDown:)];
        downSwipeRecognizer.delegate = del;
        downSwipeRecognizer.delaysTouchesBegan = YES;
        [downSwipeRecognizer setDirection:UISwipeGestureRecognizerDirectionDown];
        [self addGestureRecognizer:downSwipeRecognizer];
        
        
	}
    return self;
}



- (void) drawWheel {

    container = [[UIView alloc] initWithFrame:self.frame];
    CGFloat angleSize = 2*M_PI/numberOfSections;

    for (int i = 0; i < numberOfSections; i++) {
        UIImage *sectorBackground = [UIImage imageNamed:@"segmentVertical.png"];
        UIImageView *im = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, sectorWidth, sectorHeight)];  //Image:[UIImage imageNamed:]];
        im.contentMode = UIViewContentModeScaleAspectFill;
        im.image = sectorBackground;
        im.layer.anchorPoint = CGPointMake(0.5f, 1.0f);
        im.layer.position = CGPointMake(container.bounds.size.width/2.0-container.frame.origin.x, 
                                        container.bounds.size.height/2.0-container.frame.origin.y);
    
        im.transform = CGAffineTransformMakeRotation(angleSize*i);
        im.alpha = minAlphavalue;
        im.tag = i;
        
        if (i == 0) {
            im.alpha = maxAlphavalue;
        }
        
        UIImageView *cloveImage = [[UIImageView alloc] initWithFrame:CGRectMake(sectorIconX, sectorIconY, sectorIconSize, sectorIconSize)];
        cloveImage.image = [UIImage imageNamed:[NSString stringWithFormat:@"icon%i.png", i]];
        [im addSubview:cloveImage];
        
        [container addSubview:im];
        
    }
    
    container.userInteractionEnabled = NO;
    [self addSubview:container];
    
    cloves = [NSMutableArray arrayWithCapacity:numberOfSections];
    
    UIImageView *bg = [[UIImageView alloc] initWithFrame:self.frame];
    bg.image = [UIImage imageNamed:@"bg.png"];
    bg.transform = CGAffineTransformMakeRotation(startingAngle);
    [self addSubview:bg];
    /*
    UIImageView *mask = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, centerButtonRadius*2, centerButtonRadius*2)];
    mask.image =[UIImage imageNamed:@"centerButton.png"] ;
    mask.center = self.center;
    mask.center = CGPointMake(mask.center.x-4, mask.center.y);
    [self addSubview:mask];
    */
    self.centerButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, centerButtonRadius*2, centerButtonRadius*2)];
    [self.centerButton setImage:[UIImage imageNamed:@"centerButton.png"] forState:UIControlStateNormal];
    self.centerButton.center = self.center;
    self.centerButton.center = CGPointMake(self.centerButton.center.x-4, self.centerButton.center.y);
    [self.centerButton addTarget:self action:@selector(centerButtonHandler:)
             forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.centerButton];
    
    if (numberOfSections % 2 == 0) {
        
        [self buildClovesEven];
        
    } else {
        
        [self buildClovesOdd];
        
    }
    
    [self.delegate wheelDidChangeValue:currentValue];

    
}


- (UIImageView *) getCloveByValue:(int)value {

    UIImageView *res;
    
    NSArray *views = [container subviews];
    
    for (UIImageView *im in views) {
        
        if (im.tag == value)
            res = im;
        
    }
    
    return res;
    
}

- (void) buildClovesEven {
    
    CGFloat fanWidth = M_PI*2/numberOfSections;
    CGFloat mid = 0; //startingAngle;

    for (int i = 0; i < numberOfSections; i++) {
        
        SMClove *clove = [[SMClove alloc] init];
        clove.midValue = mid;
        clove.minValue = mid - (fanWidth/2);
        clove.maxValue = mid + (fanWidth/2);
        clove.value = i;
        
        
        if (clove.maxValue-fanWidth < - M_PI) {
            
            mid = M_PI;
            clove.midValue = mid;
            clove.minValue = fabsf(clove.maxValue);
            
        }
        
        mid -= fanWidth;
        
        
        NSLog(@"cl is %@", clove);
        
        [cloves addObject:clove];
        
    }
    
}


- (void) buildClovesOdd {
    
    CGFloat fanWidth = M_PI*2/numberOfSections;
    CGFloat mid = 0;
    
    for (int i = 0; i < numberOfSections; i++) {
        
        SMClove *clove = [[SMClove alloc] init];
        clove.midValue = mid;
        clove.minValue = mid - (fanWidth/2);
        clove.maxValue = mid + (fanWidth/2);
        clove.value = i;
        
        mid -= fanWidth;
        
        if (clove.minValue < - M_PI) {
            
            mid = -mid;
            mid -= fanWidth; 
            
        }
        
                
        [cloves addObject:clove];
        
        NSLog(@"cl is %@", clove);
        
    }
    
}

- (float) calculateDistanceFromCenter:(CGPoint)point {
    
    CGPoint center = CGPointMake(self.bounds.size.width/2.0f, self.bounds.size.height/2.0f);
	float dx = point.x - center.x;
	float dy = point.y - center.y;
	return sqrt(dx*dx + dy*dy);
    
}

#pragma mark - touch event handling

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    
    CGPoint touchPoint = [touch locationInView:self];
    CGFloat dist = [self calculateDistanceFromCenter:touchPoint];
    CGSize size = self.container.bounds.size;
    CGFloat diameter = size.width;

    if (dist < centerButtonRadius || dist > diameter/2)
    {
        // forcing a tap to be on the sector
        NSLog(@"ignoring tap (%f,%f)", touchPoint.x, touchPoint.y);
        return NO;
    }

	float dx = touchPoint.x - container.center.x;
	float dy = touchPoint.y - container.center.y;
	deltaAngle = atan2(dy,dx);
    
    startTransform = container.transform;
    
    UIImageView *im = [self getCloveByValue:currentValue];
    im.alpha = minAlphavalue;
    
    return YES;
    
}

- (BOOL)continueTrackingWithTouch:(UITouch*)touch withEvent:(UIEvent*)event
{
    
    if (self.rotationDisabled) {
        return NO;
    }
    
	CGPoint pt = [touch locationInView:self];
    
    float dist = [self calculateDistanceFromCenter:pt];
    CGSize size = self.container.bounds.size;
    CGFloat diameter = size.width;
    
    if (dist < centerButtonRadius || dist > diameter/2)
    {
        // a drag path too close to the center
        NSLog(@"drag path too close to the center (%f,%f)", pt.x, pt.y);
        
    }
	
	float dx = pt.x  - container.center.x;
	float dy = pt.y  - container.center.y;
	float ang = atan2(dy,dx);
    
    float angleDifference = deltaAngle - ang;
    
    container.transform = CGAffineTransformRotate(startTransform, -angleDifference);
    
    return YES;
	
}

- (void)endTrackingWithTouch:(UITouch*)touch withEvent:(UIEvent*)event
{
    
    CGFloat radians = atan2f(container.transform.b, container.transform.a);
    
    CGFloat newVal = 0.0;
    
    for (SMClove *c in cloves) {
        
        if (c.minValue > 0 && c.maxValue < 0) { // anomalous case
            
            if (c.maxValue > radians || c.minValue < radians) {
                
                if (radians > 0) { // we are in the positive quadrant
                    
                    newVal = radians - M_PI;
                    
                } else { // we are in the negative one
                    
                    newVal = M_PI + radians;                    
                    
                }
                currentValue = c.value;
                
            }
            
        }
        
        else if (radians > c.minValue && radians < c.maxValue) {
            
            newVal = radians - c.midValue;
            currentValue = c.value;
            
        }
        
    }
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.2];
    
    CGAffineTransform t = CGAffineTransformRotate(container.transform, -newVal);
    container.transform = t;
    
    [UIView commitAnimations];
    
    [self.delegate wheelDidChangeValue:currentValue];
    
    UIImageView *im = [self getCloveByValue:currentValue];
    im.alpha = maxAlphavalue;
    
}


- (void)centerButtonHandler:(UIButton *)sender
{
    NSLog(@"touched up inside center button. go to dashboard");
}
     

+ (NSString *) getCloveName:(int)position {
    
    NSString *res = @"";
    
    switch (position) {
        case 0:
            res = @"Star";
            break;
            
        case 1:
            res = @"All Rooms";
            break;
            
        case 2:
            res = @"Monster";
            break;
            
        case 3:
            res = @"Person";
            break;
            
        case 4:
            res = @"Smile";
            break;
            
        case 5:
            res = @"Sun";
            break;
            
        case 6:
            res = @"Swirl";
            break;
            
        case 7:
            res = @"3 circles";
            break;
            
        case 8:
            res = @"Triangle";
            break;
            
        default:
            break;
    }
    
    return res;
}

#pragma mark - UIGestureRecognizerDelegate

- (IBAction)handleSwipeUp:(UISwipeGestureRecognizer *)recognizer {
	CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
    CGFloat diameter = self.bounds.size.width;
    CGFloat upOffset = diameter/2;
    CGFloat newY = recognizer.view.center.y - upOffset;

    
    if (recognizer.direction == UISwipeGestureRecognizerDirectionUp && newY <=  screenHeight - diameter/2) {
        
        [UIView animateWithDuration:1
                              delay:0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             recognizer.view.alpha = 1.0;
                             recognizer.view.center = CGPointMake(recognizer.view.center.x, screenHeight - diameter/2);
                         }
         // wheel rotation is disabled when it's fully displayed
                         completion:^(BOOL finished){ self.rotationDisabled = YES; }
         ];
    }
    
}


- (IBAction)handleSwipeDown:(UISwipeGestureRecognizer *)recognizer {
	CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
    CGFloat diameter = self.bounds.size.width;
    CGFloat dnOffset = diameter/2;
    CGFloat newY = recognizer.view.center.y + dnOffset;
    
    if (recognizer.direction == UISwipeGestureRecognizerDirectionDown && newY >=  screenHeight) {
        
        [UIView animateWithDuration:1
                              delay:0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             recognizer.view.center = CGPointMake(recognizer.view.center.x, screenHeight);
                         }
         // reenable rotation of wheel when it's half hidden
                         completion:^(BOOL finished){ self.rotationDisabled = NO; }
         ];
    }
    
}

/*
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if ([touch.view isKindOfClass:[SMRotaryWheel class]])
    {
        return YES;
    }
    return NO;
}
*/


@end

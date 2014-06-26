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
@property (nonatomic, strong) NSMutableArray *sections;
@property CGAffineTransform startTransform;
@property (nonatomic, strong) NSMutableArray *cloves;
@property (nonatomic, readwrite) int lastSelectedIndex;

- (void)drawWheel;
- (float) calculateDistanceFromCenter:(CGPoint)point;
- (void) buildClovesEven;
- (void) buildClovesOdd;
- (UIImageView *) getCloveByValue:(int)value;

@end

static float deltaAngle;
static float minAlphavalue = 0.6;
static float maxAlphavalue = 1.0;
static float centerButtonRadius = 30;
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
        self.sections = [NSMutableArray arrayWithCapacity:sectionsNumber];
        self.delegate = del;
        self.rotationDisabled = NO;
        
        // Add a gesture recognizer to support swiping up
        UISwipeGestureRecognizer * upSwipeRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeUp:)];
        upSwipeRecognizer.delegate = del;
        upSwipeRecognizer.delaysTouchesBegan = YES;
        upSwipeRecognizer.cancelsTouchesInView = NO;
        [upSwipeRecognizer setDirection:UISwipeGestureRecognizerDirectionUp];
        [self addGestureRecognizer:upSwipeRecognizer];
        
        // down swipe recognizer
        UISwipeGestureRecognizer * downSwipeRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeDown:)];
        downSwipeRecognizer.delegate = del;
        downSwipeRecognizer.delaysTouchesBegan = YES;
        downSwipeRecognizer.cancelsTouchesInView = NO;
        [downSwipeRecognizer setDirection:UISwipeGestureRecognizerDirectionDown];
        [self addGestureRecognizer:downSwipeRecognizer];

        // tap recognizer
        UITapGestureRecognizer * tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
        tapRecognizer.delegate = del;
        tapRecognizer.delaysTouchesBegan = NO;
        tapRecognizer.cancelsTouchesInView = NO;
        tapRecognizer.numberOfTapsRequired = 1;
        [self addGestureRecognizer:tapRecognizer];

		[self drawWheel];
        [self enableTaps:NO withDelegate: del];  // start in half wheel mode, with taps disabled and rotation enabled

        
	}
    return self;
}


- (void) updateCenterButtonIcon {
    [self.centerButton setImage:[UIImage imageNamed:@"home-icon-red"] forState:UIControlStateNormal];
    
    CGSize imageSize = self.centerButton.imageView.frame.size;
    CGFloat padding = centerButtonRadius/2;
    CGFloat totalHeight = (imageSize.height + padding);
    
    if (!self.rotationDisabled)
    {
        // show home icon in the top half of the centerButton
        self.centerButton.imageEdgeInsets = UIEdgeInsetsMake(- (totalHeight - imageSize.height),
                                                             0.0f,
                                                             0.0f,
                                                             0.0f);
    }
    else {
        //reset to center the home icon
        self.centerButton.imageEdgeInsets = UIEdgeInsetsMake(0.0f,
                                                             0.0f,
                                                             0.0f,
                                                             0.0f);
    }
    
}


- (void) drawWheel {

    container = [[UIView alloc] initWithFrame:self.frame];
    CGFloat angleSize = 2*M_PI/numberOfSections;

    for (int i = 0; i < numberOfSections; i++) {
        UIImage *sectorBackground = [UIImage imageNamed:@"sector-background"];
        UIImageView *im = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, sectorWidth, sectorHeight)];
        im.contentMode = UIViewContentModeScaleAspectFill;
        im.image = sectorBackground;
        im.layer.anchorPoint = CGPointMake(0.5f, 1.0f);
        im.layer.position = CGPointMake(container.bounds.size.width/2.0-container.frame.origin.x, 
                                        container.bounds.size.height/2.0-container.frame.origin.y);
    
        im.transform = CGAffineTransformMakeRotation(angleSize*i);
        im.alpha = self.rotationDisabled? maxAlphavalue : minAlphavalue;
        im.tag = i;
        im.userInteractionEnabled = NO;
        if (i == 0) {
            im.alpha = maxAlphavalue;
        }
        
        UIImageView *cloveImage = [[UIImageView alloc] initWithFrame:CGRectMake(sectorIconX, sectorIconY, sectorIconSize, sectorIconSize)];
        cloveImage.image = [UIImage imageNamed:[NSString stringWithFormat:@"wheel-icon%i", i]];
        cloveImage.tag = i;
        [im addSubview:cloveImage];

        self.sections[i] = im;
        [container addSubview:im];
        
    }

    [self addSubview:container];
    
    cloves = [NSMutableArray arrayWithCapacity:numberOfSections];
    
    self.centerButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, centerButtonRadius*2, centerButtonRadius*2)];
    self.centerButton.layer.cornerRadius = self.centerButton.bounds.size.width/2;
    self.centerButton.backgroundColor = [UIColor whiteColor];
    
    [self updateCenterButtonIcon];
    
    self.centerButton.center = self.center;
    self.centerButton.center = CGPointMake(self.centerButton.center.x-4, self.centerButton.center.y);
    [self.centerButton addTarget:self action:@selector(centerButtonHandler:)
             forControlEvents:UIControlEventTouchUpInside];
    self.centerButton.tag = 7;// center button
    [self addSubview:self.centerButton];

    UIImage *bgImage = [UIImage imageNamed:@"arrow-circle"];
    UIImageView *bg = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, bgImage.size.width, bgImage.size.height)];
    bg.center = self.centerButton.center;
    bg.backgroundColor = [UIColor clearColor];
    bg.image = bgImage;
    bg.userInteractionEnabled = NO;
    [self addSubview:bg];
    
    if (numberOfSections % 2 == 0) {
        
        [self buildClovesEven];
        
    } else {
        
        [self buildClovesOdd];
        
    }
    
    [self.delegate wheel:self didChangeValue:currentValue];

    
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
- (void)enableTaps:(BOOL)enable withDelegate:(id) del
{
    // tap and rotation are mutually exclusive. either we rotate a sector to top to select it or when wheel is showing fully, we tap to select a sector
    self.tapEnabled = enable;
    self.rotationDisabled = enable;
    if (self.sections.count > 0)
    {
        for (int i = 0; i < numberOfSections; i++) {
            UIView * sector = (UIView *)self.sections[i];
            sector.userInteractionEnabled = enable;
        }
    }
    // user interaction must be enabled to respond to hitTest method used to detect which sector was selected
    container.userInteractionEnabled = enable;
    if (self.centerButton) self.centerButton.userInteractionEnabled = enable;
}

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

    if (self.rotationDisabled) {
        return;
    }
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
    
    [self.delegate wheel:self didChangeValue:currentValue];
    
    UIImageView *im = [self getCloveByValue:currentValue];
    im.alpha = maxAlphavalue;
    
}

- (void)cancelTrackingWithEvent:(UIEvent *)event
{
    NSLog(@"cancelTrackingWithEvent %@", event);
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

- (void)centerButtonHandler:(UIButton *)sender
{
    NSLog(@"touched up inside center button");
    //self.centerButton.backgroundColor = [UIColor whiteColor];
    UIView *lastSector = (UIView *)self.sections[self.lastSelectedIndex];
    lastSector.alpha = minAlphavalue;
    [self.delegate wheelDidSelectCenterButton];
}

#pragma mark - UIGestureRecognizerDelegate

- (void)handleSwipeUp:(UISwipeGestureRecognizer *)recognizer {
	CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
    CGFloat diameter = self.bounds.size.width;
    CGFloat upOffset = diameter/2;
    CGFloat newY = recognizer.view.center.y - upOffset;

    
    if (recognizer.direction == UISwipeGestureRecognizerDirectionUp && newY <=  screenHeight - diameter/2) {
        
        [UIView animateWithDuration:1
                              delay:0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             //recognizer.view.alpha = 1.0;
                             recognizer.view.center = CGPointMake(recognizer.view.center.x, screenHeight - diameter/2);
                             self.centerButton.imageEdgeInsets = UIEdgeInsetsMake(0.0f,
                                                                                  0.0f,
                                                                                  0.0f,
                                                                                  0.0f);
                         }
         // wheel rotation is disabled when it's fully displayed
                         completion:^(BOOL finished){
                             [self enableTaps:YES withDelegate: self.delegate];
                             self.lastSelectedIndex = self.currentValue;
                         }
         ];
    }
    
}


- (void)handleSwipeDown:(UISwipeGestureRecognizer *)recognizer {
	CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
    CGFloat diameter = self.bounds.size.width;
    CGFloat dnOffset = diameter/2;
    CGFloat newY = recognizer.view.center.y + dnOffset;
    
    if (recognizer.direction == UISwipeGestureRecognizerDirectionDown && newY >=  screenHeight) {
        CGSize imageSize = self.centerButton.imageView.frame.size;
        CGFloat padding = centerButtonRadius/2;
        
        CGFloat totalHeight = (imageSize.height + padding);
    
        [UIView animateWithDuration:1
                              delay:0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             recognizer.view.center = CGPointMake(recognizer.view.center.x, screenHeight);
                             // show home icon in the top half of the centerButton
                             self.centerButton.imageEdgeInsets = UIEdgeInsetsMake(- (totalHeight - imageSize.height),
                                                                                  0.0f,
                                                                                  0.0f,
                                                                                  0.0f);
                         }
         // reenable rotation of wheel when it's half hidden
                         completion:^(BOOL finished){
                             [self enableTaps:NO withDelegate:self.delegate];
                         }
         ];
    }
    
}


- (void)handleTap:(UITapGestureRecognizer *)sender
{
    if (!self.tapEnabled) {
        NSLog(@"detected a tap while taps are disabled");
    }
    else {

        UIView* view = sender.view;
        CGPoint loc = [sender locationInView:view];
        UIView *subview = nil;
        double index = 0;
        float dist = [self calculateDistanceFromCenter:loc];
        

        if (dist > view.bounds.size.width/2) {
            // touch was outside the wheel            
            return;
        }
        else if (dist <= centerButtonRadius) {
            // touch was on center button
            return;
        }
        else if ([container pointInside:loc withEvent:nil])
        {
            //self.centerButton.backgroundColor = [UIColor lightGrayColor];
            subview = [container hitTest:loc withEvent:nil];
            UIView *lastSector = (UIView *)self.sections[self.lastSelectedIndex];
            lastSector.alpha = minAlphavalue;
            index = fmod(subview.tag + currentValue, 6);
            UIView *selectedSector = (UIView *)self.sections[(int)index];
            selectedSector.alpha = maxAlphavalue;
            self.lastSelectedIndex = index;
            NSLog(@"detected a tap in wheel %@ at loc %@ container %@", NSStringFromCGSize(view.frame.size), NSStringFromCGPoint(loc), NSStringFromCGSize(container.frame.size));
        }
        [self.delegate wheel:self didSelectSectorAtIndex:index];
    }
}



@end

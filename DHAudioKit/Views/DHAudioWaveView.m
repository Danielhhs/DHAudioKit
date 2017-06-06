//
//  DHAudioWaveView.m
//  DHAudio
//
//  Created by Huang Hongsen on 17/6/6.
//  Copyright © 2017年 Huang Hongsen. All rights reserved.
//

#import "DHAudioWaveView.h"
#import "NSBKeyframeAnimationFunctions.h"

static const CGFloat kDefaultFrequency = 1.5f;
static const CGFloat kDefaultAmplitude = 1.0f;
static const CGFloat kDefaultIdleAmplitude = 0.01f;
static const CGFloat kDefaultNumberOfWaves = 5.f;
static const CGFloat kDefaultPhaseShift = -0.075f;
static const CGFloat kDefaultDensity = 5.f;
static const CGFloat kDefaultPrimaryLineWidth = 3.f;
static const CGFloat kDefaultSecondaryLineWidth = 1.f;
static const CGFloat kDefaultProcessingCircleRadius = 50;

typedef NS_ENUM(NSInteger, DHAudioWaveViewStatus) {
    DHAudioWaveViewStatusUnKnown,
    DHAudioWaveViewStatusRecording,
    DHAudioWaveViewStatusMuting,
    DHAudioWaveViewStatusTransitioningToPause,
    DHAudioWaveViewStatusPaused,
    DHAudioWaveViewStatusTransitioningToProcessing,
    DHAudioWaveViewStatusProcessing,
    DHAudioWaveViewStatusTransitioningToFinished,
    DHAudioWaveViewStatusTransitioningToResume,
    DHAudioWaveViewStatusFinished,
};

@interface DHAudioWaveView ()

@property (nonatomic) CGFloat phase;
@property (nonatomic) CGFloat amplitude;

@property (nonatomic, strong) CADisplayLink *displayLink;

@property (nonatomic) NSTimeInterval transitionDuration;
@property (nonatomic) CGFloat transitionPercent;
@property (nonatomic) CGFloat level;
@property (nonatomic) NSTimeInterval elapsedTime;
@property (nonatomic) NSTimeInterval processingCycle;
@property (nonatomic) CGFloat processingPercent;

@property (nonatomic) NSTimeInterval elapsedTimeInPreviousStage;

@property (nonatomic) DHAudioWaveViewStatus status;

@end

@implementation DHAudioWaveView

#pragma mark - Initialization
- (instancetype) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (instancetype) initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setup];
    }
    return self;
}

- (void) setup
{
    self.waveColor = [UIColor grayColor];
    self.frequency = kDefaultFrequency;
    self.amplitude = kDefaultAmplitude;
    self.idleAmplitude = kDefaultIdleAmplitude;
    self.numberOfWaves = kDefaultNumberOfWaves;
    self.phaseShift = kDefaultPhaseShift;
    self.density = kDefaultDensity;
    self.primaryWaveLineWidth = kDefaultPrimaryLineWidth;
    self.secondaryWaveLineWidth = kDefaultSecondaryLineWidth;
}

#pragma mark - Actions
- (void) startRecording
{
    [self.displayLink invalidate];
    self.status = DHAudioWaveViewStatusRecording;
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateVoiceWaveForRecording)];
    [self.displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
}

- (void) stopRecordingAndStartProcessing
{
    self.elapsedTime = 0;
    self.transitionPercent = 0.f;
    [self.displayLink invalidate];
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(transitToProcessing)];
    [self.displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
}

- (void) finishProcessing
{
    [self.displayLink invalidate];
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateForTransitioningToFinished)];
    [self.displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
}

- (void) pause
{
    self.elapsedTime = 0;
    self.transitionPercent = 0.f;
    [self.displayLink invalidate];
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(transitToPause)];
    [self.displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
}

- (void) resumeRecording
{
    
}

#pragma mark - Update Data
- (void) updateVoiceWaveForRecording
{
    self.phase += self.phaseShift;
    double level = [self.dataSource audioLevel];
    self.amplitude = fmax(level, self.idleAmplitude);
    self.level = level;
    [self setNeedsDisplay];
}

- (void) updateForProcessing
{
    self.elapsedTime += self.displayLink.duration;
    NSTimeInterval timeInCycle = ((int)(self.elapsedTime * 1000) % (int)(self.processingCycle * 1000)) / 1000.f;
    self.processingPercent = NSBKeyframeAnimationFunctionEaseInOutCubic(timeInCycle * 1000, 0, 1, self.processingCycle * 1000);
    [self setNeedsDisplay];
}

- (void) updateForTransitioningToFinished
{
    if (self.status == DHAudioWaveViewStatusProcessing) {
        self.elapsedTimeInPreviousStage = ((int)(self.elapsedTime * 1000) % (int)(self.processingCycle * 1000)) / 1000.f;
        self.status = DHAudioWaveViewStatusTransitioningToFinished;
        self.elapsedTime = 0;
    }
    self.elapsedTime += self.displayLink.duration;
    if (self.elapsedTime > self.transitionDuration) {
        [self.displayLink invalidate];
        self.status = DHAudioWaveViewStatusFinished;
    }
    [self setNeedsDisplay];
}

- (NSTimeInterval) transitionDuration
{
    return 1.f;
}

- (NSTimeInterval) processingCycle
{
    return 1.5f;
}

#define SILENCE_RATIO 0.3
#define TRANSFORM_RATIO (1 - SILENCE_RATIO)

- (void) transitToProcessing
{
    self.elapsedTime += self.displayLink.duration;
    CGFloat percent = self.elapsedTime / self.transitionDuration;
    if (percent <= SILENCE_RATIO) {
        [self muteCurrentRecordWithPercent:percent];
    } else if (percent <= 1) {
        self.status = DHAudioWaveViewStatusTransitioningToProcessing;
        self.transitionPercent = (percent - SILENCE_RATIO) / TRANSFORM_RATIO;
        [self setNeedsDisplay];
    } else {
        self.transitionPercent = 1.f;
        [self setNeedsDisplay];
        self.status = DHAudioWaveViewStatusProcessing;
        [self.displayLink invalidate];
        self.elapsedTime = self.processingCycle / 2;    //Shift the phase for half of a cycle
        self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateForProcessing)];
        [self.displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    }
}

- (void) transitToPause
{
    self.elapsedTime += self.displayLink.duration;
    CGFloat percent = self.elapsedTime / self.transitionDuration;
    if (percent <= SILENCE_RATIO) {
        [self muteCurrentRecordWithPercent:percent];
    } else if (percent <= 1) {
        self.status = DHAudioWaveViewStatusTransitioningToPause;
        self.transitionPercent = (percent - SILENCE_RATIO) / TRANSFORM_RATIO;
        [self setNeedsDisplay];
    } else {
        self.transitionPercent = 1.f;
        [self setNeedsDisplay];
        self.status = DHAudioWaveViewStatusPaused;
    }
}

- (void) muteCurrentRecordWithPercent:(double)percent
{
    self.status = DHAudioWaveViewStatusMuting;
    self.amplitude = self.level - (self.level) * percent / SILENCE_RATIO;
    self.phase += self.phaseShift;
    [self setNeedsDisplay];
}

#pragma mark - Drawing
- (void)drawRect:(CGRect)rect {
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextClearRect(context, self.bounds);
    
    [self.backgroundColor set];
    CGContextFillRect(context, self.bounds);
    
    if (self.status == DHAudioWaveViewStatusRecording || self.status == DHAudioWaveViewStatusMuting) {
        [self drawRecordingWaveInContext:context];
    } else if (self.status == DHAudioWaveViewStatusTransitioningToProcessing) {
        [self drawTransitionToProcessingCircleInContext:context];
    } else if (self.status == DHAudioWaveViewStatusProcessing) {
        [self drawProcessingInContext:context];
    } else if (self.status == DHAudioWaveViewStatusTransitioningToFinished) {
        [self drawTransitioningToFinishedInContext:context];
    } else if (self.status == DHAudioWaveViewStatusTransitioningToPause) {
        [self drawTransitioningToPauseInContext:context];
    } else if (self.status == DHAudioWaveViewStatusPaused) {
        [self drawPausedIconInContext:context];
    }
}

- (void) drawRecordingWaveInContext:(CGContextRef)context
{
    CGFloat red, green, blue, alpha;
    [self.waveColor getRed:&red green:&green blue:&blue alpha:&alpha];
    CGFloat colors [] = {
        red, green, blue, alpha * 0.8,
        red, green, blue, 0.1
    };
    CGColorSpaceRef baseSpace = CGColorSpaceCreateDeviceRGB();
    CGGradientRef gradient = CGGradientCreateWithColorComponents(baseSpace, colors, NULL, 2);
    CGColorSpaceRelease(baseSpace), baseSpace = NULL;
    
    for (int i = 0; i < self.numberOfWaves; i++) {
        CGContextSetLineWidth(context, i == 0 ? self.primaryWaveLineWidth : self.secondaryWaveLineWidth);
        
        CGFloat halfHeight = CGRectGetHeight(self.bounds) / 2;
        CGFloat width = CGRectGetWidth(self.bounds);
        CGFloat mid = width / 2.f;
        
        const CGFloat maxAmplitude = halfHeight - self.primaryWaveLineWidth * 2;
        
        CGFloat progress = 1.f - (CGFloat)i / self.numberOfWaves;
        CGFloat normedAmplitude = (1.5f * progress - 0.5f) * self.amplitude;
        
        CGFloat multiplier = MIN(1.f, (progress / 3.f * 2.f) + (1.f / 3.f));
        CGFloat alpha = pow(multiplier * CGColorGetAlpha(self.waveColor.CGColor), 2) ;
        [[self.waveColor colorWithAlphaComponent:alpha] set];
        
        CGMutablePathRef path = CGPathCreateMutable();
        CGMutablePathRef strokePath = CGPathCreateMutable();
        for (CGFloat x = 0; x < width + self.density; x += self.density) {
            CGFloat scaling = -pow(1 / mid * (x - mid), 2) + 1;
            CGFloat y = scaling * maxAmplitude * normedAmplitude * sinf(2 * M_PI * (x / width) * self.frequency + self.phase) + halfHeight;
            
            if (x == 0) {
                CGPathMoveToPoint(strokePath, NULL, x, y);
                if (y < CGRectGetMidY(self.bounds)) {
                    CGPathMoveToPoint(path, NULL, x, y);
                } else {
                    CGPathMoveToPoint(path, NULL, x, y);
                }
            } else {
                CGPathAddLineToPoint(strokePath, NULL, x, y);
                if (y < CGRectGetMidY(self.bounds)) {
                    CGPathAddLineToPoint(path, NULL, x, y);
                } else {
                    CGPathAddLineToPoint(path, NULL, x, y);
                }
            }
        }
        if (i == 0) {
            CGContextAddPath(context, path);
            CGContextSaveGState(context);
            CGContextSetLineWidth(context, 0.5);
            CGContextClip(context);
            CGFloat minY = self.bounds.size.height / 2 - maxAmplitude * normedAmplitude;
            CGPoint start = CGPointMake(CGRectGetMidX(self.bounds), minY);
            CGPoint end = CGPointMake(CGRectGetMidX(self.bounds),CGRectGetMidY(self.bounds));
            CGContextDrawLinearGradient(context, gradient, start, end, 0);
            CGContextRestoreGState(context);
        }
        CGContextAddPath(context, strokePath);
        CGContextStrokePath(context);
    }
}

- (void) drawTransitionToProcessingCircleInContext:(CGContextRef)context
{
    CGFloat finalLength = 2 * M_PI * kDefaultProcessingCircleRadius;
    CGFloat currentLength = (self.bounds.size.width - (self.bounds.size.width - finalLength) * self.transitionPercent) / 2;
    CGFloat curveLength = M_PI * kDefaultProcessingCircleRadius * self.transitionPercent;
    CGFloat horizontalLength = currentLength - curveLength;
    
    CGMutablePathRef leftPath = CGPathCreateMutable();
    CGPathMoveToPoint(leftPath, NULL, self.bounds.size.width / 2 - kDefaultProcessingCircleRadius - horizontalLength, self.bounds.size.height / 2);
    CGPathAddLineToPoint(leftPath, NULL, self.bounds.size.width / 2 - kDefaultProcessingCircleRadius, self.bounds.size.height / 2);
    CGPathAddRelativeArc(leftPath, NULL, self.bounds.size.width / 2, self.bounds.size.height / 2, kDefaultProcessingCircleRadius, M_PI, M_PI * self.transitionPercent);
    
    CGMutablePathRef rightPath = CGPathCreateMutable();
    CGPathMoveToPoint(rightPath, NULL, self.bounds.size.width / 2 + kDefaultProcessingCircleRadius + horizontalLength, self.bounds.size.height / 2);
    CGPathAddLineToPoint(rightPath, NULL, self.bounds.size.width / 2 + kDefaultProcessingCircleRadius, self.bounds.size.height / 2);
    CGPathAddRelativeArc(rightPath, NULL, self.bounds.size.width / 2, self.bounds.size.height / 2, kDefaultProcessingCircleRadius, 0, M_PI * self.transitionPercent);
    
    CGContextAddPath(context, leftPath);
    CGContextAddPath(context, rightPath);
    
    CGContextSetLineCap(context, kCGLineCapRound);
    CGContextSetLineWidth(context, self.primaryWaveLineWidth);
    [self.waveColor set];
    CGContextStrokePath(context);
}

- (void) drawProcessingInContext:(CGContextRef)context
{
    CGMutablePathRef topPath = CGPathCreateMutable();
    CGFloat startAngle, delta;
    if (self.processingPercent < 0.5) {
        startAngle = M_PI;
        delta = self.processingPercent / 0.5 * M_PI;
    } else {
        startAngle = M_PI + (self.processingPercent - 0.5) / 0.5 * M_PI;
        delta = M_PI - (self.processingPercent - 0.5) / 0.5 * M_PI;
    }
    CGPathAddRelativeArc(topPath, NULL, self.bounds.size.width / 2, self.bounds.size.height / 2, kDefaultProcessingCircleRadius, startAngle, delta);
    CGContextAddPath(context, topPath);
    
    CGMutablePathRef bottomPath = CGPathCreateMutable();
    if (self.processingPercent < 0.5) {
        startAngle = 0.f;
        delta = self.processingPercent / 0.5 * M_PI;
    } else {
        startAngle = (self.processingPercent - 0.5) / 0.5 * M_PI;
        delta = M_PI - startAngle;
    }
    CGPathAddRelativeArc(bottomPath, NULL, self.bounds.size.width / 2, self.bounds.size.height / 2, kDefaultProcessingCircleRadius, startAngle, delta);
    CGContextAddPath(context, bottomPath);
    
    CGContextSetLineCap(context, kCGLineCapRound);
    CGContextSetLineWidth(context, self.primaryWaveLineWidth);
    [self.waveColor set];
    CGContextStrokePath(context);
}

- (void) drawTransitioningToFinishedInContext:(CGContextRef)context
{
    CGPoint startPoint, endPoint;
    CGFloat startPointLength, endPointLength;
    CGFloat startPointPercent, endPointPercent;
    
    CGMutablePathRef leftPath = CGPathCreateMutable();
    
    CGMutablePathRef rightPath = CGPathCreateMutable();
    
    CGFloat percentInPreviousProcess = NSBKeyframeAnimationFunctionEaseInOutCubic(self.elapsedTimeInPreviousStage * 1000, 0, 1, self.processingCycle * 1000);
    CGFloat basicLength = self.bounds.size.width / 2 - kDefaultProcessingCircleRadius;
    if (percentInPreviousProcess < 0.5) {
        startPointLength = basicLength + percentInPreviousProcess / 0.5 * M_PI * kDefaultProcessingCircleRadius;
        endPointLength = basicLength + M_PI * kDefaultProcessingCircleRadius;
    } else {
        startPointLength = basicLength;
        endPointLength = basicLength + (percentInPreviousProcess - 0.5) / 0.5 * M_PI * kDefaultProcessingCircleRadius;
    }
    
    startPointPercent = NSBKeyframeAnimationFunctionEaseOutExpo(self.elapsedTime * 1000, 0, 1, self.transitionDuration * 1000);
    endPointPercent = NSBKeyframeAnimationFunctionEaseOutCubic(self.elapsedTime * 1000, 0, 1, self.transitionDuration * 1000);
    
    CGFloat startPointRemainingLength = startPointLength * (1 - startPointPercent);
    CGFloat endPointRemainingLength = endPointLength * (1 - endPointPercent);
    if (startPointRemainingLength > basicLength) {
        CGFloat startPointAngle = (startPointRemainingLength - basicLength) / kDefaultProcessingCircleRadius;
        CGFloat endPointAngle = (endPointRemainingLength - basicLength) / kDefaultProcessingCircleRadius;
        CGPathAddRelativeArc(leftPath, NULL, CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds), kDefaultProcessingCircleRadius, M_PI * 2 - endPointAngle, endPointAngle - startPointAngle);
        
        CGPathAddRelativeArc(rightPath, NULL, CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds), kDefaultProcessingCircleRadius, M_PI - endPointAngle, endPointAngle - startPointAngle);
    } else {
        startPoint = CGPointMake(self.bounds.size.width - startPointRemainingLength, self.bounds.size.height / 2);
        CGPathMoveToPoint(leftPath, NULL, startPoint.x, startPoint.y);
        CGPathMoveToPoint(rightPath, NULL, startPointRemainingLength, self.bounds.size.height / 2);
        if (endPointRemainingLength < basicLength) {
            endPoint = CGPointMake(self.bounds.size.width - endPointRemainingLength, self.bounds.size.height / 2);
            CGPathAddLineToPoint(leftPath, NULL, endPoint.x, endPoint.y);
            CGPathAddLineToPoint(rightPath, NULL, endPointRemainingLength, self.bounds.size.height / 2);
        } else {
            CGPathAddLineToPoint(leftPath, NULL, self.bounds.size.width - basicLength, self.bounds.size.height / 2);
            CGFloat endPointAngle = (endPointRemainingLength - basicLength) / kDefaultProcessingCircleRadius;
            CGPathAddRelativeArc(leftPath, NULL, CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds), kDefaultProcessingCircleRadius, 0, -endPointAngle);
            
            CGPathAddLineToPoint(rightPath, NULL, basicLength, self.bounds.size.height / 2);
            CGPathAddRelativeArc(rightPath, NULL, CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds), kDefaultProcessingCircleRadius, M_PI, -endPointAngle);
        }
    }
    
    CGContextAddPath(context, leftPath);
    CGContextAddPath(context, rightPath);
    
    CGContextSetLineCap(context, kCGLineCapRound);
    CGContextSetLineWidth(context, self.primaryWaveLineWidth);
    [self.waveColor set];
    CGContextStrokePath(context);
}

- (void) drawTransitioningToPauseInContext:(CGContextRef)context
{
    CGFloat centerX = CGRectGetMidX(self.bounds);
    CGFloat centerY = CGRectGetMidY(self.bounds);
    
    CGMutablePathRef leftPath = CGPathCreateMutable();
    CGMutablePathRef rightPath = CGPathCreateMutable();
    CGFloat basicLength = self.bounds.size.width / 2 - kDefaultProcessingCircleRadius;
    CGPoint leftPoint = CGPointMake(basicLength * self.transitionPercent, centerY);
    CGPoint rightPoint = CGPointMake(basicLength, centerY);
    CGPathMoveToPoint(leftPath, NULL, leftPoint.x, leftPoint.y);
    CGPathAddLineToPoint(leftPath, NULL, rightPoint.x, rightPoint.y);
    
    CGPathAddRelativeArc(leftPath, NULL, centerX, centerY, kDefaultProcessingCircleRadius, M_PI, M_PI * self.transitionPercent);
    
    leftPoint = CGPointMake(centerX + kDefaultProcessingCircleRadius, centerY);
    rightPoint = CGPointMake(centerX + kDefaultProcessingCircleRadius + basicLength * (1 - self.transitionPercent), centerY);
    
    CGPathMoveToPoint(rightPath, NULL, rightPoint.x, rightPoint.y);
    CGPathAddLineToPoint(rightPath, NULL, leftPoint.x, leftPoint.y);
    CGPathAddRelativeArc(rightPath, NULL, centerX, CGRectGetMidY(self.bounds), kDefaultProcessingCircleRadius, 0, M_PI * self.transitionPercent);
    
    CGContextAddPath(context, leftPath);
    CGContextAddPath(context, rightPath);
    
    CGContextSetLineCap(context, kCGLineCapRound);
    CGContextSetLineWidth(context, self.primaryWaveLineWidth);
    [self.waveColor set];
    
    CGContextStrokePath(context);
    
    CGMutablePathRef leftLine = CGPathCreateMutable();
    CGMutablePathRef rightLine = CGPathCreateMutable();
    
    CGFloat percent = NSBKeyframeAnimationFunctionEaseOutBack(self.transitionPercent, 0, 1, 1);
    CGFloat length = kDefaultProcessingCircleRadius * 0.618 / 2 * percent;
    CGFloat topY = centerY - length;
    CGFloat bottomY = centerY + length;
    
    CGPathMoveToPoint(leftLine, NULL, centerX - kDefaultProcessingCircleRadius * 0.2, topY);
    CGPathAddLineToPoint(leftLine, NULL, centerX - kDefaultProcessingCircleRadius * 0.2, bottomY);
    
    CGPathMoveToPoint(rightLine, NULL, centerX + kDefaultProcessingCircleRadius * 0.2, topY);
    CGPathAddLineToPoint(rightLine, NULL, centerX + kDefaultProcessingCircleRadius * 0.2, bottomY);
    
    CGContextAddPath(context, leftLine);
    CGContextAddPath(context, rightLine);
    CGContextSetLineWidth(context, self.primaryWaveLineWidth * 2);
    
    CGContextStrokePath(context);
}

- (void) drawPausedIconInContext:(CGContextRef) context
{
    CGFloat centerX = CGRectGetMidX(self.bounds);
    CGFloat centerY = CGRectGetMidY(self.bounds);
    
    CGMutablePathRef circle = CGPathCreateMutable();
    CGPathAddArc(circle, NULL, centerX, centerY, kDefaultProcessingCircleRadius, 0, M_PI * 2, true);
    CGContextAddPath(context, circle);
    CGContextSetLineWidth(context, self.primaryWaveLineWidth);
    [self.waveColor set];
    
    CGContextStrokePath(context);
    
    CGMutablePathRef leftLine = CGPathCreateMutable();
    CGMutablePathRef rightLine = CGPathCreateMutable();
    
    CGFloat percent = NSBKeyframeAnimationFunctionEaseOutBack(self.transitionPercent, 0, 1, 1);
    CGFloat length = kDefaultProcessingCircleRadius * 0.618 / 2 * percent;
    CGFloat topY = centerY - length;
    CGFloat bottomY = centerY + length;
    
    CGPathMoveToPoint(leftLine, NULL, centerX - kDefaultProcessingCircleRadius * 0.2, topY);
    CGPathAddLineToPoint(leftLine, NULL, centerX - kDefaultProcessingCircleRadius * 0.2, bottomY);
    
    CGPathMoveToPoint(rightLine, NULL, centerX + kDefaultProcessingCircleRadius * 0.2, topY);
    CGPathAddLineToPoint(rightLine, NULL, centerX + kDefaultProcessingCircleRadius * 0.2, bottomY);
    
    CGContextAddPath(context, leftLine);
    CGContextAddPath(context, rightLine);
    CGContextSetLineCap(context, kCGLineCapRound);
    CGContextSetLineWidth(context, self.primaryWaveLineWidth * 2);
    
    CGContextStrokePath(context);
}

#pragma mark - Microphone Image
- (UIImage *) microphoneImage
{
    return [UIImage imageNamed:@"microphone.png"];
}
@end

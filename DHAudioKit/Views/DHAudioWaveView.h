//
//  DHAudioWaveView.h
//  DHAudio
//
//  Created by Huang Hongsen on 17/6/6.
//  Copyright © 2017年 Huang Hongsen. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol DHAudioWaveViewDataSource
- (double) audioLevel;
@end

@interface DHAudioWaveView : UIView

- (void) startRecording;

- (void) stopRecordingAndStartProcessing;

- (void) finishProcessing;

- (void) resumeRecording;

- (void) pause;

@property (nonatomic, weak) id<DHAudioWaveViewDataSource> dataSource;

@property (nonatomic) NSUInteger numberOfWaves;

@property (nonatomic, strong) UIColor *waveColor;

@property (nonatomic) CGFloat primaryWaveLineWidth;

@property (nonatomic) CGFloat secondaryWaveLineWidth;

@property (nonatomic) CGFloat idleAmplitude;

@property (nonatomic) CGFloat frequency;

@property (nonatomic, readonly) CGFloat amplitude;

@property (nonatomic) CGFloat density;

@property (nonatomic) CGFloat phaseShift;

@end

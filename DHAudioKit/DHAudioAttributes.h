//
//  DHAudioAttributes.h
//  DHAudio
//
//  Created by Huang Hongsen on 17/6/6.
//  Copyright © 2017年 Huang Hongsen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DHAudioAttributes : NSObject

typedef NS_ENUM(NSInteger, DHAudioSampleRate) {
    DHAudioSampleRate96000 = 96000,
    DHAudioSampleRate88200 = 88200,
    DHAudioSampleRate64000 = 64000,
    DHAudioSampleRate48000 = 48000,
    DHAudioSampleRate44100 = 44100,
    DHAudioSampleRate32000 = 32000,
    DHAudioSampleRate24000 = 24000,
    DHAudioSampleRate22050 = 22050,
    DHAudioSampleRate16000 = 16000,
    DHAudioSampleRate12000 = 12000,
    DHAudioSampleRate11025 = 11025,
    DHAudioSampleRate8000 = 8000,
    DHAudioSampleRate7350 = 7350
};


typedef NS_ENUM(NSInteger, DHAudioType) {
    DHAudioTypeLinearPCM,
    DHAudioTypeAAC,
    DHAudioTypeMP3,
    DHAudioTypeOpus,
};


typedef NS_ENUM(NSInteger, DHAudioPauseEvent) {
    DHAudioPauseEventUserPause,
    DHAudioPauseEventRunningOutOfData,
    DHAudioPauseEventInterruption,
    DHAudioPauseEventRouterChange,
};

@end
